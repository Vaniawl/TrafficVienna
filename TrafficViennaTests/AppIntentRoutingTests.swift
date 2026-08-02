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

    func testStationRequestIsPersistedRestoredAndConsumed() {
        let router = TrafficViennaShortcutRouter(defaults: defaults)
        router.requestStation(id: 42)

        let restored = TrafficViennaShortcutRouter(defaults: defaults)

        XCTAssertEqual(restored.pendingStationID, 42)
        XCTAssertEqual(restored.consumeStation(), 42)
        XCTAssertNil(restored.pendingStationID)
        XCTAssertNil(
            defaults.object(
                forKey: TrafficViennaShortcutRouter.pendingStationIDKey
            )
        )
    }

    func testSupportedDeepLinksRoundTripAndRoute() throws {
        let router = TrafficViennaShortcutRouter(defaults: defaults)

        for destination in TrafficViennaDestination.allCases {
            let url = try XCTUnwrap(destination.deepLinkURL)
            XCTAssertEqual(TrafficViennaDestination(deepLinkURL: url), destination)
            XCTAssertTrue(router.handle(deepLinkURL: url))
            XCTAssertEqual(router.consume(), destination)
        }
    }

    func testDeepLinkRejectsUnknownOrParameterizedRoutes() throws {
        let router = TrafficViennaShortcutRouter(defaults: defaults)
        let rejectedURLs = [
            "https://favourites",
            "trafficvienna://alerts",
            "trafficvienna://favourites/extra",
            "trafficvienna://favourites?delete=true",
            "trafficvienna://user:password@favourites",
        ]

        for value in rejectedURLs {
            let url = try XCTUnwrap(URL(string: value))
            XCTAssertFalse(router.handle(deepLinkURL: url), value)
            XCTAssertNil(router.pendingDestination)
        }
    }
}
