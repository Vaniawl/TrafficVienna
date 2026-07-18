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
    }

    func testSelectingKindClearsIncompatibleCategoryFilter() async {
        let viewModel = makeLoadedViewModel()
        await viewModel.load()
        viewModel.categoryFilter = .metro

        viewModel.selectKind(.accessibility)

        XCTAssertNil(viewModel.categoryFilter)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["accessibility"])
    }

    func testLineCategoryFilterMatchesAffectedLines() async {
        let viewModel = makeLoadedViewModel()
        await viewModel.load()
        viewModel.categoryFilter = .metro

        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])

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
    }

    func testRefreshFailureKeepsExistingAlertsVisible() async {
        let provider = StubTrafficInfoProvider(result: .success([serviceInfo]))
        let viewModel = DisruptionsViewModel(service: provider)
        await viewModel.load()
        await provider.setResult(.failure(TestError.unavailable))

        await viewModel.load(force: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertNotNil(viewModel.refreshErrorMessage)
    }

    func testStaleSnapshotShowsSavedDataNotice() async {
        let viewModel = DisruptionsViewModel(
            service: StubTrafficInfoProvider(result: .success([serviceInfo]), isStale: true)
        )

        await viewModel.load(force: true)

        XCTAssertEqual(viewModel.state, .loaded)
        XCTAssertEqual(viewModel.filteredInfos.map(\.id), ["service"])
        XCTAssertNotNil(viewModel.refreshErrorMessage)
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
