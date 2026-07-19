//
//  NearbyViewModel.swift
//  TrafficVienna
//
//  Coordinates the Nearby tab. Instead of each card firing its own request
//  (which used to flood the API), this loads nearby stations concurrently
//  through the shared, throttled MonitorService, tracks a single "last updated"
//  time and supports manual refresh.
//

import Foundation
import Combine
import CoreLocation

nonisolated struct StationCardContent: Equatable, Sendable {
    struct Row: Equatable, Sendable {
        let lineName: String
        let destination: String
        let minutes: [Int]
        let nextIsLive: Bool
    }

    static let empty = StationCardContent(badgeLineNames: [], rows: [])
    private static let maximumRows = 4
    private static let maximumDepartureMinutes = 3

    let badgeLineNames: [String]
    let rows: [Row]

    init(lines: [Lines]) {
        var badges = Set<String>()
        badges.reserveCapacity(lines.count)
        var preparedRows: [Row] = []
        preparedRows.reserveCapacity(min(Self.maximumRows, lines.count))

        for line in lines {
            badges.insert(line.name)
            guard preparedRows.count < Self.maximumRows else { continue }

            var minutes: [Int] = []
            minutes.reserveCapacity(min(Self.maximumDepartureMinutes, line.departures.departure.count))
            for departure in line.departures.departure.prefix(Self.maximumDepartureMinutes) {
                minutes.append(departure.departureTime.liveMinutes)
            }
            preparedRows.append(Row(
                lineName: line.name,
                destination: line.towards,
                minutes: minutes,
                nextIsLive: line.departures.departure.first?.departureTime.timeReal != nil
            ))
        }

        badgeLineNames = badges.sorted()
        rows = preparedRows
    }

    private init(badgeLineNames: [String], rows: [Row]) {
        self.badgeLineNames = badgeLineNames
        self.rows = rows
    }
}

nonisolated private struct NearbyStationUpdate: Sendable {
    let cardContent: StationCardContent
    let freshness: DataFreshness
}

@MainActor
final class NearbyViewModel: ObservableObject {
    struct Item: Identifiable {
        let station: Station
        let distance: Double
        var cardContent: StationCardContent = .empty
        var failed: Bool = false
        var updatedAt: Date? = nil
        var freshness: DataFreshness? = nil

        var id: Int { station.id }
        var walkMinutes: Int { max(1, Int((distance / walkingSpeed).rounded())) }
    }

    @Published private(set) var items: [Item] = []
    @Published private(set) var isLoading = false      // first fill, nothing to show yet
    @Published private(set) var isRefreshing = false   // updating already-shown data

    private let store: StationStore
    private let location: LocationManager
    private let service: MonitorService
    private let radius: Double = 500
    private let maxStations = 8
    private var loadGeneration = 0

    init(store: StationStore, location: LocationManager, service: MonitorService = .shared) {
        self.store = store
        self.location = location
        self.service = service
    }

    var hasLocation: Bool { location.userLocation != nil }

    // Rebuilds the nearby list from the current location, keeping already-loaded
    // departures for stations that are still in range.
    private func rebuildList() {
        guard let location = location.userLocation else {
            items = []
            return
        }
        let previous = Dictionary(uniqueKeysWithValues: items.map { ($0.id, $0) })
        items = store.nearestStationsWithDistance(
            near: location,
            radiusInMeters: radius,
            limit: maxStations
        )
            .map { pair in
                Item(station: pair.station,
                     distance: pair.meters,
                     cardContent: previous[pair.station.id]?.cardContent ?? .empty,
                     failed: false)
            }
    }

    func load(force: Bool = false) async {
        guard force || (!isLoading && !isRefreshing) else { return }
        loadGeneration &+= 1
        let generation = loadGeneration
        rebuildList()
        guard !items.isEmpty else {
            isLoading = false
            isRefreshing = false
            return
        }

        let firstFill = items.allSatisfy { $0.cardContent.rows.isEmpty }
        isLoading = false
        isRefreshing = false
        if firstFill { isLoading = true } else { isRefreshing = true }
        defer {
            if generation == loadGeneration {
                isLoading = false
                isRefreshing = false
            }
        }

        // MonitorService owns request spacing; overlapping waits avoid adding
        // response latency on top of the required API cadence.
        await withTaskGroup(of: (Int, NearbyStationUpdate?).self) { group in
            for item in items {
                guard let diva = item.station.diva else { continue }
                let id = item.id
                group.addTask { [service] in
                    guard let result = try? await service.monitorResult(
                        diva: diva,
                        forceRefresh: force
                    ) else { return (id, nil) }
                    let lines = result.value.data.monitors.flatMap { $0.lines }
                    return (
                        id,
                        NearbyStationUpdate(
                            cardContent: StationCardContent(lines: lines),
                            freshness: result.freshness
                        )
                    )
                }
            }

            for await (id, stationUpdate) in group {
                guard !Task.isCancelled, generation == loadGeneration else {
                    group.cancelAll()
                    return
                }
                guard let stationUpdate else {
                    update(id: id) { $0.failed = true }
                    continue
                }
                update(id: id) {
                    $0.cardContent = stationUpdate.cardContent
                    $0.failed = false
                    $0.updatedAt = stationUpdate.freshness.updatedAt
                    $0.freshness = stationUpdate.freshness
                }
            }
        }
    }

    private func update(id: Int, _ mutate: (inout Item) -> Void) {
        guard let index = items.firstIndex(where: { $0.id == id }) else { return }
        mutate(&items[index])
    }
}
