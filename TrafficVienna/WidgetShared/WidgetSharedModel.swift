//
//  WidgetSharedModel.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 25.11.25.
//

import Foundation

struct WidgetDepartureData: Codable {
    let lineName: String
    let stopName: String
    let destination: String
    let departures: [Int]
}
