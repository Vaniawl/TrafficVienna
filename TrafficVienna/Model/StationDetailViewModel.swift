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
    var categoryFilter: LineCategory?
    var notice: StationDetailNotice?

    private var allGroups: [StationDepartureGroup] = []
    private var favoriteRoutes: Set<FavoriteRoute>
    private let service: MonitorProviding
    private let favoritesRepo: FavoritesRepository
    private let stationsRepo: FavoriteStationsStoring
    private let liveActivityStarter: LiveActivityStarting

    init(
        station: Station,
        service: MonitorProviding = MonitorService.shared,
        favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository(),
        stationsRepo: FavoriteStationsStoring = UserDefaultsFavoriteStationsRepository(),
        liveActivityStarter: LiveActivityStarting = SystemLiveActivityStarter()
    ) {
        self.station = station
        self.service = service
        self.favoritesRepo = favoritesRepo
        self.stationsRepo = stationsRepo
        self.liveActivityStarter = liveActivityStarter
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
        isStationFavorited = stationsRepo.contains(id: station.id)
    }

    func toggleFavorite(_ group: StationDepartureGroup) {
        guard let diva = station.diva else { return }
        let route = FavoriteRoute(diva: String(diva), lineName: group.line, destination: group.destination)
        favoritesRepo.toggle(diva: route.diva, lineName: route.lineName, destination: route.destination)
        if favoriteRoutes.remove(route) == nil {
            favoriteRoutes.insert(route)
        }
    }

    func startTracking(_ group: StationDepartureGroup) {
        guard liveActivityStarter.isAvailable else {
            notice = StationDetailNotice(
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
            trackedDepartureID = group.id
        } catch {
            notice = StationDetailNotice(
                message: String(localized: "The Live Activity could not be started. Please try again.")
            )
        }
    }

    func load(forceRefresh: Bool = false) async {
        guard !isLoadingRequest else { return }
        isLoadingRequest = true
        refreshErrorMessage = nil
        if lastUpdated == nil { state = .loading }
        defer { isLoadingRequest = false }

        guard let diva = station.diva else {
            state = .failed(String(localized: "No live data for this station."))
            return
        }

        do {
            let snapshot = try await service.monitorSnapshot(diva: diva, forceRefresh: forceRefresh)
            guard !Task.isCancelled else { return }
            let response = snapshot.response
            trafficInfos = response.data.trafficInfos ?? []
            allGroups = Self.departureGroups(from: response)
            lastUpdated = snapshot.updatedAt
            if snapshot.isStale {
                refreshErrorMessage = String(localized: "Showing saved data from the last successful update.")
            }
            state = allGroups.isEmpty ? .empty : .loaded
        } catch {
            if allGroups.isEmpty {
                state = .failed(error.monitorDisplayMessage)
            } else {
                refreshErrorMessage = error.monitorDisplayMessage
            }
        }
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
