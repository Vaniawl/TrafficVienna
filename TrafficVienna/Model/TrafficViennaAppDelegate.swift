import UIKit
import UserNotifications

final class TrafficViennaAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        guard SystemDepartureReminderScheduler.isDepartureReminder(
            identifier: notification.request.identifier
        ) else {
            return []
        }
        return [.banner, .list, .sound]
    }

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        guard SystemDepartureReminderScheduler.isDepartureReminder(
            identifier: response.notification.request.identifier
        ) else {
            return
        }
        let userInfo = response.notification.request.content.userInfo
        let stationID = (userInfo["stationID"] as? NSNumber)?.intValue
            ?? userInfo["stationID"] as? Int
        if let stationID {
            await TrafficViennaShortcutRouter.shared.requestStation(
                id: stationID
            )
        } else {
            await TrafficViennaShortcutRouter.shared.request(.search)
        }
    }
}
