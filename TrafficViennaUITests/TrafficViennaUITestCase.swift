import XCTest

@MainActor
class TrafficViennaUITestCase: XCTestCase {
    private(set) var app = XCUIApplication()

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    func launchApp(
        language: String = "en",
        locale: String = "en_US",
        skipOnboarding: Bool = true,
        seedFavourites: Bool = false,
        requestLocation: Bool = false,
        initialTab: String? = nil
    ) {
        var arguments = [
            "-ui-testing",
            "-ui-testing-reset",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
        ]

        if skipOnboarding {
            arguments.append("-ui-testing-skip-onboarding")
        }
        if seedFavourites {
            arguments.append("-ui-testing-seed-favourites")
        }
        if requestLocation {
            arguments.append("-ui-testing-request-location")
        }
        if let initialTab {
            arguments.append(contentsOf: ["-ui-testing-tab", initialTab])
        }

        app.launchArguments = arguments
        app.launch()
    }

    @discardableResult
    func waitForIdentifier(
        _ identifier: String,
        timeout: TimeInterval = 15,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let element = app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected UI element \(identifier)",
            file: file,
            line: line
        )
        return element
    }

    @discardableResult
    func selectTab(
        _ index: Int,
        expecting identifier: String,
        timeout: TimeInterval = 15,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> XCUIElement {
        let tabLabels = ["Nearby", "Search", "Map", "Alerts", "Favourites"]
        guard tabLabels.indices.contains(index) else {
            XCTFail("Unsupported tab index \(index)", file: file, line: line)
            return app.buttons.firstMatch
        }

        let indexedTab = app.tabBars.buttons.element(boundBy: index)
        let labelledTab = app.buttons[tabLabels[index]].firstMatch
        let tab = indexedTab.exists ? indexedTab : labelledTab
        XCTAssertTrue(
            tab.waitForExistence(timeout: 10),
            "Expected tab at index \(index) (\(tabLabels[index]))",
            file: file,
            line: line
        )

        let destination = app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
        let attemptTimeout = timeout / 2

        for _ in 0..<2 {
            tab.tap()
            if destination.waitForExistence(timeout: attemptTimeout) {
                return destination
            }
        }

        XCTFail(
            "Expected tab at index \(index) to show \(identifier)",
            file: file,
            line: line
        )
        return destination
    }

    func waitForLoadingToFinish(
        timeout: TimeInterval = 20,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let indicator = app.progressIndicators.firstMatch
        guard indicator.exists else { return }

        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: indicator)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Loading did not finish",
            file: file,
            line: line
        )
    }

    func focusAndType(
        _ text: String,
        into element: XCUIElement,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected text input before typing",
            file: file,
            line: line
        )

        let focusPredicate = NSPredicate(format: "hasKeyboardFocus == true")
        for _ in 0..<3 {
            element.coordinate(
                withNormalizedOffset: CGVector(dx: 0.75, dy: 0.5)
            ).tap()

            let focusExpectation = XCTNSPredicateExpectation(
                predicate: focusPredicate,
                object: element
            )
            if XCTWaiter.wait(for: [focusExpectation], timeout: 2) == .completed {
                element.typeText(text)
                return
            }
        }

        XCTFail(
            "Text input did not receive keyboard focus",
            file: file,
            line: line
        )
    }

    func waitForIdentifierToDisappear(
        _ identifier: String,
        timeout: TimeInterval = 30,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = app.descendants(matching: .any)
            .matching(identifier: identifier)
            .firstMatch
        guard element.exists else { return }

        let predicate = NSPredicate(format: "exists == false")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Expected UI element \(identifier) to disappear",
            file: file,
            line: line
        )
    }

    func attachScreenshot(named name: String) {
        let attachment = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
