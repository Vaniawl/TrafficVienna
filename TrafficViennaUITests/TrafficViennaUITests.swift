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
        let submit = app.buttons["auth.submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 3))
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: submit)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        if !submit.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(submit.isHittable)
        submit.tap()

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

        XCTAssertFalse(app.buttons["auth.submit"].isEnabled)
        XCTAssertTrue(app.staticTexts["auth.email.validation"].exists)
        XCTAssertTrue(app.staticTexts["auth.password.validation"].exists)
    }

    func testKeyboardNextAndGoCompleteEmailRegistration() {
        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("keyboard-\(UUID().uuidString.lowercased())@example.com")

        let next = app.keyboards.buttons.matching(NSPredicate(format: "label ==[c] %@", "Next")).firstMatch
        XCTAssertTrue(next.exists)
        next.tap()

        let password = app.secureTextFields["auth.password"]
        password.typeText("tramline26")
        let go = app.keyboards.buttons.matching(NSPredicate(format: "label ==[c] %@", "Go")).firstMatch
        XCTAssertTrue(go.exists)
        go.tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8))
    }

    func testEmailUserCanPersonalizeDisplayName() {
        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("profile-\(UUID().uuidString.lowercased())@example.com")
        let password = app.secureTextFields["auth.password"]
        password.tap()
        password.typeText("tramline26")
        dismissKeyboardIfPresent()

        let submit = app.buttons["auth.submit"]
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: submit)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        if !submit.isHittable { app.scrollViews.firstMatch.swipeUp() }
        submit.tap()

        XCTAssertTrue(app.tabBars.firstMatch.waitForExistence(timeout: 8))
        let favouritesTab = app.tabBars.buttons["Favourites"]
        for _ in 0..<3 where !favouritesTab.isSelected {
            favouritesTab.tap()
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "selected == true"),
                object: favouritesTab
            )
            _ = XCTWaiter.wait(for: [selected], timeout: 1)
        }
        XCTAssertTrue(favouritesTab.isSelected)
        let account = app.buttons["favourites.account"]
        XCTAssertTrue(account.waitForExistence(timeout: 3))
        let editName = app.descendants(matching: .any)["account.editDisplayName"]
        for _ in 0..<3 where !editName.exists {
            account.tap()
            _ = editName.waitForExistence(timeout: 1)
        }
        XCTAssertTrue(editName.waitForExistence(timeout: 3))
        editName.tap()

        let nameField = app.textFields["Display name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.typeText("Codex Rider")
        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Codex Rider"].waitForExistence(timeout: 3))
        let reminders = app.descendants(matching: .any)["account.departureReminders"]
        XCTAssertTrue(reminders.waitForExistence(timeout: 3))
        for _ in 0..<3 where !app.buttons["BackButton"].exists {
            reminders.tap()
            _ = app.buttons["BackButton"].waitForExistence(timeout: 1)
        }
        let backToAccount = app.buttons["BackButton"]
        XCTAssertTrue(backToAccount.waitForExistence(timeout: 3))
        XCTAssertEqual(backToAccount.label, "Account")
        backToAccount.tap()
        app.buttons["Done"].tap()
        app.tabBars.buttons["Nearby"].tap()
        XCTAssertTrue(app.staticTexts["Codex Rider"].waitForExistence(timeout: 3))
    }

    func testSearchCanSaveStationWithoutOpeningDetails() {
        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("quick-favourite-\(UUID().uuidString.lowercased())@example.com")
        let password = app.secureTextFields["auth.password"]
        password.tap()
        password.typeText("tramline26")
        dismissKeyboardIfPresent()

        let submit = app.buttons["auth.submit"]
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: submit)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        if !submit.isHittable { app.scrollViews.firstMatch.swipeUp() }
        submit.tap()

        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 8))
        let searchTab = tabBar.buttons["Search"]
        for _ in 0..<3 where !searchTab.isSelected {
            searchTab.tap()
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "selected == true"),
                object: searchTab
            )
            _ = XCTWaiter.wait(for: [selected], timeout: 1)
        }
        XCTAssertTrue(searchTab.isSelected)

        let searchField = app.searchFields["Station or stop"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 3))
        searchField.tap()
        searchField.typeText("Karlsplatz")
        let keyboardSearch = app.keyboards.buttons.matching(
            NSPredicate(format: "label ==[c] %@", "Search")
        ).firstMatch
        if keyboardSearch.exists { keyboardSearch.tap() }

        let quickFavorite = app.buttons["search.favorite.1085618000"]
        XCTAssertTrue(quickFavorite.waitForExistence(timeout: 5))
        if quickFavorite.label == "Remove station from favourites" {
            quickFavorite.tap()
            let removed = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "label == %@", "Add station to favourites"),
                object: quickFavorite
            )
            XCTAssertEqual(XCTWaiter.wait(for: [removed], timeout: 3), .completed)
        }
        quickFavorite.tap()
        let saved = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", "Remove station from favourites"),
            object: quickFavorite
        )
        XCTAssertEqual(XCTWaiter.wait(for: [saved], timeout: 3), .completed)

        dismissKeyboardIfPresent()
        let favouritesTab = tabBar.buttons["Favourites"]
        for _ in 0..<3 where !favouritesTab.isSelected {
            favouritesTab.tap()
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "selected == true"),
                object: favouritesTab
            )
            _ = XCTWaiter.wait(for: [selected], timeout: 1)
        }
        XCTAssertTrue(favouritesTab.isSelected)
        let savedStation = app.descendants(matching: .any)["favourites.station.1085618000"]
        XCTAssertTrue(savedStation.waitForExistence(timeout: 3))
        let stationIsHittable = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"),
            object: savedStation
        )
        XCTAssertEqual(XCTWaiter.wait(for: [stationIsHittable], timeout: 3), .completed)
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

    func testUkrainianInvalidCredentialsErrorIsLocalized() {
        app.terminate()
        app.launchArguments = [
            "-ui-testing-reset",
            "-AppleLanguages", "(uk)",
            "-AppleLocale", "uk_UA"
        ]
        app.launch()

        let signInMode = app.buttons["Увійти"].firstMatch
        XCTAssertTrue(signInMode.waitForExistence(timeout: 5))
        signInMode.tap()
        XCTAssertEqual(app.buttons["auth.submit"].label, "Увійти")

        let email = app.textFields["auth.email"]
        email.tap()
        email.typeText("missing@example.com")
        let password = app.secureTextFields["auth.password"]
        password.tap()
        password.typeText("12345678")
        dismissKeyboardIfPresent()

        XCTAssertEqual(email.value as? String, "missing@example.com")
        XCTAssertNotEqual(password.value as? String, "Пароль")
        XCTAssertEqual(app.staticTexts["auth.email.validation"].value as? String, "Виконано")
        XCTAssertEqual(app.staticTexts["auth.password.validation"].value as? String, "Виконано")

        let submit = app.buttons["auth.submit"]
        let enabled = XCTNSPredicateExpectation(predicate: NSPredicate(format: "enabled == true"), object: submit)
        XCTAssertEqual(XCTWaiter.wait(for: [enabled], timeout: 3), .completed)
        if !submit.isHittable {
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(submit.isHittable)
        submit.tap()

        let error = app.staticTexts["auth.error"]
        XCTAssertTrue(error.waitForExistence(timeout: 3))
        XCTAssertEqual(error.label, "Неправильна електронна адреса або пароль.")

        app.scrollViews.firstMatch.swipeDown()
        email.tap()
        email.typeText("x")
        XCTAssertFalse(error.exists)
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
