import Combine
import LocalAuthentication

enum BiometricKind: Equatable {
    case faceID
    case touchID
    case opticID
    case unavailable

    var title: String {
        switch self {
        case .faceID: String(localized: "Face ID")
        case .touchID: String(localized: "Touch ID")
        case .opticID: String(localized: "Optic ID")
        case .unavailable: String(localized: "Device passcode")
        }
    }

    var symbolName: String {
        switch self {
        case .faceID: "faceid"
        case .touchID: "touchid"
        case .opticID: "opticid"
        case .unavailable: "lock.open"
        }
    }
}

enum AppLockTimeout: Int, CaseIterable, Identifiable {
    case immediately = 0
    case oneMinute = 60
    case fiveMinutes = 300

    var id: Int { rawValue }
    var interval: TimeInterval { TimeInterval(rawValue) }

    var title: String {
        switch self {
        case .immediately: String(localized: "Immediately")
        case .oneMinute: String(localized: "After 1 minute")
        case .fiveMinutes: String(localized: "After 5 minutes")
        }
    }
}

@MainActor
protocol BiometricAuthenticating {
    var kind: BiometricKind { get }
    var canAuthenticate: Bool { get }
    func authenticate(reason: String) async throws
}

struct SystemBiometricAuthenticator: BiometricAuthenticating {
    static let policy: LAPolicy = .deviceOwnerAuthentication

    var kind: BiometricKind {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        default: return .unavailable
        }
    }

    var canAuthenticate: Bool {
        LAContext().canEvaluatePolicy(Self.policy, error: nil)
    }

    func authenticate(reason: String) async throws {
        let context = LAContext()
        context.localizedCancelTitle = String(localized: "Cancel")
        guard context.canEvaluatePolicy(Self.policy, error: nil) else {
            throw AppLockError.unavailable
        }
        guard try await context.evaluatePolicy(
            Self.policy,
            localizedReason: reason
        ) else { throw AppLockError.failed }
    }
}

enum AppLockError: LocalizedError, Equatable {
    case unavailable
    case failed

    var errorDescription: String? {
        switch self {
        case .unavailable: String(localized: "Biometric authentication is not available on this device.")
        case .failed: String(localized: "Couldn’t verify your identity. Please try again.")
        }
    }
}

@MainActor
final class AppLockStore: ObservableObject {
    @Published private(set) var isEnabled: Bool
    @Published private(set) var isLocked: Bool
    @Published private(set) var isPrivacyShieldVisible = false
    @Published private(set) var timeout: AppLockTimeout
    @Published private(set) var isAuthenticating = false
    @Published var errorMessage: String?

    let biometricKind: BiometricKind

    private let defaults: UserDefaults
    private let authenticator: BiometricAuthenticating
    private let enabledKey = "appLock.biometricEnabled"
    private let timeoutKey = "appLock.timeout"
    private var inactiveSince: TimeInterval?

    init(
        defaults: UserDefaults = .standard,
        authenticator: BiometricAuthenticating? = nil,
        resetLock: Bool = ProcessInfo.processInfo.arguments.contains("-ui-testing-reset")
    ) {
        let authenticator = authenticator ?? SystemBiometricAuthenticator()
        self.defaults = defaults
        self.authenticator = authenticator
        biometricKind = authenticator.kind
        if resetLock {
            defaults.removeObject(forKey: enabledKey)
            defaults.removeObject(forKey: timeoutKey)
        }
        let enabled = !resetLock && defaults.bool(forKey: enabledKey) && authenticator.canAuthenticate
        timeout = AppLockTimeout(rawValue: defaults.integer(forKey: timeoutKey)) ?? .immediately
        isEnabled = enabled
        isLocked = enabled
    }

    func enable() async {
        guard biometricKind != .unavailable, authenticator.canAuthenticate else {
            errorMessage = AppLockError.unavailable.localizedDescription
            return
        }
        guard await authenticate(reason: String(localized: "Confirm to enable biometric unlock.")) else { return }
        isEnabled = true
        isLocked = false
        defaults.set(true, forKey: enabledKey)
    }

    func disable() {
        isEnabled = false
        isLocked = false
        isPrivacyShieldVisible = false
        inactiveSince = nil
        errorMessage = nil
        defaults.removeObject(forKey: enabledKey)
    }

    func setTimeout(_ timeout: AppLockTimeout) {
        self.timeout = timeout
        defaults.set(timeout.rawValue, forKey: timeoutKey)
    }

    func protectForInactivity(
        hasSession: Bool,
        at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) {
        guard isEnabled, hasSession, !isAuthenticating else { return }
        inactiveSince = inactiveSince ?? uptime
        isPrivacyShieldVisible = true
        if timeout == .immediately {
            isLocked = true
        }
    }

    @discardableResult
    func resumeAfterInactivity(
        at uptime: TimeInterval = ProcessInfo.processInfo.systemUptime
    ) -> Bool {
        isPrivacyShieldVisible = false
        guard isEnabled, let inactiveSince else { return isLocked }
        if max(0, uptime - inactiveSince) >= timeout.interval {
            isLocked = true
        }
        self.inactiveSince = nil
        return isLocked
    }

    func clearLockForSignedOutSession() {
        isLocked = false
        isPrivacyShieldVisible = false
        inactiveSince = nil
        errorMessage = nil
    }

    func unlock() async {
        guard isEnabled, isLocked else { return }
        _ = await authenticate(reason: String(localized: "Unlock Traffic Vienna."))
    }

    private func authenticate(reason: String) async -> Bool {
        guard !isAuthenticating else { return false }
        isAuthenticating = true
        defer { isAuthenticating = false }
        do {
            try await authenticator.authenticate(reason: reason)
            isLocked = false
            errorMessage = nil
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }
}
