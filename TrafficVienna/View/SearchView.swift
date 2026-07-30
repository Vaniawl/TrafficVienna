import CoreLocation
import SwiftUI

struct SearchView: View {
    @ObservedObject private var store: StationStore
    @ObservedObject private var locationManager: LocationManager
    @Bindable private var favoritesViewModel: FavoritesListViewModel
    @State private var viewModel: SearchViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        store: StationStore,
        locationManager: LocationManager,
        favoritesViewModel: FavoritesListViewModel,
        recentSearches: RecentSearchesStoring = RecentSearchesStore()
    ) {
        _store = ObservedObject(wrappedValue: store)
        _locationManager = ObservedObject(wrappedValue: locationManager)
        _favoritesViewModel = Bindable(wrappedValue: favoritesViewModel)
        _viewModel = State(
            initialValue: SearchViewModel(
                stationStore: store,
                recentSearches: recentSearches
            )
        )
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        List {
            if viewModel.query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Section("Explore") {
                    NavigationLink {
                        MapStationsView(
                            store: store,
                            locationManager: locationManager
                        )
                    } label: {
                        DiscoverMapRow()
                    }
                    .accessibilityIdentifier("discover.map")
                }

                if viewModel.recentStations.isEmpty {
                    Section("Find a stop") {
                        Label(
                            "Search by stop name to see live departures.",
                            systemImage: "text.magnifyingglass"
                        )
                        .foregroundStyle(.secondary)
                    }
                } else {
                    RecentStationsList(
                        stations: viewModel.recentStations,
                        isFavorite: isFavorite,
                        distanceText: distanceText,
                        onClear: viewModel.clearRecents
                    )
                }
            }

            if viewModel.status == .results || viewModel.status == .searching {
                SearchResultsList(
                    stations: viewModel.results,
                    isFavorite: isFavorite,
                    distanceText: distanceText
                )
            }
        }
        .listStyle(.insetGrouped)
        .overlay {
            switch viewModel.status {
            case .loadingCatalog:
                ProgressView("Loading stops…")
                    .controlSize(.large)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignColor.background)

            case .unavailable:
                ContentUnavailableView {
                    Label("Search unavailable", systemImage: "exclamationmark.magnifyingglass")
                } description: {
                    Text("The stop catalogue could not be loaded.")
                } actions: {
                    Button("Try again", systemImage: "arrow.clockwise", action: retry)
                        .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(DesignColor.background)

            case .noResults:
                ContentUnavailableView.search
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DesignColor.background)

            case .idle, .searching, .results:
                EmptyView()
            }
        }
        .overlay(alignment: .top) {
            if viewModel.status == .searching {
                ProgressView()
                    .controlSize(.small)
                    .padding(Spacing.sm)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, Spacing.xs)
                    .transition(.opacity)
            }
        }
        .navigationTitle("Discover")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink {
                    MapStationsView(
                        store: store,
                        locationManager: locationManager
                    )
                } label: {
                    Label("Open map", systemImage: "map.fill")
                }
                .labelStyle(.iconOnly)
                .accessibilityIdentifier("discover.map.toolbar")
            }
        }
        .navigationDestination(for: Station.self) { station in
            StationDetailView(station: station)
                .onAppear {
                    viewModel.record(station)
                }
        }
        .searchable(
            text: $viewModel.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Stop name"
        )
        .scrollDismissesKeyboard(.immediately)
        .background(DesignColor.background)
        .animation(Motion.quick(reduceMotion: reduceMotion), value: viewModel.status)
        .task(id: viewModel.query) {
            await viewModel.updateSearch()
        }
    }

    private func isFavorite(_ station: Station) -> Bool {
        favoritesViewModel.containsStation(id: station.id)
    }

    private func distanceText(_ station: Station) -> String? {
        guard let userLocation = locationManager.userLocation else {
            return nil
        }
        let stationLocation = CLLocation(
            latitude: station.lat,
            longitude: station.lon
        )
        return Measurement(
            value: stationLocation.distance(from: userLocation),
            unit: UnitLength.meters
        )
        .formatted(
            .measurement(
                width: .abbreviated,
                usage: .road
            )
        )
    }

    private func retry() {
        Task {
            await viewModel.retry()
        }
    }
}

private struct DiscoverMapRow: View {
    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: "map.fill")
                .font(.title3)
                .foregroundStyle(.appAccent)
                .frame(width: 44, height: 44)
                .background(DesignColor.brand.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text("Explore the map")
                    .font(.headline)
                Text("Browse stops anywhere in Vienna")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    NavigationStack {
        SearchView(
            store: StationStore(),
            locationManager: LocationManager(),
            favoritesViewModel: FavoritesListViewModel()
        )
    }
}
