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

nonisolated enum DepartureActivityLifecycle {
    static let gracePeriod: TimeInterval = 120

    static func departureDate(
        minutes: Int,
        now: Date = .now
    ) -> Date {
        now.addingTimeInterval(TimeInterval(max(0, minutes) * 60))
    }

    static func automaticEndDate(
        departureDate: Date
    ) -> Date {
        departureDate.addingTimeInterval(gracePeriod)
    }

    static func contentStaleDate(
        departureDate: Date
    ) -> Date {
        departureDate
    }

    static func isExpired(
        departureDate: Date,
        now: Date = .now
    ) -> Bool {
        automaticEndDate(departureDate: departureDate) <= now
    }
}
