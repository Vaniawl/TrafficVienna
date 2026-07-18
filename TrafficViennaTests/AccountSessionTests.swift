import AuthenticationServices
import XCTest
@testable import TrafficVienna

@MainActor
final class AccountSessionTests: XCTestCase {
    func testRestoresStoredAppleProfile() {
        let profile = AccountProfile(
            id: "apple-user-id",
            displayName: "Anna Example",
            email: "anna@example.com",
            provider: .apple
        )
        let session = AccountSession(store: InMemoryAccountProfileStore(profile: profile))

        XCTAssertEqual(session.profile, profile)
        XCTAssertFalse(session.isShowingError)
    }

    func testSignOutDeletesStoredProfile() {
        let profile = AccountProfile(
            id: "apple-user-id",
            displayName: nil,
            email: "anna@example.com",
            provider: .apple
        )
        let store = InMemoryAccountProfileStore(profile: profile)
        let session = AccountSession(store: store)

        session.signOut()

        XCTAssertNil(session.profile)
        XCTAssertNil(store.storedProfile)
    }

    func testStorageFailureIsVisibleToUser() {
        let store = InMemoryAccountProfileStore()
        store.shouldThrow = true

        let session = AccountSession(store: store)

        XCTAssertNil(session.profile)
        XCTAssertTrue(session.isShowingError)
        XCTAssertNotNil(session.errorMessage)
    }

    func testSignOutClearsInMemoryProfileWhenSecureDeletionFails() {
        let profile = AccountProfile(
            id: "apple-user-id",
            displayName: "Anna Example",
            email: nil,
            provider: .apple
        )
        let store = InMemoryAccountProfileStore(profile: profile)
        let session = AccountSession(store: store)
        store.shouldThrow = true

        session.signOut()

        XCTAssertNil(session.profile)
        XCTAssertTrue(session.isShowingError)
        XCTAssertNotNil(session.errorMessage)
    }

    func testPreferredNameFallsBackToEmail() {
        let profile = AccountProfile(
            id: "apple-user-id",
            displayName: nil,
            email: "anna@example.com",
            provider: .apple
        )

        XCTAssertEqual(profile.preferredName, "anna@example.com")
    }

    func testAuthorizedAppleCredentialKeepsSession() async {
        let profile = AccountProfile(
            id: "apple-user-id",
            displayName: "Anna Example",
            email: nil,
            provider: .apple
        )
        let session = AccountSession(
            store: InMemoryAccountProfileStore(profile: profile),
            credentialStateChecker: StubAppleCredentialStateChecker(state: .authorized)
        )

        await session.validateCredential()

        XCTAssertEqual(session.profile, profile)
    }

    func testRevokedAppleCredentialClearsSession() async {
        let store = InMemoryAccountProfileStore(profile: appleProfile)
        let session = AccountSession(
            store: store,
            credentialStateChecker: StubAppleCredentialStateChecker(state: .revoked)
        )

        await session.validateCredential()

        XCTAssertNil(session.profile)
        XCTAssertNil(store.storedProfile)
    }

    func testTransferredAppleCredentialClearsSession() async {
        let store = InMemoryAccountProfileStore(profile: appleProfile)
        let session = AccountSession(
            store: store,
            credentialStateChecker: StubAppleCredentialStateChecker(state: .transferred)
        )

        await session.validateCredential()

        XCTAssertNil(session.profile)
        XCTAssertNil(store.storedProfile)
    }

    func testAppleCredentialRevocationNotificationClearsSession() {
        let store = InMemoryAccountProfileStore(profile: appleProfile)
        let session = AccountSession(store: store)

        session.handleAppleCredentialRevoked()

        XCTAssertNil(session.profile)
        XCTAssertNil(store.storedProfile)
    }

    private var appleProfile: AccountProfile {
        AccountProfile(
            id: "apple-user-id",
            displayName: "Anna Example",
            email: nil,
            provider: .apple
        )
    }
}
