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
        requestLocation: Bool = false
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
        let tab = app.tabBars.buttons.element(boundBy: index)
        XCTAssertTrue(
            tab.waitForExistence(timeout: 10),
            "Expected tab at index \(index)",
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
}
