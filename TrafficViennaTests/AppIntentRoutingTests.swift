import XCTest
@testable import TrafficVienna

@MainActor
final class AppIntentRoutingTests: XCTestCase {
    private var defaults: StubShortcutDestinationStore!

    override func setUp() {
        super.setUp()
        defaults = StubShortcutDestinationStore()
    }

    override func tearDown() {
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

private final class StubShortcutDestinationStore: ShortcutDestinationStoring {
    private var values: [String: Any] = [:]

    func string(forKey defaultName: String) -> String? {
        values[defaultName] as? String
    }

    func set(_ value: Any?, forKey defaultName: String) {
        values[defaultName] = value
    }

    func removeObject(forKey defaultName: String) {
        values.removeValue(forKey: defaultName)
    }
}
