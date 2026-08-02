import Foundation
import UserNotifications

nonisolated struct DepartureReminderRequest: Equatable, Sendable {
    let stationID: Int
    let line: String
    let destination: String
    let stop: String
    let minutes: Int
}

nonisolated struct DepartureReminderPlan: Equatable, Sendable {
    let leadMinutes: Int
    let fireDate: Date
    let departureDate: Date
}

nonisolated struct ScheduledDepartureReminder: Identifiable, Equatable, Sendable {
    let id: String
    let line: String
    let destination: String
    let stop: String
    let fireDate: Date?
    let departureDate: Date?
}

nonisolated enum DepartureReminderPermission: Equatable, Sendable {
    case notDetermined
    case enabled
    case disabled
}

nonisolated enum DepartureReminderError: LocalizedError, Equatable, Sendable {
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

nonisolated enum DepartureReminderPlanner {
    static func plan(
        minutes: Int,
        now: Date = .now
    ) throws -> DepartureReminderPlan {
        let leadMinutes: Int
        switch minutes {
        case 15...:
            leadMinutes = 5
        case 5...:
            leadMinutes = 3
        default:
            leadMinutes = 1
        }

        guard minutes > leadMinutes else {
            throw DepartureReminderError.departureTooSoon
        }

        return DepartureReminderPlan(
            leadMinutes: leadMinutes,
            fireDate: now.addingTimeInterval(TimeInterval((minutes - leadMinutes) * 60)),
            departureDate: now.addingTimeInterval(TimeInterval(minutes * 60))
        )
    }

    static func validateStillSchedulable(
        _ plan: DepartureReminderPlan,
        now: Date = .now
    ) throws {
        guard plan.fireDate.timeIntervalSince(now) > 1 else {
            throw DepartureReminderError.departureTooSoon
        }
    }
}

nonisolated struct DepartureReminderClient: Sendable {
    var permission: @Sendable () async -> DepartureReminderPermission
    var schedule: @Sendable (DepartureReminderRequest) async throws -> ScheduledDepartureReminder
    var scheduled: @Sendable () async -> [ScheduledDepartureReminder]
    var cancel: @Sendable (String) -> Void
    var cancelAll: @Sendable () async -> Void

    nonisolated static let live = Self(
        permission: {
            await SystemDepartureReminderScheduler.permission()
        },
        schedule: { request in
            try await SystemDepartureReminderScheduler.schedule(request)
        },
        scheduled: {
            await SystemDepartureReminderScheduler.scheduled()
        },
        cancel: { identifier in
            SystemDepartureReminderScheduler.cancel(identifier: identifier)
        },
        cancelAll: {
            await SystemDepartureReminderScheduler.cancelAll()
        }
    )
}

nonisolated enum SystemDepartureReminderScheduler {
    static let identifierPrefix = "departure."

    private enum UserInfoKey {
        static let line = "line"
        static let destination = "destination"
        static let stop = "stop"
        static let stationID = "stationID"
        static let fireDate = "fireDate"
        static let departureDate = "departureDate"
    }

    static func permission() async -> DepartureReminderPermission {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return permission(from: settings.authorizationStatus)
    }

    static func schedule(
        _ request: DepartureReminderRequest
    ) async throws -> ScheduledDepartureReminder {
        let plan = try DepartureReminderPlanner.plan(minutes: request.minutes)
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()

        switch permission(from: settings.authorizationStatus) {
        case .notDetermined:
            guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                throw DepartureReminderError.notificationsDisabled
            }
        case .disabled:
            throw DepartureReminderError.notificationsDisabled
        case .enabled:
            break
        }

        // The permission prompt can remain visible past the planned reminder
        // time. Never convert that case into an immediate, misleading alert.
        try DepartureReminderPlanner.validateStillSchedulable(plan)

        let content = UNMutableNotificationContent()
        content.title = String(
            format: String(localized: "%@ leaves in %lld min"),
            locale: .current,
            request.line,
            Int64(plan.leadMinutes)
        )
        content.body = String(
            format: String(localized: "%@ → %@"),
            locale: .current,
            request.stop,
            request.destination
        )
        content.sound = .default
        content.userInfo = [
            UserInfoKey.stationID: request.stationID,
            UserInfoKey.line: request.line,
            UserInfoKey.destination: request.destination,
            UserInfoKey.stop: request.stop,
            UserInfoKey.fireDate: plan.fireDate.timeIntervalSince1970,
            UserInfoKey.departureDate: plan.departureDate.timeIntervalSince1970,
        ]

        let identifier = "\(identifierPrefix)\(UUID().uuidString)"
        let delay = max(1, plan.fireDate.timeIntervalSinceNow)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        try await center.add(
            UNNotificationRequest(
                identifier: identifier,
                content: content,
                trigger: trigger
            )
        )

        return ScheduledDepartureReminder(
            id: identifier,
            line: request.line,
            destination: request.destination,
            stop: request.stop,
            fireDate: plan.fireDate,
            departureDate: plan.departureDate
        )
    }

    static func scheduled() async -> [ScheduledDepartureReminder] {
        reminders(
            from: await UNUserNotificationCenter.current().pendingNotificationRequests()
        )
    }

    static func cancel(identifier: String) {
        guard identifier.hasPrefix(identifierPrefix) else { return }
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }
        let delivered = await center.deliveredNotifications()
            .map(\.request.identifier)
            .filter { $0.hasPrefix(identifierPrefix) }

        center.removePendingNotificationRequests(withIdentifiers: pending)
        center.removeDeliveredNotifications(withIdentifiers: delivered)
    }

    static func reminders(
        from requests: [UNNotificationRequest]
    ) -> [ScheduledDepartureReminder] {
        requests.compactMap { request in
            guard request.identifier.hasPrefix(identifierPrefix),
                  let line = request.content.userInfo[UserInfoKey.line] as? String,
                  let destination = request.content.userInfo[UserInfoKey.destination] as? String,
                  let stop = request.content.userInfo[UserInfoKey.stop] as? String
            else {
                return nil
            }

            let fireTimestamp = request.content.userInfo[UserInfoKey.fireDate] as? TimeInterval
            let departureTimestamp = request.content.userInfo[UserInfoKey.departureDate] as? TimeInterval
            return ScheduledDepartureReminder(
                id: request.identifier,
                line: line,
                destination: destination,
                stop: stop,
                fireDate: fireTimestamp.map(Date.init(timeIntervalSince1970:))
                    ?? nextFireDate(for: request.trigger),
                departureDate: departureTimestamp.map(Date.init(timeIntervalSince1970:))
            )
        }
        .sorted {
            ($0.fireDate ?? .distantFuture, $0.id)
                < ($1.fireDate ?? .distantFuture, $1.id)
        }
    }

    static func isDepartureReminder(identifier: String) -> Bool {
        identifier.hasPrefix(identifierPrefix)
    }

    private static func permission(
        from status: UNAuthorizationStatus
    ) -> DepartureReminderPermission {
        switch status {
        case .notDetermined:
            .notDetermined
        case .authorized, .provisional, .ephemeral:
            .enabled
        case .denied:
            .disabled
        @unknown default:
            .disabled
        }
    }

    private static func nextFireDate(
        for trigger: UNNotificationTrigger?
    ) -> Date? {
        if let trigger = trigger as? UNTimeIntervalNotificationTrigger {
            return trigger.nextTriggerDate()
        }
        if let trigger = trigger as? UNCalendarNotificationTrigger {
            return trigger.nextTriggerDate()
        }
        return nil
    }
}
