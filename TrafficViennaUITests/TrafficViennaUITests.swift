import XCTest

final class TrafficViennaUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = [
            "-ui-testing-reset",
            "-AppleLanguages", "(en)",
            "-AppleLocale", "en_US"
        ]
        app.launch()
    }

    func testEmailRegistrationOpensMainNavigation() {
        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("ui-\(UUID().uuidString.lowercased())@example.com")

        let password = app.secureTextFields["auth.password"]
        XCTAssertTrue(password.exists)
        password.tap()
        password.typeText("tramline26")

        dismissKeyboardIfPresent()
        tapCenter(of: app.buttons["auth.submit"])

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 8))
        for title in ["Nearby", "Search", "Map", "Alerts", "Favourites"] {
            XCTAssertTrue(tabBar.buttons[title].exists, "Missing \(title) tab after registration")
        }
    }

    func testInvalidEmailShowsValidationMessage() {
        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("invalid")

        let password = app.secureTextFields["auth.password"]
        password.tap()
        password.typeText("tramline26")
        dismissKeyboardIfPresent()
        tapCenter(of: app.buttons["auth.submit"])

        XCTAssertTrue(app.staticTexts["Enter a valid email address."].waitForExistence(timeout: 3))
    }

    func testUkrainianAuthenticationModesAreLocalized() {
        app.terminate()
        app.launchArguments = [
            "-ui-testing-reset",
            "-AppleLanguages", "(uk)",
            "-AppleLocale", "uk_UA"
        ]
        app.launch()

        let submit = app.buttons["auth.submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 5))
        XCTAssertEqual(submit.label, "Створити акаунт")

        let signInMode = app.buttons["Увійти"].firstMatch
        XCTAssertTrue(signInMode.exists)
        signInMode.tap()

        XCTAssertEqual(submit.label, "Увійти")
    }

    private func dismissKeyboardIfPresent() {
        let keyboard = app.keyboards.firstMatch
        if keyboard.exists {
            keyboard.swipeDown()
        }
    }

    private func tapCenter(of element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 3))
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

}
