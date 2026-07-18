import Foundation

protocol MonitorProviding: Sendable {
    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse
    func monitorSnapshot(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot
}

extension MonitorProviding {
    func monitorSnapshot(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot {
        MonitorSnapshot(
            response: try await monitor(diva: diva, forceRefresh: forceRefresh),
            updatedAt: .now,
            isStale: false
        )
    }
}

extension MonitorService: MonitorProviding {}
