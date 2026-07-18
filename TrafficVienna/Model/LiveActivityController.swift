import Foundation
import ActivityKit

@MainActor
enum LiveActivityController {
    static var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func track(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityStartError.notAvailable
        }

        let departureDate = Date.now.addingTimeInterval(TimeInterval(max(0, minutes) * 60))
        let attributes = DepartureActivityAttributes(line: line, destination: destination, stopName: stop)
        let state = DepartureActivityAttributes.ContentState(departureDate: departureDate, isLive: isLive)

        _ = try Activity.request(
            attributes: attributes,
            content: .init(state: state, staleDate: departureDate.addingTimeInterval(120))
        )
    }

    static func update(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) {
        let departureDate = Date.now.addingTimeInterval(TimeInterval(max(0, minutes) * 60))
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
