import XCTest
@testable import TrafficVienna

@MainActor
final class DisruptionsViewModelTests: XCTestCase {
    func testLoadDeduplicatesExactFeedEntries() async {
        let duplicate = makeInfo(
            name: "first",
            title: "U3: Bauarbeiten",
            description: "Kein Betrieb",
            lines: ["U3"],
            categoryID: 2
        )
        let repeated = makeInfo(
            name: "second",
            title: duplicate.title,
            description: "Kein Betrieb",
            lines: ["U3"],
            categoryID: 2
        )
        let viewModel = DisruptionsViewModel(
            service: StubTrafficInfoProvider(result: .success([duplicate, repeated]))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.state, DisruptionsViewState.loaded)
        XCTAssertEqual(viewModel.infos.map { $0.id }, ["first"])
    }

    func testServiceAlertsAreTheDefaultAndDriveBadgeCount() async {
        let viewModel = makeLoadedViewModel()

        await viewModel.load()

        XCTAssertEqual(viewModel.selectedKind, .service)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertEqual(viewModel.activeServiceCount, 1)
        XCTAssertEqual(viewModel.badgeCount, 1)
        XCTAssertEqual(viewModel.dashboardStatus, .alerts(count: 1, isSaved: false))
    }

    func testSavedLinesPersonalizeDefaultAlertScopeAndBadge() async {
        let viewModel = makeLoadedViewModel()
        viewModel.updateRelevantLines(["U3"])

        await viewModel.load()

        XCTAssertEqual(viewModel.selectedScope, .relevant)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertEqual(viewModel.badgeCount, 1)

        viewModel.updateRelevantLines(["U1"])

        XCTAssertTrue(viewModel.filteredInfos.isEmpty)
        XCTAssertEqual(viewModel.badgeCount, 0)
        XCTAssertEqual(viewModel.dashboardStatus, .allClear(isSaved: false))
    }

    func testAllViennaScopeShowsAlertsOutsideSavedLines() async {
        let viewModel = makeLoadedViewModel()
        viewModel.updateRelevantLines(["U1"])
        await viewModel.load()

        viewModel.selectScope(.all)

        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertEqual(viewModel.filterSummary, "All Vienna · Service")
    }

    func testEmptySuccessfulFeedShowsAllClearDashboardStatus() async {
        let viewModel = DisruptionsViewModel(
            service: StubTrafficInfoProvider(result: .success([]))
        )

        await viewModel.load()

        XCTAssertEqual(viewModel.dashboardStatus, .allClear(isSaved: false))
    }

    func testSelectingKindClearsIncompatibleCategoryFilter() async {
        let viewModel = makeLoadedViewModel()
        await viewModel.load()
        viewModel.categoryFilter = .metro

        viewModel.selectKind(.accessibility)

        XCTAssertNil(viewModel.categoryFilter)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["accessibility"])
    }

    func testSuccessfulRefreshClearsCategoryFilterMissingFromSelectedKind() async {
        let provider = StubTrafficInfoProvider(result: .success([serviceInfo]))
        let viewModel = DisruptionsViewModel(service: provider)
        await viewModel.load()
        viewModel.categoryFilter = .metro
        await provider.setResult(
            .success([
                makeInfo(
                    name: "bus-service",
                    title: "13A: Umleitung",
                    description: "Geänderte Strecke",
                    lines: ["13A"],
                    categoryID: 2
                )
            ])
        )

        await viewModel.load(force: true)

        XCTAssertNil(viewModel.categoryFilter)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["bus-service"])
    }

    func testSuccessfulRefreshPreservesAvailableCategoryFilter() async {
        let provider = StubTrafficInfoProvider(result: .success([serviceInfo]))
        let viewModel = DisruptionsViewModel(service: provider)
        await viewModel.load()
        viewModel.categoryFilter = .metro
        await provider.setResult(
            .success([
                makeInfo(
                    name: "replacement-metro-service",
                    title: "U4: Bauarbeiten",
                    description: "Kein Betrieb",
                    lines: ["U4"],
                    categoryID: 2
                )
            ])
        )

        await viewModel.load(force: true)

        XCTAssertEqual(viewModel.categoryFilter, .metro)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["replacement-metro-service"])
    }

    func testLineCategoryFilterMatchesAffectedLines() async {
        let viewModel = makeLoadedViewModel()
        await viewModel.load()
        viewModel.categoryFilter = .metro

        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertEqual(viewModel.filterSummary, "All Vienna · Service · U-Bahn")

        viewModel.categoryFilter = .bus
        XCTAssertTrue(viewModel.filteredInfos.isEmpty)
    }

    func testSearchMatchesTitleDescriptionAndLine() async {
        let viewModel = makeLoadedViewModel()
        await viewModel.load()

        viewModel.lineFilter = "bauarbeiten"
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])

        viewModel.lineFilter = "kein betrieb"
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])

        viewModel.lineFilter = "u3"
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
    }

    func testInitialFailureShowsFailedState() async {
        let viewModel = DisruptionsViewModel(
            service: StubTrafficInfoProvider(result: .failure(TestError.unavailable))
        )

        await viewModel.load()

        guard case .failed = viewModel.state else {
            return XCTFail("Expected an explicit failure state")
        }
        XCTAssertTrue(viewModel.infos.isEmpty)
        XCTAssertEqual(viewModel.dashboardStatus, .unavailable)
    }

    func testRefreshFailureKeepsExistingAlertsVisible() async {
        let provider = StubTrafficInfoProvider(result: .success([serviceInfo]))
        let viewModel = DisruptionsViewModel(service: provider)
        await viewModel.load()
        viewModel.categoryFilter = .metro
        await provider.setResult(.failure(TestError.unavailable))

        await viewModel.load(force: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.categoryFilter, .metro)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertNotNil(viewModel.refreshErrorMessage)
        XCTAssertEqual(viewModel.dashboardStatus, .alerts(count: 1, isSaved: true))
    }

    func testStaleSnapshotShowsSavedDataNotice() async {
        let viewModel = DisruptionsViewModel(
            service: StubTrafficInfoProvider(result: .success([serviceInfo]), isStale: true)
        )

        await viewModel.load(force: true)
        viewModel.categoryFilter = .metro
        await viewModel.load(force: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.categoryFilter, .metro)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertNotNil(viewModel.refreshErrorMessage)
        XCTAssertEqual(viewModel.dashboardStatus, .alerts(count: 1, isSaved: true))
    }

    func testQueuedManualRefreshRunsAfterBackgroundLoadAndSuppressesItsFailure() async {
        let provider = ControlledTrafficInfoProvider(
            results: [
                .failure(TestError.unavailable),
                .success([serviceInfo]),
            ]
        )
        let viewModel = DisruptionsViewModel(service: provider)
        let backgroundLoad = Task { await viewModel.load() }
        await provider.waitUntilCallCount(1)

        await viewModel.load(force: true)
        await viewModel.load()
        await provider.releaseCall(1)
        await provider.releaseCall(2)
        await backgroundLoad.value

        let forceRefreshValues = await provider.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false, true])
        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertNil(viewModel.refreshErrorMessage)
        XCTAssertFalse(viewModel.isLoadingRequest)
    }

    func testCancellationDropsQueuedDisruptionsRefresh() async {
        let provider = ControlledTrafficInfoProvider(
            results: [
                .success([serviceInfo]),
                .success([serviceInfo]),
            ]
        )
        let viewModel = DisruptionsViewModel(service: provider)
        let backgroundLoad = Task { await viewModel.load() }
        await provider.waitUntilCallCount(1)
        await viewModel.load(force: true)

        backgroundLoad.cancel()
        await provider.releaseCall(1)
        await provider.releaseCall(2)
        await backgroundLoad.value

        let forceRefreshValues = await provider.forceRefreshValues
        XCTAssertEqual(forceRefreshValues, [false])
        XCTAssertTrue(viewModel.infos.isEmpty)
        XCTAssertFalse(viewModel.isLoadingRequest)
    }

    private func makeLoadedViewModel() -> DisruptionsViewModel {
        DisruptionsViewModel(
            service: StubTrafficInfoProvider(
                result: .success([
                    makeInfo(
                        name: "stop",
                        title: "Betrieb ab Hirschengasse",
                        description: "Haltestelle verlegt",
                        lines: ["57A"],
                        categoryID: 3
                    ),
                    makeInfo(
                        name: "accessibility",
                        title: "Johnstraße",
                        description: "Aufzug außer Betrieb",
                        lines: ["U3"],
                        categoryID: 1
                    ),
                    serviceInfo,
                ])
            )
        )
    }

    private var serviceInfo: TrafficInfo {
        makeInfo(
            name: "service",
            title: "U3: Bauarbeiten",
            description: "Kein Betrieb zwischen zwei Stationen",
            lines: ["U3"],
            categoryID: 2
        )
    }

    private func makeInfo(
        name: String,
        title: String,
        description: String,
        lines: [String],
        categoryID: Int
    ) -> TrafficInfo {
        TrafficInfo(
            name: name,
            title: title,
            description: description,
            priority: "1",
            relatedLines: lines,
            categoryID: categoryID
        )
    }
}

private enum TestError: Error {
    case unavailable
}

private actor StubTrafficInfoProvider: TrafficInfoProviding {
    private var result: Result<[TrafficInfo], Error>
    private let isStale: Bool

    init(result: Result<[TrafficInfo], Error>, isStale: Bool = false) {
        self.result = result
        self.isStale = isStale
    }

    func setResult(_ result: Result<[TrafficInfo], Error>) {
        self.result = result
    }

    func trafficInfoList(forceRefresh: Bool) async throws -> [TrafficInfo] {
        try result.get()
    }

    func trafficInfoSnapshot(forceRefresh: Bool) async throws -> TrafficInfoSnapshot {
        TrafficInfoSnapshot(
            infos: try await trafficInfoList(forceRefresh: forceRefresh),
            updatedAt: .now,
            isStale: isStale
        )
    }
}

private actor ControlledTrafficInfoProvider: TrafficInfoProviding {
    private let results: [Result<[TrafficInfo], Error>]
    private var recordedForceRefreshValues: [Bool] = []
    private var callCountWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] = []
    private var releaseWaiters: [Int: CheckedContinuation<Void, Never>] = [:]
    private var releasedCalls: Set<Int> = []

    init(results: [Result<[TrafficInfo], Error>]) {
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

    func trafficInfoList(forceRefresh: Bool) async throws -> [TrafficInfo] {
        try await trafficInfoSnapshot(forceRefresh: forceRefresh).infos
    }

    func trafficInfoSnapshot(forceRefresh: Bool) async throws -> TrafficInfoSnapshot {
        let call = recordedForceRefreshValues.count + 1
        recordedForceRefreshValues.append(forceRefresh)
        resumeCallCountWaiters()

        if releasedCalls.remove(call) == nil {
            await withCheckedContinuation { continuation in
                releaseWaiters[call] = continuation
            }
        }

        let result = results[min(call - 1, results.count - 1)]
        return TrafficInfoSnapshot(
            infos: try result.get(),
            updatedAt: Date(timeIntervalSince1970: TimeInterval(call)),
            isStale: false
        )
    }

    private func resumeCallCountWaiters() {
        let ready = callCountWaiters.filter { $0.count <= recordedForceRefreshValues.count }
        callCountWaiters.removeAll { $0.count <= recordedForceRefreshValues.count }
        ready.forEach { $0.continuation.resume() }
    }
}
