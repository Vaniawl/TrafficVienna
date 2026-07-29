import Foundation
import OSLog
import Security

nonisolated protocol LegacyAccountProfileDeleting {
    func delete() -> OSStatus
}

nonisolated struct KeychainLegacyAccountProfileDeleter: LegacyAccountProfileDeleting {
    func delete() -> OSStatus {
        SecItemDelete([
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "wellbe.TrafficVienna.account",
            kSecAttrAccount as String: "current-profile",
        ] as CFDictionary)
    }
}

@MainActor
enum LegacyAccountProfileCleanup {
    static let completionKey = "did_remove_legacy_apple_profile_v1"

    private static let log = Logger(
        subsystem: "wellbe.TrafficVienna",
        category: "migration"
    )

    static func run(
        defaults: UserDefaults = .standard,
        deleter: any LegacyAccountProfileDeleting = KeychainLegacyAccountProfileDeleter()
    ) {
        guard !defaults.bool(forKey: completionKey) else { return }

        let status = deleter.delete()
        guard status == errSecSuccess || status == errSecItemNotFound else {
            log.error("Legacy profile cleanup failed with status \(status, privacy: .public)")
            return
        }

        defaults.set(true, forKey: completionKey)
    }
}
