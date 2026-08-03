import XCTest
@testable import TrafficVienna

@MainActor
final class NetworkMonitorTests: XCTestCase {
    func testStartsWithoutClaimingOfflineBeforeFirstPathUpdate() {
        let monitor = NetworkMonitor()

        XCTAssertTrue(monitor.isConnected)
    }
}
