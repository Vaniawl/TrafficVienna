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
    @ObservedObject private var store: StationStore
    @State private var vm: NearbyViewModel
    @ObservedObject private var locationManager: LocationManager
    @Bindable private var favoritesViewModel: FavoritesListViewModel
    @Bindable private var disruptionsViewModel: DisruptionsViewModel
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let onShowFavourites: () -> Void
    private let onShowAlerts: () -> Void
    private let onShowAbout: () -> Void

    init(
        store: StationStore,
        locationManager: LocationManager,
        favoritesViewModel: FavoritesListViewModel,
        disruptionsViewModel: DisruptionsViewModel,
        onShowFavourites: @escaping () -> Void,
        onShowAlerts: @escaping () -> Void,
        onShowAbout: @escaping () -> Void
    ) {
        _store = ObservedObject(wrappedValue: store)
        _vm = State(initialValue: NearbyViewModel(store: store, location: locationManager))
        _locationManager = ObservedObject(wrappedValue: locationManager)
        _favoritesViewModel = Bindable(wrappedValue: favoritesViewModel)
        _disruptionsViewModel = Bindable(wrappedValue: disruptionsViewModel)
        self.onShowFavourites = onShowFavourites
        self.onShowAlerts = onShowAlerts
        self.onShowAbout = onShowAbout
    }

    var body: some View {
        stationList
        .navigationTitle("Home")
        .navigationDestination(for: Station.self) { station in
            StationDetailView(station: station)
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("About Traffic Vienna", systemImage: "info.circle") {
                    onShowAbout()
                }
                .labelStyle(.iconOnly)
            }
        }
        .task {
            locationManager.requestLocationIfNeeded()
        }
        .task(id: locationRefreshKey) {
            await vm.load(force: false)

            guard vm.hasLocation else { return }
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    break
                }
                await vm.load(force: false)
            }
        }
        .background(DesignColor.background)
    }

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                if let featuredDeparture = favoritesViewModel.featuredDeparture {
                    featuredDepartureLink(featuredDeparture)
                    .transition(Motion.stateTransition(reduceMotion: reduceMotion))
                }

                ServiceStatusCard(
                    status: disruptionsViewModel.dashboardStatus,
                    isPersonalized: disruptionsViewModel.hasRelevantLines,
                    action: onShowAlerts
                )
                .transition(Motion.stateTransition(reduceMotion: reduceMotion))
                .animation(
                    Motion.quick(reduceMotion: reduceMotion),
                    value: disruptionsViewModel.dashboardStatus
                )

                if !favoritesViewModel.stations.isEmpty {
                    FavoriteStationsQuickAccessView(stations: favoritesViewModel.stations)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Text("Around you")
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)

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
                        title: "No stops around you",
                        message: "There are no Vienna stops within 500 meters of your location.",
                        actionTitle: "Refresh",
                        action: refresh
                    )
                case .stations:
                    if vm.isLoading {
                        skeletonView
                    }

                    ForEach(vm.items) { item in
                        NavigationLink(value: item.station) {
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
        .refreshable {
            locationManager.requestLocationIfNeeded()
            await vm.load(force: true)
        }
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

    private var locationRefreshKey: String {
        guard let location = locationManager.userLocation else {
            return "no-location-\(locationManager.authorizationStatus.rawValue)"
        }
        return "\(location.coordinate.latitude),\(location.coordinate.longitude)"
    }

    @ViewBuilder
    private func featuredDepartureLink(_ item: FeaturedDeparture) -> some View {
        if let station = store.stations.first(where: {
            $0.diva.map(String.init) == item.route.diva
        }) {
            NavigationLink(value: station) {
                FavoriteNextDepartureCard(item: item)
            }
            .buttonStyle(.plain)
        } else {
            Button(action: onShowFavourites) {
                FavoriteNextDepartureCard(item: item)
            }
            .buttonStyle(.plain)
        }
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
        locationManager.requestLocationIfNeeded()
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
            disruptionsViewModel: DisruptionsViewModel(),
            onShowFavourites: {},
            onShowAlerts: {},
            onShowAbout: {}
        )
    }
}
