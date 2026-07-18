import Foundation
import UserNotifications

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

    private static let identifierPrefix = "departure."

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
