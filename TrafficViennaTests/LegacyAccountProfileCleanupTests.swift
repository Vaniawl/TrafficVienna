import Foundation
import Security
import XCTest
@testable import TrafficVienna

@MainActor
final class LegacyAccountProfileCleanupTests: XCTestCase {
    func testSuccessfulCleanupRunsOnlyOnce() throws {
        let defaults = try makeDefaults()
        let deleter = StubLegacyAccountProfileDeleter(status: errSecSuccess)

        LegacyAccountProfileCleanup.run(defaults: defaults, deleter: deleter)
        LegacyAccountProfileCleanup.run(defaults: defaults, deleter: deleter)

        XCTAssertEqual(deleter.callCount, 1)
        XCTAssertTrue(defaults.bool(forKey: LegacyAccountProfileCleanup.completionKey))
    }

    func testMissingLegacyItemCompletesMigration() throws {
        let defaults = try makeDefaults()
        let deleter = StubLegacyAccountProfileDeleter(status: errSecItemNotFound)

        LegacyAccountProfileCleanup.run(defaults: defaults, deleter: deleter)

        XCTAssertEqual(deleter.callCount, 1)
        XCTAssertTrue(defaults.bool(forKey: LegacyAccountProfileCleanup.completionKey))
    }

    func testFailedCleanupRetriesOnNextLaunch() throws {
        let defaults = try makeDefaults()
        let deleter = StubLegacyAccountProfileDeleter(status: errSecInteractionNotAllowed)

        LegacyAccountProfileCleanup.run(defaults: defaults, deleter: deleter)
        LegacyAccountProfileCleanup.run(defaults: defaults, deleter: deleter)

        XCTAssertEqual(deleter.callCount, 2)
        XCTAssertFalse(defaults.bool(forKey: LegacyAccountProfileCleanup.completionKey))
    }

    private func makeDefaults() throws -> UserDefaults {
        let suiteName = "LegacyAccountProfileCleanupTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock {
            defaults.removePersistentDomain(forName: suiteName)
        }
        return defaults
    }
}

private final class StubLegacyAccountProfileDeleter: LegacyAccountProfileDeleting {
    private let status: OSStatus
    private(set) var callCount = 0

    init(status: OSStatus) {
        self.status = status
    }

    func delete() -> OSStatus {
        callCount += 1
        return status
    }
}
