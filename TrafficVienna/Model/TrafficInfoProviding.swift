protocol TrafficInfoProviding: Sendable {
    func trafficInfoList(forceRefresh: Bool) async throws -> [TrafficInfo]
}

extension MonitorService: TrafficInfoProviding {}
