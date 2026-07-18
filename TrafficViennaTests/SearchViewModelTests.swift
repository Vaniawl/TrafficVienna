import XCTest
@testable import TrafficVienna

@MainActor
final class SearchViewModelTests: XCTestCase {
    func testEmptyQueryShowsIdleStateWithoutSearching() async {
        let stationStore = StubStationStore(stations: sampleStations)
        let viewModel = makeViewModel(stationStore: stationStore)

        viewModel.query = "   "
        await viewModel.updateSearch()

        XCTAssertEqual(viewModel.status, .idle)
        XCTAssertTrue(viewModel.results.isEmpty)
        XCTAssertTrue(stationStore.requestedQueries.isEmpty)
    }

    func testFailedCatalogueStartsUnavailable() {
        let viewModel = makeViewModel(
            stationStore: StubStationStore(
                stations: [],
                loadState: .failed
            )
        )

        XCTAssertEqual(viewModel.status, .unavailable)
    }

    func testSearchTrimsQueryAndReturnsMatchingStations() async {
        let stationStore = StubStationStore(stations: sampleStations)
        let viewModel = makeViewModel(stationStore: stationStore)

        viewModel.query = "  Karlsplatz  "
        await viewModel.updateSearch()

        XCTAssertEqual(viewModel.status, .results)
        XCTAssertEqual(viewModel.results.map(\.name), ["Karlsplatz"])
        XCTAssertEqual(stationStore.requestedQueries, ["Karlsplatz"])
    }

    func testSearchShowsNoResultsState() async {
        let viewModel = makeViewModel(
            stationStore: StubStationStore(stations: sampleStations)
        )

        viewModel.query = "Not a Vienna stop"
        await viewModel.updateSearch()

        XCTAssertEqual(viewModel.status, .noResults)
        XCTAssertTrue(viewModel.results.isEmpty)
    }

    func testCancelledSearchCannotReplaceNewerResults() async {
        let stationStore = StubStationStore(stations: sampleStations)
        let viewModel = SearchViewModel(
            stationStore: stationStore,
            recentSearches: StubRecentSearchesStore(),
            debounceDuration: .seconds(1)
        )

        viewModel.query = "Karlsplatz"
        let oldSearch = Task { await viewModel.updateSearch() }
        await Task.yield()
        oldSearch.cancel()

        viewModel.query = "Praterstern"
        await viewModel.retry()
        await oldSearch.value

        XCTAssertEqual(viewModel.results.map(\.name), ["Praterstern"])
        XCTAssertEqual(viewModel.status, .results)
    }

    func testRetryReloadsFailedCatalogueAndRepeatsSearch() async {
        let stationStore = StubStationStore(
            stations: sampleStations,
            loadState: .failed,
            reloadState: .loaded
        )
        let viewModel = makeViewModel(stationStore: stationStore)
        viewModel.query = "Karlsplatz"

        await viewModel.updateSearch()
        XCTAssertEqual(viewModel.status, .unavailable)

        await viewModel.retry()

        XCTAssertEqual(stationStore.reloadCount, 1)
        XCTAssertEqual(viewModel.status, .results)
        XCTAssertEqual(viewModel.results.map(\.name), ["Karlsplatz"])
    }

    func testRecentStationsFollowStoredOrderAndCanBeCleared() {
        let recentSearches = StubRecentSearchesStore(ids: [2, 1])
        let viewModel = SearchViewModel(
            stationStore: StubStationStore(stations: sampleStations),
            recentSearches: recentSearches,
            debounceDuration: .zero
        )

        XCTAssertEqual(viewModel.recentStations.map(\.id), [2, 1])

        viewModel.record(sampleStations[0])
        XCTAssertEqual(viewModel.recentStations.map(\.id), [1, 2])

        viewModel.clearRecents()
        XCTAssertTrue(viewModel.recentStations.isEmpty)
        XCTAssertTrue(recentSearches.ids.isEmpty)
    }

    func testResultLimitIsApplied() async {
        let viewModel = SearchViewModel(
            stationStore: StubStationStore(stations: sampleStations),
            recentSearches: StubRecentSearchesStore(),
            resultLimit: 1,
            debounceDuration: .zero
        )

        viewModel.query = "a"
        await viewModel.updateSearch()

        XCTAssertEqual(viewModel.results.count, 1)
    }

    private func makeViewModel(stationStore: StationStoring) -> SearchViewModel {
        SearchViewModel(
            stationStore: stationStore,
            recentSearches: StubRecentSearchesStore(),
            debounceDuration: .zero
        )
    }

    private var sampleStations: [Station] {
        [
            Station(
                id: 1,
                diva: 60200644,
                name: "Karlsplatz",
                lat: 48.2003,
                lon: 16.3695
            ),
            Station(
                id: 2,
                diva: 60201040,
                name: "Praterstern",
                lat: 48.2181,
                lon: 16.3915
            )
        ]
    }
}
