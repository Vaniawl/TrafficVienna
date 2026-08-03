import XCTest
@testable import TrafficVienna

@MainActor
final class DepartureRemindersViewModelTests: XCTestCase {
    func testDeleteRemovesSelectedReminderAndCancelsItsSystemRequest() async {
        let first = reminder(id: "departure.first", line: "U1")
        let second = reminder(id: "departure.second", line: "U4")
        let provider = ControlledScheduledReminderProvider(
            results: [[first, second]]
        )
        let recorder = CancelledIdentifierRecorder()
        let viewModel = DepartureRemindersViewModel(
            client: DepartureReminderClient(
                permission: { .enabled },
                schedule: { _ in first },
                scheduled: { await provider.scheduled() },
                cancel: { identifier in
                    Task { await recorder.record(identifier) }
                },
                cancelAll: {}
            )
        )

        let initialLoad = Task { await viewModel.load() }
        await provider.waitUntilCallCount(1)
        await provider.releaseCall(1)
        await initialLoad.value

        viewModel.cancel(at: IndexSet(integer: 1))
        await recorder.waitUntilCount(1)

        XCTAssertEqual(viewModel.reminders, [first])
        let cancelledIdentifiers = await recorder.identifiers
        XCTAssertEqual(cancelledIdentifiers, [second.id])
    }

    func testDeleteCannotBeUndoneByAnOlderReload() async {
        let reminder = ScheduledDepartureReminder(
            id: "departure.test",
            line: "U1",
            destination: "Leopoldau",
            stop: "Stephansplatz",
            fireDate: nil,
            departureDate: nil
        )
        let provider = ControlledScheduledReminderProvider(
            results: [[reminder], [reminder]]
        )
        let viewModel = DepartureRemindersViewModel(
            client: DepartureReminderClient(
                permission: { .enabled },
                schedule: { _ in reminder },
                scheduled: { await provider.scheduled() },
                cancel: { _ in },
                cancelAll: {}
            )
        )

        let initialLoad = Task { await viewModel.load() }
        await provider.waitUntilCallCount(1)
        await provider.releaseCall(1)
        await initialLoad.value
        XCTAssertEqual(viewModel.reminders, [reminder])

        let reload = Task { await viewModel.load() }
        await provider.waitUntilCallCount(2)
        viewModel.cancel(at: IndexSet(integer: 0))
        XCTAssertTrue(viewModel.reminders.isEmpty)

        await provider.releaseCall(2)
        await reload.value

        XCTAssertTrue(viewModel.reminders.isEmpty)
    }

    func testOverlappingReloadsSerializeAndPublishTheFollowUpSnapshot() async {
        let first = reminder(id: "departure.first", line: "U1")
        let latest = reminder(id: "departure.latest", line: "U4")
        let provider = ControlledScheduledReminderProvider(
            results: [[first], [first], [latest]]
        )
        let viewModel = makeViewModel(provider: provider)

        let initialLoad = Task { await viewModel.load() }
        await provider.waitUntilCallCount(1)
        await provider.releaseCall(1)
        await initialLoad.value

        let firstReload = Task { await viewModel.load() }
        await provider.waitUntilCallCount(2)
        let overlappingReload = Task { await viewModel.load() }
        await Task.yield()
        let callCountBeforeRelease = await provider.currentCallCount()
        XCTAssertEqual(callCountBeforeRelease, 2)

        await provider.releaseCall(2)
        await provider.waitUntilCallCount(3)
        await provider.releaseCall(3)
        await firstReload.value
        await overlappingReload.value

        XCTAssertEqual(viewModel.reminders, [latest])
    }

    func testCancelledInitialLoadCannotPublishLateSystemState() async {
        let reminder = reminder(id: "departure.test", line: "U1")
        let provider = ControlledScheduledReminderProvider(
            results: [[reminder]]
        )
        let viewModel = makeViewModel(provider: provider)

        let load = Task { await viewModel.load() }
        await provider.waitUntilCallCount(1)
        load.cancel()
        await provider.releaseCall(1)
        await load.value

        XCTAssertTrue(viewModel.reminders.isEmpty)
        XCTAssertEqual(viewModel.permission, .notDetermined)
        XCTAssertTrue(viewModel.isLoading)
    }

    func testCancelAllSuppressesOlderReloadAndReconcilesAfterRemoval() async {
        let reminder = reminder(id: "departure.test", line: "U1")
        let provider = ControlledScheduledReminderProvider(
            results: [[reminder], [reminder], []]
        )
        let viewModel = makeViewModel(provider: provider)

        let initialLoad = Task { await viewModel.load() }
        await provider.waitUntilCallCount(1)
        await provider.releaseCall(1)
        await initialLoad.value

        let reload = Task { await viewModel.load() }
        await provider.waitUntilCallCount(2)
        await viewModel.cancelAll()
        XCTAssertTrue(viewModel.reminders.isEmpty)

        await provider.releaseCall(2)
        await provider.waitUntilCallCount(3)
        await provider.releaseCall(3)
        await reload.value

        XCTAssertTrue(viewModel.reminders.isEmpty)
    }

    private func makeViewModel(
        provider: ControlledScheduledReminderProvider
    ) -> DepartureRemindersViewModel {
        DepartureRemindersViewModel(
            client: DepartureReminderClient(
                permission: { .enabled },
                schedule: { _ in
                    Self.reminder(id: "departure.scheduled", line: "U2")
                },
                scheduled: { await provider.scheduled() },
                cancel: { _ in },
                cancelAll: {}
            )
        )
    }

    nonisolated private static func reminder(
        id: String,
        line: String
    ) -> ScheduledDepartureReminder {
        ScheduledDepartureReminder(
            id: id,
            line: line,
            destination: "Destination",
            stop: "Stephansplatz",
            fireDate: nil,
            departureDate: nil
        )
    }

    private func reminder(
        id: String,
        line: String
    ) -> ScheduledDepartureReminder {
        Self.reminder(id: id, line: line)
    }
}

private actor CancelledIdentifierRecorder {
    private(set) var identifiers: [String] = []

    func record(_ identifier: String) {
        identifiers.append(identifier)
    }

    func waitUntilCount(_ expected: Int) async {
        while identifiers.count < expected {
            await Task.yield()
        }
    }
}

private actor ControlledScheduledReminderProvider {
    private let results: [[ScheduledDepartureReminder]]
    private var callCount = 0
    private var releases: [Int: CheckedContinuation<Void, Never>] = [:]

    init(results: [[ScheduledDepartureReminder]]) {
        self.results = results
    }

    func scheduled() async -> [ScheduledDepartureReminder] {
        callCount += 1
        let call = callCount
        await withCheckedContinuation { continuation in
            releases[call] = continuation
        }
        return results[call - 1]
    }

    func waitUntilCallCount(_ expected: Int) async {
        while callCount < expected {
            await Task.yield()
        }
    }

    func currentCallCount() -> Int {
        callCount
    }

    func releaseCall(_ call: Int) {
        releases.removeValue(forKey: call)?.resume()
    }
}
