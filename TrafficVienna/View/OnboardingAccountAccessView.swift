import AuthenticationServices
import SwiftUI

struct OnboardingAccountAccessView: View {
    @Environment(AccountSession.self) private var accountSession
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        @Bindable var accountSession = accountSession

        Group {
            if let profile = accountSession.profile {
                signedInView(profile)
            } else {
                SignInWithAppleButton(.continue) { request in
                    request.requestedScopes = [.fullName, .email]
                } onCompletion: { result in
                    accountSession.handleAppleAuthorization(result)
                }
                .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
                .frame(minHeight: 52)
                .clipShape(.rect(cornerRadius: CornerRadius.sm))
                .accessibilityLabel("Continue with Apple")
                .accessibilityInputLabels(["Continue with Apple", "Apple"])
            }
        }
        .alert("Account error", isPresented: $accountSession.isShowingError) {
            Button("OK", action: accountSession.dismissError)
        } message: {
            Text(accountSession.errorMessage ?? "Please try again.")
        }
    }

    private func signedInView(_ profile: AccountProfile) -> some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: "checkmark.circle.fill")
                .font(.title2)
                .foregroundStyle(.green)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Signed in with Apple")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Text(profile.preferredName)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(DesignColor.cardBackground, in: .rect(cornerRadius: CornerRadius.md))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    OnboardingAccountAccessView()
        .environment(AccountSession())
        .padding()
}
