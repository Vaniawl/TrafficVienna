import AuthenticationServices
import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var auth: AuthStore
    @State private var mode: Mode = .register
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false

    private enum Mode: String, CaseIterable {
        case register = "Create account"
        case signIn = "Sign in"
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
    }

    private var authCard: some View {
        VStack(spacing: 18) {
            Picker("Authentication mode", selection: $mode) {
                ForEach(Mode.allCases, id: \.self) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            VStack(spacing: 12) {
                Label {
                    TextField("Email", text: $email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                } icon: { Image(systemName: "envelope") }
                .padding(14)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                Label {
                    HStack {
                        Group {
                            if isPasswordVisible {
                                TextField("Password", text: $password)
                            } else {
                                SecureField("Password", text: $password)
                            }
                        }
                        .textContentType(mode == .register ? .newPassword : .password)

                        Button { isPasswordVisible.toggle() } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundStyle(.secondary)
                        }
                    }
                } icon: { Image(systemName: "lock") }
                .padding(14)
                .background(.quaternary, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if let error = auth.errorMessage {
                Text(error)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Button(action: submitEmail) {
                Text(mode.rawValue)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0xE20917))

            HStack { Divider(); Text("or").font(.footnote).foregroundStyle(.secondary); Divider() }

            SignInWithAppleButton(.continue) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                auth.handleAppleAuthorization(result)
            }
            .signInWithAppleButtonStyle(.black)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text("Email accounts are stored securely on this device. Apple ID uses Apple's private authentication flow.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(20)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay { RoundedRectangle(cornerRadius: 28, style: .continuous).stroke(.white.opacity(0.4)) }
        .shadow(color: .black.opacity(0.08), radius: 24, y: 12)
    }

    private func submitEmail() {
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
}

#Preview {
    AuthenticationView().environmentObject(AuthStore())
}
