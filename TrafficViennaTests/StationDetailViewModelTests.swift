import XCTest
@testable import TrafficVienna

@MainActor
final class StationDetailViewModelTests: XCTestCase {
    func testMissingDivaShowsExplicitUnavailableState() async {
        let viewModel = makeViewModel(station: Station(id: 1, diva: nil, name: "Test", lat: 0, lon: 0))

        await viewModel.load()

        guard case .failed = viewModel.state else {
            return XCTFail("Expected a failure state for a station without DIVA")
        }
    }

    func testLoadMergesDuplicateDirectionsAndSortsLiveMinutes() async {
        let viewModel = makeViewModel(response: responseWithMergedU1())

        await viewModel.load()

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.groups.count, 1)
        XCTAssertEqual(viewModel.groups.first?.minutes, [2, 5, 8])
        XCTAssertEqual(viewModel.groups.first?.isLive, true)
    }

    func testCategoryFilterCanProduceClearEmptyResult() async {
        let viewModel = makeViewModel(response: responseWithMergedU1())
        await viewModel.load()

        viewModel.categoryFilter = .bus

        XCTAssertTrue(viewModel.groups.isEmpty)
        XCTAssertEqual(viewModel.availableCategories, [.metro])
    }

    func testInitialNetworkFailureShowsFailureState() async {
        let viewModel = makeViewModel(result: .failure(DetailTestError.failed))

        await viewModel.load()

        guard case .failed = viewModel.state else {
            return XCTFail("Expected an initial network failure state")
        }
    }

    func testRefreshFailureKeepsExistingDeparturesVisible() async {
        let monitor = DetailMonitorProvider(result: .success(responseWithMergedU1()))
        let viewModel = makeViewModel(service: monitor)
        await viewModel.load()
        await monitor.setResult(.failure(DetailTestError.failed))

        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.groups.first?.minutes, [2, 5, 8])
        XCTAssertNotNil(viewModel.refreshErrorMessage)
    }

    func testCancelledLoadCannotPublishLateResponse() async {
        let monitor = DetailMonitorProvider(
            result: .success(responseWithMergedU1()),
            delay: .milliseconds(100)
        )
        let viewModel = makeViewModel(service: monitor)
        let load = Task { await viewModel.load() }
        await Task.yield()

        load.cancel()
        await load.value

        XCTAssertNil(viewModel.lastUpdated)
        XCTAssertTrue(viewModel.groups.isEmpty)
        XCTAssertFalse(viewModel.isLoadingRequest)
    }

    func testStationAndRouteFavouritesUseExistingRepositories() async {
        let stations = DetailStationsRepository()
        let routes = DetailRoutesRepository()
        let viewModel = makeViewModel(favoritesRepo: routes, stationsRepo: stations)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        viewModel.toggleStationFavorite()
        viewModel.toggleFavorite(group)

        XCTAssertTrue(viewModel.isStationFavorited)
        XCTAssertTrue(viewModel.isFavorite(group))
        XCTAssertTrue(stations.contains(id: 1))
    }

    func testUnavailableLiveActivitiesShowUserNotice() async {
        let starter = DetailLiveActivityStarter(isAvailable: false)
        let viewModel = makeViewModel(liveActivityStarter: starter)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        viewModel.startTracking(group)

        XCTAssertNotNil(viewModel.notice)
        XCTAssertNil(viewModel.trackedDepartureID)
    }

    func testSuccessfulLiveActivityTracksSelectedDeparture() async {
        let starter = DetailLiveActivityStarter(isAvailable: true)
        let viewModel = makeViewModel(liveActivityStarter: starter)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        viewModel.startTracking(group)

        XCTAssertEqual(viewModel.trackedDepartureID, group.id)
        XCTAssertEqual(starter.startedLine, "U1")
    }

    func testFailedLiveActivityStartShowsUserNotice() async {
        let starter = DetailLiveActivityStarter(isAvailable: true, shouldThrow: true)
        let viewModel = makeViewModel(liveActivityStarter: starter)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        viewModel.startTracking(group)

        XCTAssertNotNil(viewModel.notice)
        XCTAssertNil(viewModel.trackedDepartureID)
    }

    private func makeViewModel(
        station: Station = Station(id: 1, diva: 123, name: "Test", lat: 0, lon: 0),
        response: MonitorResponse? = nil,
        result: Result<MonitorResponse, Error>? = nil,
        service: DetailMonitorProvider? = nil,
        favoritesRepo: DetailRoutesRepository = DetailRoutesRepository(),
        stationsRepo: DetailStationsRepository = DetailStationsRepository(),
        liveActivityStarter: DetailLiveActivityStarter? = nil
    ) -> StationDetailViewModel {
        let resolvedResult = result ?? .success(response ?? responseWithMergedU1())
        return StationDetailViewModel(
            station: station,
            service: service ?? DetailMonitorProvider(result: resolvedResult),
            favoritesRepo: favoritesRepo,
            stationsRepo: stationsRepo,
            liveActivityStarter: liveActivityStarter ?? DetailLiveActivityStarter(isAvailable: true)
        )
    }

    private func responseWithMergedU1() -> MonitorResponse {
        let planned = Departure(departureTime: DepartureTime(countdown: 8, timePlanned: nil, timeReal: nil))
        let live = Departure(departureTime: DepartureTime(countdown: 2, timePlanned: nil, timeReal: "live"))
        let later = Departure(departureTime: DepartureTime(countdown: 5, timePlanned: nil, timeReal: nil))
        let first = Lines(name: "U1", towards: "Leopoldau", departures: Departures(departure: [planned, live]))
        let second = Lines(name: "U1", towards: "Leopoldau", departures: Departures(departure: [later]))
        return MonitorResponse(
            data: DataBlock(
                monitors: [monitor(lines: [first]), monitor(lines: [second])],
                trafficInfos: []
            )
        )
    }

    private func monitor(lines: [Lines]) -> Monitor {
        Monitor(
            locationStop: LocationStop(
                properties: Properties(title: "Test", attributes: Attributes(rbl: 1)),
                geometry: nil
            ),
            lines: lines
        )
    }
}

private enum DetailTestError: Error { case failed }

private actor DetailMonitorProvider: MonitorProviding {
    private var result: Result<MonitorResponse, Error>
    private let delay: Duration
    init(result: Result<MonitorResponse, Error>, delay: Duration = .zero) {
        self.result = result
        self.delay = delay
    }
    func setResult(_ result: Result<MonitorResponse, Error>) { self.result = result }
    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse {
        if delay != .zero { try? await Task.sleep(for: delay) }
        return try result.get()
    }
}

private final class DetailRoutesRepository: FavoritesRepository, @unchecked Sendable {
    private var routes = Set<FavoriteRoute>()
    func isFavorite(diva: String, lineName: String, destination: String) -> Bool {
        routes.contains(FavoriteRoute(diva: diva, lineName: lineName, destination: destination))
    }
    func toggle(diva: String, lineName: String, destination: String) {
        let route = FavoriteRoute(diva: diva, lineName: lineName, destination: destination)
        if routes.remove(route) == nil { routes.insert(route) }
    }
    func getAll() -> [FavoriteRoute] { Array(routes) }
    func removeAll() { routes = [] }
}

private final class DetailStationsRepository: FavoriteStationsStoring, @unchecked Sendable {
    private var stations: [FavoriteStation] = []
    func all() -> [FavoriteStation] { stations }
    func contains(id: Int) -> Bool { stations.contains { $0.id == id } }
    func toggle(_ station: FavoriteStation) {
        if let index = stations.firstIndex(where: { $0.id == station.id }) {
            stations.remove(at: index)
        } else {
            stations.append(station)
        }
    }
    func remove(id: Int) { stations.removeAll { $0.id == id } }
    func setOrder(_ stations: [FavoriteStation]) { self.stations = stations }
}

@MainActor
private final class DetailLiveActivityStarter: LiveActivityStarting {
    let isAvailable: Bool
    let shouldThrow: Bool
    var startedLine: String?
    init(isAvailable: Bool, shouldThrow: Bool = false) {
        self.isAvailable = isAvailable
        self.shouldThrow = shouldThrow
    }
    func start(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) throws {
        if shouldThrow { throw DetailTestError.failed }
        startedLine = line
    }
}
