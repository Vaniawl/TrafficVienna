import Foundation

nonisolated struct MonitorSnapshot: Sendable {
    let response: MonitorResponse
    let updatedAt: Date
    let isStale: Bool
}

nonisolated struct TrafficInfoSnapshot: Sendable {
    let infos: [TrafficInfo]
    let updatedAt: Date
    let isStale: Bool
}
