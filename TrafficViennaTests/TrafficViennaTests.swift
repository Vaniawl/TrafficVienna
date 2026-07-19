import XCTest
import CoreLocation
import MapKit
import UserNotifications
@testable import TrafficVienna

final class TrafficViennaTests: XCTestCase {

    @MainActor
    func testStationDirectionsPreserveNameCoordinatesAndWalkingMode() {
        let station = Station(
            id: 1,
            diva: 60200001,
            name: "Karlsplatz",
            lat: 48.200832,
            lon: 16.369505
        )

        let item = StationDirections.mapItem(for: station)

        XCTAssertEqual(item.name, "Karlsplatz")
        XCTAssertEqual(item.location.coordinate.latitude, station.lat, accuracy: 0.000_001)
        XCTAssertEqual(item.location.coordinate.longitude, station.lon, accuracy: 0.000_001)
        XCTAssertEqual(
            StationDirections.walkingLaunchOptions[MKLaunchOptionsDirectionsModeKey] as? String,
            MKLaunchOptionsDirectionsModeWalking
        )
        XCTAssertTrue(StationDirections.isAvailable(for: station))
        XCTAssertFalse(StationDirections.isAvailable(for: Station(
            id: 2, diva: nil, name: "Unresolved", lat: 0, lon: 0
        )))
    }

    func testFavoriteStationResolvesCanonicalCoordinatesBeforeStoredFallback() throws {
        let store = StationStore()
        let canonical = try XCTUnwrap(store.station(id: 1085618000))
        let favorite = FavoriteStation(
            id: canonical.id,
            diva: canonical.diva,
            name: canonical.name,
            lat: 1,
            lon: 2
        )

        let resolved = favorite.resolved(in: store)

        XCTAssertEqual(resolved.lat, canonical.lat)
        XCTAssertEqual(resolved.lon, canonical.lon)
        XCTAssertTrue(StationDirections.isAvailable(for: resolved))
    }

    func testLegacyFavoriteStationWithoutCoordinatesStillDecodes() throws {
        let data = try JSONSerialization.data(withJSONObject: [
            "id": 42,
            "diva": 123,
            "name": "Legacy stop"
        ])

        let favorite = try JSONDecoder().decode(FavoriteStation.self, from: data)

        XCTAssertNil(favorite.lat)
        XCTAssertNil(favorite.lon)
    }

    func testRecentSearchRemovalPersistsWithoutReorderingOthers() {
        let suite = "RecentSearchTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RecentSearchesStore(defaults: defaults)
        store.record(1)
        store.record(2)
        store.record(3)

        store.remove(2)

        XCTAssertEqual(store.ids, [3, 1])
        XCTAssertEqual(RecentSearchesStore(defaults: defaults).ids, [3, 1])
    }

    func testRemovingLastRecentSearchClearsPersistence() {
        let suite = "RecentSearchClearTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = RecentSearchesStore(defaults: defaults)
        store.record(42)

        store.remove(42)

        XCTAssertTrue(store.ids.isEmpty)
        XCTAssertNil(defaults.array(forKey: "recent_search_ids"))
    }

    @MainActor
    func testAppRouterParsesStationDeepLink() {
        let router = AppRouter()
        router.open(URL(string: "trafficvienna://station/123")!)
        XCTAssertEqual(router.destination, .station(123))
    }

    @MainActor
    func testAppRouterIgnoresUnknownScheme() {
        let router = AppRouter()
        router.open(URL(string: "https://example.com/station/123")!)
        XCTAssertNil(router.destination)
    }

    @MainActor
    func testAppRouterNavigatesToInAppDestination() {
        let router = AppRouter()

        router.navigate(to: .favourites)
        XCTAssertEqual(router.destination, .favourites)
        router.consume()
        XCTAssertNil(router.destination)
    }

    @MainActor
    func testThemeSelectionPersistsWithInvalidValueFallback() {
        let suite = "ThemeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let manager = ThemeManager(defaults: defaults)

        XCTAssertEqual(manager.preset, .vienna)
        manager.preset = .night
        XCTAssertEqual(ThemeManager(defaults: defaults).preset, .night)

        defaults.set("unsupported-theme", forKey: "themePreset")
        XCTAssertEqual(ThemeManager(defaults: defaults).preset, .vienna)
    }

    @MainActor
    func testHomePreferencesPersistIndependentlyAndRestoreDefaults() {
        let suite = "HomePreferencesTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let preferences = HomePreferences(defaults: defaults)

        XCTAssertTrue(preferences.isDefault)
        preferences.showsSavedStations = false
        preferences.showsSmartInsight = false

        let restored = HomePreferences(defaults: defaults)
        XCTAssertFalse(restored.showsSavedStations)
        XCTAssertTrue(restored.showsSavedRoutes)
        XCTAssertFalse(restored.showsSmartInsight)
        XCTAssertFalse(restored.isDefault)

        restored.moveModules(fromOffsets: IndexSet(integer: 0), toOffset: 3)
        XCTAssertEqual(restored.moduleOrder, [.savedRoutes, .smartInsight, .savedStations])
        XCTAssertEqual(
            HomePreferences(defaults: defaults).moduleOrder,
            [.savedRoutes, .smartInsight, .savedStations]
        )

        restored.restoreDefaults()
        let reset = HomePreferences(defaults: defaults)
        XCTAssertTrue(reset.showsSavedStations)
        XCTAssertTrue(reset.showsSavedRoutes)
        XCTAssertTrue(reset.showsSmartInsight)
        XCTAssertEqual(reset.moduleOrder, HomeModule.allCases)
        XCTAssertTrue(reset.isDefault)
    }

    @MainActor
    func testHomePreferencesNormalizesDuplicateAndFutureModules() {
        let suite = "HomeModuleMigrationTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(
            ["smartInsight", "smartInsight", "futureModule"],
            forKey: "home.moduleOrder"
        )

        let preferences = HomePreferences(defaults: defaults)

        XCTAssertEqual(preferences.moduleOrder, [.smartInsight, .savedStations, .savedRoutes])
    }

    func testHomePollingPlanSkipsWorkThatCannotProduceVisibleContent() {
        let inactive = HomePollingPlan.make(
            isActive: false,
            hasLocation: true,
            showsSavedRoutes: true,
            hasSavedRoutes: true
        )
        XCTAssertEqual(
            inactive,
            HomePollingPlan(
                isActive: false,
                loadsNearbyDepartures: false,
                loadsFavoriteRoutes: false,
                loadsAlerts: false
            )
        )

        let noLocationOrVisibleRoutes = HomePollingPlan.make(
            isActive: true,
            hasLocation: false,
            showsSavedRoutes: false,
            hasSavedRoutes: true
        )
        XCTAssertFalse(noLocationOrVisibleRoutes.loadsNearbyDepartures)
        XCTAssertFalse(noLocationOrVisibleRoutes.loadsFavoriteRoutes)
        XCTAssertTrue(noLocationOrVisibleRoutes.loadsAlerts)

        let noSavedRoutes = HomePollingPlan.make(
            isActive: true,
            hasLocation: true,
            showsSavedRoutes: true,
            hasSavedRoutes: false
        )
        XCTAssertTrue(noSavedRoutes.loadsNearbyDepartures)
        XCTAssertFalse(noSavedRoutes.loadsFavoriteRoutes)
        XCTAssertTrue(noSavedRoutes.loadsAlerts)
    }

    func testHomePollingPlanLoadsEveryActiveDataSourceWhenUseful() {
        let plan = HomePollingPlan.make(
            isActive: true,
            hasLocation: true,
            showsSavedRoutes: true,
            hasSavedRoutes: true
        )

        XCTAssertTrue(plan.loadsNearbyDepartures)
        XCTAssertTrue(plan.loadsFavoriteRoutes)
        XCTAssertTrue(plan.loadsAlerts)
    }

    @MainActor
    func testLiveActivityPlanStartsOrUpdatesOneMatchingDeparture() {
        let target = LiveActivityDescriptor(line: "U1", destination: "Leopoldau", stop: "Karlsplatz")
        let other = LiveActivityDescriptor(line: "D", destination: "Nussdorf", stop: "Schottentor")

        XCTAssertEqual(LiveActivityController.plan(for: target, among: [other]), .start)
        XCTAssertEqual(
            LiveActivityController.plan(for: target, among: [other, target, other, target]),
            .update(primaryIndex: 1, duplicateIndices: [3])
        )
    }

    @MainActor
    func testManagedLiveActivitiesAreChronologicalAndStable() {
        let later = TrackedLiveActivity(
            id: "b",
            line: "D",
            destination: "Nussdorf",
            stop: "Schottentor",
            departureDate: Date(timeIntervalSince1970: 200),
            isLive: true
        )
        let sameTimeFirst = TrackedLiveActivity(
            id: "a",
            line: "U1",
            destination: "Leopoldau",
            stop: "Karlsplatz",
            departureDate: Date(timeIntervalSince1970: 200),
            isLive: false
        )
        let earlier = TrackedLiveActivity(
            id: "c",
            line: "2",
            destination: "Dornbach",
            stop: "Schwedenplatz",
            departureDate: Date(timeIntervalSince1970: 100),
            isLive: true
        )

        XCTAssertEqual(
            LiveActivityController.sorted([later, sameTimeFirst, earlier]).map(\.id),
            ["c", "a", "b"]
        )
    }

    @MainActor
    func testCommuteRoutinePersistence() {
        let suite = "RoutineTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let station = FavoriteStation(id: 1, diva: 123, name: "Karlsplatz")
        let store = CommuteRoutineStore(defaults: defaults)
        store.add(name: "Work", station: station, hour: 8, minute: 45, activeWeekdays: [2, 3, 4, 5, 6])

        let restored = CommuteRoutineStore(defaults: defaults)
        XCTAssertEqual(restored.routines.first?.station.name, "Karlsplatz")
        XCTAssertEqual(restored.routines.first?.hour, 8)
        XCTAssertEqual(restored.routines.first?.minute, 45)
        XCTAssertEqual(restored.routines.first?.activeWeekdays, [2, 3, 4, 5, 6])
    }

    @MainActor
    func testLegacyCommuteRoutineDefaultsToWholeHour() throws {
        struct LegacyRoutine: Codable {
            let id: UUID
            let name: String
            let station: FavoriteStation
            let hour: Int
            let isEnabled: Bool
        }

        let suite = "LegacyRoutineTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let legacy = LegacyRoutine(
            id: UUID(),
            name: "Work",
            station: FavoriteStation(id: 1, diva: 123, name: "Karlsplatz"),
            hour: 8,
            isEnabled: true
        )
        defaults.set(try JSONEncoder().encode([legacy]), forKey: "commute_routines")

        let restored = CommuteRoutineStore(defaults: defaults)

        XCTAssertEqual(restored.routines.first?.hour, 8)
        XCTAssertEqual(restored.routines.first?.minute, 0)
        XCTAssertEqual(restored.routines.first?.activeWeekdays, CommuteRoutine.everyWeekday)
    }

    @MainActor
    func testCurrentRoutineRespectsSelectedWeekdays() {
        let suite = "RoutineWeekdayTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let station = FavoriteStation(id: 1, diva: 123, name: "Karlsplatz")
        let store = CommuteRoutineStore(defaults: defaults)
        store.add(
            name: "Work",
            station: station,
            hour: 8,
            activeWeekdays: [2, 3, 4, 5, 6]
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let saturday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 8))!
        let monday = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 8))!

        XCTAssertNil(store.current(at: saturday, calendar: calendar))
        XCTAssertEqual(store.current(at: monday, calendar: calendar)?.name, "Work")
    }

    @MainActor
    func testCurrentRoutineOnlySurfacesInsideRelevanceWindow() {
        let suite = "RoutineRelevanceTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CommuteRoutineStore(defaults: defaults)
        store.add(
            name: "Work",
            station: FavoriteStation(id: 1, diva: 123, name: "Karlsplatz"),
            hour: 8
        )
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let startBoundary = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 6))!
        let endBoundary = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 10))!
        let tooEarly = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 5, minute: 59))!
        let tooLate = calendar.date(from: DateComponents(year: 2026, month: 7, day: 20, hour: 10, minute: 1))!

        XCTAssertEqual(store.current(at: startBoundary, calendar: calendar)?.name, "Work")
        XCTAssertEqual(store.current(at: endBoundary, calendar: calendar)?.name, "Work")
        XCTAssertNil(store.current(at: tooEarly, calendar: calendar))
        XCTAssertNil(store.current(at: tooLate, calendar: calendar))
    }

    @MainActor
    func testCurrentRoutineUsesCircularMinuteDistanceAcrossMidnight() {
        let suite = "RoutineMidnightTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let station = FavoriteStation(id: 1, diva: 123, name: "Karlsplatz")
        let store = CommuteRoutineStore(defaults: defaults)
        store.add(name: "Before midnight", station: station, hour: 23, minute: 50)
        store.add(name: "After midnight", station: station, hour: 0, minute: 10)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = calendar.date(from: DateComponents(year: 2026, month: 7, day: 18, hour: 0, minute: 2))!

        XCTAssertEqual(store.current(at: now, calendar: calendar)?.name, "After midnight")
    }

    @MainActor
    func testCommuteRoutineEditPreservesIdentityAndPersists() throws {
        let suite = "RoutineEditTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let originalStation = FavoriteStation(id: 1, diva: 123, name: "Karlsplatz")
        let updatedStation = FavoriteStation(id: 2, diva: 456, name: "Praterstern")
        let store = CommuteRoutineStore(defaults: defaults)
        store.add(name: "Work", station: originalStation, hour: 8, minute: 0)
        let id = try XCTUnwrap(store.routines.first?.id)

        store.update(
            id: id,
            name: "Office",
            station: updatedStation,
            hour: 8,
            minute: 45,
            activeWeekdays: [2, 4, 6]
        )
        let restored = CommuteRoutineStore(defaults: defaults)
        let routine = try XCTUnwrap(restored.routines.first)

        XCTAssertEqual(routine.id, id)
        XCTAssertEqual(routine.name, "Office")
        XCTAssertEqual(routine.station, updatedStation)
        XCTAssertEqual(routine.hour, 8)
        XCTAssertEqual(routine.minute, 45)
        XCTAssertEqual(routine.activeWeekdays, [2, 4, 6])
        XCTAssertTrue(routine.isEnabled)
    }

    @MainActor
    func testEmailRegistrationAndSignIn() throws {
        let suite = "AuthStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let keychain = MemoryKeychain()
        let store = AuthStore(keychain: keychain, defaults: defaults)

        try store.register(email: " Rider@Example.com ", password: "tramline26")
        XCTAssertEqual(store.session?.email, "rider@example.com")
        store.signOut()
        try store.signIn(email: "rider@example.com", password: "tramline26")
        XCTAssertEqual(store.session?.provider, .email)
    }

    @MainActor
    func testUITestResetClearsPersistedAuthSessionBeforeLoading() throws {
        let suite = "AuthStoreResetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let keychain = MemoryKeychain()

        let signedInStore = AuthStore(keychain: keychain, defaults: defaults, resetSession: false)
        try signedInStore.register(email: "rider@example.com", password: "tramline26")
        XCTAssertNotNil(defaults.data(forKey: "auth.session"))

        let resetStore = AuthStore(keychain: keychain, defaults: defaults, resetSession: true)
        XCTAssertNil(resetStore.session)
        XCTAssertNil(defaults.data(forKey: "auth.session"))
    }

    @MainActor
    func testEmailRegistrationRejectsInvalidInput() {
        let store = AuthStore(keychain: MemoryKeychain(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        XCTAssertThrowsError(try store.register(email: "invalid", password: "tramline26"))
        XCTAssertThrowsError(try store.register(email: "rider@example.com", password: "short"))
    }

    func testAuthInputValidationMatchesRegistrationRules() {
        XCTAssertEqual(AuthStore.normalizedValidEmail(" Rider@Example.com "), "rider@example.com")
        XCTAssertNil(AuthStore.normalizedValidEmail("invalid"))
        XCTAssertFalse(AuthStore.isValidPassword("1234567"))
        XCTAssertTrue(AuthStore.isValidPassword("12345678"))
    }

    func testRegistrationRequiresMatchingPasswordConfirmation() {
        XCTAssertFalse(AuthFormValidation.passwordsMatch("tramline26", confirmation: ""))
        XCTAssertFalse(AuthFormValidation.passwordsMatch("tramline26", confirmation: "tramline27"))
        XCTAssertTrue(AuthFormValidation.passwordsMatch("tramline26", confirmation: "tramline26"))

        XCTAssertFalse(AuthFormValidation.canSubmit(
            email: "rider@example.com",
            password: "tramline26",
            confirmation: "tramline27",
            requiresConfirmation: true
        ))
        XCTAssertTrue(AuthFormValidation.canSubmit(
            email: "rider@example.com",
            password: "tramline26",
            confirmation: "tramline26",
            requiresConfirmation: true
        ))
        XCTAssertTrue(AuthFormValidation.canSubmit(
            email: "rider@example.com",
            password: "tramline26",
            confirmation: "",
            requiresConfirmation: false
        ))
    }

    @MainActor
    func testBiometricAppLockPersistsAndRelocksAfterBackgrounding() async {
        let suite = "AppLockTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let authenticator = MockBiometricAuthenticator(kind: .faceID)
        let store = AppLockStore(defaults: defaults, authenticator: authenticator)

        XCTAssertFalse(store.isEnabled)
        await store.enable()
        XCTAssertTrue(store.isEnabled)
        XCTAssertFalse(store.isLocked)
        XCTAssertEqual(authenticator.reasons, ["Confirm to enable biometric unlock."])

        store.lockIfNeeded(hasSession: true)
        XCTAssertTrue(store.isLocked)
        await store.unlock()
        XCTAssertFalse(store.isLocked)
        XCTAssertEqual(authenticator.reasons.last, "Unlock Traffic Vienna.")

        let restored = AppLockStore(defaults: defaults, authenticator: authenticator)
        XCTAssertTrue(restored.isEnabled)
        XCTAssertTrue(restored.isLocked)
        XCTAssertEqual(SystemBiometricAuthenticator.policy, .deviceOwnerAuthentication)
    }

    @MainActor
    func testUnavailableOrFailedBiometricsNeverEnableAppLock() async {
        let suite = "UnavailableAppLockTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }

        let unavailable = AppLockStore(
            defaults: defaults,
            authenticator: MockBiometricAuthenticator(kind: .unavailable)
        )
        await unavailable.enable()
        XCTAssertFalse(unavailable.isEnabled)
        XCTAssertEqual(unavailable.errorMessage, AppLockError.unavailable.localizedDescription)

        let failingAuthenticator = MockBiometricAuthenticator(kind: .touchID, error: AppLockError.failed)
        let failing = AppLockStore(defaults: defaults, authenticator: failingAuthenticator)
        await failing.enable()
        XCTAssertFalse(failing.isEnabled)
        XCTAssertFalse(failing.isLocked)
        XCTAssertEqual(failing.errorMessage, AppLockError.failed.localizedDescription)

        defaults.set(true, forKey: "appLock.biometricEnabled")
        let passcodeFallback = MockBiometricAuthenticator(kind: .unavailable, canAuthenticate: true)
        let fallbackStore = AppLockStore(defaults: defaults, authenticator: passcodeFallback)
        XCTAssertTrue(fallbackStore.isEnabled)
        XCTAssertTrue(fallbackStore.isLocked)
        await fallbackStore.unlock()
        XCTAssertFalse(fallbackStore.isLocked)
    }

    @MainActor
    func testMultipleEmailAccountsCanRegister() throws {
        let store = AuthStore(keychain: MemoryKeychain(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        try store.register(email: "first@example.com", password: "tramline26")
        store.signOut()
        try store.register(email: "second@example.com", password: "tramline27")
        XCTAssertEqual(store.session?.email, "second@example.com")
    }

    @MainActor
    func testEmailPasswordCanBeChangedOnlyWithCurrentPassword() throws {
        let suite = "PasswordChangeTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let keychain = MemoryKeychain()
        let store = AuthStore(keychain: keychain, defaults: defaults)
        try store.register(email: "rider@example.com", password: "tramline26")

        XCTAssertThrowsError(try store.changePassword(currentPassword: "wrongpass", newPassword: "nightbus42")) { error in
            XCTAssertEqual(error as? AuthError, .incorrectCurrentPassword)
        }
        try store.changePassword(currentPassword: "tramline26", newPassword: "nightbus42")
        XCTAssertNotNil(store.session)

        store.signOut()
        XCTAssertThrowsError(try store.signIn(email: "rider@example.com", password: "tramline26"))
        try store.signIn(email: "rider@example.com", password: "nightbus42")
        XCTAssertEqual(store.session?.email, "rider@example.com")
    }

    @MainActor
    func testFailedPasswordUpdatePreservesExistingPassword() throws {
        let suite = "PasswordChangeFailureTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let keychain = MemoryKeychain()
        let store = AuthStore(keychain: keychain, defaults: defaults)
        try store.register(email: "rider@example.com", password: "tramline26")
        keychain.setSucceeds = false

        XCTAssertThrowsError(try store.changePassword(currentPassword: "tramline26", newPassword: "nightbus42"))
        store.signOut()
        keychain.setSucceeds = true
        try store.signIn(email: "rider@example.com", password: "tramline26")
        XCTAssertEqual(store.session?.email, "rider@example.com")
    }

    @MainActor
    func testDisplayNameNormalizesAndPersistsWithoutChangingIdentity() throws {
        let suite = "DisplayNameTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let keychain = MemoryKeychain()
        let store = AuthStore(keychain: keychain, defaults: defaults)
        try store.register(email: "rider@example.com", password: "tramline26")

        store.updateDisplayName("  Ivan   Dovhosheia  ")

        XCTAssertEqual(store.session?.displayName, "Ivan Dovhosheia")
        XCTAssertEqual(store.session?.userID, "rider@example.com")
        XCTAssertEqual(store.session?.provider, .email)
        let restored = AuthStore(keychain: keychain, defaults: defaults)
        XCTAssertEqual(restored.session?.displayName, "Ivan Dovhosheia")

        restored.updateDisplayName("   ")
        XCTAssertNil(restored.session?.displayName)
        XCTAssertEqual(AuthStore(keychain: keychain, defaults: defaults).session?.email, "rider@example.com")
    }

    func testDisplayNameHasDeterministicLengthBoundary() {
        XCTAssertEqual(AuthStore.normalizedDisplayName(String(repeating: "a", count: 50))?.count, 40)
        XCTAssertNil(AuthStore.normalizedDisplayName("\n\t "))
    }

    func testDepartureReminderPlanUsesUsefulLeadTime() throws {
        XCTAssertEqual(
            try DepartureReminderScheduler.plan(minutes: 4),
            .init(leadMinutes: 1, delay: 180)
        )
        XCTAssertEqual(
            try DepartureReminderScheduler.plan(minutes: 8),
            .init(leadMinutes: 3, delay: 300)
        )
    }

    func testDepartureReminderRejectsDepartureThatIsTooSoon() {
        XCTAssertThrowsError(try DepartureReminderScheduler.plan(minutes: 1)) { error in
            XCTAssertEqual(error as? DepartureReminderError, .departureTooSoon)
        }
        XCTAssertThrowsError(try DepartureReminderScheduler.plan(minutes: 0))
    }

    func testScheduledDepartureRemindersFilterMapAndSortPendingRequests() {
        let later = reminderRequest(
            identifier: "departure.U1.Karlsplatz.Leopoldau",
            line: "U1",
            destination: "Leopoldau",
            stop: "Karlsplatz",
            delay: 600
        )
        let sooner = reminderRequest(
            identifier: "departure.D.Schottentor.Nussdorf",
            line: "D",
            destination: "Nussdorf",
            stop: "Schottentor",
            delay: 120
        )
        let unrelated = UNNotificationRequest(
            identifier: "marketing.message",
            content: UNMutableNotificationContent(),
            trigger: nil
        )
        let malformed = UNNotificationRequest(
            identifier: "departure.missing.metadata",
            content: UNMutableNotificationContent(),
            trigger: nil
        )

        let reminders = DepartureReminderScheduler.reminders(from: [later, unrelated, malformed, sooner])

        XCTAssertEqual(reminders.map(\.line), ["D", "U1"])
        XCTAssertEqual(reminders.first?.destination, "Nussdorf")
        XCTAssertEqual(reminders.first?.stop, "Schottentor")
        XCTAssertNotNil(reminders.first?.fireDate)
    }

    @MainActor
    func testRemovingLocalEmailAccountDeletesVerifierAndSession() throws {
        let suite = "AuthRemovalTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let keychain = MemoryKeychain()
        let store = AuthStore(keychain: keychain, defaults: defaults)
        try store.register(email: "rider@example.com", password: "tramline26")

        try store.removeCurrentAccountFromDevice()

        XCTAssertNil(store.session)
        XCTAssertNil(defaults.data(forKey: "auth.session"))
        XCTAssertThrowsError(try store.signIn(email: "rider@example.com", password: "tramline26"))
    }

    @MainActor
    func testFailedEmailAccountRemovalKeepsSessionActive() throws {
        let suite = "AuthRemovalFailureTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let keychain = MemoryKeychain()
        let store = AuthStore(keychain: keychain, defaults: defaults)
        try store.register(email: "rider@example.com", password: "tramline26")
        keychain.removeSucceeds = false

        XCTAssertThrowsError(try store.removeCurrentAccountFromDevice())
        XCTAssertNotNil(store.session)
        XCTAssertNotNil(defaults.data(forKey: "auth.session"))
    }

    @MainActor
    func testRemovingAppleAccountOnlyClearsLocalSession() throws {
        let suite = "AppleRemovalTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let session = AuthSession(userID: "apple-user", email: nil, displayName: "Rider", provider: .apple)
        defaults.set(try JSONEncoder().encode(session), forKey: "auth.session")
        let keychain = MemoryKeychain()
        let store = AuthStore(keychain: keychain, defaults: defaults)

        try store.removeCurrentAccountFromDevice()

        XCTAssertNil(store.session)
        XCTAssertEqual(keychain.removeCallCount, 0)
    }

    // MARK: - StationStore

    @MainActor
    func testStationStoreLoadsAsynchronouslyWithoutPublishingPartialIndexes() async {
        let store = StationStore(loadSynchronously: false)

        XCTAssertFalse(store.isReady)
        XCTAssertTrue(store.stations.isEmpty)

        await store.waitUntilReady()

        XCTAssertTrue(store.isReady)
        XCTAssertGreaterThan(store.stations.count, 0)
        guard let station = store.stations.first else { return }
        XCTAssertEqual(store.station(id: station.id)?.name, station.name)
    }

    func testStationLookupByIDUsesIndex() {
        let store = StationStore()
        guard let station = store.stations.first else { return XCTFail("Missing station fixture") }
        XCTAssertEqual(store.station(id: station.id)?.name, station.name)
    }

    func testStationLookupByDivaUsesDeterministicIndex() throws {
        let store = StationStore()
        let station = try XCTUnwrap(store.stations.filter { $0.diva != nil }.min { $0.id < $1.id })
        let diva = try XCTUnwrap(station.diva)
        let expected = try XCTUnwrap(store.stations.filter { $0.diva == diva }.min { $0.id < $1.id })

        XCTAssertEqual(store.station(diva: diva)?.id, expected.id)
    }

    @MainActor
    func testFavoriteRouteResolvesOnlyCanonicalStationData() throws {
        let store = StationStore()
        let canonical = try XCTUnwrap(store.stations.first { $0.diva != nil })
        let diva = try XCTUnwrap(canonical.diva)
        let route = FavoriteRoute(diva: String(diva), lineName: "U1", destination: "Leopoldau")

        XCTAssertEqual(route.station(in: store)?.id, store.station(diva: diva)?.id)
        XCTAssertNil(FavoriteRoute(
            diva: "invalid", lineName: "U1", destination: "Leopoldau"
        ).station(in: store))
        XCTAssertNil(FavoriteRoute(
            diva: "-1", lineName: "U1", destination: "Leopoldau"
        ).station(in: store))
    }

    func testStationSearchRanksExactMatchBeforePartialMatches() {
        let store = StationStore()
        let results = store.stationsSuggestion(matching: "Karlsplatz")

        XCTAssertEqual(results.first?.name, "Karlsplatz")
        XCTAssertTrue(results.dropFirst().contains { $0.name.contains("Karlsplatz") })
    }

    func testStationSearchRanksPrefixBeforeEmbeddedMatch() {
        let store = StationStore()
        let names = store.stationsSuggestion(matching: "Hauptbahnhof").map(\.name)

        XCTAssertEqual(names.first, "Hauptbahnhof")
        XCTAssertLessThan(
            names.firstIndex(of: "Hauptbahnhof Ost")!,
            names.firstIndex(of: "St. Pölten Hauptbahnhof")!
        )
    }

    func testStationSearchBigramIndexNarrowsCandidatesWithoutDroppingMatches() {
        let store = StationStore()

        let names = store.stationsSuggestion(matching: "Haupt").map(\.name)

        XCTAssertTrue(names.contains("Hauptbahnhof"))
        XCTAssertTrue(names.contains("St. Pölten Hauptbahnhof"))
        XCTAssertLessThan(store.indexedCandidateCount(matching: "Haupt"), store.stations.count / 2)
        XCTAssertEqual(store.indexedCandidateCount(matching: "H"), store.stations.count)
    }

    func testExactDivaLookupUsesNormalizedName() {
        let store = StationStore()

        XCTAssertEqual(store.diva(forExact: "  KÁRLSPLATZ  "), store.diva(forExact: "Karlsplatz"))
        XCTAssertNotNil(store.diva(forExact: "Karlsplatz"))
    }

    func testStationSearchPerformance() {
        let store = StationStore()
        measure {
            for _ in 0..<100 {
                _ = store.stationsSuggestion(matching: "Haupt")
            }
        }
    }

    func testNearbySpatialIndexPerformance() {
        let store = StationStore()
        let center = CLLocation(latitude: 48.2082, longitude: 16.3738)
        measure {
            for _ in 0..<100 {
                _ = store.stations(near: center, radiusInMeters: 1_500)
            }
        }
    }

    @MainActor
    func testNearbyLoadsStationMonitorsConcurrentlyThroughService() async {
        let network = MockNetworkManager(monitorDelayNanoseconds: 50_000_000)
        let service = MonitorService(network: network, cacheTTL: 0, minInterval: 0)
        let store = StationStore()
        let location = LocationManager()
        location.userLocation = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let viewModel = NearbyViewModel(store: store, location: location, service: service)

        await viewModel.load()

        XCTAssertGreaterThan(viewModel.items.count, 1)
        XCTAssertTrue(viewModel.items.allSatisfy { !$0.lines.isEmpty })
        XCTAssertGreaterThan(network.maxConcurrentMonitorCalls, 1)
    }

    @MainActor
    func testNearbyManualRefreshBypassesMonitorCache() async {
        let network = MockNetworkManager()
        let service = MonitorService(network: network, cacheTTL: 600, minInterval: 0)
        let store = StationStore()
        let location = LocationManager()
        location.userLocation = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let viewModel = NearbyViewModel(store: store, location: location, service: service)

        await viewModel.load()
        let firstRequestCount = network.callCount
        await viewModel.load(force: true)

        XCTAssertEqual(firstRequestCount, viewModel.items.count)
        XCTAssertEqual(network.callCount, firstRequestCount * 2)
    }

    @MainActor
    func testNearbyPollingDoesNotStartOverlappingBatch() async {
        let network = MockNetworkManager(monitorDelayNanoseconds: 100_000_000)
        let service = MonitorService(network: network, cacheTTL: 0, minInterval: 0)
        let store = StationStore()
        let location = LocationManager()
        location.userLocation = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let viewModel = NearbyViewModel(store: store, location: location, service: service)

        let first = Task { await viewModel.load() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        await viewModel.load()
        await first.value

        XCTAssertEqual(network.callCount, viewModel.items.count)
        XCTAssertTrue(viewModel.items.allSatisfy { !$0.lines.isEmpty })
    }

    @MainActor
    func testNearbyManualRefreshSupersedesActivePollingBatch() async {
        let network = MockNetworkManager(monitorDelayNanoseconds: 100_000_000)
        let service = MonitorService(network: network, cacheTTL: 0, minInterval: 0)
        let store = StationStore()
        let location = LocationManager()
        location.userLocation = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let viewModel = NearbyViewModel(store: store, location: location, service: service)
        var manualRefreshCompleted = false

        let polling = Task { await viewModel.load() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        let manualRefresh = Task {
            await viewModel.load(force: true)
            manualRefreshCompleted = true
        }
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertFalse(manualRefreshCompleted)
        await polling.value
        await manualRefresh.value
        XCTAssertEqual(network.callCount, viewModel.items.count)
        XCTAssertTrue(viewModel.items.allSatisfy { !$0.lines.isEmpty })
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    @MainActor
    func testStationDetailManualRefreshBypassesMonitorCache() async {
        let station = Station(id: 1, diva: 1, name: "Test Stop", lat: 48.2, lon: 16.3)
        let network = MockNetworkManager()
        let viewModel = StationDetailViewModel(
            station: station,
            service: MonitorService(network: network, cacheTTL: 600, minInterval: 0),
            widgetSync: NoopWidgetSync()
        )

        await viewModel.load()
        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(network.callCount, 2)
        XCTAssertFalse(viewModel.groups.isEmpty)
    }

    @MainActor
    func testStationDetailPollingDoesNotStartOverlappingRequest() async {
        let station = Station(id: 1, diva: 1, name: "Test Stop", lat: 48.2, lon: 16.3)
        let network = MockNetworkManager(monitorDelayNanoseconds: 100_000_000)
        let viewModel = StationDetailViewModel(
            station: station,
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            widgetSync: NoopWidgetSync()
        )

        let first = Task { await viewModel.load() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        await viewModel.load()
        await first.value

        XCTAssertEqual(network.callCount, 1)
        XCTAssertFalse(viewModel.groups.isEmpty)
    }

    @MainActor
    func testStationDetailManualRefreshSupersedesActivePollingRequest() async {
        let station = Station(id: 1, diva: 1, name: "Test Stop", lat: 48.2, lon: 16.3)
        let network = MockNetworkManager(monitorDelayNanoseconds: 100_000_000)
        let widget = RecordingWidgetSync()
        let viewModel = StationDetailViewModel(
            station: station,
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            widgetSync: widget
        )
        var manualRefreshCompleted = false

        let polling = Task { await viewModel.load() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        let manualRefresh = Task {
            await viewModel.load(forceRefresh: true)
            manualRefreshCompleted = true
        }
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertFalse(manualRefreshCompleted)
        await polling.value
        await manualRefresh.value
        XCTAssertEqual(network.callCount, 1)
        XCTAssertEqual(widget.saveCallCount, 1)
        XCTAssertFalse(viewModel.groups.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    @MainActor
    func testStationDetailRefreshPublishesBusyStateWithExistingContent() async {
        let station = Station(id: 1, diva: 1, name: "Test Stop", lat: 48.2, lon: 16.3)
        let network = MockNetworkManager()
        let viewModel = StationDetailViewModel(
            station: station,
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            widgetSync: NoopWidgetSync()
        )
        await viewModel.load()
        network.monitorDelayNanoseconds = 100_000_000

        let refresh = Task { await viewModel.load(forceRefresh: true) }
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(viewModel.isRefreshing)
        XCTAssertFalse(viewModel.isLoading)
        await refresh.value
        XCTAssertFalse(viewModel.isRefreshing)
    }

    @MainActor
    func testStationDetailRefreshFailurePreservesUsefulDepartures() async {
        let station = Station(id: 1, diva: 1, name: "Test Stop", lat: 48.2, lon: 16.3)
        let network = MockNetworkManager()
        let service = MonitorService(network: network, cacheTTL: 0, minInterval: 0)
        let widget = RecordingWidgetSync()
        let viewModel = StationDetailViewModel(
            station: station,
            service: service,
            widgetSync: widget
        )
        await viewModel.load()
        let originalGroups = viewModel.groups.map(\.id)
        await service.clearCache()
        network.shouldFail = true

        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.groups.map(\.id), originalGroups)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertEqual(widget.saveCallCount, 1)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)

        network.shouldFail = false
        await viewModel.load(forceRefresh: true)

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(widget.saveCallCount, 2)
        XCTAssertEqual(viewModel.groups.map(\.id), originalGroups)
    }

    func testMapStationSelectionIsDistanceSortedAndLimited() {
        let store = StationStore()
        let center = CLLocation(latitude: 48.2082, longitude: 16.3738)

        let stations = MapStationSelection.nearest(in: store, to: center, radius: 1_500, limit: 25)
        let distances = stations.map {
            CLLocation(latitude: $0.lat, longitude: $0.lon).distance(from: center)
        }

        XCTAssertEqual(stations.count, 25)
        XCTAssertEqual(distances, distances.sorted())
        XCTAssertLessThanOrEqual(distances.last ?? .infinity, 1_500)
    }

    func testMapCenterKeyIgnoresSmallLocationJitter() {
        let first = MapCenterKey(location: CLLocation(latitude: 48.20820, longitude: 16.37380))
        let jittered = MapCenterKey(location: CLLocation(latitude: 48.20824, longitude: 16.37384))
        let moved = MapCenterKey(location: CLLocation(latitude: 48.20940, longitude: 16.37500))

        XCTAssertEqual(first, jittered)
        XCTAssertNotEqual(first, moved)
    }

    func testMapFavoriteFilterPreservesVisibleStationOrder() {
        let stations = [
            Station(id: 1, diva: 1, name: "First", lat: 48.1, lon: 16.1),
            Station(id: 2, diva: 2, name: "Second", lat: 48.2, lon: 16.2),
            Station(id: 3, diva: 3, name: "Third", lat: 48.3, lon: 16.3)
        ]

        XCTAssertEqual(
            MapStationFilter.visible(stations, favoriteIDs: [3, 1], favoritesOnly: true).map(\.id),
            [1, 3]
        )
        XCTAssertEqual(
            MapStationFilter.visible(stations, favoriteIDs: [], favoritesOnly: true).map(\.id),
            []
        )
        XCTAssertEqual(
            MapStationFilter.visible(stations, favoriteIDs: [], favoritesOnly: false).map(\.id),
            stations.map(\.id)
        )
    }

    func testMapStationListSearchIsDiacriticInsensitiveAndPreservesDistanceOrder() {
        let stations = [
            Station(id: 1, diva: 1, name: "Schönbrunn", lat: 48.1, lon: 16.1),
            Station(id: 2, diva: 2, name: "Westbahnhof", lat: 48.2, lon: 16.2),
            Station(id: 3, diva: 3, name: "Schönbrunner Straße", lat: 48.3, lon: 16.3)
        ]

        XCTAssertEqual(
            MapStationListSearch.matching(stations, query: "  SCHON  ").map(\.id),
            [1, 3]
        )
        XCTAssertEqual(
            MapStationListSearch.matching(stations, query: "str schon").map(\.id),
            [3]
        )
        XCTAssertEqual(
            MapStationListSearch.matching(stations, query: "   ").map(\.id),
            stations.map(\.id)
        )
    }

    func testMapStationListOrderUsesUserDistanceAndStableTies() {
        let origin = CLLocation(latitude: 48.2000, longitude: 16.3700)
        let stations = [
            Station(id: 1, diva: 1, name: "Far", lat: 48.2100, lon: 16.3700),
            Station(id: 2, diva: 2, name: "Near first", lat: 48.2010, lon: 16.3700),
            Station(id: 3, diva: 3, name: "Near second", lat: 48.2010, lon: 16.3700)
        ]

        XCTAssertEqual(
            MapStationListOrder.nearest(stations, to: origin).map(\.id),
            [2, 3, 1]
        )
        XCTAssertEqual(
            MapStationListOrder.nearest(stations, to: nil).map(\.id),
            stations.map(\.id)
        )
    }

    func testWalkingEstimateUsesSharedMinutesAndDistanceFormatting() {
        XCTAssertEqual(WalkingEstimate(distanceMeters: 280).minutes, 4)
        XCTAssertEqual(WalkingEstimate(distanceMeters: 280).text, "4 min · 280 m")
        XCTAssertEqual(WalkingEstimate(distanceMeters: 1_280).minutes, 16)
        XCTAssertEqual(WalkingEstimate(distanceMeters: 1_280).distanceText, "1.3 km")
        XCTAssertEqual(WalkingEstimate(distanceMeters: -10).distanceMeters, 0)
        XCTAssertEqual(WalkingEstimate(distanceMeters: -10).minutes, 1)

        let origin = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let destination = CLLocation(latitude: 48.2100, longitude: 16.3738)
        XCTAssertEqual(
            origin.walkMinutes(to: destination),
            WalkingEstimate(distanceMeters: destination.distance(from: origin)).minutes
        )
    }

    // MARK: - RouteMatching

    func testNormalizeTrimsWhitespace() {
        XCTAssertEqual(RouteMatching.normalize("  Praterstern  "), "praterstern")
    }

    func testNormalizeLowercases() {
        XCTAssertEqual(RouteMatching.normalize("Leopoldau"), "leopoldau")
    }

    func testNormalizeStripsTrailingU() {
        XCTAssertEqual(RouteMatching.normalize("Kagran U"), "kagran")
    }

    func testNormalizeStripsTrailingS() {
        XCTAssertEqual(RouteMatching.normalize("Meidling S"), "meidling")
    }

    func testNormalizeDoesNotStripMidStringU() {
        XCTAssertEqual(RouteMatching.normalize("Wien Mitte"), "wien mitte")
    }

    func testNormalizeCollapsesInternalWhitespace() {
        XCTAssertEqual(RouteMatching.normalize("Wien   Mitte"), "wien mitte")
    }

    func testNormalizeFoldsDiacritics() {
        XCTAssertEqual(RouteMatching.normalize("Franz-Josefs-Bahnhof"), "franz-josefs-bahnhof")
    }

    func testMatchesExact() {
        XCTAssertTrue(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U1", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesWithTrailingMarker() {
        XCTAssertTrue(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau U",
            favoriteLine: "U1", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesDifferentLineFails() {
        XCTAssertFalse(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U2", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesDifferentDestinationFails() {
        XCTAssertFalse(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U1", favoriteDestination: "Kagran"
        ))
    }

    // MARK: - DepartureClock

    func testDepartureShareContentUsesNearestCountdown() {
        let content = DepartureShareContent.make(
            line: "U4",
            destination: "Hütteldorf",
            station: "Karlsplatz",
            minutes: 3
        )

        XCTAssertEqual(content.subject, "Live departure: U4 to Hütteldorf")
        XCTAssertEqual(content.text, "U4 to Hütteldorf departs from Karlsplatz in 3 min. — Traffic Vienna")
    }

    func testDepartureShareContentDescribesDepartingNow() {
        let content = DepartureShareContent.make(
            line: "D",
            destination: "Nußdorf",
            station: "Schottentor",
            minutes: 0
        )

        XCTAssertEqual(content.text, "D to Nußdorf is departing now from Schottentor. — Traffic Vienna")
    }

    func testLiveMinutesFallback() {
        let result = DepartureClock.liveMinutes(realtime: nil, planned: nil, fallback: 42)
        XCTAssertEqual(result, 42)
    }

    func testLiveMinutesFromRealTime() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(300))
        let result = DepartureClock.liveMinutes(realtime: future, planned: nil, fallback: 99)
        XCTAssertEqual(result, 5)
    }

    func testLiveMinutesFromPlanned() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(120))
        let result = DepartureClock.liveMinutes(realtime: nil, planned: future, fallback: 99)
        XCTAssertEqual(result, 2)
    }

    func testLiveMinutesFromFractionalISODate() {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let future = formatter.string(from: Date().addingTimeInterval(180))
        let result = DepartureClock.liveMinutes(realtime: future, planned: nil, fallback: 99)
        XCTAssertEqual(result, 3)
    }

    func testLiveMinutesNeverNegative() {
        let past = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-60))
        let result = DepartureClock.liveMinutes(realtime: nil, planned: past, fallback: 0)
        XCTAssertEqual(result, 0)
    }

    // MARK: - DepartureTime liveMinutes

    func testDepartureTimeLiveMinutesFallback() {
        let dt = DepartureTime(countdown: 7, timePlanned: nil, timeReal: nil)
        XCTAssertEqual(dt.liveMinutes, 7)
    }

    // MARK: - MonitorService (mock network)

    func testMonitorServiceReturnsCachedResponse() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        let first = try await service.monitor(diva: 60201435)
        let cached = try await service.monitor(diva: 60201435)

        XCTAssertEqual(first.data.monitors.count, cached.data.monitors.count)
        XCTAssertEqual(mock.callCount, 1, "Second call should hit cache, not network")
    }

    func testMonitorServiceClearCacheForcesNextNetworkRequest() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30, minInterval: 0)
        _ = try await service.monitor(diva: 60201435)
        _ = try await service.monitor(diva: 60201435)
        XCTAssertEqual(mock.callCount, 1)

        await service.clearCache()
        _ = try await service.monitor(diva: 60201435)

        XCTAssertEqual(mock.callCount, 2)
    }

    func testMonitorServiceForceRefreshBypassesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.monitor(diva: 60201435)
        _ = try await service.monitor(diva: 60201435, forceRefresh: true)

        XCTAssertEqual(mock.callCount, 2, "Force refresh should bypass cache")
    }

    func testMonitorServiceFallbackToStaleCacheOnNetworkError() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.monitor(diva: 60201435)
        mock.shouldFail = true

        let result = try await service.monitorResult(diva: 60201435, forceRefresh: true)
        XCTAssertFalse(result.value.data.monitors.isEmpty, "Should return stale cache on error")
        XCTAssertTrue(result.freshness.isStale)
        if case let .stale(_, message) = result.freshness {
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Expected stale freshness metadata")
        }
    }

    func testMonitorServiceReportsNetworkThenFreshCache() async throws {
        let service = MonitorService(network: MockNetworkManager(), cacheTTL: 30, minInterval: 0)

        let first = try await service.monitorResult(diva: 60201435)
        let second = try await service.monitorResult(diva: 60201435)

        if case .network = first.freshness {} else { XCTFail("First result should come from network") }
        if case .cache = second.freshness {} else { XCTFail("Second result should come from fresh cache") }
    }

    func testRateLimitWithoutCacheRemainsVisibleAsError() async {
        let mock = MockNetworkManager(shouldRateLimit: true)
        let service = MonitorService(network: mock, minInterval: 0, maxRetries: 0)

        do {
            _ = try await service.monitorResult(diva: 60201435)
            XCTFail("Expected rate-limit error")
        } catch {
            XCTAssertTrue(error is MonitorApiError)
            XCTAssertFalse(error.monitorDisplayMessage.isEmpty)
            XCTAssertEqual(mock.callCount, 1)
        }
    }

    func testPersistentURLCacheIsReportedAsStale() async throws {
        let storedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let mock = MockNetworkManager(responseSource: .urlCache(storedAt: storedAt))
        let service = MonitorService(network: mock, minInterval: 0)

        let result = try await service.monitorResult(diva: 60201435)

        if case let .stale(date, message) = result.freshness {
            XCTAssertEqual(date, storedAt)
            XCTAssertFalse(message.isEmpty)
        } else {
            XCTFail("Persistent URL cache must be visible as stale data")
        }
    }

    func testTrafficInfoListUsesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)
        _ = try await service.trafficInfoList()
        _ = try await service.trafficInfoList()
        XCTAssertEqual(mock.callCount, 1)
    }

    func testConcurrentTrafficInfoRefreshesShareOneRequest() async throws {
        let mock = MockNetworkManager(trafficInfoDelayNanoseconds: 50_000_000)
        let service = MonitorService(network: mock, cacheTTL: 0, minInterval: 0)

        async let first = service.trafficInfoList(forceRefresh: true)
        async let second = service.trafficInfoList(forceRefresh: true)
        _ = try await (first, second)

        XCTAssertEqual(mock.callCount, 1)
    }

    func testFailedTrafficInfoRequestDoesNotRemainInFlight() async throws {
        let mock = MockNetworkManager(shouldFail: true)
        let service = MonitorService(network: mock, cacheTTL: 0, minInterval: 0)

        do {
            _ = try await service.trafficInfoList(forceRefresh: true)
            XCTFail("Expected the first traffic-info request to fail")
        } catch {}

        mock.shouldFail = false
        _ = try await service.trafficInfoList(forceRefresh: true)

        XCTAssertEqual(mock.callCount, 2)
    }

    func testClearCacheCancelsTrafficInfoRequestAndAllowsRetry() async throws {
        let mock = MockNetworkManager(trafficInfoDelayNanoseconds: 200_000_000)
        let service = MonitorService(network: mock, cacheTTL: 0, minInterval: 0)
        let request = Task { try await service.trafficInfoList(forceRefresh: true) }
        try await Task.sleep(nanoseconds: 20_000_000)

        await service.clearCache()

        do {
            _ = try await request.value
            XCTFail("Expected clearCache to cancel the in-flight request")
        } catch is CancellationError {}

        mock.trafficInfoDelayNanoseconds = 0
        _ = try await service.trafficInfoList(forceRefresh: true)

        XCTAssertEqual(mock.callCount, 2)
    }

    // MARK: - Rendering and energy regressions

    func testFavoriteItemsUseStableIdentity() {
        let route = FavoriteRoute(diva: "60201435", lineName: "U1", destination: "Leopoldau")
        let first = FavoriteWithDeparture(route: route, stopName: "Stephansplatz", departures: [])
        let refreshed = FavoriteWithDeparture(route: route, stopName: "Stephansplatz", departures: [])

        XCTAssertEqual(first.id, refreshed.id)
    }

    @MainActor
    func testFavoritesLoadConcurrentlyWhilePreservingSavedOrder() async {
        let routes = [
            FavoriteRoute(diva: "3", lineName: "U1", destination: "Leopoldau"),
            FavoriteRoute(diva: "1", lineName: "U1", destination: "Oberlaa"),
            FavoriteRoute(diva: "2", lineName: "U1", destination: "Reumannplatz")
        ]
        let network = MockNetworkManager(monitorDelayNanoseconds: 50_000_000)
        let widget = RecordingWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: routes),
            stationsRepo: CountingFavoriteStationsRepository(),
            widgetSync: widget
        )

        await viewModel.loadFavorites()

        XCTAssertGreaterThan(network.maxConcurrentMonitorCalls, 1)
        XCTAssertEqual(viewModel.items.map(\.route), routes)
        XCTAssertEqual(widget.savedData.map(\.destination), routes.map(\.destination))
    }

    @MainActor
    func testFavoritePullToRefreshBypassesMonitorCache() async {
        let route = FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")
        let network = MockNetworkManager()
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: network, cacheTTL: 600, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: [route]),
            stationsRepo: CountingFavoriteStationsRepository(),
            widgetSync: NoopWidgetSync()
        )

        await viewModel.loadFavorites()
        await viewModel.loadFavorites(forceRefresh: true)

        XCTAssertEqual(network.callCount, 2)
    }

    @MainActor
    func testFavoriteRefreshFailurePreservesDeparturesAndRecovers() async {
        let route = FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")
        let network = MockNetworkManager()
        let service = MonitorService(network: network, cacheTTL: 0, minInterval: 0)
        let widget = RecordingWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: service,
            favoritesRepo: CountingFavoritesRepository(routes: [route]),
            stationsRepo: CountingFavoriteStationsRepository(),
            widgetSync: widget
        )
        await viewModel.loadFavorites()
        let originalDepartures = viewModel.items.first?.departures
        await service.clearCache()
        network.shouldFail = true

        await viewModel.loadFavorites(forceRefresh: true)

        XCTAssertEqual(viewModel.items.first?.departures, originalDepartures)
        XCTAssertNotNil(viewModel.items.first?.loadError)
        XCTAssertEqual(widget.savedData.first?.departures, originalDepartures?.prefix(3).map(\.countdown))
        XCTAssertFalse(viewModel.isLoading)

        network.shouldFail = false
        await viewModel.loadFavorites(forceRefresh: true)

        XCTAssertNil(viewModel.items.first?.loadError)
        XCTAssertEqual(viewModel.items.first?.departures, originalDepartures)
    }

    @MainActor
    func testFavoriteFirstLoadFailureHasNoInventedDepartures() async {
        let route = FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: MockNetworkManager(shouldFail: true), cacheTTL: 0, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: [route]),
            stationsRepo: CountingFavoriteStationsRepository(),
            widgetSync: NoopWidgetSync()
        )

        await viewModel.loadFavorites()

        XCTAssertTrue(viewModel.items.first?.departures.isEmpty == true)
        XCTAssertNotNil(viewModel.items.first?.loadError)
    }

    @MainActor
    func testFavoritePollingDoesNotStartOverlappingBatch() async {
        let route = FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")
        let network = MockNetworkManager(monitorDelayNanoseconds: 100_000_000)
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: [route]),
            stationsRepo: CountingFavoriteStationsRepository(),
            widgetSync: NoopWidgetSync()
        )

        let first = Task { await viewModel.loadFavorites() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        await viewModel.loadFavorites()
        await first.value

        XCTAssertEqual(network.callCount, 1)
        XCTAssertEqual(viewModel.items.map(\.route), [route])
    }

    @MainActor
    func testRemovingFavoriteDuringLoadCannotRepublishIt() async {
        let route = FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")
        let viewModel = FavoritesListViewModel(
            service: MonitorService(
                network: MockNetworkManager(monitorDelayNanoseconds: 100_000_000),
                cacheTTL: 0,
                minInterval: 0
            ),
            favoritesRepo: CountingFavoritesRepository(routes: [route]),
            stationsRepo: CountingFavoriteStationsRepository(),
            widgetSync: NoopWidgetSync()
        )

        let load = Task { await viewModel.loadFavorites() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        viewModel.remove(route)
        await load.value

        XCTAssertTrue(viewModel.favoriteRoutes.isEmpty)
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testDisruptionRelevanceDoesNotReadFavoritesForEveryItem() async {
        let favorites = CountingFavoritesRepository(
            routes: [FavoriteRoute(diva: "60201435", lineName: "U1", destination: "Leopoldau")]
        )
        let info = TrafficInfo(name: "test", title: "U1 delay", description: nil, priority: "1", relatedLines: ["U1"])
        let viewModel = DisruptionsViewModel(
            service: MonitorService(network: MockNetworkManager(trafficInfos: [info]), cacheTTL: 0),
            favoritesRepo: favorites
        )

        await viewModel.load()

        for _ in 0..<100 { XCTAssertTrue(viewModel.isRelevant(info)) }

        XCTAssertEqual(favorites.getAllCallCount, 2)
    }

    @MainActor
    func testDisruptionRelevanceCacheUpdatesAfterLoadAndFavouriteChanges() async {
        let u1 = TrafficInfo(name: "u1", title: "U1 delay", description: nil, priority: "1", relatedLines: ["U1"])
        let u3 = TrafficInfo(name: "u3", title: "U3 delay", description: nil, priority: "1", relatedLines: ["U3"])
        let network = MockNetworkManager(trafficInfos: [u3, u1])
        let favorites = CountingFavoritesRepository(
            routes: [FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")]
        )
        let viewModel = DisruptionsViewModel(
            service: MonitorService(network: network, cacheTTL: 0),
            favoritesRepo: favorites
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.relevantCount, 1)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["u1", "u3"])
        XCTAssertTrue(viewModel.isRelevant(u1))
        XCTAssertFalse(viewModel.isRelevant(u3))

        viewModel.updateFavoriteRoutes([
            FavoriteRoute(diva: "3", lineName: "U3", destination: "Ottakring")
        ])

        XCTAssertEqual(viewModel.relevantCount, 1)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["u3", "u1"])
        XCTAssertFalse(viewModel.isRelevant(u1))
        XCTAssertTrue(viewModel.isRelevant(u3))
    }

    @MainActor
    func testAlertManualRefreshBypassesTrafficInfoCache() async {
        let info = TrafficInfo(name: "u1", title: "U1 delay", description: nil, priority: "1", relatedLines: ["U1"])
        let network = MockNetworkManager(trafficInfos: [info])
        let viewModel = DisruptionsViewModel(
            service: MonitorService(network: network, cacheTTL: 600, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: [])
        )

        await viewModel.load()
        await viewModel.load(force: true)

        XCTAssertEqual(network.callCount, 2)
        XCTAssertEqual(viewModel.infos.map(\.id), [info.id])
    }

    @MainActor
    func testAlertRefreshPublishesBusyStateWithExistingContent() async {
        let info = TrafficInfo(name: "u1", title: "U1 delay", description: nil, priority: "1", relatedLines: ["U1"])
        let network = MockNetworkManager(trafficInfos: [info])
        let viewModel = DisruptionsViewModel(
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: [])
        )
        await viewModel.load()
        network.trafficInfoDelayNanoseconds = 100_000_000

        let refresh = Task { await viewModel.load(force: true) }
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertTrue(viewModel.isRefreshing)
        XCTAssertFalse(viewModel.isLoading)
        await refresh.value
        XCTAssertFalse(viewModel.isRefreshing)
    }

    @MainActor
    func testAlertRefreshFailurePreservesUsefulContentAndRecovers() async {
        let info = TrafficInfo(name: "u1", title: "U1 delay", description: nil, priority: "1", relatedLines: ["U1"])
        let network = MockNetworkManager(trafficInfos: [info])
        let service = MonitorService(network: network, cacheTTL: 0, minInterval: 0)
        let viewModel = DisruptionsViewModel(
            service: service,
            favoritesRepo: CountingFavoritesRepository(
                routes: [FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")]
            )
        )
        await viewModel.load()
        let originalInfoIDs = viewModel.infos.map(\.id)
        await service.clearCache()
        network.shouldFail = true

        await viewModel.load(force: true)

        XCTAssertEqual(viewModel.infos.map(\.id), originalInfoIDs)
        XCTAssertEqual(viewModel.relevantCount, 1)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)

        network.shouldFail = false
        await viewModel.load(force: true)

        XCTAssertNil(viewModel.errorMessage)
        XCTAssertEqual(viewModel.infos.map(\.id), originalInfoIDs)
        XCTAssertEqual(viewModel.relevantCount, 1)
    }

    @MainActor
    func testAlertFirstLoadFailureRemainsBlockingWithoutContent() async {
        let network = MockNetworkManager(shouldFail: true)
        let viewModel = DisruptionsViewModel(
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: [])
        )

        await viewModel.load()

        XCTAssertTrue(viewModel.infos.isEmpty)
        XCTAssertNotNil(viewModel.errorMessage)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    @MainActor
    func testAlertPollingDoesNotStartOverlappingRequest() async {
        let info = TrafficInfo(name: "u1", title: "U1 delay", description: nil, priority: "1", relatedLines: ["U1"])
        let network = MockNetworkManager(trafficInfos: [info], trafficInfoDelayNanoseconds: 100_000_000)
        let viewModel = DisruptionsViewModel(
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: [])
        )

        let first = Task { await viewModel.load() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        await viewModel.load()
        await first.value

        XCTAssertEqual(network.callCount, 1)
        XCTAssertEqual(viewModel.infos.map(\.id), [info.id])
    }

    @MainActor
    func testAlertManualRefreshSupersedesActivePollingRequest() async {
        let info = TrafficInfo(name: "u1", title: "U1 delay", description: nil, priority: "1", relatedLines: ["U1"])
        let network = MockNetworkManager(trafficInfos: [info], trafficInfoDelayNanoseconds: 100_000_000)
        let viewModel = DisruptionsViewModel(
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(routes: [])
        )
        var manualRefreshCompleted = false

        let polling = Task { await viewModel.load() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        let manualRefresh = Task {
            await viewModel.load(force: true)
            manualRefreshCompleted = true
        }
        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertFalse(manualRefreshCompleted)
        await polling.value
        await manualRefresh.value
        XCTAssertEqual(network.callCount, 1)
        XCTAssertEqual(viewModel.infos.map(\.id), [info.id])
        XCTAssertFalse(viewModel.isLoading)
    }

    @MainActor
    func testFavoriteLineChangeDuringAlertLoadControlsPublishedRelevance() async {
        let u1 = TrafficInfo(name: "u1", title: "U1 delay", description: nil, priority: "1", relatedLines: ["U1"])
        let u3 = TrafficInfo(name: "u3", title: "U3 delay", description: nil, priority: "1", relatedLines: ["U3"])
        let network = MockNetworkManager(trafficInfos: [u1, u3], trafficInfoDelayNanoseconds: 100_000_000)
        let viewModel = DisruptionsViewModel(
            service: MonitorService(network: network, cacheTTL: 0, minInterval: 0),
            favoritesRepo: CountingFavoritesRepository(
                routes: [FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")]
            )
        )

        let load = Task { await viewModel.load() }
        try? await Task.sleep(nanoseconds: 10_000_000)
        viewModel.updateFavoriteRoutes([
            FavoriteRoute(diva: "3", lineName: "U3", destination: "Ottakring")
        ])
        await load.value

        XCTAssertFalse(viewModel.isRelevant(u1))
        XCTAssertTrue(viewModel.isRelevant(u3))
        XCTAssertEqual(viewModel.relevantCount, 1)
    }

    @MainActor
    func testStationFavoriteToggleUpdatesSharedStateWithoutReloadingStorage() {
        let station = Station(id: 1, diva: 60200657, name: "Karlsplatz", lat: 48.2, lon: 16.3)
        let stations = CountingFavoriteStationsRepository()
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: MockNetworkManager()),
            favoritesRepo: CountingFavoritesRepository(routes: []),
            stationsRepo: stations,
            widgetSync: NoopWidgetSync()
        )

        viewModel.toggleStation(station)
        XCTAssertTrue(viewModel.isStationFavorite(id: station.id))
        XCTAssertEqual(stations.allCallCount, 1)

        viewModel.removeStation(id: station.id)
        XCTAssertFalse(viewModel.isStationFavorite(id: station.id))
        XCTAssertEqual(stations.allCallCount, 1)

        viewModel.toggleStation(station)
        viewModel.toggleStation(station)
        XCTAssertFalse(viewModel.isStationFavorite(id: station.id))
        XCTAssertEqual(stations.allCallCount, 1)
    }

    @MainActor
    func testLineFavoriteToggleUpdatesSharedStateWithoutReloadingStorage() {
        let routes = CountingFavoritesRepository(routes: [])
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: MockNetworkManager()),
            favoritesRepo: routes,
            stationsRepo: CountingFavoriteStationsRepository(),
            widgetSync: NoopWidgetSync()
        )

        for _ in 0..<100 {
            XCTAssertFalse(viewModel.isLineFavorite(diva: 60200657, lineName: "U1", destination: "Leopoldau"))
        }
        viewModel.toggleLineFavorite(diva: 60200657, lineName: "U1", destination: "Leopoldau")
        XCTAssertTrue(viewModel.isLineFavorite(diva: 60200657, lineName: "U1", destination: "Leopoldau"))
        viewModel.toggleLineFavorite(diva: 60200657, lineName: "U1", destination: "Leopoldau")
        XCTAssertFalse(viewModel.isLineFavorite(diva: 60200657, lineName: "U1", destination: "Leopoldau"))
        XCTAssertEqual(routes.getAllCallCount, 1)
    }

    @MainActor
    func testClearTravelFavoritesUpdatesStateAndRepositories() {
        let route = FavoriteRoute(diva: "60200657", lineName: "U1", destination: "Leopoldau")
        let routes = CountingFavoritesRepository(routes: [route])
        let station = FavoriteStation(id: 1, diva: 60200657, name: "Karlsplatz")
        let stations = CountingFavoriteStationsRepository(stations: [station])
        let widget = RecordingWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: MockNetworkManager()),
            favoritesRepo: routes,
            stationsRepo: stations,
            widgetSync: widget
        )

        viewModel.clearTravelFavorites()

        XCTAssertTrue(viewModel.favoriteRoutes.isEmpty)
        XCTAssertTrue(viewModel.stations.isEmpty)
        XCTAssertTrue(routes.getAll().isEmpty)
        XCTAssertTrue(stations.all().isEmpty)
        XCTAssertEqual(widget.clearCallCount, 1)
    }

    @MainActor
    func testBatchFavoriteRemovalUpdatesPersistenceAndWidgetOnce() {
        let firstRoute = FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")
        let secondRoute = FavoriteRoute(diva: "2", lineName: "U2", destination: "Seestadt")
        let routes = CountingFavoritesRepository(routes: [firstRoute, secondRoute])
        let firstStation = FavoriteStation(id: 1, diva: 1, name: "First")
        let secondStation = FavoriteStation(id: 2, diva: 2, name: "Second")
        let stations = CountingFavoriteStationsRepository(stations: [firstStation, secondStation])
        let widget = RecordingWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: MockNetworkManager()),
            favoritesRepo: routes,
            stationsRepo: stations,
            widgetSync: widget
        )

        viewModel.removeStations(at: IndexSet(integer: 0))
        viewModel.removeFavoriteRoutes(at: IndexSet(integer: 1))

        XCTAssertEqual(viewModel.stations, [secondStation])
        XCTAssertEqual(stations.all(), [secondStation])
        XCTAssertEqual(viewModel.favoriteRoutes, [firstRoute])
        XCTAssertEqual(routes.getAll(), [firstRoute])
        XCTAssertEqual(widget.saveCallCount, 1)
    }

    func testTravelDataResetClearsOnlyAllowlistedAuxiliaryKeys() {
        let suite = "TravelDataResetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        TravelDataResetService.auxiliaryKeys.forEach { defaults.set("value", forKey: $0) }
        defaults.set("keep", forKey: "themePreset")
        defaults.set("keep", forKey: "auth.session")

        TravelDataResetService(defaults: defaults).clearAuxiliaryData()

        TravelDataResetService.auxiliaryKeys.forEach { XCTAssertNil(defaults.object(forKey: $0)) }
        XCTAssertEqual(defaults.string(forKey: "themePreset"), "keep")
        XCTAssertEqual(defaults.string(forKey: "auth.session"), "keep")
    }

    @MainActor
    func testRemovingAllRoutinesClearsPersistence() {
        let suite = "RoutineResetTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = CommuteRoutineStore(defaults: defaults)
        store.add(
            name: "Work",
            station: FavoriteStation(id: 1, diva: 123, name: "Karlsplatz"),
            hour: 8
        )

        store.removeAll()

        XCTAssertTrue(store.routines.isEmpty)
        XCTAssertNil(defaults.data(forKey: "commute_routines"))
    }

    func testLineFavoritesPersistInsertionOrderAndRemainRollbackCompatible() throws {
        let suite = "OrderedFavoriteRouteTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let repository = UserDefaultsFavoritesRepository(storage: defaults)
        let u2 = FavoriteRoute(diva: "2", lineName: "U2", destination: "Seestadt")
        let u1 = FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")

        repository.toggle(diva: "2", lineName: "U2", destination: "Seestadt")
        repository.toggle(diva: "1", lineName: "U1", destination: "Leopoldau")

        XCTAssertEqual(repository.getAll().map(\.lineName), ["U2", "U1"])
        let stored = try XCTUnwrap(defaults.data(forKey: "favorite_routes"))
        XCTAssertEqual(try JSONDecoder().decode(Set<FavoriteRoute>.self, from: stored).count, 2)

        repository.setOrder([u1, u2, u1])
        XCTAssertEqual(UserDefaultsFavoritesRepository(storage: defaults).getAll(), [u1, u2])

        repository.toggle(diva: "2", lineName: "U2", destination: "Seestadt")
        XCTAssertEqual(UserDefaultsFavoritesRepository(storage: defaults).getAll().map(\.lineName), ["U1"])
    }

    @MainActor
    func testFavoriteRouteReorderingPersistsAndUpdatesWidgetPriority() {
        let routes = [
            FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau"),
            FavoriteRoute(diva: "2", lineName: "U2", destination: "Seestadt"),
            FavoriteRoute(diva: "3", lineName: "U3", destination: "Ottakring")
        ]
        let repository = CountingFavoritesRepository(routes: routes)
        let widget = RecordingWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: MonitorService(network: MockNetworkManager()),
            favoritesRepo: repository,
            stationsRepo: CountingFavoriteStationsRepository(),
            widgetSync: widget
        )
        viewModel.items = routes.enumerated().map { index, route in
            FavoriteWithDeparture(
                route: route,
                stopName: "Stop \(index)",
                departures: [DepartureInfo(countdown: index + 1, planned: "", real: nil, isRealtime: false)]
            )
        }

        viewModel.moveFavoriteRoutes(fromOffsets: IndexSet(integer: 2), toOffset: 0)

        let expected = [routes[2], routes[0], routes[1]]
        XCTAssertEqual(viewModel.favoriteRoutes, expected)
        XCTAssertEqual(viewModel.items.map(\.route), expected)
        XCTAssertEqual(repository.getAll(), expected)
        XCTAssertEqual(widget.savedData.map(\.destination), expected.map(\.destination))
    }

    func testLegacyDuplicateLineFavoritesNormalizeInFirstSeenOrder() throws {
        let suite = "DuplicateFavoriteRouteTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let u2 = FavoriteRoute(diva: "2", lineName: "U2", destination: "Seestadt")
        let u1 = FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau")
        defaults.set(try JSONEncoder().encode([u2, u2, u1]), forKey: "favorite_routes")

        let routes = UserDefaultsFavoritesRepository(storage: defaults).getAll()

        XCTAssertEqual(routes, [u2, u1])
    }

    // MARK: - LineColors

    func testLineColorsU1() {
        let color = LineColors.color(for: "U1")
        XCTAssertNotNil(color)
    }

    func testLineCategoryOfU1() {
        XCTAssertEqual(LineCategory.of("U1"), .metro)
    }

    func testLineCategoryOfS1() {
        XCTAssertEqual(LineCategory.of("S1"), .sbahn)
    }

    func testLineCategoryOf13A() {
        XCTAssertEqual(LineCategory.of("13A"), .bus)
    }

    func testLineCategoryOfN25() {
        XCTAssertEqual(LineCategory.of("N25"), .night)
    }

    func testLineCategoryOfTram() {
        XCTAssertEqual(LineCategory.of("O"), .tram)
        XCTAssertEqual(LineCategory.of("D"), .tram)
    }

    // MARK: - WidgetDepartureData

    func testWidgetDepartureDataCodable() {
        let data = WidgetDepartureData(lineName: "U1", stopName: "Stephansplatz", destination: "Leopoldau", departures: [2, 5, 12])
        let encoded = try! JSONEncoder().encode(data)
        let decoded = try! JSONDecoder().decode(WidgetDepartureData.self, from: encoded)
        XCTAssertEqual(decoded.lineName, "U1")
        XCTAssertEqual(decoded.departures, [2, 5, 12])
    }

    func testWidgetMergePreservesSelectedOrderAndUsesCacheForPartialFailure() {
        let selected = [
            WidgetRouteKey(lineName: "U1", destination: "Leopoldau"),
            WidgetRouteKey(lineName: "O", destination: "Raxstraße")
        ]
        let cached = [
            WidgetDepartureData(lineName: "U1", stopName: "Stephansplatz", destination: "Leopoldau", departures: [9]),
            WidgetDepartureData(lineName: "O", stopName: "Praterstern", destination: "Raxstraße", departures: [8])
        ]
        let fresh = [
            WidgetDepartureData(lineName: "O", stopName: "Praterstern", destination: "Raxstraße", departures: [2])
        ]

        let merged = WidgetDataMerge.ordered(selected: selected, fresh: fresh, cached: cached)

        XCTAssertEqual(merged.map(\.lineName), ["U1", "O"])
        XCTAssertEqual(merged.map(\.departures), [[9], [2]])
    }

    func testWidgetMergeDropsCachedRoutesNoLongerSelected() {
        let selected = [WidgetRouteKey(lineName: "O", destination: "Raxstraße")]
        let cached = [
            WidgetDepartureData(lineName: "U1", stopName: "Stephansplatz", destination: "Leopoldau", departures: [9]),
            WidgetDepartureData(lineName: "O", stopName: "Praterstern", destination: "Raxstraße", departures: [8])
        ]

        let merged = WidgetDataMerge.ordered(selected: selected, fresh: [], cached: cached)

        XCTAssertEqual(merged.map(\.lineName), ["O"])
    }
}

private func reminderRequest(
    identifier: String,
    line: String,
    destination: String,
    stop: String,
    delay: TimeInterval
) -> UNNotificationRequest {
    let content = UNMutableNotificationContent()
    content.userInfo = ["line": line, "destination": destination, "stop": stop]
    return UNNotificationRequest(
        identifier: identifier,
        content: content,
        trigger: UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
    )
}

private final class CountingFavoritesRepository: FavoritesRepository, @unchecked Sendable {
    private(set) var getAllCallCount = 0
    private var routes: [FavoriteRoute]

    init(routes: [FavoriteRoute]) { self.routes = routes }

    func isFavorite(diva: String, lineName: String, destination: String) -> Bool {
        routes.contains(FavoriteRoute(diva: diva, lineName: lineName, destination: destination))
    }

    func toggle(diva: String, lineName: String, destination: String) {}

    func getAll() -> [FavoriteRoute] {
        getAllCallCount += 1
        return routes
    }

    func setOrder(_ routes: [FavoriteRoute]) { self.routes = routes }

    func removeAll() { routes = [] }
}

private final class CountingFavoriteStationsRepository: FavoriteStationsStoring, @unchecked Sendable {
    private(set) var allCallCount = 0
    private var stations: [FavoriteStation]

    init(stations: [FavoriteStation] = []) {
        self.stations = stations
    }

    func all() -> [FavoriteStation] {
        allCallCount += 1
        return stations
    }

    func contains(id: Int) -> Bool { stations.contains { $0.id == id } }

    func toggle(_ station: FavoriteStation) {
        if let index = stations.firstIndex(where: { $0.id == station.id }) {
            stations.remove(at: index)
        } else {
            stations.append(station)
        }
    }

    func remove(id: Int) { stations.removeAll { $0.id == id } }
    func setOrder(_ stations: [FavoriteStation]) { self.stations = stations }
    func removeAll() { stations = [] }
}

private struct NoopWidgetSync: WidgetSyncing {
    func save(_ data: [WidgetDepartureData]) {}
}

private final class RecordingWidgetSync: WidgetSyncing, @unchecked Sendable {
    private(set) var clearCallCount = 0
    private(set) var saveCallCount = 0
    private(set) var savedData: [WidgetDepartureData] = []
    func save(_ data: [WidgetDepartureData]) {
        saveCallCount += 1
        savedData = data
    }
    func clear() { clearCallCount += 1 }
}

private final class MemoryKeychain: KeychainStoring {
    private var storage: [String: Data] = [:]
    var removeSucceeds = true
    var setSucceeds = true
    private(set) var removeCallCount = 0
    func data(for key: String) -> Data? { storage[key] }
    func set(_ data: Data, for key: String) -> Bool {
        guard setSucceeds else { return false }
        storage[key] = data
        return true
    }
    func remove(_ key: String) -> Bool {
        removeCallCount += 1
        guard removeSucceeds else { return false }
        storage.removeValue(forKey: key)
        return true
    }
}

@MainActor
private final class MockBiometricAuthenticator: BiometricAuthenticating {
    let kind: BiometricKind
    let canAuthenticate: Bool
    let error: Error?
    private(set) var reasons: [String] = []

    init(kind: BiometricKind, canAuthenticate: Bool? = nil, error: Error? = nil) {
        self.kind = kind
        self.canAuthenticate = canAuthenticate ?? (kind != .unavailable)
        self.error = error
    }

    func authenticate(reason: String) async throws {
        reasons.append(reason)
        if let error { throw error }
    }
}

// MARK: - Mock Network Manager

private final class MockNetworkManager: NetworkManaging, @unchecked Sendable {
    private let lock = NSLock()
    private var recordedCallCount = 0
    private var activeMonitorCalls = 0
    private var recordedMaxConcurrentMonitorCalls = 0
    var shouldFail = false
    var shouldRateLimit = false
    var responseSource: NetworkResponseSource = .network
    var trafficInfos: [TrafficInfo]?
    var monitorDelayNanoseconds: UInt64
    var trafficInfoDelayNanoseconds: UInt64

    var callCount: Int { lock.withLock { recordedCallCount } }
    var maxConcurrentMonitorCalls: Int { lock.withLock { recordedMaxConcurrentMonitorCalls } }

    init(
        shouldFail: Bool = false,
        shouldRateLimit: Bool = false,
        responseSource: NetworkResponseSource = .network,
        trafficInfos: [TrafficInfo]? = nil,
        monitorDelayNanoseconds: UInt64 = 0,
        trafficInfoDelayNanoseconds: UInt64 = 0
    ) {
        self.shouldFail = shouldFail
        self.shouldRateLimit = shouldRateLimit
        self.responseSource = responseSource
        self.trafficInfos = trafficInfos
        self.monitorDelayNanoseconds = monitorDelayNanoseconds
        self.trafficInfoDelayNanoseconds = trafficInfoDelayNanoseconds
    }

    func fetchMonitorData(for stopId: Int) async throws -> MonitorResponse {
        beginMonitorCall()
        defer { endMonitorCall() }
        if monitorDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: monitorDelayNanoseconds)
        }
        if shouldRateLimit { throw MonitorApiError.rateLimited }
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        beginMonitorCall()
        defer { endMonitorCall() }
        if monitorDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: monitorDelayNanoseconds)
        }
        if shouldRateLimit { throw MonitorApiError.rateLimited }
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    func fetchTrafficInfoList() async throws -> MonitorResponse {
        recordCall()
        if trafficInfoDelayNanoseconds > 0 {
            try await Task.sleep(nanoseconds: trafficInfoDelayNanoseconds)
        }
        if shouldRateLimit { throw MonitorApiError.rateLimited }
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    private func beginMonitorCall() {
        lock.withLock {
            recordedCallCount += 1
            activeMonitorCalls += 1
            recordedMaxConcurrentMonitorCalls = max(recordedMaxConcurrentMonitorCalls, activeMonitorCalls)
        }
    }

    private func endMonitorCall() {
        lock.withLock { activeMonitorCalls -= 1 }
    }

    private func recordCall() {
        lock.withLock { recordedCallCount += 1 }
    }

    private func mockResponse() -> MonitorResponse {
        let departure = Departure(departureTime: DepartureTime(countdown: 5, timePlanned: nil, timeReal: nil))
        let departures = Departures(departure: [departure])
        let line = Lines(name: "U1", towards: "Leopoldau", departures: departures)
        let attr = Attributes(rbl: 1234)
        let props = Properties(title: "Test Stop", attributes: attr)
        let stop = LocationStop(properties: props, geometry: nil)
        let monitor = Monitor(locationStop: stop, lines: [line])
        let data = DataBlock(monitors: [monitor], trafficInfos: trafficInfos)
        return MonitorResponse(data: data, source: responseSource)
    }
}
