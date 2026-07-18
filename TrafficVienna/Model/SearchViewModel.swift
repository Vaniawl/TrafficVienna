import Foundation
import Observation

@MainActor
@Observable
final class SearchViewModel {
    var query = ""
    private(set) var status: SearchStatus
    private(set) var results: [Station] = []
    private(set) var recentStations: [Station] = []

    private let stationStore: StationStoring
    private let recentSearches: RecentSearchesStoring
    private let resultLimit: Int
    private let debounceDuration: Duration

    init(
        stationStore: StationStoring,
        recentSearches: RecentSearchesStoring,
        resultLimit: Int = 50,
        debounceDuration: Duration = .milliseconds(160)
    ) {
        self.stationStore = stationStore
        self.recentSearches = recentSearches
        self.resultLimit = resultLimit
        self.debounceDuration = debounceDuration
        switch stationStore.loadState {
        case .loading:
            status = .loadingCatalog
        case .loaded:
            status = .idle
        case .failed:
            status = .unavailable
        }
        refreshRecents()
    }

    func updateSearch() async {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            results = []
            status = catalogReadyStatus
            return
        }

        guard stationStore.loadState == .loaded else {
            results = []
            status = stationStore.loadState == .loading ? .loadingCatalog : .unavailable
            return
        }

        status = .searching

        do {
            try await Task.sleep(for: debounceDuration)
            try Task.checkCancellation()
        } catch {
            return
        }

        results = Array(
            stationStore.stationsSuggestion(matching: trimmedQuery).prefix(resultLimit)
        )
        status = results.isEmpty ? .noResults : .results
    }

    func retry() async {
        stationStore.reload()
        refreshRecents()
        await updateSearch()
    }

    func record(_ station: Station) {
        recentSearches.record(station.id)
        refreshRecents()
    }

    func clearRecents() {
        recentSearches.clear()
        recentStations = []
    }

    private var catalogReadyStatus: SearchStatus {
        switch stationStore.loadState {
        case .loading:
            .loadingCatalog
        case .loaded:
            .idle
        case .failed:
            .unavailable
        }
    }

    private func refreshRecents() {
        recentStations = recentSearches.ids.compactMap { id in
            stationStore.stations.first { $0.id == id }
        }
    }
}
