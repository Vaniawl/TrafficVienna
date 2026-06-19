//
//  LiveActivityController.swift
//  TrafficVienna
//
//  Starts a Lock Screen / Dynamic Island countdown for a chosen departure.
//  The countdown is rendered by the system from the target date, so no
//  background updates are required.
//

import Foundation
import ActivityKit

@MainActor
enum LiveActivityController {
    static var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func track(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        let departureDate = Date().addingTimeInterval(TimeInterval(max(0, minutes) * 60))
        let attributes = DepartureActivityAttributes(line: line, destination: destination, stopName: stop)
        let state = DepartureActivityAttributes.ContentState(departureDate: departureDate, isLive: isLive)

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: departureDate.addingTimeInterval(120))
            )
        } catch {
            print("Live Activity error:", error)
        }
    }
}
