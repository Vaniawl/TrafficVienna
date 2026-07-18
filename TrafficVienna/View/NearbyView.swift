//
//  NearbyView.swift
//  TrafficVienna
//
//  "Nearby" tab: stations around the user, each shown as a card with its next
//  departures. Loading is coordinated by NearbyViewModel (sequential, shared
//  "last updated", manual refresh) to stay within the API limit.
//

import SwiftUI
import CoreLocation
import MapKit

struct NearbyView: View {
    @State private var vm: NearbyViewModel
    @ObservedObject private var locationManager: LocationManager
    @Bindable private var favoritesViewModel: FavoritesListViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let onShowFavourites: () -> Void

    init(
        store: StationStore,
        locationManager: LocationManager,
        favoritesViewModel: FavoritesListViewModel,
        onShowFavourites: @escaping () -> Void
    ) {
        _vm = State(initialValue: NearbyViewModel(store: store, location: locationManager))
        _locationManager = ObservedObject(wrappedValue: locationManager)
        _favoritesViewModel = Bindable(wrappedValue: favoritesViewModel)
        self.onShowFavourites = onShowFavourites
    }

    var body: some View {
        stationList
        .navigationTitle("Nearby")
        .toolbar {
            if vm.hasLocation && !vm.items.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.load(force: true) }
                    } label: {
                        if vm.isRefreshing {
                            ProgressView().controlSize(.small)
                                .accessibilityLabel("Refreshing departures")
                        } else {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                    .disabled(vm.isRefreshing)
                    .accessibilityLabel("Refresh departures")
                }
            }
        }
        .task {
            while !Task.isCancelled {
                await vm.load(force: false)
                try? await Task.sleep(for: .seconds(vm.items.isEmpty ? 5 : 60))
            }
        }
        .background(DesignColor.background)
    }

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                if let featuredDeparture = favoritesViewModel.featuredDeparture {
                    FavoriteNextDepartureCard(
                        item: featuredDeparture,
                        action: onShowFavourites
                    )
                    .transition(Motion.stateTransition(reduceMotion: reduceMotion))
                }

                if !favoritesViewModel.stations.isEmpty {
                    FavoriteStationsQuickAccessView(stations: favoritesViewModel.stations)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                switch dashboardState {
                case .locationDenied:
                    NearbyStatusCard(
                        icon: "location.slash",
                        title: "Location is off",
                        message: "Allow location access in Settings to see stops near you.",
                        actionTitle: "Open Settings",
                        action: openSettings
                    )
                case .permissionRequired:
                    NearbyStatusCard(
                        icon: "location",
                        title: "Find stops near you",
                        message: "Allow location access to see live departures around you.",
                        actionTitle: "Allow location",
                        action: locationManager.requestLocationIfNeeded
                    )
                case .locating:
                    NearbyStatusCard(
                        icon: nil,
                        title: "Locating you…",
                        message: "Use your location to show the closest stops.",
                        actionTitle: nil,
                        action: nil
                    )
                case .noStations:
                    NearbyStatusCard(
                        icon: "tram.fill",
                        title: "No stops nearby",
                        message: "There are no stations within 500 meters.",
                        actionTitle: "Refresh",
                        action: refresh
                    )
                case .stations:
                    if vm.isLoading {
                        skeletonView
                    }

                    ForEach(vm.items) { item in
                        NavigationLink {
                            StationDetailView(station: item.station)
                        } label: {
                            StationCardView(
                                station: item.station,
                                distance: item.distance,
                                lines: item.lines,
                                failed: item.failed,
                                updatedAt: item.updatedAt,
                                isStale: item.isStale
                            )
                        }
                        .buttonStyle(.plain)
                        .contextMenu {
                            let station = item.station
                            let isFav = favoritesViewModel.containsStation(id: station.id)

                            Button {
                                favoritesViewModel.toggleStation(FavoriteStation(station))
                            } label: {
                                Label(
                                    isFav ? "Remove station from favourites" : "Add station to favourites",
                                    systemImage: isFav ? "star.slash" : "star"
                                )
                            }

                            ShareLink(item: stationShareText(station))

                            Button {
                                openInMaps(station)
                            } label: {
                                Label("Open in Maps", systemImage: "map")
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, horizontalSizeClass == .regular ? Spacing.xxxl : Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .refreshable { await vm.load(force: true) }
        .animation(
            Motion.standard(reduceMotion: reduceMotion),
            value: favoritesViewModel.featuredDeparture?.id
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Nearby stations")
    }

    private var dashboardState: NearbyDashboardState {
        NearbyDashboardState(
            authorizationStatus: locationManager.authorizationStatus,
            hasLocation: vm.hasLocation,
            hasStations: !vm.items.isEmpty
        )
    }

    private func stationShareText(_ station: Station) -> String {
        "\(station.name) — live departures on Traffic Vienna"
    }

    private func openInMaps(_ station: Station) {
        let location = CLLocation(latitude: station.lat, longitude: station.lon)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = station.name
        mapItem.openInMaps()
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }

    private func refresh() {
        Task { await vm.load(force: true) }
    }

    private var skeletonView: some View {
        VStack(spacing: Spacing.md) {
            ForEach(0..<3, id: \.self) { index in
                StationCardView(
                    station: Station(id: index, diva: 60201435, name: "Loading station",
                                     lat: 48.200832, lon: 16.369505),
                    distance: Double(index * 100),
                    lines: [],
                    failed: false,
                    updatedAt: nil,
                    isStale: false
                )
                if index < 2 { Divider() }
            }
        }
        .redacted(reason: .placeholder)
        .shimmer()
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Loading stations")
    }
}

#Preview {
    let lm = LocationManager()
    lm.userLocation = CLLocation(latitude: 48.200832, longitude: 16.369505)
    return NavigationStack {
        NearbyView(
            store: StationStore(),
            locationManager: lm,
            favoritesViewModel: FavoritesListViewModel(),
            onShowFavourites: {}
        )
    }
}
