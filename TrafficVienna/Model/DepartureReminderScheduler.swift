import Foundation
import UserNotifications

enum DepartureReminderError: LocalizedError {
    case notificationsDisabled

    var errorDescription: String? { "Enable notifications in Settings to receive departure reminders." }
}

struct DepartureReminderScheduler {
    static func schedule(line: String, destination: String, stop: String, minutes: Int) async throws {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            guard try await center.requestAuthorization(options: [.alert, .sound]) else {
                throw DepartureReminderError.notificationsDisabled
            }
        } else if settings.authorizationStatus != .authorized && settings.authorizationStatus != .provisional {
            throw DepartureReminderError.notificationsDisabled
        }

        let leadMinutes = minutes >= 5 ? 3 : 1
        let delay = max(5, (minutes - leadMinutes) * 60)
        let content = UNMutableNotificationContent()
        content.title = "\(line) leaves soon"
        content.body = "\(stop) → \(destination) in about \(leadMinutes) min."
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["line": line, "destination": destination, "stop": stop]

        let identifier = "departure.\(line).\(stop).\(destination)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(delay), repeats: false))
        try await center.add(request)
    }
}
