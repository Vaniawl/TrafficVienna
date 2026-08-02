import XCTest

@MainActor
final class TrafficViennaUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += [
            "-hasOnboarded", "YES",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US",
        ]
        app.launch()
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 8))
    }

    override func tearDown() {
        app = nil
        super.tearDown()
    }

    func testTopLevelJourneysAndMapEntryAreReachable() {
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.buttons["Home"].exists)
        XCTAssertTrue(tabBar.buttons["Discover"].exists)
        XCTAssertTrue(tabBar.buttons["Alerts"].exists)
        XCTAssertTrue(tabBar.buttons["Saved"].exists)

        tabBar.buttons["Discover"].tap()
        XCTAssertTrue(app.navigationBars["Discover"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["discover.map"].exists)

        app.buttons["discover.map"].tap()
        XCTAssertTrue(app.navigationBars["Map"].waitForExistence(timeout: 5))
        app.navigationBars["Map"].buttons.firstMatch.tap()

        tabBar.buttons["Alerts"].tap()
        XCTAssertTrue(app.navigationBars["Alerts"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["alerts.filters"].waitForExistence(timeout: 5))

        tabBar.buttons["Saved"].tap()
        XCTAssertTrue(app.navigationBars["Saved"].waitForExistence(timeout: 3))
    }

    func testSearchOpensTheSelectedStation() {
        openStation(named: "Stephansplatz")

        XCTAssertTrue(
            app.navigationBars["Stephansplatz"].waitForExistence(timeout: 5)
                || app.navigationBars["Stephansplatz U"].waitForExistence(timeout: 5)
        )
    }

    func testLiveActivityCanBeStartedAndStoppedFromDepartureOptions() {
        openStation(named: "Schwedenplatz")

        let options = app.buttons.matching(
            NSPredicate(format: "label BEGINSWITH 'Departure options for'")
        ).firstMatch
        XCTAssertTrue(options.waitForExistence(timeout: 15))
        options.tap()

        let track = app.buttons["Track on Lock Screen"]
        XCTAssertTrue(track.waitForExistence(timeout: 3))
        track.tap()

        options.tap()
        let stop = app.buttons["Stop Lock Screen tracking"]
        XCTAssertTrue(stop.waitForExistence(timeout: 3))
        stop.tap()
    }

    func testPendingReminderRouteOpensItsStationOnColdLaunch() {
        app.terminate()
        app.launchArguments += [
            "-pending_station_id", "1085621741",
        ]
        app.launch()

        XCTAssertTrue(
            app.navigationBars["Stephansplatz"].waitForExistence(timeout: 8)
        )
        XCTAssertTrue(
            app.tabBars.firstMatch.buttons["Discover"].isSelected
        )
    }

    private func openStation(named stationName: String) {
        app.tabBars.firstMatch.buttons["Discover"].tap()

        let searchField = app.searchFields["Stop name"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText(stationName)

        let result = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'search.station.'")
        ).firstMatch
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        result.tap()
        XCTAssertTrue(
            app.navigationBars[stationName].waitForExistence(timeout: 5)
                || app.navigationBars["\(stationName) U"].waitForExistence(timeout: 5)
        )
    }
}
