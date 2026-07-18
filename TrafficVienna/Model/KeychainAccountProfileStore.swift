import Foundation
import Security

struct KeychainAccountProfileStore: AccountProfileStoring {
    private let service = "wellbe.TrafficVienna.account"
    private let account = "current-profile"

    nonisolated init() {}

    func load() throws -> AccountProfile? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else {
            throw AccountStorageError.keychain(status)
        }
        guard let data = item as? Data else {
            throw AccountStorageError.encodingFailed
        }

        return try JSONDecoder().decode(AccountProfile.self, from: data)
    }

    func save(_ profile: AccountProfile) throws {
        guard let data = try? JSONEncoder().encode(profile) else {
            throw AccountStorageError.encodingFailed
        }

        var attributes = baseQuery
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly

        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        if addStatus == errSecSuccess {
            return
        }
        guard addStatus == errSecDuplicateItem else {
            throw AccountStorageError.keychain(addStatus)
        }

        let updateStatus = SecItemUpdate(
            baseQuery as CFDictionary,
            [kSecValueData as String: data] as CFDictionary
        )
        guard updateStatus == errSecSuccess else {
            throw AccountStorageError.keychain(updateStatus)
        }
    }

    func delete() throws {
        let status = SecItemDelete(baseQuery as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw AccountStorageError.keychain(status)
        }
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
    }
}
