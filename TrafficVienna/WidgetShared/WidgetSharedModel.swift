//
//  WidgetSharedModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 25.11.25.
//

import Foundation

nonisolated struct WidgetDepartureData: Codable {
    let lineName: String
    let stopName: String
    let destination: String
    let departures: [Int]
}

nonisolated struct WidgetRouteKey: Hashable {
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

private extension WidgetDepartureData {
    nonisolated var routeKey: WidgetRouteKey {
        WidgetRouteKey(lineName: lineName, destination: destination)
    }
}
