import Foundation
import ActivityKit
import OSLog

private let log = Logger(subsystem: "at.wellbe.TrafficVienna", category: "live-activity")

struct LiveActivityDescriptor: Equatable {
    let line: String
    let destination: String
    let stop: String
}

enum LiveActivityPlan: Equatable {
    case start
    case update(primaryIndex: Int, duplicateIndices: [Int])
}

enum LiveActivityTrackingResult: Equatable {
    case started
    case updated
    case unavailable
    case failed

    func message(line: String) -> String {
        switch self {
        case .started:
            String(format: String(localized: "Tracking %@ on your Lock Screen."), locale: .current, line)
        case .updated:
            String(format: String(localized: "Updated %@ on your Lock Screen."), locale: .current, line)
        case .unavailable:
            String(localized: "Live Activities are turned off. Enable them in Settings to track departures on your Lock Screen.")
        case .failed:
            String(localized: "Couldn’t start Lock Screen tracking. Please try again.")
        }
    }
}

@MainActor
enum LiveActivityController {
    static var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func plan(
        for target: LiveActivityDescriptor,
        among active: [LiveActivityDescriptor]
    ) -> LiveActivityPlan {
        let matchingIndices = active.indices.filter { active[$0] == target }
        guard let primaryIndex = matchingIndices.first else { return .start }
        return .update(primaryIndex: primaryIndex, duplicateIndices: Array(matchingIndices.dropFirst()))
    }

    static func track(
        line: String,
        destination: String,
        stop: String,
        minutes: Int,
        isLive: Bool
    ) async -> LiveActivityTrackingResult {
        guard isAvailable else { return .unavailable }

        let departureDate = Date().addingTimeInterval(TimeInterval(max(0, minutes) * 60))
        let attributes = DepartureActivityAttributes(line: line, destination: destination, stopName: stop)
        let state = DepartureActivityAttributes.ContentState(departureDate: departureDate, isLive: isLive)
        let activities = Activity<DepartureActivityAttributes>.activities
        let target = LiveActivityDescriptor(line: line, destination: destination, stop: stop)
        let active = activities.map {
            LiveActivityDescriptor(
                line: $0.attributes.line,
                destination: $0.attributes.destination,
                stop: $0.attributes.stopName
            )
        }

        switch plan(for: target, among: active) {
        case .update(let primaryIndex, let duplicateIndices):
            await activities[primaryIndex].update(
                .init(state: state, staleDate: departureDate.addingTimeInterval(120))
            )
            for index in duplicateIndices {
                await activities[index].end(nil, dismissalPolicy: .immediate)
            }
            return .updated
        case .start:
            break
        }

        do {
            _ = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: departureDate.addingTimeInterval(120))
            )
            return .started
        } catch {
            log.error("start error: \(error, privacy: .public)")
            return .failed
        }
    }

    static func stopAll() async {
        for activity in Activity<DepartureActivityAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
    }
}
