import SwiftUI

struct SearchView: View {
    @State private var viewModel: SearchViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        store: StationStoring,
        recentSearches: RecentSearchesStoring = RecentSearchesStore()
    ) {
        _viewModel = State(
            initialValue: SearchViewModel(
                stationStore: store,
                recentSearches: recentSearches
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
            switch viewModel.status {
            case .loadingCatalog, .searching:
                ProgressView(
                    viewModel.status == .loadingCatalog
                        ? "Loading stops…"
                        : "Searching…"
                )
                .controlSize(.large)

            case .unavailable:
                ContentUnavailableView {
                    Label("Search unavailable", systemImage: "exclamationmark.magnifyingglass")
                } description: {
                    Text("The stop catalogue could not be loaded.")
                } actions: {
                    Button("Try again", systemImage: "arrow.clockwise", action: retry)
                        .buttonStyle(.borderedProminent)
                }

            case .idle where viewModel.recentStations.isEmpty:
                ContentUnavailableView(
                    "Search Vienna",
                    systemImage: "magnifyingglass",
                    description: Text("Enter a stop name to see live departures.")
                )

            case .idle:
                RecentStationsList(
                    stations: viewModel.recentStations,
                    onClear: viewModel.clearRecents
                )

            case .noResults:
                ContentUnavailableView.search

            case .results:
                SearchResultsList(stations: viewModel.results)
            }
        }
        .navigationTitle("Search")
        .navigationDestination(for: Station.self) { station in
            StationDetailView(station: station)
                .onAppear {
                    viewModel.record(station)
                }
        }
        .searchable(
            text: $viewModel.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Enter stop name…"
        )
        .scrollDismissesKeyboard(.immediately)
        .background(DesignColor.background)
        .animation(reduceMotion ? nil : .snappy, value: viewModel.status)
        .task(id: viewModel.query) {
            await viewModel.updateSearch()
        }
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(store: StationStore())
    }
}
