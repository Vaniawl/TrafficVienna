import XCTest

@MainActor
final class TrafficViennaAppStoreScreenshotTests: TrafficViennaUITestCase {
    func testCaptureEnglishScreenshots() {
        captureScreenshots(language: "en", locale: "en_US")
    }

    func testCaptureGermanScreenshots() {
        captureScreenshots(language: "de", locale: "de_DE")
    }

    private func captureScreenshots(language: String, locale: String) {
        launchApp(
            language: language,
            locale: locale,
            seedFavourites: true,
            requestLocation: true
        )

        waitForIdentifier("nearby-stations-header", timeout: 30)
        waitForIdentifierToDisappear("nearby-loading-skeleton", timeout: 30)
        waitForLoadingToFinish()
        attachScreenshot(named: "01-nearby")

        selectTab(1, expecting: "search-screen")

        let searchField = app.searchFields.firstMatch
        focusAndType("Stephansplatz", into: searchField)

        let result = waitForIdentifier("station-row-1085621741")
        result.tap()
        waitForIdentifier("station-detail-screen", timeout: 20)
        waitForLoadingToFinish()
        attachScreenshot(named: "02-station-detail")

        app.navigationBars.buttons.firstMatch.tap()
        waitForIdentifier("search-screen")

        selectTab(2, expecting: "stations-map", timeout: 20)
        waitForMapTilesToRender()
        attachScreenshot(named: "03-map")

        selectTab(3, expecting: "alerts-screen", timeout: 20)
        waitForLoadingToFinish()
        attachScreenshot(named: "04-alerts")

        selectTab(4, expecting: "favourites-screen")
        waitForIdentifier("favourite-station-row-1085621741")
        waitForLoadingToFinish()
        attachScreenshot(named: "05-favourites")
    }

    private func waitForMapTilesToRender() {
        RunLoop.current.run(until: Date().addingTimeInterval(6))
    }
}
