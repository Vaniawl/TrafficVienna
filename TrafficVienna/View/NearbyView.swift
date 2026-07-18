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
    @Environment(\.openURL) private var openURL
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var favoriteStations: [FavoriteStation] = []

    private let favoriteStationsRepository = UserDefaultsFavoriteStationsRepository()

    init(store: StationStore, locationManager: LocationManager) {
        _vm = State(initialValue: NearbyViewModel(store: store, location: locationManager))
        _locationManager = ObservedObject(wrappedValue: locationManager)
    }

    var body: some View {
        Group {
            switch locationManager.authorizationStatus {
            case .denied, .restricted:
                emptyStateView(
                    icon: "location.slash",
                    title: "Location is off",
                    subtitle: "Allow location access in Settings to see stops near you.",
                    action: ("Open Settings", openSettings)
                )
                .accessibilityLabel("Location access denied")
            case .notDetermined:
                emptyStateView(
                    icon: "location",
                    title: "Find stops near you",
                    subtitle: "Allow location access to see live departures around you.",
                    action: ("Allow location", locationManager.requestLocationIfNeeded)
                )
                .accessibilityLabel("Location permission needed")
            default:
                if !vm.hasLocation {
                    locatingView
                } else if vm.items.isEmpty && !vm.isLoading {
                    emptyStateView(
                        icon: "tram.fill",
                        title: "No stops nearby",
                        subtitle: "There are no stations within 500 meters.",
                        action: ("Refresh", { Task { await vm.load(force: true) } })
                    )
                    .accessibilityElement(children: .contain)
                    .accessibilityLabel("No stops nearby")
                } else {
                    stationList
                }
            }
        }
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
            loadFavoriteStations()
            while !Task.isCancelled {
                await vm.load(force: false)
                try? await Task.sleep(for: .seconds(vm.items.isEmpty ? 5 : 60))
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoriteStationsDidChange)) { _ in
            loadFavoriteStations()
        }
        .background(Color(.systemBackground))
    }

    private var stationList: some View {
        ScrollView {
            LazyVStack(spacing: Spacing.md) {
                if !favoriteStations.isEmpty {
                    FavoriteStationsQuickAccessView(stations: favoriteStations)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

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
                        let isFav = favoriteStationsRepository.contains(id: station.id)

                        Button {
                            favoriteStationsRepository.toggle(FavoriteStation(station))
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
            .padding(.horizontal, horizontalSizeClass == .regular ? Spacing.xxxl : Spacing.md)
            .padding(.vertical, Spacing.sm)
        }
        .refreshable { await vm.load(force: true) }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Nearby stations")
    }

    private var locatingView: some View {
        VStack(spacing: Spacing.sm) {
            ProgressView()
                .accessibilityLabel("Locating you")
            Text("Locating you…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(Spacing.md)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Locating you")
    }

    private func stationShareText(_ station: Station) -> String {
        "\(station.name) — live departures on Traffic Vienna"
    }

    private func loadFavoriteStations() {
        favoriteStations = favoriteStationsRepository.all()
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

    private func emptyStateView(
        icon: String,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        action: (title: LocalizedStringKey, perform: () -> Void)? = nil
    ) -> some View {
        VStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .font(.title.scaled(by: 1.4))
                .foregroundStyle(.tertiary)
            Text(title)
                .font(.title3)
                .bold()
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if let action {
                Button(action.title, action: action.perform)
                    .buttonStyle(.borderedProminent)
                    .padding(.top, Spacing.xs)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(Spacing.xxxl)
        .accessibilityElement(children: .contain)
        .accessibilityLabel(Text(title))
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
        NearbyView(store: StationStore(), locationManager: lm)
    }
}
