import AuthenticationServices
import SwiftUI

struct AccountView: View {
    @Environment(AccountSession.self) private var accountSession
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dismiss) private var dismiss
    @State private var showAbout = false
    @State private var showSignOutConfirmation = false

    var body: some View {
        @Bindable var accountSession = accountSession

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Spacing.xl) {
                    accountHeader

                    if let profile = accountSession.profile {
                        signedInContent(profile)
                    } else {
                        signedOutContent
                    }

                    privacyNote
                }
                .padding(Spacing.xl)
            }
            .background(DesignColor.background)
            .navigationTitle("Account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close", systemImage: "xmark", action: dismiss.callAsFunction)
                        .labelStyle(.iconOnly)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("About", systemImage: "info.circle") {
                        showAbout = true
                    }
                    .labelStyle(.iconOnly)
                }
            }
            .sheet(isPresented: $showAbout) {
                AboutView()
            }
            .alert("Account error", isPresented: $accountSession.isShowingError) {
                Button("OK", action: accountSession.dismissError)
            } message: {
                Text(accountSession.errorMessage ?? "Please try again.")
            }
        }
    }

    private var accountHeader: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: "person.crop.circle.fill")
                .font(.largeTitle.scaled(by: 1.7))
                .foregroundStyle(.appAccent)
                .accessibilityHidden(true)

            Text(accountSession.profile == nil ? "Your Traffic Vienna" : "Welcome back")
                .font(.largeTitle)
                .bold()

            Text("Keep transport essentials fast and private. Signing in is always optional.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
    }

    private func signedInContent(_ profile: AccountProfile) -> some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Label("Signed in with Apple", systemImage: "apple.logo")
                    .font(.headline)

                Text(profile.preferredName)
                    .font(.title2)
                    .bold()

                if let email = profile.email, email != profile.preferredName {
                    Text(email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Spacing.lg)
            .background(DesignColor.cardBackground, in: .rect(cornerRadius: CornerRadius.lg))

            Button("Sign out", role: .destructive) {
                showSignOutConfirmation = true
            }
            .frame(minHeight: 44)
            .confirmationDialog(
                "Sign out of Traffic Vienna?",
                isPresented: $showSignOutConfirmation,
                titleVisibility: .visible
            ) {
                Button("Sign out", role: .destructive, action: accountSession.signOut)
                Button("Cancel", role: .cancel) {}
            }
        }
    }

    private var signedOutContent: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                accountSession.handleAppleAuthorization(result)
            }
            .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
            .frame(minHeight: 52)
            .clipShape(.rect(cornerRadius: CornerRadius.sm))
            .accessibilityLabel("Continue with Apple")

            Text("Apple provides a verified identity. Traffic information and local favourites still work without an account.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var privacyNote: some View {
        Label {
            Text("Your Apple profile is stored only in this device’s Keychain. No identity token is saved or logged.")
        } icon: {
            Image(systemName: "lock.shield.fill")
                .foregroundStyle(.appAccent)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(Spacing.md)
        .background(DesignColor.cardBackground, in: .rect(cornerRadius: CornerRadius.md))
    }
}

#Preview {
    AccountView()
        .environment(AccountSession())
}
