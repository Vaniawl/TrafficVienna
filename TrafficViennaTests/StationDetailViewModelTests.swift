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

    func testRefreshClearsCategoryFilterThatIsNoLongerAvailable() async {
        let monitor = DetailMonitorProvider(
            result: .success(responseWithU1And13A())
        )
        let viewModel = makeViewModel(service: monitor)
        await viewModel.load()
        viewModel.categoryFilter = .bus
        await monitor.setResult(.success(responseWithMergedU1()))

        await viewModel.load(forceRefresh: true)

        XCTAssertNil(viewModel.categoryFilter)
        XCTAssertEqual(viewModel.groups.map(\.line), ["U1"])
    }

    func testRefreshPreservesCategoryFilterThatIsStillAvailable() async {
        let monitor = DetailMonitorProvider(
            result: .success(responseWithU1And13A())
        )
        let viewModel = makeViewModel(service: monitor)
        await viewModel.load()
        viewModel.categoryFilter = .bus

        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.categoryFilter, .bus)
        XCTAssertEqual(viewModel.groups.map(\.line), ["13A"])
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
        viewModel.categoryFilter = .metro
        await monitor.setResult(.failure(DetailTestError.failed))

        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.categoryFilter, .metro)
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

    func testQueuedManualRefreshRunsAfterBackgroundLoadAndSuppressesItsFailure() async {
        let monitor = ControlledDetailMonitorProvider(
            results: [
                .failure(DetailTestError.failed),
                .success(responseWithMergedU1()),
            ]
        )
        let viewModel = StationDetailViewModel(
            station: Station(id: 1, diva: 123, name: "Test", lat: 0, lon: 0),
            service: monitor,
            favoritesRepo: DetailRoutesRepository(),
            stationsRepo: DetailStationsRepository(),
            liveActivityStarter: DetailLiveActivityStarter(isAvailable: true),
            reminderClient: .test
        )
        let backgroundLoad = Task { await viewModel.load() }
        await monitor.waitUntilCallCount(1)

        await viewModel.load(forceRefresh: true)
        await viewModel.load()
        await monitor.releaseCall(1)
        await monitor.releaseCall(2)
        await backgroundLoad.value

        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false, true])
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.groups.first?.minutes, [2, 5, 8])
        XCTAssertNil(viewModel.refreshErrorMessage)
        XCTAssertFalse(viewModel.isLoadingRequest)
    }

    func testCancellationDropsQueuedStationDetailRefresh() async {
        let monitor = ControlledDetailMonitorProvider(
            results: [
                .success(responseWithMergedU1()),
                .success(responseWithMergedU1()),
            ]
        )
        let viewModel = StationDetailViewModel(
            station: Station(id: 1, diva: 123, name: "Test", lat: 0, lon: 0),
            service: monitor,
            favoritesRepo: DetailRoutesRepository(),
            stationsRepo: DetailStationsRepository(),
            liveActivityStarter: DetailLiveActivityStarter(isAvailable: true),
            reminderClient: .test
        )
        let backgroundLoad = Task { await viewModel.load() }
        await monitor.waitUntilCallCount(1)
        await viewModel.load(forceRefresh: true)

        backgroundLoad.cancel()
        await monitor.releaseCall(1)
        await monitor.releaseCall(2)
        await backgroundLoad.value

        let forceRefreshValues = await monitor.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false])
        XCTAssertNil(viewModel.lastUpdated)
        XCTAssertTrue(viewModel.groups.isEmpty)
        XCTAssertFalse(viewModel.isLoadingRequest)
    }

    func testStaleSnapshotKeepsOriginalTimestampAndShowsSavedDataNotice() async {
        let updatedAt = Date.now.addingTimeInterval(-30)
        let monitor = DetailMonitorProvider(
            result: .success(responseWithMergedU1()),
            isStale: true,
            updatedAt: updatedAt
        )
        let viewModel = makeViewModel(service: monitor)

        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.lastUpdated, updatedAt)
        XCTAssertNotNil(viewModel.refreshErrorMessage)
    }

    func testStaleFallbackDeparturesExpireFromSourceTimestamp() async {
        let monitor = DetailMonitorProvider(
            result: .success(responseWithMergedU1()),
            isStale: true,
            updatedAt: Date.now.addingTimeInterval(-10 * 60)
        )
        let viewModel = makeViewModel(service: monitor)

        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(viewModel.state, .empty)
        XCTAssertTrue(viewModel.groups.isEmpty)
        XCTAssertNotNil(viewModel.refreshErrorMessage)
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

    func testRouteFavouriteToggleReconcilesExternallyChangedRepositoryState() async {
        let routes = DetailRoutesRepository()
        let viewModel = makeViewModel(favoritesRepo: routes)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        viewModel.toggleFavorite(group)
        routes.toggle(diva: "123", lineName: group.line, destination: group.destination)
        viewModel.toggleFavorite(group)

        XCTAssertTrue(
            routes.isFavorite(diva: "123", lineName: group.line, destination: group.destination)
        )
        XCTAssertTrue(viewModel.isFavorite(group))
    }

    func testRouteFavouriteReloadReflectsExternalRemoval() async {
        let routes = DetailRoutesRepository()
        let viewModel = makeViewModel(favoritesRepo: routes)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        viewModel.toggleFavorite(group)
        routes.toggle(diva: "123", lineName: group.line, destination: group.destination)
        viewModel.reloadRouteFavorites()

        XCTAssertFalse(viewModel.isFavorite(group))
    }

    func testStationFavouriteReloadReflectsExternalChange() {
        let stations = DetailStationsRepository()
        let viewModel = makeViewModel(stationsRepo: stations)

        stations.toggle(FavoriteStation(viewModel.station))
        viewModel.reloadStationFavorite()

        XCTAssertTrue(viewModel.isStationFavorited)
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

    func testSelectingTrackedDepartureAgainStopsLiveActivity() async {
        let starter = DetailLiveActivityStarter(isAvailable: true)
        let viewModel = makeViewModel(liveActivityStarter: starter)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        viewModel.startTracking(group)
        viewModel.startTracking(group)

        XCTAssertNil(viewModel.trackedDepartureID)
        XCTAssertEqual(starter.stopCount, 1)
    }

    func testStopDuringRefreshCannotRestorePendingSystemActivity() async {
        let activeID = StationDepartureID(
            line: "U1",
            destination: "Leopoldau"
        )
        let starter = DetailLiveActivityStarter(
            isAvailable: true,
            activeDepartureID: activeID
        )
        let monitor = ControlledDetailMonitorProvider(
            results: [
                .success(responseWithMergedU1()),
                .success(responseWithMergedU1()),
            ]
        )
        let viewModel = StationDetailViewModel(
            station: Station(id: 1, diva: 123, name: "Test", lat: 0, lon: 0),
            service: monitor,
            favoritesRepo: DetailRoutesRepository(),
            stationsRepo: DetailStationsRepository(),
            liveActivityStarter: starter,
            reminderClient: .test
        )
        let initialLoad = Task { await viewModel.load() }
        await monitor.waitUntilCallCount(1)
        await monitor.releaseCall(1)
        await initialLoad.value
        guard let group = viewModel.groups.first else {
            return XCTFail("Missing group")
        }
        XCTAssertEqual(starter.updateCount, 1)

        let refresh = Task { await viewModel.load(forceRefresh: true) }
        await monitor.waitUntilCallCount(2)
        viewModel.startTracking(group)
        await monitor.releaseCall(2)
        await refresh.value

        XCTAssertNil(viewModel.trackedDepartureID)
        XCTAssertEqual(starter.stopCount, 1)
        XCTAssertEqual(starter.updateCount, 1)
    }

    func testRefreshClearsTrackingAfterSystemActivityEnds() async {
        let activeID = StationDepartureID(
            line: "U1",
            destination: "Leopoldau"
        )
        let starter = DetailLiveActivityStarter(
            isAvailable: true,
            activeDepartureID: activeID
        )
        let viewModel = makeViewModel(liveActivityStarter: starter)
        await viewModel.load()
        XCTAssertEqual(viewModel.trackedDepartureID, activeID)
        XCTAssertEqual(starter.updateCount, 1)

        starter.activeDepartureID = nil
        await viewModel.load(forceRefresh: true)

        XCTAssertNil(viewModel.trackedDepartureID)
        XCTAssertEqual(starter.updateCount, 1)
    }

    func testReloadUpdatesTrackedLiveActivity() async {
        let starter = DetailLiveActivityStarter(isAvailable: true)
        let viewModel = makeViewModel(liveActivityStarter: starter)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }
        viewModel.startTracking(group)

        await viewModel.load(forceRefresh: true)

        XCTAssertEqual(starter.updatedLine, "U1")
        XCTAssertEqual(starter.updatedMinutes, 2)
    }

    func testLoadRestoresMatchingLiveActivityFromSystemState() async {
        let activeID = StationDepartureID(
            line: "U1",
            destination: "Leopoldau"
        )
        let starter = DetailLiveActivityStarter(
            isAvailable: true,
            activeDepartureID: activeID
        )
        let viewModel = makeViewModel(liveActivityStarter: starter)

        await viewModel.load()

        XCTAssertEqual(viewModel.trackedDepartureID, activeID)
        XCTAssertEqual(starter.updatedLine, "U1")
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

    func testSchedulingReminderShowsConfirmation() async {
        let fireDate = Date(timeIntervalSince1970: 1_800_000_000)
        let client = DepartureReminderClient(
            permission: { .enabled },
            schedule: { request in
                ScheduledDepartureReminder(
                    id: "departure.test",
                    line: request.line,
                    destination: request.destination,
                    stop: request.stop,
                    fireDate: fireDate,
                    departureDate: fireDate.addingTimeInterval(180)
                )
            },
            scheduled: { [] },
            cancel: { _ in },
            cancelAll: {}
        )
        let viewModel = makeViewModel(reminderClient: client)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        await viewModel.scheduleReminder(group)

        XCTAssertEqual(viewModel.notice?.title, String(localized: "Reminder set"))
        XCTAssertEqual(viewModel.notice?.offersSettings, false)
    }

    func testDeniedReminderOffersNotificationSettings() async {
        let client = DepartureReminderClient(
            permission: { .disabled },
            schedule: { _ in throw DepartureReminderError.notificationsDisabled },
            scheduled: { [] },
            cancel: { _ in },
            cancelAll: {}
        )
        let viewModel = makeViewModel(reminderClient: client)
        await viewModel.load()
        guard let group = viewModel.groups.first else { return XCTFail("Missing group") }

        await viewModel.scheduleReminder(group)

        XCTAssertEqual(viewModel.notice?.title, String(localized: "Departure reminder"))
        XCTAssertEqual(viewModel.notice?.offersSettings, true)
    }

    func testUnexpectedReminderFailureUsesSafeUserMessage() async {
        let client = DepartureReminderClient(
            permission: { .enabled },
            schedule: { _ in throw DetailTestError.failed },
            scheduled: { [] },
            cancel: { _ in },
            cancelAll: {}
        )
        let viewModel = makeViewModel(reminderClient: client)
        await viewModel.load()
        guard let group = viewModel.groups.first else {
            return XCTFail("Missing group")
        }

        await viewModel.scheduleReminder(group)

        XCTAssertEqual(
            viewModel.notice?.message,
            String(localized: "The reminder could not be scheduled. Please try again.")
        )
    }

    func testStaleDeparturesCannotStartReminderOrLiveActivity() async {
        let starter = DetailLiveActivityStarter(isAvailable: true)
        let recorder = ReminderInvocationRecorder()
        let client = DepartureReminderClient(
            permission: { .enabled },
            schedule: { _ in
                await recorder.recordCall()
                throw DepartureReminderError.departureTooSoon
            },
            scheduled: { [] },
            cancel: { _ in },
            cancelAll: {}
        )
        let monitor = DetailMonitorProvider(
            result: .success(responseWithMergedU1()),
            isStale: true
        )
        let viewModel = makeViewModel(
            service: monitor,
            liveActivityStarter: starter,
            reminderClient: client
        )
        await viewModel.load()
        guard let group = viewModel.groups.first else {
            return XCTFail("Missing group")
        }

        await viewModel.scheduleReminder(group)
        viewModel.startTracking(group)

        let reminderWasScheduled = await recorder.wasCalled
        XCTAssertFalse(reminderWasScheduled)
        XCTAssertNil(starter.startedLine)
        XCTAssertEqual(
            viewModel.notice?.title,
            String(localized: "Live departures required")
        )
    }

    func testStaleDeparturesStillAllowExistingActivityToStop() async {
        let activeID = StationDepartureID(
            line: "U1",
            destination: "Leopoldau"
        )
        let starter = DetailLiveActivityStarter(
            isAvailable: true,
            activeDepartureID: activeID
        )
        let monitor = DetailMonitorProvider(
            result: .success(responseWithMergedU1()),
            isStale: true
        )
        let viewModel = makeViewModel(
            service: monitor,
            liveActivityStarter: starter
        )
        await viewModel.load()
        guard let group = viewModel.groups.first else {
            return XCTFail("Missing group")
        }

        viewModel.startTracking(group)

        XCTAssertNil(viewModel.trackedDepartureID)
        XCTAssertEqual(starter.stopCount, 1)
    }

    private func makeViewModel(
        station: Station = Station(id: 1, diva: 123, name: "Test", lat: 0, lon: 0),
        response: MonitorResponse? = nil,
        result: Result<MonitorResponse, Error>? = nil,
        service: DetailMonitorProvider? = nil,
        favoritesRepo: DetailRoutesRepository = DetailRoutesRepository(),
        stationsRepo: DetailStationsRepository = DetailStationsRepository(),
        liveActivityStarter: DetailLiveActivityStarter? = nil,
        reminderClient: DepartureReminderClient = .test
    ) -> StationDetailViewModel {
        let resolvedResult = result ?? .success(response ?? responseWithMergedU1())
        return StationDetailViewModel(
            station: station,
            service: service ?? DetailMonitorProvider(result: resolvedResult),
            favoritesRepo: favoritesRepo,
            stationsRepo: stationsRepo,
            liveActivityStarter: liveActivityStarter ?? DetailLiveActivityStarter(isAvailable: true),
            reminderClient: reminderClient
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

    private func responseWithU1And13A() -> MonitorResponse {
        let u1 = Lines(
            name: "U1",
            towards: "Leopoldau",
            departures: Departures(
                departure: [
                    Departure(
                        departureTime: DepartureTime(
                            countdown: 2,
                            timePlanned: nil,
                            timeReal: "live"
                        )
                    ),
                ]
            )
        )
        let bus = Lines(
            name: "13A",
            towards: "Hauptbahnhof",
            departures: Departures(
                departure: [
                    Departure(
                        departureTime: DepartureTime(
                            countdown: 4,
                            timePlanned: nil,
                            timeReal: nil
                        )
                    ),
                ]
            )
        )
        return MonitorResponse(
            data: DataBlock(
                monitors: [monitor(lines: [u1, bus])],
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
    private let isStale: Bool
    private let updatedAt: Date
    init(
        result: Result<MonitorResponse, Error>,
        delay: Duration = .zero,
        isStale: Bool = false,
        updatedAt: Date = .now
    ) {
        self.result = result
        self.delay = delay
        self.isStale = isStale
        self.updatedAt = updatedAt
    }
    func setResult(_ result: Result<MonitorResponse, Error>) { self.result = result }
    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse {
        if delay != .zero { try? await Task.sleep(for: delay) }
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

private actor ControlledDetailMonitorProvider: MonitorProviding {
    private let results: [Result<MonitorResponse, Error>]
    private var recordedForceRefreshValues: [Bool] = []
    private var callCountWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var releaseWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private var releasedCalls: Set<Int> = []

    init(results: [Result<MonitorResponse, Error>]) {
        self.results = results
    }

    var forceRefreshValues: [Bool] {
        recordedForceRefreshValues
    }

    func waitUntilCallCount(_ count: Int) async {
        guard recordedForceRefreshValues.count < count else { return }
        await withCheckedContinuation { continuation in
            callCountWaiters.append((count, continuation))
        }
    }

    func releaseCall(_ call: Int) {
        if let continuation = releaseWaiters.removeValue(forKey: call) {
            continuation.resume()
        } else {
            releasedCalls.insert(call)
        }
    }

    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse {
        try await monitorSnapshot(diva: diva, forceRefresh: forceRefresh).response
    }

    func monitorSnapshot(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot {
        let call = recordedForceRefreshValues.count + 1
        recordedForceRefreshValues.append(forceRefresh)
        resumeCallCountWaiters()

        if releasedCalls.remove(call) == nil {
            await withCheckedContinuation { continuation in
                releaseWaiters[call] = continuation
            }
        }

        let result = results[min(call - 1, results.count - 1)]
        return MonitorSnapshot(
            response: try result.get(),
            updatedAt: .now,
            isStale: false
        )
    }

    private func resumeCallCountWaiters() {
        let ready = callCountWaiters.filter { $0.count <= recordedForceRefreshValues.count }
        callCountWaiters.removeAll { $0.count <= recordedForceRefreshValues.count }
        ready.forEach { $0.continuation.resume() }
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
    func remove(diva: String, lineName: String, destination: String) {
        routes.remove(FavoriteRoute(diva: diva, lineName: lineName, destination: destination))
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
    var activeDepartureID: StationDepartureID?
    var startedLine: String?
    var updatedLine: String?
    var updatedMinutes: Int?
    var updateCount = 0
    var stopCount = 0
    init(
        isAvailable: Bool,
        shouldThrow: Bool = false,
        activeDepartureID: StationDepartureID? = nil
    ) {
        self.isAvailable = isAvailable
        self.shouldThrow = shouldThrow
        self.activeDepartureID = activeDepartureID
    }
    func start(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) throws {
        if shouldThrow { throw DetailTestError.failed }
        startedLine = line
        activeDepartureID = StationDepartureID(
            line: line,
            destination: destination
        )
    }
    func update(line: String, destination: String, stop: String, minutes: Int, isLive: Bool) {
        updateCount += 1
        updatedLine = line
        updatedMinutes = minutes
    }
    func activeDepartureID(for stop: String) -> StationDepartureID? {
        activeDepartureID
    }
    func stopAll() {
        stopCount += 1
    }
}

private actor ReminderInvocationRecorder {
    private(set) var wasCalled = false

    func recordCall() {
        wasCalled = true
    }
}

private extension DepartureReminderClient {
    nonisolated static let test = DepartureReminderClient(
        permission: { .notDetermined },
        schedule: { _ in throw DepartureReminderError.departureTooSoon },
        scheduled: { [] },
        cancel: { _ in },
        cancelAll: {}
    )
}
