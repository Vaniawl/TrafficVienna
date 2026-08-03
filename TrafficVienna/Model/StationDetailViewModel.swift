import Foundation
import Observation

@MainActor
@Observable
final class StationDetailViewModel {
    let station: Station
    private(set) var state: StationDetailState = .loading
    private(set) var isLoadingRequest = false
    private(set) var refreshErrorMessage: String?
    private(set) var trafficInfos: [TrafficInfo] = []
    private(set) var lastUpdated: Date?
    private(set) var isStationFavorited: Bool
    private(set) var trackedDepartureID: StationDepartureID?
    private(set) var isShowingStaleData = false
    var categoryFilter: LineCategory?
    var notice: StationDetailNotice?

    private var allGroups: [StationDepartureGroup] = []
    private var isForceRefreshQueued = false
    private var explicitlyStoppedDepartureID: StationDepartureID?
    private var favoriteRoutes: Set<FavoriteRoute>
    private let service: MonitorProviding
    private let favoritesRepo: FavoritesRepository
    private let stationsRepo: FavoriteStationsStoring
    private let liveActivityStarter: LiveActivityStarting
    private let reminderClient: DepartureReminderClient

    init(
        station: Station,
        service: MonitorProviding = MonitorService.shared,
        favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository(),
        stationsRepo: FavoriteStationsStoring = UserDefaultsFavoriteStationsRepository(),
        liveActivityStarter: LiveActivityStarting = SystemLiveActivityStarter(),
        reminderClient: DepartureReminderClient = .live
    ) {
        self.station = station
        self.service = service
        self.favoritesRepo = favoritesRepo
        self.stationsRepo = stationsRepo
        self.liveActivityStarter = liveActivityStarter
        self.reminderClient = reminderClient
        isStationFavorited = stationsRepo.contains(id: station.id)
        favoriteRoutes = Set(favoritesRepo.getAll())
    }

    var groups: [StationDepartureGroup] {
        guard let categoryFilter else { return allGroups }
        return allGroups.filter { LineCategory.of($0.line) == categoryFilter }
    }

    var availableCategories: [LineCategory] {
        let categories = Set(allGroups.map { LineCategory.of($0.line) })
        return LineCategory.allCases.filter(categories.contains)
    }

    func hasDisruption(lineName: String) -> Bool {
        trafficInfos.contains { ($0.relatedLines ?? []).contains(lineName) }
    }

    func isFavorite(_ group: StationDepartureGroup) -> Bool {
        guard let diva = station.diva else { return false }
        return favoriteRoutes.contains(
            FavoriteRoute(diva: String(diva), lineName: group.line, destination: group.destination)
        )
    }

    func toggleStationFavorite() {
        stationsRepo.toggle(FavoriteStation(station))
        reloadStationFavorite()
    }

    func toggleFavorite(_ group: StationDepartureGroup) {
        guard let diva = station.diva else { return }
        let route = FavoriteRoute(diva: String(diva), lineName: group.line, destination: group.destination)
        favoritesRepo.toggle(diva: route.diva, lineName: route.lineName, destination: route.destination)
        reloadRouteFavorites()
    }

    func reloadStationFavorite() {
        isStationFavorited = stationsRepo.contains(id: station.id)
    }

    func reloadRouteFavorites() {
        favoriteRoutes = Set(favoritesRepo.getAll())
    }

    func startTracking(_ group: StationDepartureGroup) {
        if trackedDepartureID == group.id {
            explicitlyStoppedDepartureID = group.id
            liveActivityStarter.stopAll()
            trackedDepartureID = nil
            return
        }

        guard ensureLiveDeparturesForSystemCountdown() else { return }

        guard liveActivityStarter.isAvailable else {
            notice = StationDetailNotice(
                title: String(localized: "Live Activity"),
                message: String(localized: "Enable Live Activities in Settings to track departures on the Lock Screen.")
            )
            return
        }

        do {
            try liveActivityStarter.start(
                line: group.line,
                destination: group.destination,
                stop: station.name,
                minutes: group.minutes.first ?? 0,
                isLive: group.isLive
            )
            explicitlyStoppedDepartureID = nil
            trackedDepartureID = group.id
        } catch {
            notice = StationDetailNotice(
                title: String(localized: "Live Activity"),
                message: String(localized: "The Live Activity could not be started. Please try again.")
            )
        }
    }

    func scheduleReminder(_ group: StationDepartureGroup) async {
        guard ensureLiveDeparturesForSystemCountdown() else { return }

        do {
            let reminder = try await reminderClient.schedule(
                DepartureReminderRequest(
                    stationID: station.id,
                    line: group.line,
                    destination: group.destination,
                    stop: station.name,
                    minutes: group.minutes.first ?? 0
                )
            )
            let time = reminder.fireDate?.formatted(date: .omitted, time: .shortened) ?? ""
            notice = StationDetailNotice(
                title: String(localized: "Reminder set"),
                message: String(
                    format: String(localized: "We’ll remind you about %@ at %@."),
                    locale: .current,
                    group.line,
                    time
                )
            )
        } catch {
            let message = (error as? DepartureReminderError)?.localizedDescription
                ?? String(localized: "The reminder could not be scheduled. Please try again.")
            notice = StationDetailNotice(
                title: String(localized: "Departure reminder"),
                message: message,
                offersSettings: error as? DepartureReminderError == .notificationsDisabled
            )
        }
    }

    func load(forceRefresh: Bool = false) async {
        guard !isLoadingRequest else {
            isForceRefreshQueued = isForceRefreshQueued || forceRefresh
            return
        }
        isLoadingRequest = true
        defer {
            isForceRefreshQueued = false
            isLoadingRequest = false
        }

        var nextForceRefresh: Bool? = forceRefresh
        while let currentForceRefresh = nextForceRefresh {
            isForceRefreshQueued = false
            await loadPass(forceRefresh: currentForceRefresh)
            guard !Task.isCancelled else { return }
            nextForceRefresh = isForceRefreshQueued ? true : nil
        }
    }

    private func loadPass(forceRefresh: Bool) async {
        refreshErrorMessage = nil
        if lastUpdated == nil { state = .loading }

        guard let diva = station.diva else {
            state = .failed(String(localized: "No live data for this station."))
            return
        }

        do {
            let snapshot = try await service.monitorSnapshot(diva: diva, forceRefresh: forceRefresh)
            guard !Task.isCancelled else { return }
            guard !isForceRefreshQueued else { return }
            let response = snapshot.response
            trafficInfos = response.data.trafficInfos ?? []
            allGroups = Self.departureGroups(from: response)
            if let categoryFilter,
               !allGroups.contains(where: {
                   LineCategory.of($0.line) == categoryFilter
               }) {
                self.categoryFilter = nil
            }
            lastUpdated = snapshot.updatedAt
            isShowingStaleData = snapshot.isStale
            if snapshot.isStale {
                refreshErrorMessage = String(localized: "Showing saved data from the last successful update.")
            }
            state = allGroups.isEmpty ? .empty : .loaded
            updateTrackedActivity()
        } catch {
            guard !Task.isCancelled else { return }
            guard !isForceRefreshQueued else { return }
            if allGroups.isEmpty {
                isShowingStaleData = false
                state = .failed(error.monitorDisplayMessage)
            } else {
                isShowingStaleData = true
                refreshErrorMessage = error.monitorDisplayMessage
            }
        }
    }

    private func updateTrackedActivity() {
        let activeID = liveActivityStarter.activeDepartureID(for: station.name)

        if let explicitlyStoppedDepartureID {
            guard activeID != explicitlyStoppedDepartureID else {
                return
            }
            self.explicitlyStoppedDepartureID = nil
        }

        guard let activeID,
              let group = allGroups.first(where: { $0.id == activeID })
        else {
            trackedDepartureID = nil
            return
        }

        trackedDepartureID = activeID
        liveActivityStarter.update(
            line: group.line,
            destination: group.destination,
            stop: station.name,
            minutes: group.minutes.first ?? 0,
            isLive: group.isLive
        )
    }

    private func ensureLiveDeparturesForSystemCountdown() -> Bool {
        guard isShowingStaleData else { return true }
        notice = StationDetailNotice(
            title: String(localized: "Live departures required"),
            message: String(localized: "Refresh live departures before setting a reminder or starting Lock Screen tracking.")
        )
        return false
    }

    private static func departureGroups(from response: MonitorResponse) -> [StationDepartureGroup] {
        var merged: [StationDepartureID: (minutes: [Int], isLive: Bool)] = [:]

        for line in response.data.monitors.flatMap(\.lines) {
            let id = StationDepartureID(line: line.name, destination: line.towards)
            let minutes = line.departures.departure.map { $0.departureTime.liveMinutes }
            guard !minutes.isEmpty else { continue }
            let isLive = line.departures.departure.contains { $0.departureTime.timeReal != nil }
            let existing = merged[id] ?? ([], false)
            merged[id] = (existing.minutes + minutes, existing.isLive || isLive)
        }

        return merged.map { id, value in
            StationDepartureGroup(
                line: id.line,
                destination: id.destination,
                minutes: value.minutes.sorted(),
                isLive: value.isLive
            )
        }
        .sorted {
            let left = $0.minutes.first ?? .max
            let right = $1.minutes.first ?? .max
            if left != right { return left < right }
            if $0.line != $1.line {
                return $0.line.localizedStandardCompare($1.line) == .orderedAscending
            }
            return $0.destination.localizedStandardCompare($1.destination) == .orderedAscending
        }
    }
}
