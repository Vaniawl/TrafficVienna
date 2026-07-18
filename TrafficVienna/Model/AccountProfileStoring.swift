protocol AccountProfileStoring {
    func load() throws -> AccountProfile?
    func save(_ profile: AccountProfile) throws
    func delete() throws
}
