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

        let current = try await service.monitorSnapshot(diva: 60201435)
        await mock.setShouldFail(true)

        let result = try await service.monitorSnapshot(diva: 60201435)
        XCTAssertFalse(result.response.data.monitors.isEmpty, "Should return stale cache on error")
        XCTAssertTrue(result.isStale)
        XCTAssertEqual(result.updatedAt, current.updatedAt)
    }

    func testTrafficInfoListUsesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.trafficInfoList()
        _ = try await service.trafficInfoList()
        let callCount = await mock.callCount

        XCTAssertEqual(callCount, 1)
    }

    func testTrafficInfoListForceRefreshBypassesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.trafficInfoList()
        _ = try await service.trafficInfoList(forceRefresh: true)
        let callCount = await mock.callCount

        XCTAssertEqual(callCount, 2)
    }

    func testTrafficInfoListCoalescesConcurrentRequests() async throws {
        let mock = MockNetworkManager(delay: .milliseconds(50))
        let service = MonitorService(network: mock, cacheTTL: 0, minInterval: 0)

        async let first = service.trafficInfoList(forceRefresh: true)
        async let second = service.trafficInfoList(forceRefresh: true)
        _ = try await (first, second)

        let callCount = await mock.callCount
        XCTAssertEqual(callCount, 1)
    }

    func testTrafficInfoListFallsBackToStaleCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 0, minInterval: 0)

        let current = try await service.trafficInfoSnapshot()
        await mock.setShouldFail(true)

        let stale = try await service.trafficInfoSnapshot(forceRefresh: true)
        XCTAssertTrue(stale.infos.isEmpty)
        XCTAssertTrue(stale.isStale)
        XCTAssertEqual(stale.updatedAt, current.updatedAt)
        let callCount = await mock.callCount
        XCTAssertEqual(callCount, 2)
    }

    func testMonitorServiceSpacesNetworkCallsWithInjectedScheduler() async throws {
        let scheduler = TestMonitorScheduler()
        let service = MonitorService(
            network: MockNetworkManager(),
            cacheTTL: 0,
            minInterval: 0.5,
            scheduler: scheduler
        )

        _ = try await service.monitor(diva: 1, forceRefresh: true)
        _ = try await service.monitor(diva: 2, forceRefresh: true)

        let sleeps = await scheduler.sleeps
        XCTAssertEqual(sleeps.count, 1)
        XCTAssertEqual(sleeps.first ?? .nan, 0.5, accuracy: 0.000_001)
    }

    func testMonitorServiceUsesBoundedExponentialRateLimitBackoff() async throws {
        let scheduler = TestMonitorScheduler()
        let network = RateLimitedNetworkManager(failuresBeforeSuccess: 2)
        let service = MonitorService(
            network: network,
            cacheTTL: 0,
            minInterval: 0,
            maxRetries: 2,
            scheduler: scheduler
        )

        _ = try await service.monitor(diva: 1, forceRefresh: true)

        let sleeps = await scheduler.sleeps
        let callCount = await network.callCount
        XCTAssertEqual(sleeps.count, 2)
        XCTAssertEqual(sleeps.first ?? .nan, 0.8, accuracy: 0.000_001)
        XCTAssertEqual(sleeps.last ?? .nan, 1.6, accuracy: 0.000_001)
        XCTAssertEqual(callCount, 3)
    }

    func testTrafficInfoDecodesFeedCategory() throws {
        let json = """
        {
          "data": {
            "monitors": [],
            "trafficInfos": [{
              "refTrafficInfoCategoryId": 3,
              "name": "stop-change",
              "title": "Betrieb ab Hirschengasse",
              "description": "Haltestelle verlegt",
              "priority": "1",
              "relatedLines": ["57A"]
            }]
          }
        }
        """

        let response = try JSONDecoder().decode(MonitorResponse.self, from: Data(json.utf8))

        XCTAssertEqual(response.data.trafficInfos?.first?.categoryID, 3)
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

    func testFavoriteRouteOrderIsSharedAndDeterministic() {
        let routes = [
            FavoriteRoute(diva: "2", lineName: "U4", destination: "Heiligenstadt"),
            FavoriteRoute(diva: "1", lineName: "U1", destination: "Leopoldau"),
        ]

        XCTAssertEqual(routes.sorted().map(\.lineName), ["U1", "U4"])
    }
}

// MARK: - Mock Network Manager

private actor MockNetworkManager: NetworkManaging {
    private(set) var callCount = 0
    private var shouldFail = false
    private let delay: Duration

    init(shouldFail: Bool = false, delay: Duration = .zero) {
        self.shouldFail = shouldFail
        self.delay = delay
    }

    func setShouldFail(_ shouldFail: Bool) {
        self.shouldFail = shouldFail
    }

    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        callCount += 1
        try await waitIfNeeded()
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    func fetchTrafficInfoList() async throws -> MonitorResponse {
        callCount += 1
        try await waitIfNeeded()
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockResponse()
    }

    private func waitIfNeeded() async throws {
        guard delay != .zero else { return }
        try await Task.sleep(for: delay)
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

private actor TestMonitorScheduler: MonitorScheduling {
    private var current = Date(timeIntervalSince1970: 1_700_000_000)
    private(set) var sleeps: [TimeInterval] = []

    func now() async -> Date {
        current
    }

    func sleep(for duration: Duration) async throws {
        try Task.checkCancellation()
        let components = duration.components
        let interval = Double(components.seconds)
            + Double(components.attoseconds) / 1_000_000_000_000_000_000
        sleeps.append(interval)
        current = current.addingTimeInterval(interval)
    }
}

private actor RateLimitedNetworkManager: NetworkManaging {
    private var failuresRemaining: Int
    private(set) var callCount = 0

    init(failuresBeforeSuccess: Int) {
        failuresRemaining = failuresBeforeSuccess
    }

    func fetchMonitorData(diva: Int, includeArea: Bool) async throws -> MonitorResponse {
        try response()
    }

    func fetchTrafficInfoList() async throws -> MonitorResponse {
        try response()
    }

    private func response() throws -> MonitorResponse {
        callCount += 1
        if failuresRemaining > 0 {
            failuresRemaining -= 1
            throw MonitorApiError.rateLimited
        }
        return MonitorResponse(data: DataBlock(monitors: [], trafficInfos: []))
    }
}
