import XCTest

@MainActor
final class TrafficViennaAdaptiveLayoutTests: TrafficViennaUITestCase {
    func testPrimaryScreensFitConfiguredAccessibilitySettings() {
        launchApp(seedFavourites: true)

        waitForIdentifier("nearby-screen")
        verifyNearbyLayout()
        attachScreenshot(named: "adaptive-nearby")

        selectTab(1, expecting: "search-screen")
        attachScreenshot(named: "adaptive-search")

        let searchField = app.searchFields.firstMatch
        focusAndType("Stephansplatz", into: searchField)
        waitForIdentifier("station-row-1085621741").tap()

        waitForIdentifier("station-detail-screen", timeout: 20)
        waitForLoadingToFinish()
        assertVisibleButtonsMeetMinimumHitArea()
        attachScreenshot(named: "adaptive-station-detail")

        if app.tabBars.firstMatch.exists {
            app.navigationBars.buttons.firstMatch.tap()
            waitForIdentifier("search-screen")

            selectTab(2, expecting: "stations-map", timeout: 20)
            attachScreenshot(named: "adaptive-map")

            selectTab(3, expecting: "alerts-screen", timeout: 20)
            verifyAlertsLayout()

            selectTab(4, expecting: "favourites-screen")
            verifyFavouritesLayout()
        } else {
            launchApp(seedFavourites: true, initialTab: "map")
            waitForIdentifier("stations-map", timeout: 20)
            attachScreenshot(named: "adaptive-map")

            launchApp(seedFavourites: true, initialTab: "alerts")
            waitForIdentifier("alerts-screen", timeout: 20)
            verifyAlertsLayout()

            launchApp(seedFavourites: true, initialTab: "favourites")
            waitForIdentifier("favourites-screen")
            verifyFavouritesLayout()
        }
    }

    private func verifyAlertsLayout() {
        waitForLoadingToFinish()
        for label in ["Service", "Accessibility", "Stop changes"] {
            let button = app.buttons[label].firstMatch
            XCTAssertTrue(button.waitForExistence(timeout: 10), "Missing full filter label: \(label)")
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
        }
        attachScreenshot(named: "adaptive-alerts")
    }

    private func verifyNearbyLayout() {
        for identifier in [
            "service-status-card",
            "favourite-quick-access-1085621741",
            "nearby-status-card",
        ] {
            let element = waitForIdentifier(identifier)
            bringIntoView(element)
            assertInsideWindow(element)
        }
    }

    private func verifyFavouritesLayout() {
        waitForIdentifier("favourite-station-row-1085621741")
        waitForLoadingToFinish()
        attachScreenshot(named: "adaptive-favourites")
    }

    private func assertVisibleButtonsMeetMinimumHitArea(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let buttons = app.buttons
        let navigationBarFrame = app.navigationBars.firstMatch.frame
        var inspected = 0

        for index in 0..<buttons.count {
            let button = buttons.element(boundBy: index)
            guard button.exists, button.isHittable else { continue }
            guard !button.frame.intersects(navigationBarFrame) else { continue }
            inspected += 1
            XCTAssertGreaterThanOrEqual(
                button.frame.width,
                44,
                "Button is narrower than 44 pt: \(button.debugDescription)",
                file: file,
                line: line
            )
            XCTAssertGreaterThanOrEqual(
                button.frame.height,
                44,
                "Button is shorter than 44 pt: \(button.debugDescription)",
                file: file,
                line: line
            )
        }

        XCTAssertGreaterThan(inspected, 0, "Expected visible buttons", file: file, line: line)
    }

    private func bringIntoView(_ element: XCUIElement) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "Expected app window")
        let visibleFrame = window.frame.insetBy(dx: -1, dy: -1)

        for _ in 0..<8 {
            if element.isHittable, visibleFrame.contains(element.frame) {
                return
            }

            if element.frame.minY < visibleFrame.minY {
                app.swipeDown()
            } else {
                app.swipeUp()
            }
        }

        XCTAssertTrue(
            element.isHittable && visibleFrame.contains(element.frame),
            "Expected element to be fully visible: \(element.identifier)"
        )
    }

    private func assertInsideWindow(
        _ element: XCUIElement,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.exists, "Expected app window", file: file, line: line)
        XCTAssertTrue(
            window.frame.insetBy(dx: -1, dy: -1).contains(element.frame),
            "Element extends outside the app window: \(element.debugDescription)",
            file: file,
            line: line
        )
    }
}
