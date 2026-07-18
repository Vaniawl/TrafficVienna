import XCTest
import CoreLocation
@testable import TrafficVienna

final class TrafficViennaTests: XCTestCase {

    @MainActor
    func testEmailRegistrationAndSignIn() throws {
        let suite = "AuthStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let keychain = MemoryKeychain()
        let store = AuthStore(keychain: keychain, defaults: defaults)

        try store.register(email: " Rider@Example.com ", password: "tramline26")
        XCTAssertEqual(store.session?.email, "rider@example.com")
        store.signOut()
        try store.signIn(email: "rider@example.com", password: "tramline26")
        XCTAssertEqual(store.session?.provider, .email)
    }

    @MainActor
    func testEmailRegistrationRejectsInvalidInput() {
        let store = AuthStore(keychain: MemoryKeychain(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        XCTAssertThrowsError(try store.register(email: "invalid", password: "tramline26"))
        XCTAssertThrowsError(try store.register(email: "rider@example.com", password: "short"))
    }

    @MainActor
    func testMultipleEmailAccountsCanRegister() throws {
        let store = AuthStore(keychain: MemoryKeychain(), defaults: UserDefaults(suiteName: UUID().uuidString)!)
        try store.register(email: "first@example.com", password: "tramline26")
        store.signOut()
        try store.register(email: "second@example.com", password: "tramline27")
        XCTAssertEqual(store.session?.email, "second@example.com")
    }

    // MARK: - StationStore

    func testLoadStationsNotEmpty() {
        let store = StationStore()
        let exp = expectation(description: "Stations loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            XCTAssertGreaterThan(store.stations.count, 0)
            exp.fulfill()
        }
        wait(for: [exp], timeout: 5)
    }

    func testStationLookupByIDUsesIndex() {
        let store = StationStore()
        guard let station = store.stations.first else { return XCTFail("Missing station fixture") }
        XCTAssertEqual(store.station(id: station.id)?.name, station.name)
    }

    func testStationSearchPerformance() {
        let store = StationStore()
        measure {
            for _ in 0..<100 {
                _ = store.stationsSuggestion(matching: "Haupt")
            }
        }
    }

    func testNearbySpatialIndexPerformance() {
        let store = StationStore()
        let center = CLLocation(latitude: 48.2082, longitude: 16.3738)
        measure {
            for _ in 0..<100 {
                _ = store.stations(near: center, radiusInMeters: 1_500)
            }
        }
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

        XCTAssertEqual(first.data.monitors.count, cached.data.monitors.count)
        XCTAssertEqual(mock.callCount, 1, "Second call should hit cache, not network")
    }

    func testMonitorServiceForceRefreshBypassesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.monitor(diva: 60201435)
        _ = try await service.monitor(diva: 60201435, forceRefresh: true)

        XCTAssertEqual(mock.callCount, 2, "Force refresh should bypass cache")
    }

    func testMonitorServiceFallbackToStaleCacheOnNetworkError() async throws {
        let mock = MockNetworkManager(shouldFail: true)
        let service = MonitorService(network: mock, cacheTTL: 30)

        _ = try await service.monitor(diva: 60201435)
        mock.shouldFail = true

        let result = try await service.monitor(diva: 60201435)
        XCTAssertFalse(result.data.monitors.isEmpty, "Should return stale cache on error")
    }

    func testTrafficInfoListUsesCache() async throws {
        let mock = MockNetworkManager()
        let service = MonitorService(network: mock, cacheTTL: 30)
        _ = try await service.trafficInfoList()
        _ = try await service.trafficInfoList()
        XCTAssertEqual(mock.callCount, 1)
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

private final class MemoryKeychain: KeychainStoring {
    private var storage: [String: Data] = [:]
    func data(for key: String) -> Data? { storage[key] }
    func set(_ data: Data, for key: String) -> Bool {
        storage[key] = data
        return true
    }
}

// MARK: - Mock Network Manager

private final class MockNetworkManager: NetworkManaging, @unchecked Sendable {
    var callCount = 0
    var shouldFail = false

    init(shouldFail: Bool = false) {
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
