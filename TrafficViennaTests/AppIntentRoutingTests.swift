import XCTest
@testable import TrafficVienna

@MainActor
final class AppIntentRoutingTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "AppIntentRoutingTests")
        defaults.removePersistentDomain(forName: "AppIntentRoutingTests")
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: "AppIntentRoutingTests")
        defaults = nil
        super.tearDown()
    }

    func testRequestIsPersistedAndRestoredForColdLaunch() {
        let router = TrafficViennaShortcutRouter(defaults: defaults)
        router.request(.search)

        let restored = TrafficViennaShortcutRouter(defaults: defaults)

        XCTAssertEqual(restored.pendingDestination, .search)
        XCTAssertEqual(restored.pendingDestination?.appTab, .search)
    }

    func testConsumeReturnsDestinationAndClearsPersistence() {
        let router = TrafficViennaShortcutRouter(defaults: defaults)
        router.request(.favourites)

        XCTAssertEqual(router.consume(), .favourites)
        XCTAssertNil(router.pendingDestination)
        XCTAssertNil(defaults.string(forKey: TrafficViennaShortcutRouter.pendingDestinationKey))
    }
}
