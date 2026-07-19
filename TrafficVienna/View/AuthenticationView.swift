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
    @State private var mode: Mode = .register
    @State private var email = ""
    @State private var password = ""
    @State private var passwordConfirmation = ""
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
            LinearGradient(
                colors: [Color(hex: 0xE20917).opacity(0.18), Color(.systemBackground), Color.indigo.opacity(0.12)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    hero
                    authCard
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 40)
            }
            .scrollDismissesKeyboard(.interactively)
        }
    }

    private var hero: some View {
        VStack(spacing: 14) {
            Image(systemName: "tram.fill")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 76, height: 76)
                .background(Color(hex: 0xE20917).gradient, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
                .shadow(color: Color(hex: 0xE20917).opacity(0.25), radius: 24, y: 12)
            Text("Traffic Vienna")
                .font(.largeTitle.bold())
            Text("Your city, moving with you")
                .font(.title3)
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(.center)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
    }

    private var authCard: some View {
        VStack(spacing: 18) {
            Picker("Authentication mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)

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
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

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
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

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
                    .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
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
                Text(mode.title)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0xE20917))
            .disabled(!canSubmitEmail)
            .accessibilityIdentifier("auth.submit")

            HStack { Divider(); Text("or").font(.footnote).foregroundStyle(.secondary); Divider() }

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                auth.handleAppleAuthorization(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
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
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.4)) }
        .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
        .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
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
        AuthFormValidation.canSubmit(
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
            .foregroundStyle(isSatisfied ? .green : .secondary)
            .accessibilityIdentifier(identifier)
            .accessibilityValue(isSatisfied ? String(localized: "Satisfied") : String(localized: "Not satisfied"))
    }

    private func submitEmail() {
        guard canSubmitEmail else { return }
        focusedField = nil
        do {
            if mode == .register {
                try auth.register(email: email, password: password)
            } else {
                try auth.signIn(email: email, password: password)
            }
        } catch {
            auth.errorMessage = error.localizedDescription
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
