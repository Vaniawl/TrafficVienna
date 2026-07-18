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

        app.buttons["auth.submit"].tap()

        let searchTab = app.tabBars.buttons["Search"]
        XCTAssertTrue(searchTab.waitForExistence(timeout: 8))
        searchTab.tap()
        XCTAssertTrue(app.searchFields["Station or stop"].waitForExistence(timeout: 5))

        let favouritesTab = app.tabBars.buttons["Favourites"]
        XCTAssertTrue(favouritesTab.exists)
        favouritesTab.tap()
        XCTAssertTrue(app.staticTexts["No favourites yet"].waitForExistence(timeout: 5))
    }

    func testInvalidEmailShowsValidationMessage() {
        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("invalid")

        let password = app.secureTextFields["auth.password"]
        password.tap()
        password.typeText("tramline26")
        app.buttons["auth.submit"].tap()

        XCTAssertTrue(app.staticTexts["Enter a valid email address."].waitForExistence(timeout: 3))
    }
}
