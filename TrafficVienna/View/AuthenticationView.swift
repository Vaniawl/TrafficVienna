import AuthenticationServices
import SwiftUI

enum AuthFormValidation {
    static func passwordsMatch(_ password: String, confirmation: String) -> Bool {
        !confirmation.isEmpty && password == confirmation
    }

    static func canSubmit(
        email: String,
        password: String,
        confirmation: String,
        requiresConfirmation: Bool
    ) -> Bool {
        guard AuthStore.normalizedValidEmail(email) != nil,
              AuthStore.isValidPassword(password) else { return false }
        return !requiresConfirmation || passwordsMatch(password, confirmation: confirmation)
    }
}

struct AuthenticationView: View {
    @EnvironmentObject private var auth: AuthStore
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var mode: Mode = .register
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
    @State private var isSubmitting = false
    @State private var isPasswordVisible = false
    @FocusState private var focusedField: Field?

    private enum Field {
        case email
        case password
        case passwordConfirmation
    }

    private enum Mode: CaseIterable {
        case register
        case signIn

        var title: LocalizedStringKey {
            switch self {
            case .register: "Create account"
            case .signIn: "Sign in"
            }
        }
    }

    var body: some View {
        ZStack {
            NeoDesign.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    hero
                    authCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 24)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "tram.fill")
                    .font(.system(size: 24, weight: .semibold))
                    .frame(width: 52, height: 52)
                    .background(.white.opacity(0.18), in: Circle())
                Spacer()
                Text("VIENNA LIVE")
                    .font(.footnote.bold())
                    .tracking(1.4)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Traffic Vienna")
                    .font(.largeTitle.bold())
                    .tracking(-0.6)
                Text("Your city, moving with you")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.82))
            }
        }
        .foregroundStyle(.white)
        .padding(24)
        .frame(maxWidth: .infinity, minHeight: 190, alignment: .leading)
        .background(NeoDesign.heroGradient, in: RoundedRectangle(cornerRadius: 26))
        .shadow(color: NeoDesign.accentDark.opacity(0.14), radius: 16, y: 8)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var authCard: some View {
        VStack(spacing: 18) {
            modeSwitcher

            VStack(spacing: 12) {
                Label {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .submitLabel(.next)
                        .focused($focusedField, equals: .email)
                        .onSubmit { focusedField = .password }
                        .accessibilityIdentifier("auth.email")
                } icon: { Image(systemName: "envelope") }
                .padding(14)
                .background(NeoDesign.subtleSurface, in: RoundedRectangle(cornerRadius: 14))

                Label {
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(mode == .register ? .next : .go)
                                    .onSubmit(submitPassword)
                            } else {
                                SecureField("Password", text: $password)
                                    .focused($focusedField, equals: .password)
                                    .submitLabel(mode == .register ? .next : .go)
                                    .onSubmit(submitPassword)
                            }
                        }
                        .textContentType(isUITesting ? nil : (mode == .register ? .newPassword : .password))
                        .accessibilityIdentifier("auth.password")

                        Button {
                            isPasswordVisible.toggle()
                            focusedField = .password
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                        .accessibilityHint("Changes whether the password is visible on screen")

                    }
                } icon: { Image(systemName: "lock") }
                .padding(14)
                .background(NeoDesign.subtleSurface, in: RoundedRectangle(cornerRadius: 14))

                if mode == .register {
                    Label {
                        HStack {
                            Group {
                                if isPasswordVisible || isUITesting {
                                    TextField("Confirm password", text: $passwordConfirmation)
                                        .textContentType(isUITesting ? nil : .newPassword)
                                        .focused($focusedField, equals: .passwordConfirmation)
                                        .submitLabel(.go)
                                        .onSubmit(submitFromKeyboard)
                                        .accessibilityIdentifier("auth.passwordConfirmation")
                                } else {
                                    SecureField("Confirm password", text: $passwordConfirmation)
                                        .textContentType(isUITesting ? nil : .newPassword)
                                        .focused($focusedField, equals: .passwordConfirmation)
                                        .submitLabel(.go)
                                        .onSubmit(submitFromKeyboard)
                                        .accessibilityIdentifier("auth.passwordConfirmation")
                                }
                            }
                        }
                    } icon: { Image(systemName: "lock.badge.checkmark") }
                    .padding(14)
                    .background(NeoDesign.subtleSurface, in: RoundedRectangle(cornerRadius: 14))
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                validationRequirement(
                    "Valid email address",
                    isSatisfied: isEmailValid,
                    identifier: "auth.email.validation"
                )
                validationRequirement(
                    "At least 8 characters",
                    isSatisfied: isPasswordValid,
                    identifier: "auth.password.validation"
                )
                if mode == .register {
                    validationRequirement(
                        "Passwords match",
                        isSatisfied: passwordsMatch,
                        identifier: "auth.passwordConfirmation.validation"
                    )
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let error = auth.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("auth.error")
            }

            Button(action: submitEmail) {
                Group {
                    if isSubmitting {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text(mode.title)
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(minHeight: 52)
            }
            .foregroundStyle(NeoDesign.primaryActionText)
            .background(NeoDesign.primaryAction, in: Capsule())
            .buttonStyle(.plain)
            .disabled(!canSubmitEmail)
            .opacity(canSubmitEmail ? 1 : 0.42)
            .accessibilityIdentifier("auth.submit")

            HStack { Divider(); Text("or").font(.footnote).foregroundStyle(.secondary); Divider() }

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                auth.handleAppleAuthorization(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 52)
            .clipShape(Capsule())
            .disabled(isSubmitting)
            .accessibilityHint("Uses your Apple ID to create or open your account")

            Text("Email accounts are stored securely on this device. Apple ID uses Apple's private authentication flow.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .onChange(of: email) { _, _ in auth.clearError() }
        .onChange(of: password) { _, _ in auth.clearError() }
        .onChange(of: passwordConfirmation) { _, _ in auth.clearError() }
        .onChange(of: mode) { _, _ in
            auth.clearError()
            passwordConfirmation = ""
        }
        .padding(20)
        .background(NeoDesign.surface, in: RoundedRectangle(cornerRadius: 24))
        .overlay { RoundedRectangle(cornerRadius: 24).stroke(NeoDesign.hairline, lineWidth: 1) }
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var modeSwitcher: some View {
        HStack(spacing: 4) {
            ForEach(Mode.allCases, id: \.self) { candidate in
                Button {
                    withAnimation(reduceMotion ? nil : .snappy(duration: 0.28)) {
                        mode = candidate
                    }
                } label: {
                    Text(candidate.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(mode == candidate ? Color.primary : Color.secondary)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
                        .background(
                            mode == candidate ? NeoDesign.surface : Color.clear,
                            in: Capsule()
                        )
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(mode == candidate ? .isSelected : [])
            }
        }
        .padding(4)
        .background(NeoDesign.subtleSurface, in: Capsule())
        .disabled(isSubmitting)
        .opacity(isSubmitting ? 0.62 : 1)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Authentication mode")
    }

    private var isUITesting: Bool {
#if DEBUG
        ProcessInfo.processInfo.arguments.contains("-ui-testing-reset")
#else
        false
#endif
    }

    private var isEmailValid: Bool {
        AuthStore.normalizedValidEmail(email) != nil
    }

    private var isPasswordValid: Bool {
        AuthStore.isValidPassword(password)
    }

    private var canSubmitEmail: Bool {
        !isSubmitting && AuthFormValidation.canSubmit(
            email: email,
            password: password,
            confirmation: passwordConfirmation,
            requiresConfirmation: mode == .register
        )
    }

    private var passwordsMatch: Bool {
        AuthFormValidation.passwordsMatch(password, confirmation: passwordConfirmation)
    }

    private func validationRequirement(
        _ title: LocalizedStringKey,
        isSatisfied: Bool,
        identifier: String
    ) -> some View {
        Label(title, systemImage: isSatisfied ? "checkmark.circle.fill" : "circle")
            .font(.footnote)
            .foregroundStyle(isSatisfied ? NeoDesign.accent : Color.secondary)
            .accessibilityIdentifier(identifier)
            .accessibilityValue(isSatisfied ? String(localized: "Satisfied") : String(localized: "Not satisfied"))
    }

    private func submitEmail() {
        guard canSubmitEmail else { return }
        focusedField = nil
        let submittedEmail = email
        let submittedPassword = password
        let submittedMode = mode
        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                if submittedMode == .register {
                    try await auth.register(email: submittedEmail, password: submittedPassword)
                } else {
                    try await auth.signIn(email: submittedEmail, password: submittedPassword)
                }
            } catch {
                auth.errorMessage = error.localizedDescription
            }
        }
    }

    private func submitFromKeyboard() {
        guard canSubmitEmail else { return }
        submitEmail()
    }

    private func submitPassword() {
        if mode == .register {
            focusedField = .passwordConfirmation
        } else {
            submitFromKeyboard()
        }
    }
}

#Preview {
    AuthenticationView().environmentObject(AuthStore())
}
