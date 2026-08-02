import CoreLocation
import XCTest
@testable import TrafficVienna

@MainActor
final class NearbyViewModelTests: XCTestCase {
    func testLoadSortsNearbyStationsAndPublishesSnapshotFreshness() async {
        let location = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let updatedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let stations = [
            Station(id: 2, diva: 202, name: "Farther", lat: 48.2100, lon: 16.3738),
            Station(id: 1, diva: 101, name: "Closer", lat: 48.2083, lon: 16.3738),
        ]
        let monitor = NearbyMonitorProvider(updatedAt: updatedAt, isStale: true)
        let viewModel = NearbyViewModel(
            store: NearbyStationStore(stations: stations),
            location: NearbyLocationProvider(userLocation: location),
            service: monitor
        )

        await viewModel.load(force: true)
        let requestedDivas = await monitor.requestedDivas

        XCTAssertEqual(viewModel.items.map(\.id), [1, 2])
        XCTAssertTrue(viewModel.items.allSatisfy(\.isStale))
        XCTAssertTrue(viewModel.items.allSatisfy { $0.updatedAt == updatedAt })
        XCTAssertTrue(viewModel.items.allSatisfy { !$0.lines.isEmpty })
        XCTAssertEqual(requestedDivas, [101, 202])
    }

    func testLoadWithoutLocationClearsItemsWithoutRequestingNetwork() async {
        let monitor = NearbyMonitorProvider()
        let viewModel = NearbyViewModel(
            store: NearbyStationStore(stations: [
                Station(id: 1, diva: 101, name: "Test", lat: 48.2083, lon: 16.3738),
            ]),
            location: NearbyLocationProvider(userLocation: nil),
            service: monitor
        )

        await viewModel.load()
        let requestedDivas = await monitor.requestedDivas

        XCTAssertTrue(viewModel.items.isEmpty)
        XCTAssertTrue(requestedDivas.isEmpty)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    func testOverlappingLoadsSerializeAndPreserveManualForceRefresh() async {
        let location = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let station = Station(
            id: 1,
            diva: 101,
            name: "Test",
            lat: 48.2083,
            lon: 16.3738
        )
        let monitor = ControlledNearbyMonitorProvider(
            results: [
                .failure(NearbyTestError.unavailable),
                .success(snapshot(lineName: "NEW", updatedAt: Date(timeIntervalSince1970: 2))),
                .success(snapshot(lineName: "DUPLICATE", updatedAt: Date(timeIntervalSince1970: 3))),
            ]
        )
        let viewModel = NearbyViewModel(
            store: NearbyStationStore(stations: [station]),
            location: NearbyLocationProvider(userLocation: location),
            service: monitor
        )
        let completionRecorder = NearbyLoadCompletionRecorder()
        let initialLoad = Task { await viewModel.load() }
        await monitor.waitUntilCallCount(1)

        let overlapsStarted = expectation(description: "Overlapping loads entered")
        overlapsStarted.expectedFulfillmentCount = 2
        let forcedLoad = Task {
            overlapsStarted.fulfill()
            await viewModel.load(force: true)
            await completionRecorder.record("forced")
        }
        let normalLoad = Task {
            overlapsStarted.fulfill()
            await viewModel.load()
            await completionRecorder.record("normal")
        }
        await fulfillment(of: [overlapsStarted], timeout: 1)

        let requestsBeforeRelease = await monitor.requests
        XCTAssertEqual(
            requestsBeforeRelease,
            [NearbyMonitorRequest(diva: 101, forceRefresh: false)]
        )
        let concurrencyBeforeRelease = await monitor.maximumConcurrentRequests
        XCTAssertEqual(concurrencyBeforeRelease, 1)
        XCTAssertTrue(viewModel.isLoading)

        await monitor.releaseCall(1)
        await monitor.waitUntilCallCount(2)

        let requestsAfterFollowUp = await monitor.requests
        XCTAssertEqual(
            requestsAfterFollowUp,
            [
                NearbyMonitorRequest(diva: 101, forceRefresh: false),
                NearbyMonitorRequest(diva: 101, forceRefresh: true),
            ]
        )
        XCTAssertTrue(viewModel.items.first?.lines.isEmpty == true)
        XCTAssertEqual(viewModel.items.first?.failed, false)
        XCTAssertTrue(viewModel.isLoading)
        let completionsBeforeFollowUp = await completionRecorder.completed
        XCTAssertTrue(completionsBeforeFollowUp.isEmpty)

        await monitor.releaseCall(2)
        await monitor.releaseCall(3)
        await initialLoad.value
        await forcedLoad.value
        await normalLoad.value

        XCTAssertEqual(viewModel.items.first?.lines.first?.name, "NEW")
        XCTAssertEqual(viewModel.items.first?.updatedAt, Date(timeIntervalSince1970: 2))
        let finalCompletions = await completionRecorder.completed
        XCTAssertEqual(finalCompletions, ["forced", "normal"])
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    func testCancelledOwnerHandsLatestLocationRequestToWaitingCaller() async {
        let firstLocation = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let secondLocation = CLLocation(latitude: 48.2200, longitude: 16.3738)
        let firstStation = Station(
            id: 1,
            diva: 101,
            name: "First",
            lat: 48.2083,
            lon: 16.3738
        )
        let secondStation = Station(
            id: 2,
            diva: 202,
            name: "Second",
            lat: 48.2201,
            lon: 16.3738
        )
        let location = NearbyLocationProvider(userLocation: firstLocation)
        let monitor = ControlledNearbyMonitorProvider(
            results: [
                .success(snapshot(lineName: "OLD", updatedAt: Date(timeIntervalSince1970: 1))),
                .success(snapshot(lineName: "CURRENT", updatedAt: Date(timeIntervalSince1970: 2))),
                .success(snapshot(lineName: "DUPLICATE", updatedAt: Date(timeIntervalSince1970: 3))),
            ]
        )
        let viewModel = NearbyViewModel(
            store: NearbyStationStore(stations: [firstStation, secondStation]),
            location: location,
            service: monitor
        )
        let firstLoad = Task { await viewModel.load() }
        await monitor.waitUntilCallCount(1)

        location.userLocation = secondLocation
        let replacementStarted = expectation(description: "Replacement load entered")
        let replacementLoad = Task {
            replacementStarted.fulfill()
            await viewModel.load()
        }
        await fulfillment(of: [replacementStarted], timeout: 1)

        let requestsBeforeCancellation = await monitor.requests
        XCTAssertEqual(
            requestsBeforeCancellation,
            [NearbyMonitorRequest(diva: 101, forceRefresh: false)]
        )

        firstLoad.cancel()
        await monitor.releaseCall(1)
        await monitor.waitUntilCallCount(2)

        let requestsAfterHandoff = await monitor.requests
        XCTAssertEqual(
            requestsAfterHandoff,
            [
                NearbyMonitorRequest(diva: 101, forceRefresh: false),
                NearbyMonitorRequest(diva: 202, forceRefresh: false),
            ]
        )
        let maximumConcurrentRequests = await monitor.maximumConcurrentRequests
        XCTAssertEqual(maximumConcurrentRequests, 1)

        await monitor.releaseCall(2)
        await monitor.releaseCall(3)
        await firstLoad.value
        await replacementLoad.value

        XCTAssertEqual(viewModel.items.map(\.id), [2])
        XCTAssertEqual(viewModel.items.first?.lines.first?.name, "CURRENT")
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    func testCancelledRefreshDoesNotMarkExistingNearbyDataFailed() async {
        let location = CLLocation(latitude: 48.2082, longitude: 16.3738)
        let station = Station(
            id: 1,
            diva: 101,
            name: "Test",
            lat: 48.2083,
            lon: 16.3738
        )
        let monitor = ControlledNearbyMonitorProvider(
            results: [
                .success(snapshot(lineName: "U1", updatedAt: Date(timeIntervalSince1970: 1))),
                .failure(CancellationError()),
            ]
        )
        let viewModel = NearbyViewModel(
            store: NearbyStationStore(stations: [station]),
            location: NearbyLocationProvider(userLocation: location),
            service: monitor
        )
        await monitor.releaseCall(1)
        await viewModel.load()

        let refresh = Task { await viewModel.load(force: true) }
        await monitor.waitUntilCallCount(2)
        XCTAssertTrue(viewModel.isRefreshing)

        refresh.cancel()
        await monitor.releaseCall(2)
        await refresh.value

        XCTAssertEqual(viewModel.items.first?.lines.first?.name, "U1")
        XCTAssertEqual(viewModel.items.first?.failed, false)
        XCTAssertEqual(viewModel.items.first?.isStale, false)
        XCTAssertFalse(viewModel.isLoading)
        XCTAssertFalse(viewModel.isRefreshing)
    }

    private func snapshot(lineName: String, updatedAt: Date) -> MonitorSnapshot {
        let line = Lines(
            name: lineName,
            towards: "Destination",
            departures: Departures(departure: [
                Departure(
                    departureTime: DepartureTime(
                        countdown: 3,
                        timePlanned: nil,
                        timeReal: nil
                    )
                ),
            ])
        )
        let stop = LocationStop(
            properties: Properties(title: "Test", attributes: Attributes(rbl: 1)),
            geometry: nil
        )
        return MonitorSnapshot(
            response: MonitorResponse(
                data: DataBlock(
                    monitors: [Monitor(locationStop: stop, lines: [line])],
                    trafficInfos: nil
                )
            ),
            updatedAt: updatedAt,
            isStale: false
        )
    }
}

@MainActor
private final class NearbyLocationProvider: LocationProviding {
    var userLocation: CLLocation?

    init(userLocation: CLLocation?) {
        self.userLocation = userLocation
    }
}

private enum NearbyTestError: Error {
    case unavailable
}

private actor NearbyLoadCompletionRecorder {
    private(set) var completed: Set<String> = []

    func record(_ label: String) {
        completed.insert(label)
    }
}

nonisolated private struct NearbyMonitorRequest: Equatable, Sendable {
    let diva: Int
    let forceRefresh: Bool
}

private actor ControlledNearbyMonitorProvider: MonitorProviding {
    private let results: [Result<MonitorSnapshot, Error>]
    private(set) var requests: [NearbyMonitorRequest] = []
    private(set) var maximumConcurrentRequests = 0
    private var activeRequestCount = 0
    private var callCountWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var releaseWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private var releasedCalls: Set<Int> = []

    init(results: [Result<MonitorSnapshot, Error>]) {
        precondition(!results.isEmpty)
        self.results = results
    }

    func waitUntilCallCount(_ count: Int) async {
        guard requests.count < count else { return }
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
        let call = requests.count + 1
        requests.append(NearbyMonitorRequest(diva: diva, forceRefresh: forceRefresh))
        activeRequestCount += 1
        maximumConcurrentRequests = max(maximumConcurrentRequests, activeRequestCount)
        resumeCallCountWaiters()
        defer { activeRequestCount -= 1 }

        if releasedCalls.remove(call) == nil {
            await withCheckedContinuation { continuation in
                releaseWaiters[call] = continuation
            }
        }

        return try results[min(call - 1, results.count - 1)].get()
    }

    private func resumeCallCountWaiters() {
        let ready = callCountWaiters.filter { $0.count <= requests.count }
        callCountWaiters.removeAll { $0.count <= requests.count }
        ready.forEach { $0.continuation.resume() }
    }
}

@MainActor
private final class NearbyStationStore: StationStoring {
    let stations: [Station]
    let loadState: StationCatalogState = .loaded

    init(stations: [Station]) {
        self.stations = stations
    }

    func diva(forExact name: String) -> Int? {
        stations.first { $0.name == name }?.diva
    }

    func stationsSuggestion(matching query: String) -> [Station] {
        stations.filter { $0.name.localizedStandardContains(query) }
    }

    func reload() {}

    func stations(near location: CLLocation, radiusInMeters radius: Double) -> [Station] {
        stations.filter { station in
            CLLocation(latitude: station.lat, longitude: station.lon).distance(from: location) <= radius
        }
    }
}

private actor NearbyMonitorProvider: MonitorProviding {
    private(set) var requestedDivas: [Int] = []
    private let updatedAt: Date
    private let isStale: Bool

    init(updatedAt: Date = .now, isStale: Bool = false) {
        self.updatedAt = updatedAt
        self.isStale = isStale
    }

    func monitor(diva: Int, forceRefresh: Bool) async throws -> MonitorResponse {
        try await monitorSnapshot(diva: diva, forceRefresh: forceRefresh).response
    }

    func monitorSnapshot(diva: Int, forceRefresh: Bool) async throws -> MonitorSnapshot {
        requestedDivas.append(diva)
        let line = Lines(
            name: "U1",
            towards: "Leopoldau",
            departures: Departures(departure: [
                Departure(departureTime: DepartureTime(countdown: 3, timePlanned: nil, timeReal: nil)),
            ])
        )
        let stop = LocationStop(
            properties: Properties(title: "Test", attributes: Attributes(rbl: diva)),
            geometry: nil
        )
        return MonitorSnapshot(
            response: MonitorResponse(
                data: DataBlock(monitors: [Monitor(locationStop: stop, lines: [line])], trafficInfos: nil)
            ),
            updatedAt: updatedAt,
            isStale: isStale
        )
    }
}
