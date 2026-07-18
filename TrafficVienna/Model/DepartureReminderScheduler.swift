import Foundation
import UserNotifications

struct ScheduledDepartureReminder: Identifiable, Equatable {
    let id: String
    let line: String
    let destination: String
    let stop: String
    let fireDate: Date?
}

enum DepartureReminderError: LocalizedError, Equatable {
    case notificationsDisabled
    case departureTooSoon

    var errorDescription: String? {
        switch self {
        case .notificationsDisabled:
            String(localized: "Enable notifications in Settings to receive departure reminders.")
        case .departureTooSoon:
            String(localized: "This departure is too soon for a reminder.")
        }
    }
}

struct DepartureReminderScheduler {
    struct Plan: Equatable {
        let leadMinutes: Int
        let delay: TimeInterval
    }

    nonisolated private static let identifierPrefix = "departure."

    static func schedule(line: String, destination: String, stop: String, minutes: Int) async throws {
        let plan = try plan(minutes: minutes)
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                throw DepartureReminderError.notificationsDisabled
            }
        } else if settings.authorizationStatus != .authorized && settings.authorizationStatus != .provisional {
            throw DepartureReminderError.notificationsDisabled
        }

        let content = UNMutableNotificationContent()
        content.title = String(
            format: String(localized: "%@ leaves soon"),
            locale: .current,
            line
        )
        content.body = String(
            format: String(localized: "%@ → %@ in about %lld min."),
            locale: .current,
            stop,
            destination,
            Int64(plan.leadMinutes)
        )
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["line": line, "destination": destination, "stop": stop]

        let identifier = "\(identifierPrefix)\(line).\(stop).\(destination)"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: plan.delay, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try await center.add(request)
    }

    nonisolated static func plan(minutes: Int) throws -> Plan {
        let leadMinutes = minutes >= 5 ? 3 : 1
        guard minutes > leadMinutes else { throw DepartureReminderError.departureTooSoon }
        return Plan(leadMinutes: leadMinutes, delay: TimeInterval((minutes - leadMinutes) * 60))
    }

    static func scheduled() async -> [ScheduledDepartureReminder] {
        reminders(from: await UNUserNotificationCenter.current().pendingNotificationRequests())
    }

    nonisolated static func cancel(identifier: String) {
        guard identifier.hasPrefix(identifierPrefix) else { return }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func cancelAllScheduled() async {
        let identifiers = await UNUserNotificationCenter.current().pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    nonisolated static func reminders(from requests: [UNNotificationRequest]) -> [ScheduledDepartureReminder] {
        requests.compactMap { request -> ScheduledDepartureReminder? in
            guard request.identifier.hasPrefix(identifierPrefix),
                  let line = request.content.userInfo["line"] as? String,
                  let destination = request.content.userInfo["destination"] as? String,
                  let stop = request.content.userInfo["stop"] as? String else { return nil }
            return ScheduledDepartureReminder(
                id: request.identifier,
                line: line,
                destination: destination,
                stop: stop,
                fireDate: nextFireDate(for: request.trigger)
            )
        }
        .sorted {
            ($0.fireDate ?? .distantFuture, $0.id) < ($1.fireDate ?? .distantFuture, $1.id)
        }
    }

    nonisolated private static func nextFireDate(for trigger: UNNotificationTrigger?) -> Date? {
        if let trigger = trigger as? UNTimeIntervalNotificationTrigger {
            return trigger.nextTriggerDate()
        }
        if let trigger = trigger as? UNCalendarNotificationTrigger {
            return trigger.nextTriggerDate()
        }
        return nil
    }

    static func removeAllScheduled() async {
        let center = UNUserNotificationCenter.current()
        let pendingIdentifiers = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        let deliveredIdentifiers = await center.deliveredNotifications()
            .map(\.request.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: pendingIdentifiers)
        center.removeDeliveredNotifications(withIdentifiers: deliveredIdentifiers)
    }
}
