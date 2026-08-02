import XCTest
@testable import TrafficVienna

@MainActor
final class LiveActivityOperationQueueTests: XCTestCase {
    func testOperationsForOneActivityWaitForTheirPredecessor() async {
        let queue = LiveActivityOperationQueue()
        let gate = AsyncGate()
        var events: [String] = []

        let first = queue.enqueue(for: "activity") {
            events.append("first started")
            await gate.wait()
            events.append("first finished")
        }

        while events.isEmpty {
            await Task.yield()
        }

        let second = queue.enqueue(for: "activity") {
            events.append("second started")
        }

        for _ in 0..<10 {
            await Task.yield()
        }

        XCTAssertEqual(events, ["first started"])

        await gate.open()
        await first.value
        await second.value

        XCTAssertEqual(
            events,
            ["first started", "first finished", "second started"]
        )
    }

    func testDifferentActivitiesDoNotWaitForEachOther() async {
        let queue = LiveActivityOperationQueue()
        let gate = AsyncGate()
        var events: [String] = []

        let first = queue.enqueue(for: "first activity") {
            events.append("first started")
            await gate.wait()
            events.append("first finished")
        }

        while events.isEmpty {
            await Task.yield()
        }

        let second = queue.enqueue(for: "second activity") {
            events.append("second started")
        }
        await second.value

        XCTAssertEqual(events, ["first started", "second started"])

        await gate.open()
        await first.value
    }

    func testEndingActivityRejectsLaterUpdatesUntilEndCompletes() async {
        let queue = LiveActivityOperationQueue()
        let gate = AsyncGate()
        var events: [String] = []

        let update = queue.enqueue(for: "activity") {
            events.append("update started")
            await gate.wait()
            events.append("update finished")
        }
        while events.isEmpty {
            await Task.yield()
        }

        let end = queue.enqueueEnd(for: "activity") {
            events.append("ended")
        }
        let rejectedUpdate = queue.enqueue(for: "activity") {
            events.append("late update")
        }

        XCTAssertTrue(queue.isEnding(activityID: "activity"))

        await gate.open()
        await update.value
        await end.value
        await rejectedUpdate.value

        XCTAssertEqual(
            events,
            ["update started", "update finished", "ended"]
        )

        while queue.isEnding(activityID: "activity") {
            await Task.yield()
        }
    }
}

private actor AsyncGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var isOpen = false

    func wait() async {
        guard !isOpen else { return }
        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func open() {
        isOpen = true
        continuation?.resume()
        continuation = nil
    }
}
