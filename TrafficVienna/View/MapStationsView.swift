//
//  MapStationsView.swift
//  TrafficVienna
//
//  "Map" tab: nearby stations as markers. Tap a marker to see its live
//  departures in a sheet.
//

import SwiftUI
import MapKit
import CoreLocation

struct MapCenterKey: Hashable {
    let latitudeBucket: Int
    let longitudeBucket: Int

    nonisolated init(location: CLLocation) {
        latitudeBucket = Int((location.coordinate.latitude * 1_000).rounded())
        longitudeBucket = Int((location.coordinate.longitude * 1_000).rounded())
    }
}

struct MapQueryKey: Hashable {
    let latitudeBucket: Int
    let longitudeBucket: Int
    let radiusBucket: Int
    let limit: Int

    nonisolated init(center: CLLocation, radius: CLLocationDistance, limit: Int) {
        latitudeBucket = Int((center.coordinate.latitude * 1_000).rounded())
        longitudeBucket = Int((center.coordinate.longitude * 1_000).rounded())
        radiusBucket = Int((radius / 250).rounded())
        self.limit = limit
    }
}

enum MapViewportMetrics {
    static func radius(for region: MKCoordinateRegion) -> CLLocationDistance {
        let center = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude
        )
        let north = CLLocation(
            latitude: region.center.latitude + region.span.latitudeDelta / 2,
            longitude: region.center.longitude
        )
        let east = CLLocation(
            latitude: region.center.latitude,
            longitude: region.center.longitude + region.span.longitudeDelta / 2
        )
        return min(max(max(center.distance(from: north), center.distance(from: east)), 450), 6_000)
    }

    static func markerLimit(for radius: CLLocationDistance) -> Int {
        switch radius {
        case ..<900: 60
        case ..<1_800: 42
        case ..<3_000: 30
        default: 22
        }
    }
}

enum MapStationSelection {
    static func nearest(
        in store: StationStore,
        to center: CLLocation,
        radius: Double,
        limit: Int
    ) -> [Station] {
        store.nearestStationsWithDistance(
            near: center,
            radiusInMeters: radius,
            limit: limit
        )
            .map(\.station)
    }
}

enum MapStationFilter {
    static func visible(
        _ stations: [Station],
        favoriteIDs: Set<Int>,
        favoritesOnly: Bool
    ) -> [Station] {
        guard favoritesOnly else { return stations }
        return stations.filter { favoriteIDs.contains($0.id) }
    }
}

struct MapStationsView: View {
    @ObservedObject var store: StationStore
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var favoritesVM: FavoritesListViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedID: Int?
    @State private var sheetStation: Station?
    @State private var stations: [Station] = []
    @State private var markerCenter = CLLocation(latitude: 48.2082, longitude: 16.3738)
    @State private var markerRadius: CLLocationDistance = 1_500
    @State private var markerLimit = 42
    @State private var didCenterOnUser = false
    @State private var favoritesOnly = false
    @State private var showsStationList = false

    // Vienna city centre, used until a real location is available.
    private static let viennaCenter = CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738)
    private let initialRadius: CLLocationDistance = 1_500

    private var mapQueryKey: MapQueryKey {
        MapQueryKey(center: markerCenter, radius: markerRadius, limit: markerLimit)
    }
    private var userLocationKey: MapCenterKey? { locationManager.userLocation.map(MapCenterKey.init) }
    private var filterTitle: LocalizedStringKey {
        favoritesOnly ? "Show all stops" : "Favourites only"
    }

    var body: some View {
        let favoriteStationIDs = favoritesVM.favoriteStationIDs
        let visibleStations = MapStationFilter.visible(
            stations,
            favoriteIDs: favoriteStationIDs,
            favoritesOnly: favoritesOnly
        )

        Map(position: $position, selection: $selectedID) {
            UserAnnotation()
            ForEach(visibleStations) { station in
                let isFavorite = favoriteStationIDs.contains(station.id)
                Annotation(
                    station.name,
                    coordinate: CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon),
                    anchor: .bottom
                ) {
                    MapStationMarker(
                        name: station.name,
                        isFavorite: isFavorite,
                        isSelected: selectedID == station.id
                    )
                }
                    .tag(station.id)
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .onMapCameraChange(frequency: .onEnd) { context in
            markerCenter = CLLocation(
                latitude: context.region.center.latitude,
                longitude: context.region.center.longitude
            )
            markerRadius = MapViewportMetrics.radius(for: context.region)
            markerLimit = MapViewportMetrics.markerLimit(for: markerRadius)
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            HStack(spacing: 10) {
                Label("Stops in view: \(visibleStations.count)", systemImage: "tram.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.primary)
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("map.visibleStops")
                Spacer(minLength: 12)
                if locationManager.userLocation == nil {
                    Image(systemName: "location.slash")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .accessibilityLabel("Showing Vienna centre — enable location to see stops near you.")
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .glassEffect(.regular, in: .rect(cornerRadius: 17))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            GlassEffectContainer(spacing: 10) {
                HStack(spacing: 10) {
                    Button {
                        showsStationList = true
                    } label: {
                        Label("Stops list", systemImage: "list.bullet")
                            .mapPill(isSelected: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("map.stopsList")

                    Button {
                        withAnimation(reduceMotion ? nil : .snappy) {
                            favoritesOnly.toggle()
                            selectedID = nil
                            sheetStation = nil
                        }
                    } label: {
                        Label(filterTitle, systemImage: favoritesOnly ? "map" : "star.fill")
                            .mapPill(isSelected: favoritesOnly)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("map.favouritesFilter")
                }
            }
            .padding(.horizontal, 14)
            .padding(.bottom, 8)
        }
        .navigationTitle("Map")
        .tint(NeoDesign.accent)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: mapQueryKey) {
            stations = MapStationSelection.nearest(
                in: store,
                to: markerCenter,
                radius: markerRadius,
                limit: markerLimit
            )
        }
        .onChange(of: userLocationKey, initial: true) { _, newKey in
            guard !didCenterOnUser, newKey != nil, let location = locationManager.userLocation else { return }
            didCenterOnUser = true
            markerCenter = location
            position = .region(MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: initialRadius * 2,
                longitudinalMeters: initialRadius * 2
            ))
        }
        .onChange(of: selectedID) { _, newValue in
            sheetStation = visibleStations.first { $0.id == newValue }
        }
        .sheet(item: $sheetStation, onDismiss: { selectedID = nil }) { station in
            NavigationStack {
                StationDetailView(station: station, presentation: .mapSheet)
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
            .presentationCornerRadius(28)
            .presentationBackground(NeoDesign.background)
        }
        .sheet(isPresented: $showsStationList) {
            MapStationListView(
                stations: visibleStations,
                favoritesVM: favoritesVM,
                favoritesOnly: $favoritesOnly,
                walkingOrigin: locationManager.userLocation
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
}

private struct MapStationMarker: View {
    let name: String
    let isFavorite: Bool
    let isSelected: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: isFavorite ? "star.fill" : "tram.fill")
                .font(.system(size: isSelected ? 15 : 12, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: isSelected ? 36 : 28, height: isSelected ? 36 : 28)
                .background(isFavorite ? NeoDesign.favorite : NeoDesign.accent, in: Circle())
                .overlay {
                    Circle().stroke(.white, lineWidth: 2)
                }
                .shadow(
                    color: .black.opacity(isSelected ? 0.22 : 0.12),
                    radius: isSelected ? 8 : 4,
                    y: 2
                )

            if isSelected {
                Text(name)
                    .font(.caption2.bold())
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .glassEffect(.regular, in: .capsule)
                    .transition(reduceMotion ? .identity : .scale.combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .snappy, value: isSelected)
        .accessibilityLabel(name)
        .accessibilityHint("Show departures")
        .accessibilityAddTraits(.isButton)
    }
}

private extension View {
    func mapPill(isSelected: Bool) -> some View {
        font(.caption.bold())
            .frame(maxWidth: .infinity, minHeight: 42)
            .padding(.horizontal, 10)
            .foregroundStyle(isSelected ? .white : .primary)
            .glassEffect(
                .regular
                    .tint(isSelected ? NeoDesign.accent : .clear)
                    .interactive(),
                in: .capsule
            )
            .contentShape(Capsule())
    }
}

#Preview {
    let lm = LocationManager()
    lm.userLocation = CLLocation(latitude: 48.2008, longitude: 16.3695)
    return NavigationStack {
        MapStationsView(
            store: StationStore(),
            locationManager: lm,
            favoritesVM: FavoritesListViewModel()
        )
    }
}
