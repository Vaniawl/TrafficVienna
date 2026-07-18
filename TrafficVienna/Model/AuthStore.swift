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
    case unavailable

    var errorDescription: String? {
        switch self {
        case .invalidEmail: return "Enter a valid email address."
        case .weakPassword: return "Use at least 8 characters for your password."
        case .accountExists: return "An account with this email already exists."
        case .invalidCredentials: return "Email or password is incorrect."
        case .unavailable: return "Sign in is unavailable right now. Please try again."
        }
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

    init(
        keychain: KeychainStoring? = nil,
        defaults: UserDefaults = .standard,
        resetSession: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing-reset")
    ) {
        self.keychain = keychain ?? Self.defaultKeychain()
        self.defaults = defaults
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

    func register(email: String, password: String) throws {
        let normalizedEmail = try validated(email: email, password: password)
        let accountKey = emailAccountKey(for: normalizedEmail)
        guard keychain.data(for: accountKey) == nil else { throw AuthError.accountExists }

        let salt = Data((0..<16).map { _ in UInt8.random(in: .min ... .max) })
        let record = EmailAccount(
            email: normalizedEmail,
            salt: salt,
            passwordHash: derivePasswordKey(password, salt: salt, iterations: passwordIterations),
            algorithm: "pbkdf2-sha256",
            iterations: passwordIterations
        )
        guard let encoded = try? JSONEncoder().encode(record), keychain.set(encoded, for: accountKey) else {
            throw AuthError.unavailable
        }
        setSession(AuthSession(userID: normalizedEmail, email: normalizedEmail, displayName: nil, provider: .email))
    }

    func signIn(email: String, password: String) throws {
        let normalizedEmail = try validated(email: email, password: password)
        let accountKey = emailAccountKey(for: normalizedEmail)
        guard
            let data = keychain.data(for: accountKey),
            let record = try? JSONDecoder().decode(EmailAccount.self, from: data),
            record.email == normalizedEmail
        else { throw AuthError.invalidCredentials }

        let candidate: Data
        if record.algorithm == "pbkdf2-sha256", let iterations = record.iterations {
            candidate = derivePasswordKey(password, salt: record.salt, iterations: iterations)
        } else {
            candidate = legacyHash(password, salt: record.salt)
        }
        guard timingSafeEqual(candidate, record.passwordHash) else { throw AuthError.invalidCredentials }

        if record.algorithm == nil {
            let upgraded = EmailAccount(
                email: normalizedEmail,
                salt: record.salt,
                passwordHash: derivePasswordKey(password, salt: record.salt, iterations: passwordIterations),
                algorithm: "pbkdf2-sha256",
                iterations: passwordIterations
            )
            if let data = try? JSONEncoder().encode(upgraded) { _ = keychain.set(data, for: accountKey) }
        }

        setSession(AuthSession(userID: normalizedEmail, email: normalizedEmail, displayName: nil, provider: .email))
    }

    func handleAppleAuthorization(_ result: Result<ASAuthorization, Error>) {
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

    func validateStoredAppleCredential() async {
        guard let session, session.provider == .apple else { return }
        let state = (try? await ASAuthorizationAppleIDProvider().credentialState(forUserID: session.userID)) ?? .notFound
        if state == .revoked || state == .notFound {
            signOut()
        }
    }

    private func validated(email: String, password: String) throws -> String {
        let email = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard email.range(of: #"^[^\s@]+@[^\s@]+\.[^\s@]+$"#, options: .regularExpression) != nil else {
            throw AuthError.invalidEmail
        }
        guard password.count >= 8 else { throw AuthError.weakPassword }
        return email
    }

    private func legacyHash(_ password: String, salt: Data) -> Data {
        Data(SHA256.hash(data: salt + Data(password.utf8)))
    }

    private func derivePasswordKey(_ password: String, salt: Data, iterations: UInt32) -> Data {
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

    private func timingSafeEqual(_ lhs: Data, _ rhs: Data) -> Bool {
        guard lhs.count == rhs.count else { return false }
        return zip(lhs, rhs).reduce(UInt8(0)) { $0 | ($1.0 ^ $1.1) } == 0
    }

    private func emailAccountKey(for email: String) -> String {
        "auth.email.\(SHA256.hash(data: Data(email.utf8)).map { String(format: "%02x", $0) }.joined())"
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
}
