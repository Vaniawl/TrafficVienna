//
//  DepartureActivityAttributes.swift
//  TrafficVienna
//
//  Shared between the app (which starts the activity) and the widget extension
//  (which renders it on the Lock Screen / Dynamic Island). The countdown uses a
//  target Date so the system animates it live — no background updates needed.
//

import Foundation
import ActivityKit

struct DepartureActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var departureDate: Date
        var isLive: Bool
    }

    var line: String
    var destination: String
    var stopName: String
}
