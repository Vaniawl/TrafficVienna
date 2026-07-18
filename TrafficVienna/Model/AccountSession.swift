import AuthenticationServices
import Foundation
import Observation

@MainActor
@Observable
final class AccountSession {
    private(set) var profile: AccountProfile?
    private(set) var isCheckingCredential = false
    var errorMessage: String?
    var isShowingError = false

    private let store: AccountProfileStoring
    private let credentialStateChecker: AppleCredentialStateChecking

    init(
        store: AccountProfileStoring = KeychainAccountProfileStore(),
        credentialStateChecker: AppleCredentialStateChecking = AppleCredentialStateProvider()
    ) {
        self.store = store
        self.credentialStateChecker = credentialStateChecker
        restore()
    }

    func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = String(localized: "Apple sign-in returned an invalid credential.")
                isShowingError = true
                return
            }

            let profile = AccountProfile(
                id: credential.user,
                displayName: credential.fullName?.formatted(),
                email: credential.email,
                provider: .apple
            )
            persist(profile)

        case .failure(let error as ASAuthorizationError) where error.code == .canceled:
            errorMessage = nil

        case .failure:
            errorMessage = String(localized: "Apple sign-in could not be completed. Please try again.")
            isShowingError = true
        }
    }

    func validateCredential() async {
        guard let profile, profile.provider == .apple else { return }

        isCheckingCredential = true
        defer { isCheckingCredential = false }

        do {
            let state = try await credentialStateChecker.credentialState(for: profile.id)
            switch state {
            case .authorized:
                break
            case .revoked, .notFound, .transferred:
                signOut()
            @unknown default:
                signOut()
            }
        } catch {
            errorMessage = String(localized: "Your Apple account status could not be checked.")
            isShowingError = true
        }
    }

    func handleAppleCredentialRevoked() {
        guard profile?.provider == .apple else { return }
        signOut()
    }

    func signOut() {
        profile = nil

        do {
            try store.delete()
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    func dismissError() {
        isShowingError = false
    }

    private func restore() {
        do {
            profile = try store.load()
        } catch {
            profile = nil
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }

    private func persist(_ profile: AccountProfile) {
        do {
            try store.save(profile)
            self.profile = profile
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
            isShowingError = true
        }
    }
}
