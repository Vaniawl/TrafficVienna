import Foundation
import ActivityKit

@MainActor
enum LiveActivityController {
    private static var endTasks: [String: Task<Void, Never>] = [:]
    private static let operations = LiveActivityOperationQueue()

    static var isAvailable: Bool {
        ActivityAuthorizationInfo().areActivitiesEnabled
    }

    static func track(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) throws {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            throw LiveActivityStartError.notAvailable
        }

        let departureDate = DepartureActivityLifecycle.departureDate(
            minutes: minutes
        )
        let attributes = DepartureActivityAttributes(line: line, destination: destination, stopName: stop)
        let state = DepartureActivityAttributes.ContentState(departureDate: departureDate, isLive: isLive)
        let content = ActivityContent(
            state: state,
            staleDate: DepartureActivityLifecycle.automaticEndDate(
                departureDate: departureDate
            )
        )

        if let matching = matchingActivity(line: line, destination: destination, stop: stop) {
            operations.enqueue(for: matching.id) {
                await matching.update(content)
            }
            scheduleEnd(for: matching, content: content)
            return
        }

        let previousActivities = Activity<DepartureActivityAttributes>.activities
        let activity = try Activity.request(attributes: attributes, content: content)

        for previous in previousActivities {
            end(previous)
        }
        previousActivities.forEach {
            endTasks[$0.id]?.cancel()
            endTasks[$0.id] = nil
        }
        scheduleEnd(for: activity, content: content)
    }

    static func update(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) {
        let departureDate = DepartureActivityLifecycle.departureDate(
            minutes: minutes
        )
        let state = DepartureActivityAttributes.ContentState(departureDate: departureDate, isLive: isLive)
        let content = ActivityContent(
            state: state,
            staleDate: DepartureActivityLifecycle.automaticEndDate(
                departureDate: departureDate
            )
        )
        let matching = matchingActivity(line: line, destination: destination, stop: stop)
        if let matching {
            operations.enqueue(for: matching.id) {
                await matching.update(content)
            }
            scheduleEnd(for: matching, content: content)
        }
    }

    static func activeDepartureID(for stop: String) -> StationDepartureID? {
        Activity<DepartureActivityAttributes>.activities
            .first {
                $0.attributes.stopName == stop &&
                    !operations.isEnding(activityID: $0.id)
            }
            .map {
                StationDepartureID(
                    line: $0.attributes.line,
                    destination: $0.attributes.destination
                )
            }
    }

    static func stopAll() {
        let activities = Activity<DepartureActivityAttributes>.activities
        activities.forEach {
            endTasks[$0.id]?.cancel()
            endTasks[$0.id] = nil
        }
        for activity in activities {
            end(activity)
        }
    }

    static func endExpiredActivities(now: Date = .now) {
        let activities = Activity<DepartureActivityAttributes>.activities
        for activity in activities {
            if DepartureActivityLifecycle.isExpired(
                departureDate: activity.content.state.departureDate,
                now: now
            ) {
                endTasks[activity.id]?.cancel()
                endTasks[activity.id] = nil
                end(activity, content: activity.content)
            } else {
                scheduleEnd(for: activity, content: activity.content)
            }
        }
    }

    private static func matchingActivity(
        line: String,
        destination: String,
        stop: String
    ) -> Activity<DepartureActivityAttributes>? {
        Activity<DepartureActivityAttributes>.activities.first { activity in
            !operations.isEnding(activityID: activity.id) &&
                activity.attributes.line == line &&
                activity.attributes.destination == destination &&
                activity.attributes.stopName == stop
        }
    }

    private static func end(
        _ activity: Activity<DepartureActivityAttributes>,
        content: ActivityContent<DepartureActivityAttributes.ContentState>? = nil
    ) {
        operations.enqueueEnd(for: activity.id) {
            await activity.end(content, dismissalPolicy: .immediate)
        }
    }

    private static func scheduleEnd(
        for activity: Activity<DepartureActivityAttributes>,
        content: ActivityContent<DepartureActivityAttributes.ContentState>
    ) {
        endTasks[activity.id]?.cancel()
        let endDate = DepartureActivityLifecycle.automaticEndDate(
            departureDate: content.state.departureDate
        )
        let delay = max(1, endDate.timeIntervalSinceNow)

        endTasks[activity.id] = Task {
            do {
                try await Task.sleep(for: .seconds(delay))
            } catch {
                return
            }
            guard !Task.isCancelled else { return }
            end(activity, content: content)
            endTasks[activity.id] = nil
        }
    }
}
