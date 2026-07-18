import Foundation
import ActivityKit
import OSLog

private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "live-activity")

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
            log.error("start error: \(error, privacy: .public)")
        }
    }

    static func update(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) {
        let departureDate = Date().addingTimeInterval(TimeInterval(max(0, minutes) * 60))
        let state = DepartureActivityAttributes.ContentState(departureDate: departureDate, isLive: isLive)
        let content = ActivityContent(state: state, staleDate: departureDate.addingTimeInterval(120))
        let matching = Activity<DepartureActivityAttributes>.activities.first { a in
            a.attributes.line == line &&
            a.attributes.destination == destination &&
            a.attributes.stopName == stop
        }
        Task {
            await matching?.update(content)
        }
    }

    static func stopAll() {
        Task {
            for activity in Activity<DepartureActivityAttributes>.activities {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }
}
