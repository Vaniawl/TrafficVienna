import AuthenticationServices
import Combine
import CommonCrypto
import CryptoKit
import Foundation
import Security

enum AuthProvider: String, Codable {
    case email
    case apple
}

struct AuthSession: Codable, Equatable {
    let userID: String
    let email: String?
    let displayName: String?
    let provider: AuthProvider
}

enum AuthError: LocalizedError, Equatable {
    case invalidEmail
    case weakPassword
    case accountExists
    case invalidCredentials
    case tooManyAttempts
    case incorrectCurrentPassword
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return String(localized: "Enter a valid email address.")
        case .weakPassword: return String(localized: "Use at least 8 characters for your password.")
        case .accountExists: return String(localized: "An account with this email already exists.")
        case .invalidCredentials: return String(localized: "Email or password is incorrect.")
        case .tooManyAttempts: return String(localized: "Too many sign-in attempts. Try again in 30 seconds.")
        case .incorrectCurrentPassword: return String(localized: "Current password is incorrect.")
        case .unavailable: return String(localized: "Sign in is unavailable right now. Please try again.")
        }
    }
}

nonisolated struct EmailSignInLimiter {
    private struct FailureState {
        var count = 0
        var blockedUntil: Date?
        var lastAttempt = Date.distantPast
    }

    private let maximumFailures: Int
    private let cooldown: TimeInterval
    private let maximumTrackedEmails: Int
    private let now: () -> Date
    private var failures: [String: FailureState] = [:]

    init(
        maximumFailures: Int = 5,
        cooldown: TimeInterval = 30,
        maximumTrackedEmails: Int = 32,
        now: @escaping () -> Date = Date.init
    ) {
        precondition(maximumFailures > 0)
        precondition(cooldown > 0)
        precondition(maximumTrackedEmails > 0)
        self.maximumFailures = maximumFailures
        self.cooldown = cooldown
        self.maximumTrackedEmails = maximumTrackedEmails
        self.now = now
    }

    mutating func checkAllowed(for email: String) throws {
        guard let state = failures[email], let blockedUntil = state.blockedUntil else { return }
        guard now() >= blockedUntil else { throw AuthError.tooManyAttempts }
        failures[email] = nil
    }

    mutating func recordFailure(for email: String) -> Bool {
        var state = failures[email] ?? FailureState()
        state.count += 1
        state.lastAttempt = now()
        if state.count >= maximumFailures {
            state.count = 0
            state.blockedUntil = state.lastAttempt.addingTimeInterval(cooldown)
            failures[email] = state
            evictOldestIfNeeded()
            return true
        }
        failures[email] = state
        evictOldestIfNeeded()
        return false
    }

    mutating func reset(for email: String) {
        failures[email] = nil
    }

    private mutating func evictOldestIfNeeded() {
        while failures.count > maximumTrackedEmails,
              let oldest = failures.min(by: { $0.value.lastAttempt < $1.value.lastAttempt })?.key {
            failures[oldest] = nil
        }
    }
}

nonisolated struct PasswordDeriver: Sendable {
    private let operation: @Sendable (String, Data, UInt32) async -> Data

    init(
        operation: @escaping @Sendable (String, Data, UInt32) async -> Data = { password, salt, iterations in
            await Task.detached(priority: .userInitiated) {
                Self.deriveSynchronously(password: password, salt: salt, iterations: iterations)
            }.value
        }
    ) {
        self.operation = operation
    }

    func derive(password: String, salt: Data, iterations: UInt32) async -> Data {
        await operation(password, salt, iterations)
    }

    private nonisolated static func deriveSynchronously(
        password: String,
        salt: Data,
        iterations: UInt32
    ) -> Data {
        var derived = Data(count: 32)
        let derivedCount = derived.count
        let status = derived.withUnsafeMutableBytes { derivedBytes in
            salt.withUnsafeBytes { saltBytes in
                CCKeyDerivationPBKDF(
                    CCPBKDFAlgorithm(kCCPBKDF2),
                    password,
                    password.lengthOfBytes(using: .utf8),
                    saltBytes.bindMemory(to: UInt8.self).baseAddress,
                    salt.count,
                    CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256),
                    iterations,
                    derivedBytes.bindMemory(to: UInt8.self).baseAddress,
                    derivedCount
                )
            }
        }
        return status == kCCSuccess ? derived : Data()
    }
}

@MainActor
final class AuthStore: ObservableObject {
    @Published private(set) var session: AuthSession?
    @Published var errorMessage: String?

    private let keychain: KeychainStoring
    private let defaults: UserDefaults
    private let sessionKey = "auth.session"
    private let passwordIterations: UInt32 = 120_000
    private let passwordDeriver: PasswordDeriver
    private var signInLimiter: EmailSignInLimiter
    private var isCredentialOperationInProgress = false

    init(
        keychain: KeychainStoring? = nil,
        defaults: UserDefaults = .standard,
        resetSession: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing-reset"),
        signInLimiter: EmailSignInLimiter = EmailSignInLimiter(),
        passwordDeriver: PasswordDeriver = PasswordDeriver()
    ) {
        self.keychain = keychain ?? Self.defaultKeychain()
        self.defaults = defaults
        self.signInLimiter = signInLimiter
        self.passwordDeriver = passwordDeriver
        if resetSession {
            defaults.removeObject(forKey: sessionKey)
        } else if let data = defaults.data(forKey: sessionKey) {
            session = try? JSONDecoder().decode(AuthSession.self, from: data)
        }
    }

    private static func defaultKeychain() -> KeychainStoring {
#if DEBUG
        if ProcessInfo.processInfo.arguments.contains("-ui-testing-reset") {
            return UITestKeychainStore()
        }
#endif
        return KeychainStore()
    }

    func register(email: String, password: String) async throws {
        let normalizedEmail = try validated(email: email, password: password)
        try beginCredentialOperation()
        defer { isCredentialOperationInProgress = false }
        let accountKey = emailAccountKey(for: normalizedEmail)
        guard keychain.data(for: accountKey) == nil else { throw AuthError.accountExists }

        let salt = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        let record = EmailAccount(
            email: normalizedEmail,
            salt: salt,
            passwordHash: try await derivePasswordKey(password, salt: salt, iterations: passwordIterations),
            algorithm: "pbkdf2-sha256",
            iterations: passwordIterations
        )
        guard keychain.data(for: accountKey) == nil else { throw AuthError.accountExists }
        guard let encoded = try? JSONEncoder().encode(record), keychain.set(encoded, for: accountKey) else {
            throw AuthError.unavailable
        }
        signInLimiter.reset(for: normalizedEmail)
        setSession(AuthSession(userID: normalizedEmail, email: normalizedEmail, displayName: nil, provider: .email))
    }

    func signIn(email: String, password: String) async throws {
        let normalizedEmail = try validated(email: email, password: password)
        try signInLimiter.checkAllowed(for: normalizedEmail)
        try beginCredentialOperation()
        defer { isCredentialOperationInProgress = false }
        let accountKey = emailAccountKey(for: normalizedEmail)
        guard
            let data = keychain.data(for: accountKey),
            let record = try? JSONDecoder().decode(EmailAccount.self, from: data),
            record.email == normalizedEmail
        else {
            throw failedSignIn(for: normalizedEmail)
        }

        let candidate: Data
        if record.algorithm == "pbkdf2-sha256", let iterations = record.iterations {
            candidate = try await derivePasswordKey(password, salt: record.salt, iterations: iterations)
        } else {
            candidate = legacyHash(password, salt: record.salt)
        }
        guard timingSafeEqual(candidate, record.passwordHash) else {
            throw failedSignIn(for: normalizedEmail)
        }

        if record.algorithm == nil {
            if let passwordHash = try? await derivePasswordKey(
                password,
                salt: record.salt,
                iterations: passwordIterations
            ) {
                let upgraded = EmailAccount(
                    email: normalizedEmail,
                    salt: record.salt,
                    passwordHash: passwordHash,
                    algorithm: "pbkdf2-sha256",
                    iterations: passwordIterations
                )
                if let data = try? JSONEncoder().encode(upgraded) { _ = keychain.set(data, for: accountKey) }
            }
        }

        signInLimiter.reset(for: normalizedEmail)
        setSession(AuthSession(userID: normalizedEmail, email: normalizedEmail, displayName: nil, provider: .email))
    }

    func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
        guard !isCredentialOperationInProgress else {
            errorMessage = AuthError.unavailable.localizedDescription
            return
        }
        switch result {
        case .success(let authorization):
            guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
                errorMessage = AuthError.unavailable.localizedDescription
                return
            }
            let name = PersonNameComponentsFormatter().string(from: credential.fullName ?? .init())
            setSession(AuthSession(
                userID: credential.user,
                email: credential.email,
                displayName: name.isEmpty ? nil : name,
                provider: .apple
            ))
        case .failure(let error):
            if (error as? ASAuthorizationError)?.code != .canceled {
                errorMessage = error.localizedDescription
            }
        }
    }

    func signOut() {
        session = nil
        defaults.removeObject(forKey: sessionKey)
        errorMessage = nil
    }

    func clearError() {
        errorMessage = nil
    }

    func updateDisplayName(_ value: String) {
        guard let session else { return }
        setSession(AuthSession(
            userID: session.userID,
            email: session.email,
            displayName: Self.normalizedDisplayName(value),
            provider: session.provider
        ))
    }

    func changePassword(currentPassword: String, newPassword: String) async throws {
        guard let session, session.provider == .email else { throw AuthError.unavailable }
        guard Self.isValidPassword(newPassword) else { throw AuthError.weakPassword }
        try beginCredentialOperation()
        defer { isCredentialOperationInProgress = false }

        let accountKey = emailAccountKey(for: session.userID)
        guard
            let data = keychain.data(for: accountKey),
            let record = try? JSONDecoder().decode(EmailAccount.self, from: data),
            try await password(currentPassword, matches: record)
        else { throw AuthError.incorrectCurrentPassword }

        let salt = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        let updated = EmailAccount(
            email: record.email,
            salt: salt,
            passwordHash: try await derivePasswordKey(
                newPassword,
                salt: salt,
                iterations: passwordIterations
            ),
            algorithm: "pbkdf2-sha256",
            iterations: passwordIterations
        )
        guard let encoded = try? JSONEncoder().encode(updated), keychain.set(encoded, for: accountKey) else {
            throw AuthError.unavailable
        }
        errorMessage = nil
    }

    func removeCurrentAccountFromDevice() throws {
        guard let session else { return }
        if session.provider == .email {
            guard keychain.remove(emailAccountKey(for: session.userID)) else {
                throw AuthError.unavailable
            }
        }
        signOut()
    }

    func validateStoredAppleCredential() async {
        guard let session, session.provider == .apple else { return }
        let state = (try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: session.userID)) ?? .notFound
        if state == .revoked || state == .notFound {
            signOut()
        }
    }

    nonisolated static func normalizedValidEmail(_ value: String) -> String? {
        let email = value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil else {
            return nil
        }
        return email
    }

    nonisolated static func isValidPassword(_ value: String) -> Bool {
        value.count >= 8
    }

    nonisolated static func normalizedDisplayName(_ value: String) -> String? {
        let normalized = value
            .split(whereSeparator: { $0.isWhitespace })
            .joined(separator: " ")
        guard !normalized.isEmpty else { return nil }
        return String(normalized.prefix(40))
    }

    private func validated(email: String, password: String) throws -> String {
        guard let email = Self.normalizedValidEmail(email) else { throw AuthError.invalidEmail }
        guard Self.isValidPassword(password) else { throw AuthError.weakPassword }
        return email
    }

    private func legacyHash(_ password: String, salt: Data) -> Data {
        Data(SHA256.hash(data: salt + Data(password.utf8)))
    }

    private func timingSafeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }

    private func derivePasswordKey(_ password: String, salt: Data, iterations: UInt32) async throws -> Data {
        try Task.checkCancellation()
        let derived = await passwordDeriver.derive(password: password, salt: salt, iterations: iterations)
        try Task.checkCancellation()
        guard derived.count == 32 else { throw AuthError.unavailable }
        return derived
    }

    private func password(_ password: String, matches record: EmailAccount) async throws -> Bool {
        let candidate: Data
        if record.algorithm == "pbkdf2-sha256", let iterations = record.iterations {
            candidate = try await derivePasswordKey(password, salt: record.salt, iterations: iterations)
        } else {
            candidate = legacyHash(password, salt: record.salt)
        }
        return timingSafeEqual(candidate, record.passwordHash)
    }

    private func emailAccountKey(for email: String) -> String {
        "auth.email.\(SHA256.hash(data: Data(email.utf8)).map { String(format: "%02x", $0) }.joined())"
    }

    private func failedSignIn(for email: String) -> AuthError {
        signInLimiter.recordFailure(for: email) ? .tooManyAttempts : .invalidCredentials
    }

    private func beginCredentialOperation() throws {
        guard !isCredentialOperationInProgress else { throw AuthError.unavailable }
        isCredentialOperationInProgress = true
    }

    private func setSession(_ value: AuthSession) {
        session = value
        errorMessage = nil
        if let data = try? JSONEncoder().encode(value) {
            defaults.set(data, forKey: sessionKey)
        }
    }
}

#if DEBUG
private final class UITestKeychainStore: KeychainStoring {
    private var storage: [String: Data] = [:]

    func data(for key: String) -> Data? { storage[key] }

    func set(_ data: Data, for key: String) -> Bool {
        storage[key] = data
        return true
    }

    func remove(_ key: String) -> Bool {
        storage.removeValue(forKey: key)
        return true
    }
}
#endif

private struct EmailAccount: Codable {
    let email: String
    let salt: Data
    let passwordHash: Data
    let algorithm: String?
    let iterations: UInt32?

    init(email: String, salt: Data, passwordHash: Data, algorithm: String? = nil, iterations: UInt32? = nil) {
        self.email = email
        self.salt = salt
        self.passwordHash = passwordHash
        self.algorithm = algorithm
        self.iterations = iterations
    }
}

protocol KeychainStoring {
    func data(for key: String) -> Data?
    @discardableResult func set(_ data: Data, for key: String) -> Bool
    @discardableResult func remove(_ key: String) -> Bool
}

struct KeychainStore: KeychainStoring {
    private let service = Bundle.main.bundleIdentifier ?? "wellbe.TrafficVienna"

    func data(for key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess else { return nil }
        return result as? Data
    }

    func set(_ data: Data, for key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        SecItemDelete(query as CFDictionary)
        var value = query
        value[kSecValueData as String] = data
        value[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        return SecItemAdd(value as CFDictionary, nil) == errSecSuccess
    }

    func remove(_ key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
