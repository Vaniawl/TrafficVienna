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

        return batches.compactMap { $0 }.flatMap { $0 }
    }
}

private extension WidgetDepartureData {
    nonisolated var routeKey: WidgetRouteKey {
        WidgetRouteKey(lineName: lineName, destination: destination)
    }
}
