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

nonisolated struct WidgetCacheEnvelope: Codable {
    let items: [WidgetDepartureData]
    let lastUpdated: Date
}
