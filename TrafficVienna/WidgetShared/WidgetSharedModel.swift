//
//  WidgetSharedModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 25.11.25.
//

import Foundation

nonisolated struct WidgetDepartureData: Codable, Equatable, Sendable {
    let lineName: String
    let stopName: String
    let destination: String
    let departures: [Int]
    let fetchedAt: Date?

    init(
        lineName: String,
        stopName: String,
        destination: String,
        departures: [Int],
        fetchedAt: Date? = nil
    ) {
        self.lineName = lineName
        self.stopName = stopName
        self.destination = destination
        self.departures = departures
        self.fetchedAt = fetchedAt
    }
}

nonisolated struct WidgetRouteKey: Hashable, Sendable {
    let lineName: String
    let destination: String
}

nonisolated enum WidgetDataMerge {
    static func ordered(
        selected: [WidgetRouteKey],
        fresh: [WidgetDepartureData],
        cached: [WidgetDepartureData]
    ) -> [WidgetDepartureData] {
        let freshByRoute = fresh.reduce(into: [WidgetRouteKey: WidgetDepartureData]()) {
            $0[$1.routeKey] = $1
        }
        let cachedByRoute = cached.reduce(into: [WidgetRouteKey: WidgetDepartureData]()) {
            $0[$1.routeKey] = $1
        }
        return selected.compactMap { freshByRoute[$0] ?? cachedByRoute[$0] }
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
                lineName: item.lineName,
                stopName: item.stopName,
                destination: item.destination,
                departures: departures,
                fetchedAt: item.fetchedAt
            )
        }
    }
}

nonisolated enum WidgetBatchLoader {
    static func load<Group: Sendable, Item: Sendable>(
        _ groups: [Group],
        spacingNanoseconds: UInt64,
        operation: @escaping @Sendable (Group) async -> [Item]
    ) async -> [Item] {
        guard !groups.isEmpty else { return [] }
        var batches = Array<[Item]?>(repeating: nil, count: groups.count)

        await withTaskGroup(of: (Int, [Item]?).self) { taskGroup in
            for (index, group) in groups.enumerated() {
                taskGroup.addTask {
                    do {
                        let (delay, overflow) = spacingNanoseconds.multipliedReportingOverflow(
                            by: UInt64(index)
                        )
                        guard !overflow else { return (index, nil) }
                        if delay > 0 {
                            try await Task.sleep(nanoseconds: delay)
                        }
                        try Task.checkCancellation()
                        return (index, await operation(group))
                    } catch {
                        return (index, nil)
                    }
                }
            }

            for await (index, items) in taskGroup {
                batches[index] = items
            }
        }

        let itemCount = batches.reduce(into: 0) { count, batch in
            count += batch?.count ?? 0
        }
        var items: [Item] = []
        items.reserveCapacity(itemCount)
        for case let batch? in batches {
            items.append(contentsOf: batch)
        }
        return items
    }
}

private extension WidgetDepartureData {
    nonisolated var routeKey: WidgetRouteKey {
        WidgetRouteKey(lineName: lineName, destination: destination)
    }
}
