import XCTest
@testable import TrafficVienna

@MainActor
final class AppIntentRoutingTests: XCTestCase {
    func testRequestIsPersistedAndRestoredForColdLaunch() {
        let defaults = StubShortcutDestinationStore()
        let router = TrafficViennaShortcutRouter(defaults: defaults)
        router.request(.search)

        let restored = TrafficViennaShortcutRouter(defaults: defaults)

        XCTAssertEqual(restored.pendingDestination, .search)
        XCTAssertEqual(restored.pendingDestination?.appTab, .search)
    }

    func testConsumeReturnsDestinationAndClearsPersistence() {
        let defaults = StubShortcutDestinationStore()
        let router = TrafficViennaShortcutRouter(defaults: defaults)
        router.request(.favourites)

        XCTAssertEqual(router.consume(), .favourites)
        XCTAssertNil(router.pendingDestination)
        XCTAssertNil(defaults.string(forKey: TrafficViennaShortcutRouter.pendingDestinationKey))
    }

    func testSupportedDeepLinksRoundTripAndRoute() throws {
        let defaults = StubShortcutDestinationStore()
        let router = TrafficViennaShortcutRouter(defaults: defaults)

        for destination in TrafficViennaDestination.allCases {
            let url = try XCTUnwrap(destination.deepLinkURL)
            XCTAssertEqual(TrafficViennaDestination(deepLinkURL: url), destination)
            XCTAssertTrue(router.handle(deepLinkURL: url))
            XCTAssertEqual(router.consume(), destination)
        }
    }

    func testDeepLinkRejectsUnknownOrParameterizedRoutes() throws {
        let defaults = StubShortcutDestinationStore()
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
