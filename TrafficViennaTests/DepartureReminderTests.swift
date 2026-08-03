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

    func testReminderIdentifierIsStableForOneRoute() {
        let request = DepartureReminderRequest(
            stationID: 42,
            line: "U1",
            destination: "Leopoldau",
            stop: "Stephansplatz",
            minutes: 8
        )
        let updatedDeparture = DepartureReminderRequest(
            stationID: 42,
            line: "U1",
            destination: "Leopoldau",
            stop: "Stephansplatz",
            minutes: 12
        )

        XCTAssertEqual(
            SystemDepartureReminderScheduler.identifier(for: request),
            SystemDepartureReminderScheduler.identifier(for: updatedDeparture)
        )
        XCTAssertTrue(
            SystemDepartureReminderScheduler.identifier(for: request)
                .hasPrefix(SystemDepartureReminderScheduler.identifierPrefix)
        )
    }

    func testReminderIdentifierKeepsDifferentRoutesDistinct() {
        let request = DepartureReminderRequest(
            stationID: 42,
            line: "U1",
            destination: "Leopoldau",
            stop: "Stephansplatz",
            minutes: 8
        )
        let otherDirection = DepartureReminderRequest(
            stationID: 42,
            line: "U1",
            destination: "Oberlaa",
            stop: "Stephansplatz",
            minutes: 8
        )
        let otherStation = DepartureReminderRequest(
            stationID: 43,
            line: "U1",
            destination: "Leopoldau",
            stop: "Praterstern",
            minutes: 8
        )

        let identifier = SystemDepartureReminderScheduler.identifier(
            for: request
        )
        XCTAssertNotEqual(
            identifier,
            SystemDepartureReminderScheduler.identifier(for: otherDirection)
        )
        XCTAssertNotEqual(
            identifier,
            SystemDepartureReminderScheduler.identifier(for: otherStation)
        )
    }

    func testMatchingLegacyRemindersAreReplacedWithoutTouchingOtherRoutes() {
        let reminder = DepartureReminderRequest(
            stationID: 42,
            line: "U1",
            destination: "Leopoldau",
            stop: "Stephansplatz",
            minutes: 8
        )
        let matching = notificationRequest(
            identifier: "departure.legacy",
            stationID: 42,
            line: "U1",
            destination: "Leopoldau"
        )
        let otherDirection = notificationRequest(
            identifier: "departure.other",
            stationID: 42,
            line: "U1",
            destination: "Oberlaa"
        )
        let unrelated = notificationRequest(
            identifier: "unrelated",
            stationID: 42,
            line: "U1",
            destination: "Leopoldau"
        )

        XCTAssertEqual(
            SystemDepartureReminderScheduler.replacementIdentifiers(
                in: [matching, otherDirection, unrelated],
                matching: reminder
            ),
            ["departure.legacy"]
        )
    }

    private func notificationRequest(
        identifier: String,
        stationID: Int,
        line: String,
        destination: String
    ) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.userInfo = [
            "stationID": stationID,
            "line": line,
            "destination": destination,
        ]
        return UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )
    }
}
