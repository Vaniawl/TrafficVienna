import Foundation

nonisolated protocol MonitorScheduling: Sendable {
    func now() async -> Date
    func sleep(for duration: Duration) async throws
}

nonisolated struct SystemMonitorScheduler: MonitorScheduling {
    func now() async -> Date {
        .now
    }

    func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
