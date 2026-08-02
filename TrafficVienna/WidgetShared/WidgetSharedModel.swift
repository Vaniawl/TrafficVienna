//
//  WidgetSharedModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 25.11.25.
//

import Foundation

nonisolated struct WidgetDepartureData: Codable, Equatable, Sendable {
    let diva: String?
    let lineName: String
    let stopName: String
    let destination: String
    let departures: [Int]
    let fetchedAt: Date?

    init(
        diva: String? = nil,
        lineName: String,
        stopName: String,
        destination: String,
        departures: [Int],
        fetchedAt: Date? = nil
    ) {
        self.diva = diva
        self.lineName = lineName
        self.stopName = stopName
        self.destination = destination
        self.departures = departures
        self.fetchedAt = fetchedAt
    }
}

nonisolated struct WidgetRouteKey: Hashable, Sendable {
    let diva: String?
    let lineName: String
    let destination: String

    init(
        diva: String? = nil,
        lineName: String,
        destination: String
    ) {
        self.diva = diva
        self.lineName = lineName
        self.destination = destination
    }
}

nonisolated enum WidgetDataMerge {
    static func ordered(
        selected: [WidgetRouteKey],
        fresh: [WidgetDepartureData],
        cached: [WidgetDepartureData]
    ) -> [WidgetDepartureData] {
        let freshByRoute = Dictionary(
            fresh.map { ($0.routeKey, $0) },
            uniquingKeysWith: { first, _ in first }
        )
        let cachedByRoute = Dictionary(
            cached.map { ($0.routeKey, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        return selected.compactMap { key in
            if let fresh = freshByRoute[key] {
                return fresh
            }
            if let cached = cachedByRoute[key] {
                return cached
            }

            let legacyKey = WidgetRouteKey(
                lineName: key.lineName,
                destination: key.destination
            )
            return cachedByRoute[legacyKey]
        }
    }
}

nonisolated enum WidgetCountdownProjection {
    static func items(
        _ items: [WidgetDepartureData],
        fallbackUpdatedAt: Date?,
        at entryDate: Date
    ) -> [WidgetDepartureData] {
        items.map { item in
            let sourceDate = item.fetchedAt ?? fallbackUpdatedAt ?? entryDate
            let elapsedMinutes = max(0, Int(entryDate.timeIntervalSince(sourceDate) / 60))
            let departures = item.departures
                .map { $0 - elapsedMinutes }
                .filter { $0 >= 0 }

            return WidgetDepartureData(
                diva: item.diva,
                lineName: item.lineName,
                stopName: item.stopName,
                destination: item.destination,
                departures: departures,
                fetchedAt: item.fetchedAt
            )
        }
    }
}

nonisolated enum WidgetFreshness {
    static func elapsedWholeMinutes(
        since lastUpdated: Date,
        at entryDate: Date
    ) -> Int {
        max(0, Int(entryDate.timeIntervalSince(lastUpdated) / 60))
    }
}

nonisolated enum WidgetSnapshotContent: Equatable, Sendable {
    case placeholder
    case empty
    case items
}

nonisolated enum WidgetSnapshotPolicy {
    static func content(
        hasItems: Bool,
        isPreview: Bool
    ) -> WidgetSnapshotContent {
        if hasItems {
            return .items
        }
        return isPreview ? .placeholder : .empty
    }
}

nonisolated enum WidgetTimelineSchedule {
    static func entryDates(
        now: Date,
        refreshDate: Date,
        items: [WidgetDepartureData],
        fallbackUpdatedAt: Date?
    ) -> [Date] {
        var dates = Set([now, refreshDate])

        for item in items {
            let sourceDate = min(
                item.fetchedAt ?? fallbackUpdatedAt ?? now,
                now
            )

            for minutes in item.departures.prefix(2) where minutes > 0 {
                let departureDate = sourceDate.addingTimeInterval(
                    TimeInterval(minutes * 60)
                )
                guard departureDate > now, departureDate < refreshDate else {
                    continue
                }

                dates.insert(departureDate)
                dates.insert(
                    min(
                        departureDate.addingTimeInterval(60),
                        refreshDate
                    )
                )
            }
        }

        return dates.sorted()
    }
}

private extension WidgetDepartureData {
    nonisolated var routeKey: WidgetRouteKey {
        WidgetRouteKey(
            diva: diva,
            lineName: lineName,
            destination: destination
        )
    }
}
