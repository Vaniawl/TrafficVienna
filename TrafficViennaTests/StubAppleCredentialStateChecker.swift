import AuthenticationServices
@testable import TrafficVienna

struct StubAppleCredentialStateChecker: AppleCredentialStateChecking {
    let state: ASAuthorizationAppleIDProvider.CredentialState

    func credentialState(
        for userID: String
    ) async throws -> ASAuthorizationAppleIDProvider.CredentialState {
        state
    }
}
