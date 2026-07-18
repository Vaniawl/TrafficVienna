import Foundation

protocol TrafficInfoProviding: Sendable {
    func trafficInfoList(forceRefresh: Bool) async throws -> [TrafficInfo]
    func trafficInfoSnapshot(forceRefresh: Bool) async throws -> TrafficInfoSnapshot
}

extension TrafficInfoProviding {
    func trafficInfoSnapshot(forceRefresh: Bool) async throws -> TrafficInfoSnapshot {
        TrafficInfoSnapshot(
            infos: try await trafficInfoList(forceRefresh: forceRefresh),
            updatedAt: .now,
            isStale: false
        )
    }
}

extension MonitorService: TrafficInfoProviding {}
