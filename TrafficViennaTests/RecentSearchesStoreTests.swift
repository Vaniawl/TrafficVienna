import Foundation
import XCTest
@testable import TrafficVienna

@MainActor
final class RecentSearchesStoreTests: XCTestCase {
    func testPersistsUniqueMostRecentStationsWithinLimitAndClears() {
        let suiteName = "TrafficViennaTests.RecentSearches.\(UUID().uuidString)"
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            XCTFail("Could not create isolated UserDefaults suite")
            return
        }
        defer { defaults.removePersistentDomain(forName: suiteName) }

        let store = RecentSearchesStore(
            defaults: defaults,
            key: "recent-search-test",
            maxCount: 3
        )
        store.record(1)
        store.record(2)
        store.record(1)
        store.record(3)
        store.record(4)

        XCTAssertEqual(store.ids, [4, 3, 1])

        let restored = RecentSearchesStore(
            defaults: defaults,
            key: "recent-search-test",
            maxCount: 3
        )
        XCTAssertEqual(restored.ids, [4, 3, 1])

        restored.clear()
        XCTAssertTrue(restored.ids.isEmpty)
        XCTAssertNil(defaults.array(forKey: "recent-search-test"))
    }
}
