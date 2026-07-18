protocol MonitorProviding: Sendable {
    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse
}

extension MonitorService: MonitorProviding {}
