import XCTest
import UserNotifications
@testable import TrafficVienna

final class DepartureReminderTests: XCTestCase {
    func testPlannerUsesThreeMinuteLeadForNearDeparture() throws {
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let plan = try DepartureReminderPlanner.plan(minutes: 12, now: now)

        XCTAssertEqual(plan.leadMinutes, 3)
        XCTAssertEqual(plan.fireDate, now.addingTimeInterval(9 * 60))
        XCTAssertEqual(plan.departureDate, now.addingTimeInterval(12 * 60))
    }

    func testPlannerUsesFiveMinuteLeadForLaterDeparture() throws {
        let plan = try DepartureReminderPlanner.plan(minutes: 20)

        XCTAssertEqual(plan.leadMinutes, 5)
    }

    func testPlannerRejectsDepartureThatCannotBeWarnedInTime() {
        XCTAssertThrowsError(
            try DepartureReminderPlanner.plan(minutes: 1)
        ) { error in
            XCTAssertEqual(
                error as? DepartureReminderError,
                .departureTooSoon
            )
        }
    }

    func testPlannerRejectsPlanThatExpiredDuringPermissionPrompt() {
        let fireDate = Date(timeIntervalSince1970: 1_700_000_000)
        let plan = DepartureReminderPlan(
            leadMinutes: 3,
            fireDate: fireDate,
            departureDate: fireDate.addingTimeInterval(180)
        )

        XCTAssertThrowsError(
            try DepartureReminderPlanner.validateStillSchedulable(
                plan,
                now: fireDate
            )
        ) { error in
            XCTAssertEqual(
                error as? DepartureReminderError,
                .departureTooSoon
            )
        }
    }

    func testPendingNotificationIsDecodedForManagementUI() {
        let departureDate = Date(timeIntervalSince1970: 1_800_000_000)
        let content = UNMutableNotificationContent()
        content.userInfo = [
            "line": "U1",
            "destination": "Leopoldau",
            "stop": "Stephansplatz",
            "fireDate": departureDate.addingTimeInterval(-180).timeIntervalSince1970,
            "departureDate": departureDate.timeIntervalSince1970,
        ]
        let request = UNNotificationRequest(
            identifier: "departure.test",
            content: content,
            trigger: UNTimeIntervalNotificationTrigger(
                timeInterval: 60,
                repeats: false
            )
        )

        let reminder = SystemDepartureReminderScheduler.reminders(
            from: [request]
        ).first

        XCTAssertEqual(reminder?.line, "U1")
        XCTAssertEqual(reminder?.destination, "Leopoldau")
        XCTAssertEqual(reminder?.stop, "Stephansplatz")
        XCTAssertEqual(
            reminder?.fireDate,
            departureDate.addingTimeInterval(-180)
        )
        XCTAssertEqual(reminder?.departureDate, departureDate)
    }

    func testOnlyOwnedNotificationIdentifiersAreAccepted() {
        XCTAssertTrue(
            SystemDepartureReminderScheduler.isDepartureReminder(
                identifier: "departure.123"
            )
        )
        XCTAssertFalse(
            SystemDepartureReminderScheduler.isDepartureReminder(
                identifier: "unrelated"
            )
        )
    }
}
