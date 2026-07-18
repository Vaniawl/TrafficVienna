import XCTest
@testable import TrafficVienna

final class TrafficViennaTests: XCTestCase {

    // MARK: - StationStore

    func testLoadStationsNotEmpty() {
        let store = StationStore()

        XCTAssertEqual(store.loadState, .loaded)
        XCTAssertGreaterThan(store.stations.count, 0)
    }

    // MARK: - RouteMatching

    func testNormalizeTrimsWhitespace() {
        XCTAssertEqual(RouteMatching.normalize("  Praterstern  "), "praterstern")
    }

    func testNormalizeLowercases() {
        XCTAssertEqual(RouteMatching.normalize("Leopoldau"), "leopoldau")
    }

    func testNormalizeStripsTrailingU() {
        XCTAssertEqual(RouteMatching.normalize("Kagran U"), "kagran")
    }

    func testNormalizeStripsTrailingS() {
        XCTAssertEqual(RouteMatching.normalize("Meidling S"), "meidling")
    }

    func testNormalizeDoesNotStripMidStringU() {
        XCTAssertEqual(RouteMatching.normalize("Wien Mitte"), "wien mitte")
    }

    func testNormalizeCollapsesInternalWhitespace() {
        XCTAssertEqual(RouteMatching.normalize("Wien   Mitte"), "wien mitte")
    }

    func testNormalizeFoldsDiacritics() {
        XCTAssertEqual(RouteMatching.normalize("Franz-Josefs-Bahnhof"), "franz-josefs-bahnhof")
    }

    func testMatchesExact() {
        XCTAssertTrue(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U1", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesWithTrailingMarker() {
        XCTAssertTrue(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau U",
            favoriteLine: "U1", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesDifferentLineFails() {
        XCTAssertFalse(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U2", favoriteDestination: "Leopoldau"
        ))
    }

    func testMatchesDifferentDestinationFails() {
        XCTAssertFalse(RouteMatching.matches(
            lineName: "U1", towards: "Leopoldau",
            favoriteLine: "U1", favoriteDestination: "Kagran"
        ))
    }

    // MARK: - DepartureClock

    func testLiveMinutesFallback() {
        let result = DepartureClock.liveMinutes(realtime: nil, planned: nil, fallback: 42)
        XCTAssertEqual(result, 42)
    }

    func testLiveMinutesFromRealTime() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(300))
        let result = DepartureClock.liveMinutes(realtime: future, planned: nil, fallback: 99)
        XCTAssertEqual(result, 5)
    }

    func testLiveMinutesFromPlanned() {
        let future = ISO8601DateFormatter().string(from: Date().addingTimeInterval(120))
        let result = DepartureClock.liveMinutes(realtime: nil, planned: future, fallback: 99)
        XCTAssertEqual(result, 2)
    }

    func testLiveMinutesNeverNegative() {
        let past = ISO8601DateFormatter().string(from: Date().addingTimeInterval(-60))
        let result = DepartureClock.liveMinutes(realtime: nil, planned: past, fallback: 0)
        XCTAssertEqual(result, 0)
    }

    // MARK: - DepartureTime liveMinutes

    func testDepartureTimeLiveMinutesFallback() {
        let dt = DepartureTime(countdown: 7, timePlanned: nil, timeReal: nil)
        XCTAssertEqual(dt.liveMinutes, 7)
    }

    // MARK: - MonitorService (mock network)

    func testMonitorServiceReturnsCachedResponse() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        let first = try await service.monitor(diva: 60201435)
        let cached = try await service.monitor(diva: 60201435)
        let callCount = await mock.callCount

        XCTAssertEqual(first.data.monitors.count, cached.data.monitors.count)
        XCTAssertEqual(callCount, 1, "Second call should hit cache, not network")
    }

    func testMonitorServiceForceRefreshBypassesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.monitor(diva: 60201435)
        _ = try await service.monitor(diva: 60201435, forceRefresh: true)
        let callCount = await mock.callCount

        XCTAssertEqual(callCount, 2, "Force refresh should bypass cache")
    }

    func testMonitorServiceFallbackToStaleCacheOnNetworkError() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 0)

        _ = try await service.monitor(diva: 60201435)
        await mock.setShouldFail(true)

        let result = try await service.monitor(diva: 60201435)
        XCTAssertFalse(result.data.monitors.isEmpty, "Should return stale cache on error")
    }

    // MARK: - LineColors

    func testLineColorsU1() {
        let color = LineColors.color(for: "U1")
        XCTAssertNotNil(color)
    }

    func testLineCategoryOfU1() {
        XCTAssertEqual(LineCategory.of("U1"), .metro)
    }

    func testLineCategoryOfS1() {
        XCTAssertEqual(LineCategory.of("S1"), .sbahn)
    }

    func testLineCategoryOf13A() {
        XCTAssertEqual(LineCategory.of("13A"), .bus)
    }

    func testLineCategoryOfN25() {
        XCTAssertEqual(LineCategory.of("N25"), .night)
    }

    func testLineCategoryOfTram() {
        XCTAssertEqual(LineCategory.of("O"), .tram)
        XCTAssertEqual(LineCategory.of("D"), .tram)
    }

    // MARK: - WidgetDepartureData

    func testWidgetDepartureDataCodable() {
        let data = WidgetDepartureData(lineName: "U1", stopName: "Stephansplatz", destination: "Leopoldau", departures: [2, 5, 12])
        let encoded = try! JSONEncoder().encode(data)
        let decoded = try! JSONDecoder().decode(WidgetDepartureData.self, from: encoded)
        XCTAssertEqual(decoded.lineName, "U1")
        XCTAssertEqual(decoded.departures, [2, 5, 12])
    }
}

// MARK: - Mock Network Manager

private actor MockNetworkManager: NetworkManaging {
    private(set) var callCount = 0
    private var shouldFail = false

    init(shouldFail: Bool = false) {
        self.shouldFail = shouldFail
    }

    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func fetchMonitorData(for stopId: Int) async throws -> MonitorResponse {
        callCount += 1
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        callCount += 1
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    func fetchTrafficInfoList() async throws -> MonitorResponse {
        callCount += 1
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    private func mockResponse() -> MonitorResponse {
        let departure = Departure(departureTime: DepartureTime(countdown: 5, timePlanned: nil, timeReal: nil))
        let departures = Departures(departure: [departure])
        let line = Lines(name: "U1", towards: "Leopoldau", departures: departures)
        let attr = Attributes(rbl: 1234)
        let props = Properties(title: "Test Stop", attributes: attr)
        let stop = LocationStop(properties: props, geometry: nil)
        let monitor = Monitor(locationStop: stop, lines: [line])
        let data = DataBlock(monitors: [monitor], trafficInfos: nil)
        return MonitorResponse(data: data)
    }
}
