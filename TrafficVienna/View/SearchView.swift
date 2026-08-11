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
                        .buttonStyle(PremiumPrimaryButtonStyle())
                }

            case .idle where viewModel.recentStations.isEmpty:
                emptySearchView

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
        .id(viewModel.status)
        .accessibilityIdentifier("search-screen")
        .transition(Motion.stateTransition(reduceMotion: reduceMotion))
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
        .tint(DesignColor.accentText)
        .animation(Motion.quick(reduceMotion: reduceMotion), value: viewModel.status)
        .task(id: viewModel.query) {
            await viewModel.updateSearch()
        }
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }

    private var emptySearchView: some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 56, weight: .regular))
                .foregroundStyle(DesignColor.secondaryText)
                .accessibilityHidden(true)

            Text("Search Vienna")
                .font(.title2.weight(.semibold))
                .foregroundStyle(DesignColor.primaryText)

            Text("Enter a stop name to see live departures.")
                .font(.body)
                .foregroundStyle(DesignColor.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(Spacing.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        SearchView(store: StationStore())
    }
}
