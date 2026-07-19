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
        enterPasswordConfirmation("tramline26")

        let submit = app.buttons["auth.submit"]
        XCTAssertTrue(submit.waitForExistence(timeout: 3))
        XCTAssertEqual(app.staticTexts["auth.email.validation"].value as? String, "Satisfied")
        XCTAssertEqual(app.staticTexts["auth.password.validation"].value as? String, "Satisfied")
        XCTAssertEqual(app.staticTexts["auth.passwordConfirmation.validation"].value as? String, "Satisfied")
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
        let passwordNext = app.keyboards.buttons.matching(NSPredicate(format: "label ==[c] %@", "Next")).firstMatch
        XCTAssertTrue(passwordNext.exists)
        passwordNext.tap()

        let confirmation = app.textFields["auth.passwordConfirmation"]
        confirmation.typeText("tramline26")
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
        enterPasswordConfirmation("tramline26")

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
        let changePassword = app.descendants(matching: .any)["account.changePassword"]
        XCTAssertTrue(changePassword.waitForExistence(timeout: 3))
        changePassword.tap()
        XCTAssertTrue(app.secureTextFields["account.currentPassword"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.secureTextFields["account.newPassword"].exists)
        XCTAssertTrue(app.secureTextFields["account.confirmNewPassword"].exists)
        app.buttons["BackButton"].tap()

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

        let liveActivities = app.descendants(matching: .any)["account.liveActivities"]
        XCTAssertTrue(liveActivities.waitForExistence(timeout: 3))
        for _ in 0..<3 where !app.navigationBars["Live Activities"].exists {
            liveActivities.tap()
            _ = app.navigationBars["Live Activities"].waitForExistence(timeout: 1)
        }
        XCTAssertTrue(app.navigationBars["Live Activities"].waitForExistence(timeout: 3))
        let backFromActivities = app.buttons["BackButton"]
        XCTAssertTrue(backFromActivities.waitForExistence(timeout: 3))
        XCTAssertEqual(backFromActivities.label, "Account")
        backFromActivities.tap()

        let appearance = app.descendants(matching: .any)["account.appearance"]
        XCTAssertTrue(appearance.waitForExistence(timeout: 3))
        appearance.tap()
        XCTAssertTrue(app.navigationBars["Appearance"].waitForExistence(timeout: 3))

        let nightTheme = app.buttons["appearance.theme.night"]
        XCTAssertTrue(nightTheme.waitForExistence(timeout: 3))
        nightTheme.tap()
        let nightSelected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Selected"),
            object: nightTheme
        )
        XCTAssertEqual(XCTWaiter.wait(for: [nightSelected], timeout: 3), .completed)

        let viennaTheme = app.buttons["appearance.theme.vienna"]
        XCTAssertTrue(viennaTheme.waitForExistence(timeout: 3))
        viennaTheme.tap()
        let viennaSelected = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Selected"),
            object: viennaTheme
        )
        XCTAssertEqual(XCTWaiter.wait(for: [viennaSelected], timeout: 3), .completed)
        app.buttons["BackButton"].tap()

        let homeSettings = app.descendants(matching: .any)["account.homeSettings"]
        XCTAssertTrue(homeSettings.waitForExistence(timeout: 3))
        homeSettings.tap()
        XCTAssertTrue(app.navigationBars["Home screen"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["homeSettings.edit"].waitForExistence(timeout: 3))
        let smartInsightToggle = app.switches["homeSettings.smartInsight"]
        XCTAssertTrue(smartInsightToggle.waitForExistence(timeout: 3))
        if smartInsightToggle.value as? String == "0" {
            smartInsightToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
            let normalizedOn = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value == %@", "1"),
                object: smartInsightToggle
            )
            XCTAssertEqual(XCTWaiter.wait(for: [normalizedOn], timeout: 3), .completed)
        }
        XCTAssertEqual(smartInsightToggle.value as? String, "1")
        smartInsightToggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let smartInsightOff = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "0"),
            object: smartInsightToggle
        )
        XCTAssertEqual(XCTWaiter.wait(for: [smartInsightOff], timeout: 3), .completed)
        app.buttons["BackButton"].tap()

        let privacyData = app.descendants(matching: .any)["account.privacyData"]
        scrollToMakeHittable(privacyData)
        privacyData.tap()
        XCTAssertTrue(app.navigationBars["Privacy & data"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Identity"].exists)
        app.buttons["BackButton"].tap()

        let about = app.descendants(matching: .any)["account.about"]
        scrollToMakeHittable(about)
        about.tap()
        XCTAssertTrue(app.navigationBars["About"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.descendants(matching: .any)["about.version"].exists)
        XCTAssertTrue(app.descendants(matching: .any)["about.source"].exists)
        app.buttons["about.done"].tap()

        app.buttons["Done"].tap()
        app.tabBars.buttons["Nearby"].tap()
        XCTAssertTrue(app.staticTexts["Codex Rider"].waitForExistence(timeout: 3))
        XCTAssertFalse(app.descendants(matching: .any)["nearby.smartInsight"].exists)

        let nearbyAccount = app.buttons["nearby.account"]
        XCTAssertTrue(nearbyAccount.waitForExistence(timeout: 3))
        nearbyAccount.tap()
        let homeSettingsAgain = app.descendants(matching: .any)["account.homeSettings"]
        XCTAssertTrue(homeSettingsAgain.waitForExistence(timeout: 3))
        homeSettingsAgain.tap()
        let smartInsightToggleAgain = app.switches["homeSettings.smartInsight"]
        XCTAssertTrue(smartInsightToggleAgain.waitForExistence(timeout: 3))
        XCTAssertEqual(smartInsightToggleAgain.value as? String, "0")
        smartInsightToggleAgain.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        let smartInsightOn = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "1"),
            object: smartInsightToggleAgain
        )
        XCTAssertEqual(XCTWaiter.wait(for: [smartInsightOn], timeout: 3), .completed)
        app.buttons["BackButton"].tap()
        app.buttons["Done"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["nearby.smartInsight"].waitForExistence(timeout: 3))
    }

    func testSearchCanSaveStationWithoutOpeningDetails() {
        let email = app.textFields["auth.email"]
        XCTAssertTrue(email.waitForExistence(timeout: 5))
        email.tap()
        email.typeText("quick-favourite-\(UUID().uuidString.lowercased())@example.com")
        let password = app.secureTextFields["auth.password"]
        password.tap()
        password.typeText("tramline26")
        enterPasswordConfirmation("tramline26")

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
        savedStation.tap()
        XCTAssertTrue(app.navigationBars["Karlsplatz"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["station.walkingDirections.toolbar"].waitForExistence(timeout: 3))
        let saveRoute = app.buttons.matching(NSPredicate(
            format: "label BEGINSWITH %@ AND label ENDSWITH %@",
            "Save ",
            " to favourites"
        )).firstMatch
        XCTAssertTrue(saveRoute.waitForExistence(timeout: 8))
        saveRoute.tap()
        app.buttons["BackButton"].tap()

        let savedRoute = app.descendants(matching: .any).matching(NSPredicate(
            format: "identifier BEGINSWITH %@",
            "favourites.route."
        )).firstMatch
        XCTAssertTrue(savedRoute.waitForExistence(timeout: 8))
        savedRoute.tap()
        XCTAssertTrue(app.navigationBars["Karlsplatz"].waitForExistence(timeout: 3))
        app.buttons["BackButton"].tap()

        let nearbyTab = tabBar.buttons["Nearby"]
        for _ in 0..<3 where !nearbyTab.isSelected {
            nearbyTab.tap()
            let selected = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "selected == true"),
                object: nearbyTab
            )
            _ = XCTWaiter.wait(for: [selected], timeout: 1)
        }
        XCTAssertTrue(nearbyTab.isSelected)
        let quickStation = app.descendants(matching: .any)["nearby.favoriteStation.1085618000"]
        XCTAssertTrue(quickStation.waitForExistence(timeout: 3))
        quickStation.tap()
        XCTAssertTrue(app.navigationBars["Karlsplatz"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["station.walkingDirections.toolbar"].waitForExistence(timeout: 3))
        app.buttons["BackButton"].tap()

        favouritesTab.tap()
        XCTAssertTrue(app.buttons["favourites.edit"].waitForExistence(timeout: 3))
        app.buttons["favourites.edit"].tap()
        XCTAssertTrue(app.buttons["favourites.clearAll"].waitForExistence(timeout: 3))
        app.buttons["favourites.clearAll"].tap()
        let confirmClear = app.buttons["Clear all"]
        XCTAssertTrue(confirmClear.waitForExistence(timeout: 3))
        confirmClear.tap()
        XCTAssertTrue(app.staticTexts["No favourites yet"].waitForExistence(timeout: 3))
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

    private func enterPasswordConfirmation(_ value: String) {
        XCTAssertEqual(app.staticTexts["auth.password.validation"].value as? String, "Satisfied")
        let confirmation = app.textFields["auth.passwordConfirmation"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 3))
        app.scrollViews.firstMatch.swipeUp()
        XCTAssertTrue(confirmation.isHittable)
        confirmation.tap()
        confirmation.typeText(value)
        let matching = app.staticTexts["auth.passwordConfirmation.validation"]
        let satisfied = XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Satisfied"),
            object: matching
        )
        XCTAssertEqual(XCTWaiter.wait(for: [satisfied], timeout: 3), .completed)
    }

    private func tapCenter(of element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 3))
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    private func scrollToMakeHittable(_ element: XCUIElement) {
        XCTAssertTrue(element.waitForExistence(timeout: 3))
        for _ in 0..<5 where !element.isHittable {
            app.tables.firstMatch.swipeUp()
        }
        XCTAssertTrue(element.isHittable)
    }

}
