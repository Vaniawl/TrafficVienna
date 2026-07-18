import XCTest
@testable import TrafficVienna

@MainActor
final class FavoritesListViewModelTests: XCTestCase {
    func testStationsLoadMoveAndPersistOrder() {
        let stations = StubFavoriteStationsRepository(stations: [station(1, "A"), station(2, "B")])
        let viewModel = makeViewModel(stationsRepo: stations)
        viewModel.loadStations()

        viewModel.moveStations(fromOffsets: IndexSet(integer: 0), toOffset: 2)

        XCTAssertEqual(viewModel.stations.map(\.name), ["B", "A"])
        XCTAssertEqual(stations.stations.map(\.name), ["B", "A"])
    }

    func testRemovingStationUpdatesRepositoryAndViewState() {
        let stations = StubFavoriteStationsRepository(stations: [station(1, "A")])
        let viewModel = makeViewModel(stationsRepo: stations)
        viewModel.loadStations()

        viewModel.removeStation(id: 1)

        XCTAssertTrue(viewModel.stations.isEmpty)
        XCTAssertTrue(stations.stations.isEmpty)
    }

    func testRoutesLoadInStableOrderWithStableIdentity() async {
        let routes = StubFavoritesRepository(routes: [route("U4", "Heiligenstadt"), route("U1", "Leopoldau")])
        let viewModel = makeViewModel(favoritesRepo: routes)

        await viewModel.loadFavorites()

        XCTAssertEqual(viewModel.items.map(\.route.lineName), ["U1", "U4"])
        XCTAssertEqual(viewModel.items.map(\.id), viewModel.items.map(\.route))
        XCTAssertTrue(viewModel.items.allSatisfy { $0.state == .available })
    }

    func testFailedRouteRemainsVisibleAndIsExcludedFromWidget() async {
        let routes = StubFavoritesRepository(routes: [route("U1", "Leopoldau")])
        let widget = StubWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: StubMonitorProvider(result: .failure(TestMonitorError.failed)),
            favoritesRepo: routes,
            stationsRepo: StubFavoriteStationsRepository(),
            widgetSync: widget
        )

        await viewModel.loadFavorites()

        XCTAssertEqual(viewModel.items.first?.state, .unavailable)
        XCTAssertTrue(widget.lastSaved.isEmpty)
    }

    func testRefreshForcesNetworkAndReplacesMatchingItem() async {
        let monitor = StubMonitorProvider(result: .success(response(countdown: 5)))
        let favorite = route("U1", "Leopoldau")
        let viewModel = makeViewModel(service: monitor, favoritesRepo: StubFavoritesRepository(routes: [favorite]))
        await viewModel.loadFavorites()
        await monitor.setResult(.success(response(countdown: 2)))

        await viewModel.refresh(favorite)

        XCTAssertEqual(viewModel.items.first?.departures.first?.countdown, 2)
        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false, true])
    }

    func testCachedRouteIsLabelledAndRemainsEligibleForWidget() async {
        let favorite = route("U1", "Leopoldau")
        let widget = StubWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: StubMonitorProvider(result: .success(response(countdown: 5)), isStale: true),
            favoritesRepo: StubFavoritesRepository(routes: [favorite]),
            stationsRepo: StubFavoriteStationsRepository(),
            widgetSync: widget
        )

        await viewModel.loadFavorites(forceRefresh: true)

        XCTAssertEqual(viewModel.items.first?.state, .cached)
        XCTAssertEqual(widget.lastSaved.first?.lineName, "U1")
    }

    private func makeViewModel(
        service: StubMonitorProvider? = nil,
        favoritesRepo: StubFavoritesRepository = StubFavoritesRepository(),
        stationsRepo: StubFavoriteStationsRepository = StubFavoriteStationsRepository()
    ) -> FavoritesListViewModel {
        FavoritesListViewModel(
            service: service ?? StubMonitorProvider(result: .success(response(countdown: 5))),
            favoritesRepo: favoritesRepo,
            stationsRepo: stationsRepo,
            widgetSync: StubWidgetSync()
        )
    }

    private func route(_ line: String, _ destination: String) -> FavoriteRoute {
        FavoriteRoute(diva: "123", lineName: line, destination: destination)
    }

    private func station(_ id: Int, _ name: String) -> FavoriteStation {
        FavoriteStation(id: id, diva: id, name: name)
    }

    private func response(countdown: Int) -> MonitorResponse {
        let departure = Departure(departureTime: DepartureTime(countdown: countdown, timePlanned: nil, timeReal: nil))
        let line1 = Lines(name: "U1", towards: "Leopoldau", departures: Departures(departure: [departure]))
        let line4 = Lines(name: "U4", towards: "Heiligenstadt", departures: Departures(departure: [departure]))
        let stop = LocationStop(
            properties: Properties(title: "Test", attributes: Attributes(rbl: 1)),
            geometry: nil
        )
        return MonitorResponse(data: DataBlock(monitors: [Monitor(locationStop: stop, lines: [line1, line4])], trafficInfos: nil))
    }
}

private enum TestMonitorError: Error { case failed }

private actor StubMonitorProvider: MonitorProviding {
    private var result: Result<MonitorResponse, Error>
    private(set) var forceRefreshValues: [Bool] = []
    private let isStale: Bool

    init(result: Result<MonitorResponse, Error>, isStale: Bool = false) {
        self.result = result
        self.isStale = isStale
    }
    func setResult(_ result: Result<MonitorResponse, Error>) { self.result = result }
    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse {
        forceRefreshValues.append(forceRefresh)
        return try result.get()
    }
    func monitorSnapshot(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot {
        MonitorSnapshot(
            response: try await monitor(diva: diva, forceRefresh: forceRefresh),
            updatedAt: .now,
            isStale: isStale
        )
    }
}

private final class StubFavoritesRepository: FavoritesRepository, @unchecked Sendable {
    var routes: Set<FavoriteRoute>
    init(routes: [FavoriteRoute] = []) { self.routes = Set(routes) }
    func isFavorite(diva: String, lineName: String, destination: String) -> Bool { routes.contains(FavoriteRoute(diva: diva, lineName: lineName, destination: destination)) }
    func toggle(diva: String, lineName: String, destination: String) {
        let route = FavoriteRoute(diva: diva, lineName: lineName, destination: destination)
        if routes.remove(route) == nil { routes.insert(route) }
    }
    func getAll() -> [FavoriteRoute] { Array(routes) }
    func removeAll() { routes = [] }
}

private final class StubFavoriteStationsRepository: FavoriteStationsStoring, @unchecked Sendable {
    var stations: [FavoriteStation]
    init(stations: [FavoriteStation] = []) { self.stations = stations }
    func all() -> [FavoriteStation] { stations }
    func contains(id: Int) -> Bool { stations.contains { $0.id == id } }
    func toggle(_ station: FavoriteStation) { }
    func remove(id: Int) { stations.removeAll { $0.id == id } }
    func setOrder(_ stations: [FavoriteStation]) { self.stations = stations }
}

private final class StubWidgetSync: WidgetSyncing, @unchecked Sendable {
    var lastSaved: [WidgetDepartureData] = []
    func save(_ data: [WidgetDepartureData]) { lastSaved = data }
}
