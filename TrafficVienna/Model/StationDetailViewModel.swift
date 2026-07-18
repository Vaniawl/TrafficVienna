//
//  StationDetailViewModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 13.11.25.
//

import Foundation
import Combine


final class StationDetailViewModel: ObservableObject {
    let station: Station
    private let service: MonitorService
    private let favoritesRepo: FavoritesRepository
    private let stationsRepo: FavoriteStationsStoring

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var monitor: MonitorResponse?
    @Published var lastUpdated: Date?
    @Published var isStationFavorited = false
    @Published var categoryFilter: LineCategory? = nil
    @Published private(set) var freshness: DataFreshness?

    // Active disruptions / notices for this station's lines.
    var trafficInfos: [TrafficInfo] {
        monitor?.data.trafficInfos ?? []
    }

    // Line names that are affected by at least one disruption.
    private var disruptedLines: Set<String> {
        Set(trafficInfos.flatMap { $0.relatedLines ?? [] })
    }

    func hasDisruption(lineName: String) -> Bool {
        disruptedLines.contains(lineName)
    }

    // One departure direction at the station.
    struct DepartureGroup: Identifiable {
        let line: String
        let destination: String
        let minutes: [Int]   // live, ascending
        let isLive: Bool
        var id: String { line + "|" + destination }
    }

    // All departures across every platform, merged by line+direction and
    // sorted so the soonest one is first. Replaces the per-platform grouping
    // that produced repeated "<station>" section headers.
    var groups: [DepartureGroup] {
        guard let monitor else { return [] }
        var merged: [String: (line: String, dest: String, mins: [Int], live: Bool)] = [:]
        var order: [String] = []

        for platform in monitor.data.monitors {
            for line in platform.lines {
                let key = line.name + "|" + line.towards
                let mins = line.departures.departure.map { $0.departureTime.liveMinutes }
                let live = line.departures.departure.first?.departureTime.timeReal != nil
                if var existing = merged[key] {
                    existing.mins += mins
                    existing.live = existing.live || live
                    merged[key] = existing
                } else {
                    merged[key] = (line.name, line.towards, mins, live)
                    order.append(key)
                }
            }
        }

        let all = order.compactMap { merged[$0] }
            .map { DepartureGroup(line: $0.line, destination: $0.dest,
                                  minutes: $0.mins.sorted(), isLive: $0.live) }
            .sorted { ($0.minutes.first ?? .max) < ($1.minutes.first ?? .max) }

        guard let filter = categoryFilter else { return all }
        return all.filter { LineCategory.of($0.line) == filter }
    }

    var availableCategories: [LineCategory] {
        guard let monitor else { return [] }
        let all = Set(
            monitor.data.monitors
                .flatMap { $0.lines }
                .map { LineCategory.of($0.name) }
        )
        return LineCategory.allCases.filter(all.contains)
    }

    var lastUpdatedText: String? {
        guard let lastUpdated else { return nil }
        let seconds = Int(Date().timeIntervalSince(lastUpdated))
        switch seconds {
        case ..<10:    return "updated just now"
        case ..<60:    return "updated \(seconds)s ago"
        case ..<3600:  return "updated \(seconds / 60)m ago"
        default:       return "updated \(seconds / 3600)h ago"
        }
    }

    init(
        station: Station,
        service: MonitorService = .shared,
        favoritesRepo: FavoritesRepository = UserDefaultsFavoritesRepository(),
        stationsRepo: FavoriteStationsStoring = UserDefaultsFavoriteStationsRepository()
    ) {
        self.station = station
        self.service = service
        self.favoritesRepo = favoritesRepo
        self.stationsRepo = stationsRepo
        self.isStationFavorited = stationsRepo.contains(id: station.id)
    }

    func toggleStationFavorite() {
        stationsRepo.toggle(FavoriteStation(station))
        isStationFavorited = stationsRepo.contains(id: station.id)
    }

    // Loads live monitor data for the current station's DIVA.
    @MainActor
    func load(forceRefresh: Bool = false) async {
        errorMessage = nil
        isLoading = true

        defer { isLoading = false }
        guard let diva = station.diva else {
            errorMessage = "No live data for this station"
            return
        }

        do {
            let result = try await service.monitorResult(diva: diva, forceRefresh: forceRefresh)
            self.monitor = result.value
            self.freshness = result.freshness
            self.lastUpdated = result.freshness.updatedAt
            if let widgetData = widgetData(from: result.value) {
                WidgetSyncManager().save([widgetData])
            }
        } catch {
            errorMessage = error.monitorDisplayMessage
        }
    }

    var staleMessage: String? {
        guard case let .stale(_, message) = freshness else { return nil }
        return message
    }
    
    func isFavorite(line: String, destination: String) -> Bool {
        guard let divaInt = station.diva else { return false }
        return favoritesRepo.isFavorite(
            diva: String(divaInt),
            lineName: line,
            destination: destination
        )
    }

    func toggleFavorite(line: String, destination: String) {
        guard let divaInt = station.diva else { return }
        favoritesRepo.toggle(
            diva: String(divaInt),
            lineName: line,
            destination: destination
        )
    }
    
    private func widgetData(from response: MonitorResponse) -> WidgetDepartureData? {
        guard let monitor = response.data.monitors.first else {
            return nil
        }
        guard let line = monitor.lines.first else {
            return nil
        }
        let lineName = line.name
        let stopName = monitor.locationStop.properties.title
        let destination = line.towards
        let allDepartures = line.departures.departure
        let minutes = allDepartures.map { $0.departureTime.countdown }
        let nextThree = Array(minutes.prefix(3))
        
        return WidgetDepartureData(
            lineName: lineName, stopName: stopName, destination: destination, departures: nextThree
        )
    }
}
