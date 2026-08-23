import XCTest
@testable import TrafficVienna

@MainActor
final class SharedStorageResetTests: XCTestCase {
    func testUIResetRemovesEverySharedStateKey() async throws {
        let suiteName = "TrafficViennaTests.SharedStorageReset"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer { defaults.removePersistentDomain(forName: suiteName) }

        for key in TrafficViennaStorage.resettableSharedKeys {
            defaults.set("stale", forKey: key)
        }

        UITestLaunchConfiguration.resetSharedState(in: defaults)

        XCTAssertTrue(
            TrafficViennaStorage.resettableSharedKeys.allSatisfy {
                defaults.object(forKey: $0) == nil
            }
        )
    }
}
