import XCTest

@MainActor
final class TrafficViennaSmokeTests: TrafficViennaUITestCase {
    func testOnboardingPages() {
        launchApp(skipOnboarding: false)

        waitForIdentifier("onboarding-page-0")
        app.buttons["Continue"].tap()
        waitForIdentifier("onboarding-page-1")
        app.buttons["Continue"].tap()
        waitForIdentifier("onboarding-page-2")
        XCTAssertTrue(app.buttons["Start exploring"].exists)
    }

    func testPrimaryTabsAndStationSearch() {
        launchApp()

        waitForIdentifier("nearby-screen")

        selectTab(1, expecting: "search-screen")

        let searchField = app.searchFields.firstMatch
        XCTAssertTrue(searchField.waitForExistence(timeout: 10))
        searchField.tap()
        searchField.typeText("Stephansplatz")

        let result = waitForIdentifier("station-row-1085621741")
        result.tap()
        waitForIdentifier("station-detail-screen", timeout: 20)

        app.navigationBars.buttons.firstMatch.tap()
        waitForIdentifier("search-screen")

        selectTab(2, expecting: "stations-map")

        selectTab(3, expecting: "alerts-screen")

        selectTab(4, expecting: "favourites-screen")
    }
}
