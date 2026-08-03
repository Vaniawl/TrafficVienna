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

    func testRemovingStaleRouteCannotRestoreItToRepository() async {
        let favorite = route("U1", "Leopoldau")
        let routes = StubFavoritesRepository(routes: [favorite])
        let viewModel = makeViewModel(favoritesRepo: routes)
        await viewModel.loadFavorites()

        routes.routes.remove(favorite)
        viewModel.remove(favorite)

        XCTAssertFalse(routes.routes.contains(favorite))
        XCTAssertTrue(viewModel.items.isEmpty)
    }

    func testPersistedRouteRemovalIsIdempotent() {
        let suiteName = "FavoritesListViewModelTests.\(UUID().uuidString)"
        guard let storage = UserDefaults(suiteName: suiteName) else {
            return XCTFail("Could not create isolated UserDefaults suite")
        }
        defer { storage.removePersistentDomain(forName: suiteName) }
        let repository = UserDefaultsFavoritesRepository(storage: storage)
        let favorite = route("U1", "Leopoldau")
        repository.toggle(diva: favorite.diva, lineName: favorite.lineName, destination: favorite.destination)

        repository.remove(diva: favorite.diva, lineName: favorite.lineName, destination: favorite.destination)
        repository.remove(diva: favorite.diva, lineName: favorite.lineName, destination: favorite.destination)

        XCTAssertFalse(repository.isFavorite(
            diva: favorite.diva,
            lineName: favorite.lineName,
            destination: favorite.destination
        ))
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

    func testRetryDuringActiveLoadRunsForcedFollowUpWithoutStaleOverwrite() async {
        let favorite = route("U1", "Leopoldau")
        let monitor = BlockingMonitorProvider(responses: [
            response(countdown: 8),
            response(countdown: 7),
            response(countdown: 2)
        ])
        let viewModel = makeViewModel(
            service: monitor,
            favoritesRepo: StubFavoritesRepository(routes: [favorite])
        )

        let initialLoad = Task { await viewModel.loadFavorites() }
        await monitor.waitForCall(1)
        await monitor.releaseCall(1)
        await initialLoad.value

        let backgroundLoad = Task { await viewModel.loadFavorites() }
        await monitor.waitForCall(2)
        await monitor.releaseCall(3)

        let retry = Task { await viewModel.refresh(favorite) }
        await retry.value
        await monitor.releaseCall(2)
        await backgroundLoad.value

        XCTAssertEqual(viewModel.items.first?.departures.first?.countdown, 2)
        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false, false, true])
    }

    func testCachedRouteIsLabelledAndRemainsEligibleForWidget() async {
        let favorite = route("U1", "Leopoldau")
        let sourceUpdatedAt = Date(timeIntervalSince1970: 1_000)
        let widget = StubWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: StubMonitorProvider(
                result: .success(response(countdown: 5)),
                isStale: true,
                updatedAt: sourceUpdatedAt
            ),
            favoritesRepo: StubFavoritesRepository(routes: [favorite]),
            stationsRepo: StubFavoriteStationsRepository(),
            widgetSync: widget
        )

        await viewModel.loadFavorites(forceRefresh: true)

        XCTAssertEqual(viewModel.items.first?.state, .cached)
        XCTAssertEqual(widget.lastSaved.first?.lineName, "U1")
        XCTAssertEqual(widget.lastSaved.first?.dataUpdatedAt, sourceUpdatedAt)
        XCTAssertNotEqual(widget.lastSaved.first?.fetchedAt, sourceUpdatedAt)
    }

    func testRouteChangeDuringLoadSkipsStaleCommitAndRunsFollowUpPass() async {
        let original = route("U1", "Leopoldau")
        let replacement = route("U4", "Heiligenstadt")
        let routes = StubFavoritesRepository(routes: [original])
        let monitor = BlockingMonitorProvider(response: response(countdown: 5))
        let widget = StubWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: monitor,
            favoritesRepo: routes,
            stationsRepo: StubFavoriteStationsRepository(),
            widgetSync: widget
        )
        let initialLoad = Task { await viewModel.loadFavorites() }
        await monitor.waitForCall(1)

        routes.routes = [replacement]
        await monitor.releaseCall(1)
        await monitor.waitForCall(2)

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertTrue(widget.savedBatches.isEmpty)

        await monitor.releaseCall(2)
        await initialLoad.value

        XCTAssertEqual(viewModel.items.map(\.route), [replacement])
        XCTAssertEqual(widget.savedBatches.count, 1)
        XCTAssertEqual(widget.lastSaved.map(\.lineName), ["U4"])
        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false, false])
    }

    func testOverlappingLoadsCoalesceAndPreserveForcedRefresh() async {
        let routes = StubFavoritesRepository(routes: [route("U1", "Leopoldau")])
        let monitor = BlockingMonitorProvider(response: response(countdown: 5))
        let viewModel = makeViewModel(service: monitor, favoritesRepo: routes)
        let initialLoad = Task { await viewModel.loadFavorites() }
        await monitor.waitForCall(1)

        await viewModel.loadFavorites()
        await viewModel.loadFavorites(forceRefresh: true)
        await monitor.releaseCall(1)
        await monitor.waitForCall(2)
        await monitor.releaseCall(2)
        await initialLoad.value

        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false, true])
        XCTAssertEqual(viewModel.items.map(\.route.lineName), ["U1"])
        XCTAssertFalse(viewModel.isLoading)
    }

    func testForcedFullReloadSubsumesQueuedRouteRetry() async {
        let favorite = route("U1", "Leopoldau")
        let routes = StubFavoritesRepository(routes: [favorite])
        let monitor = BlockingMonitorProvider(response: response(countdown: 5))
        let viewModel = makeViewModel(service: monitor, favoritesRepo: routes)
        let initialLoad = Task { await viewModel.loadFavorites() }
        await monitor.waitForCall(1)

        await viewModel.refresh(favorite)
        await viewModel.loadFavorites(forceRefresh: true)
        await monitor.releaseCall(1)
        await monitor.waitForCall(2)
        await monitor.releaseCall(2)
        await initialLoad.value

        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false, true])
        XCTAssertEqual(viewModel.items.map(\.route), [favorite])
        XCTAssertFalse(viewModel.isLoading)
    }

    func testCancelledLoadDropsQueuedPassWithoutPublishing() async {
        let routes = StubFavoritesRepository(routes: [route("U1", "Leopoldau")])
        let monitor = BlockingMonitorProvider(response: response(countdown: 5))
        let widget = StubWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: monitor,
            favoritesRepo: routes,
            stationsRepo: StubFavoriteStationsRepository(),
            widgetSync: widget
        )
        let load = Task { await viewModel.loadFavorites() }
        await monitor.waitForCall(1)

        await viewModel.loadFavorites(forceRefresh: true)
        load.cancel()
        await monitor.releaseCall(1)
        await load.value

        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false])
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertTrue(widget.savedBatches.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testCancelledLoadDropsQueuedRouteRetryWithoutPublishing() async {
        let favorite = route("U1", "Leopoldau")
        let routes = StubFavoritesRepository(routes: [favorite])
        let monitor = BlockingMonitorProvider(response: response(countdown: 5))
        let widget = StubWidgetSync()
        let viewModel = FavoritesListViewModel(
            service: monitor,
            favoritesRepo: routes,
            stationsRepo: StubFavoriteStationsRepository(),
            widgetSync: widget
        )
        let load = Task { await viewModel.loadFavorites() }
        await monitor.waitForCall(1)
        await monitor.releaseCall(2)

        let retry = Task { await viewModel.refresh(favorite) }
        await retry.value
        load.cancel()
        await monitor.releaseCall(1)
        await load.value

        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false])
        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertTrue(widget.savedBatches.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
    }

    func testFeaturedDepartureSelectsSoonestNonnegativeSavedRoute() async {
        let routes = StubFavoritesRepository(routes: [
            route("U4", "Heiligenstadt"),
            route("U1", "Leopoldau")
        ])
        let monitor = StubMonitorProvider(
            result: .success(response(u1Countdown: 7, u4Countdown: 3))
        )
        let viewModel = makeViewModel(service: monitor, favoritesRepo: routes)

        await viewModel.loadFavorites()

        XCTAssertEqual(viewModel.featuredDeparture?.route.lineName, "U4")
        XCTAssertEqual(viewModel.featuredDeparture?.departure.liveMinutes, 3)
        XCTAssertEqual(viewModel.featuredDeparture?.stopName, "Test")
    }

    func testFeaturedDepartureIgnoresUnavailableRoutesAndMissingDepartures() async {
        let routes = StubFavoritesRepository(routes: [route("U1", "Leopoldau")])
        let viewModel = makeViewModel(
            service: StubMonitorProvider(result: .failure(TestMonitorError.failed)),
            favoritesRepo: routes
        )

        await viewModel.loadFavorites()

        XCTAssertNil(viewModel.featuredDeparture)
    }

    func testFeaturedDepartureIgnoresPastDepartures() async {
        let routes = StubFavoritesRepository(routes: [route("U1", "Leopoldau")])
        let monitor = StubMonitorProvider(
            result: .success(response(u1Countdown: -1, u4Countdown: 3))
        )
        let viewModel = makeViewModel(service: monitor, favoritesRepo: routes)

        await viewModel.loadFavorites()

        XCTAssertNil(viewModel.featuredDeparture)
    }

    func testToggleStationUsesSharedRepositoryAndRefreshesViewState() {
        let stations = StubFavoriteStationsRepository()
        let viewModel = makeViewModel(stationsRepo: stations)
        let favorite = station(1, "A")

        viewModel.toggleStation(favorite)

        XCTAssertTrue(viewModel.containsStation(id: favorite.id))
        XCTAssertEqual(viewModel.stations, [favorite])
    }

    private func makeViewModel(
        service: MonitorProviding? = nil,
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
        response(u1Countdown: countdown, u4Countdown: countdown)
    }

    private func response(u1Countdown: Int, u4Countdown: Int) -> MonitorResponse {
        let line1Departure = Departure(
            departureTime: DepartureTime(countdown: u1Countdown, timePlanned: nil, timeReal: nil)
        )
        let line4Departure = Departure(
            departureTime: DepartureTime(countdown: u4Countdown, timePlanned: nil, timeReal: nil)
        )
        let line1 = Lines(name: "U1", towards: "Leopoldau", departures: Departures(departure: [line1Departure]))
        let line4 = Lines(name: "U4", towards: "Heiligenstadt", departures: Departures(departure: [line4Departure]))
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
    private let updatedAt: Date

    init(
        result: Result<MonitorResponse, Error>,
        isStale: Bool = false,
        updatedAt: Date = .now
    ) {
        self.result = result
        self.isStale = isStale
        self.updatedAt = updatedAt
    }
    func setResult(_ result: Result<MonitorResponse, Error>) { self.result = result }
    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse {
        forceRefreshValues.append(forceRefresh)
        return try result.get()
    }
    func monitorSnapshot(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot {
        MonitorSnapshot(
            response: try await monitor(diva: diva, forceRefresh: forceRefresh),
            updatedAt: updatedAt,
            isStale: isStale
        )
    }
}

private actor BlockingMonitorProvider: MonitorProviding {
    private let responses: [MonitorResponse]
    private var callCount = 0
    private var callWaiters: [Int: [CheckedContinuation<Void, Never>]] = [:]
    private var releaseContinuations: [Int: CheckedContinuation<Void, Never>] = [:]
    private var releasedCalls: Set<Int> = []
    private(set) var forceRefreshValues: [Bool] = []

    init(response: MonitorResponse) {
        responses = [response]
    }

    init(responses: [MonitorResponse]) {
        precondition(!responses.isEmpty)
        self.responses = responses
    }

    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse {
        try await monitorSnapshot(diva: diva, forceRefresh: forceRefresh).response
    }

    func monitorSnapshot(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot {
        callCount += 1
        let call = callCount
        forceRefreshValues.append(forceRefresh)
        resumeCallWaiters()

        await withCheckedContinuation { continuation in
            if releasedCalls.remove(call) != nil {
                continuation.resume()
            } else {
                releaseContinuations[call] = continuation
            }
        }

        return MonitorSnapshot(
            response: responses[min(call - 1, responses.count - 1)],
            updatedAt: .now,
            isStale: false
        )
    }

    func waitForCall(_ expectedCount: Int) async {
        guard callCount < expectedCount else { return }
        await withCheckedContinuation { continuation in
            callWaiters[expectedCount, default: []].append(continuation)
        }
    }

    func releaseCall(_ call: Int) {
        if let continuation = releaseContinuations.removeValue(forKey: call) {
            continuation.resume()
        } else {
            releasedCalls.insert(call)
        }
    }

    private func resumeCallWaiters() {
        let readyCounts = callWaiters.keys.filter { $0 <= callCount }
        for count in readyCounts {
            callWaiters.removeValue(forKey: count)?.forEach { $0.resume() }
        }
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
    func remove(diva: String, lineName: String, destination: String) {
        routes.remove(FavoriteRoute(diva: diva, lineName: lineName, destination: destination))
    }
    func getAll() -> [FavoriteRoute] { Array(routes) }
    func removeAll() { routes = [] }
}

private final class StubFavoriteStationsRepository: FavoriteStationsStoring, @unchecked Sendable {
    var stations: [FavoriteStation]
    init(stations: [FavoriteStation] = []) { self.stations = stations }
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

private final class StubWidgetSync: WidgetSyncing, @unchecked Sendable {
    var lastSaved: [WidgetDepartureData] = []
    var savedBatches: [[WidgetDepartureData]] = []
    func save(_ data: [WidgetDepartureData]) {
        lastSaved = data
        savedBatches.append(data)
    }
}
