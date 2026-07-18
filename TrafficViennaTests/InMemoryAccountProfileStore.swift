@testable import TrafficVienna

final class InMemoryAccountProfileStore: AccountProfileStoring {
    var storedProfile: AccountProfile?
    var shouldThrow = false

    init(profile: AccountProfile? = nil) {
        storedProfile = profile
    }

    func load() throws -> AccountProfile? {
        try checkForFailure()
        return storedProfile
    }

    func save(_ profile: AccountProfile) throws {
        try checkForFailure()
        storedProfile = profile
    }

    func delete() throws {
        try checkForFailure()
        storedProfile = nil
    }

    private func checkForFailure() throws {
        if shouldThrow {
            throw AccountStorageError.encodingFailed
        }
    }
}
