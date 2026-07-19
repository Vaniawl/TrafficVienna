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

enum MapStationSelection {
    static func nearest(
        in store: StationStore,
        to center: CLLocation,
        radius: Double,
        limit: Int
    ) -> [Station] {
        store.stationsWithDistance(near: center, radiusInMeters: radius)
            .sorted { ($0.meters, $0.station.id) < ($1.meters, $1.station.id) }
            .prefix(limit)
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

enum MapStationListSearch {
    static func matching(_ stations: [Station], query: String) -> [Station] {
        let tokens = normalized(query).split(separator: " ")
        guard !tokens.isEmpty else { return stations }

        return stations.filter { station in
            let name = normalized(station.name)
            return tokens.allSatisfy(name.contains)
        }
    }

    static func matching(_ items: [MapStationListItem], query: String) -> [MapStationListItem] {
        let matchingIDs = Set(matching(items.map(\.station), query: query).map(\.id))
        return items.filter { matchingIDs.contains($0.id) }
    }

    private static func normalized(_ text: String) -> String {
        text.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "de_AT")
        )
    }
}

struct MapStationListItem: Identifiable {
    let station: Station
    let distance: CLLocationDistance?

    var id: Int { station.id }
    var walkingEstimate: WalkingEstimate? { distance.map(WalkingEstimate.init(distanceMeters:)) }
}

struct MapStationListInputKey: Equatable {
    let stationIDs: [Int]
    let latitude: Double?
    let longitude: Double?

    init(stations: [Station], origin: CLLocation?) {
        stationIDs = stations.map(\.id)
        latitude = origin?.coordinate.latitude
        longitude = origin?.coordinate.longitude
    }
}

enum MapStationListOrder {
    static func items(_ stations: [Station], from origin: CLLocation?) -> [MapStationListItem] {
        guard let origin else {
            return stations.map { MapStationListItem(station: $0, distance: nil) }
        }

        return stations.enumerated()
            .map { offset, station in
                let location = CLLocation(latitude: station.lat, longitude: station.lon)
                return (
                    offset: offset,
                    item: MapStationListItem(
                        station: station,
                        distance: location.distance(from: origin)
                    )
                )
            }
            .sorted { (($0.item.distance ?? 0), $0.offset) < (($1.item.distance ?? 0), $1.offset) }
            .map(\.item)
    }

    static func nearest(_ stations: [Station], to origin: CLLocation?) -> [Station] {
        items(stations, from: origin).map(\.station)
    }
}

struct MapStationsView: View {
    @ObservedObject var store: StationStore
    @ObservedObject var locationManager: LocationManager
    @ObservedObject var favoritesVM: FavoritesListViewModel

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedID: Int?
    @State private var sheetStation: Station?
    @State private var stations: [Station] = []
    @State private var markerCenter = CLLocation(latitude: 48.2082, longitude: 16.3738)
    @State private var didCenterOnUser = false
    @State private var favoritesOnly = false
    @State private var showsStationList = false

    // Vienna city centre, used until a real location is available.
    private static let viennaCenter = CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738)
    private let radius: Double = 1500
    private let maxMarkers = 60

    private var markerCenterKey: MapCenterKey { MapCenterKey(location: markerCenter) }
    private var userLocationKey: MapCenterKey? { locationManager.userLocation.map(MapCenterKey.init) }
    private var favoriteStationIDs: Set<Int> { Set(favoritesVM.stations.map(\.id)) }
    private var visibleStations: [Station] {
        MapStationFilter.visible(
            stations,
            favoriteIDs: favoriteStationIDs,
            favoritesOnly: favoritesOnly
        )
    }
    private var filterTitle: LocalizedStringKey {
        favoritesOnly ? "Show all stops" : "Favourites only"
    }

    var body: some View {
        Map(position: $position, selection: $selectedID) {
            UserAnnotation()
            ForEach(visibleStations) { station in
                let isFavorite = favoriteStationIDs.contains(station.id)
                Marker(station.name, systemImage: isFavorite ? "star.fill" : "tram.fill",
                       coordinate: CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon))
                    .tint(isFavorite ? .yellow : NeoDesign.accent)
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
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            VStack(spacing: 8) {
                if locationManager.userLocation == nil {
                    Text("Showing Vienna centre — enable location to see stops near you.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                }
                Label("Stops in view: \(visibleStations.count)", systemImage: "tram.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("map.visibleStops")
                HStack(spacing: 8) {
                    Button {
                        showsStationList = true
                    } label: {
                        Label("Stops list", systemImage: "list.bullet")
                            .mapPill(isSelected: false)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("map.stopsList")

                    Button {
                        favoritesOnly.toggle()
                        selectedID = nil
                        sheetStation = nil
                    } label: {
                        Label(
                            filterTitle,
                            systemImage: favoritesOnly ? "map" : "star.fill"
                        )
                        .mapPill(isSelected: favoritesOnly)
                    }
                    .buttonStyle(.plain)
                    .accessibilityIdentifier("map.favouritesFilter")
                }
            }
            .padding(.vertical, 8)
        }
        .navigationTitle("Map")
        .tint(NeoDesign.accent)
        .navigationBarTitleDisplayMode(.inline)
        .task(id: markerCenterKey) {
            stations = MapStationSelection.nearest(
                in: store,
                to: markerCenter,
                radius: radius,
                limit: maxMarkers
            )
        }
        .onChange(of: userLocationKey, initial: true) { _, newKey in
            guard !didCenterOnUser, newKey != nil, let location = locationManager.userLocation else { return }
            didCenterOnUser = true
            markerCenter = location
            position = .region(MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: radius * 2,
                longitudinalMeters: radius * 2
            ))
        }
        .onChange(of: selectedID) { _, newValue in
            sheetStation = visibleStations.first { $0.id == newValue }
        }
        .sheet(item: $sheetStation, onDismiss: { selectedID = nil }) { station in
            NavigationStack {
                StationDetailView(station: station)
            }
            .presentationDetents([.medium, .large])
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

private struct MapStationListView: View {
    let stations: [Station]
    @ObservedObject var favoritesVM: FavoritesListViewModel
    @Binding var favoritesOnly: Bool
    let walkingOrigin: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var orderedItems: [MapStationListItem]

    init(
        stations: [Station],
        favoritesVM: FavoritesListViewModel,
        favoritesOnly: Binding<Bool>,
        walkingOrigin: CLLocation?
    ) {
        self.stations = stations
        _favoritesVM = ObservedObject(wrappedValue: favoritesVM)
        _favoritesOnly = favoritesOnly
        self.walkingOrigin = walkingOrigin
        _orderedItems = State(initialValue: MapStationListOrder.items(stations, from: walkingOrigin))
    }

    private var inputKey: MapStationListInputKey {
        MapStationListInputKey(stations: stations, origin: walkingOrigin)
    }

    private var displayedItems: [MapStationListItem] {
        return MapStationListSearch.matching(orderedItems, query: query)
    }

    private var hasQuery: Bool {
        !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if displayedItems.isEmpty {
                    ContentUnavailableView {
                        Label(
                            hasQuery
                                ? "No matching stops"
                                : favoritesOnly ? "No favourite stops in view" : "No stops in view",
                            systemImage: hasQuery ? "magnifyingglass" : favoritesOnly ? "star.slash" : "tram"
                        )
                    } description: {
                        Text(hasQuery ? "Try another station name." : "Move the map or show all stops.")
                    } actions: {
                        if favoritesOnly {
                            Button("Show all stops") { favoritesOnly = false }
                                .buttonStyle(.borderedProminent)
                        }
                    }
                } else {
                    List(displayedItems) { item in
                        let station = item.station
                        let isFavorite = favoritesVM.isStationFavorite(id: station.id)
                        HStack(spacing: 8) {
                            NavigationLink {
                                StationDetailView(station: station)
                            } label: {
                                HStack(spacing: 14) {
                                    NeoIcon(
                                        systemName: isFavorite ? "star.fill" : "tram.fill",
                                        tint: isFavorite ? .yellow : NeoDesign.accent
                                    )
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(station.name)
                                            .font(.headline)
                                        Text(station.diva == nil ? "Schedule only" : "Live departures")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                        if let walkingEstimate = item.walkingEstimate {
                                            Label(walkingEstimate.text, systemImage: "figure.walk")
                                                .font(.caption2)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)

                            Button {
                                withAnimation { favoritesVM.toggleStation(station) }
                            } label: {
                                Image(systemName: isFavorite ? "star.fill" : "star")
                                    .foregroundStyle(isFavorite ? .yellow : .secondary)
                                    .frame(width: 44, height: 44)
                            }
                            .buttonStyle(.plain)
                            .accessibilityLabel(
                                isFavorite
                                    ? "Remove station from favourites"
                                    : "Add station to favourites"
                            )
                            .accessibilityHint(Text(verbatim: station.name))
                            .accessibilityIdentifier("map.favorite.\(station.id)")
                        }
                        .padding(.vertical, 4)
                        .accessibilityIdentifier("map.station.\(station.id)")
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Visible stops")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search visible stops")
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Closest first")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(NeoDesign.accent)
        .onChange(of: inputKey) { _, _ in
            orderedItems = MapStationListOrder.items(stations, from: walkingOrigin)
        }
    }

}

private extension View {
    func mapPill(isSelected: Bool) -> some View {
        font(.caption.bold())
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(isSelected ? NeoDesign.accent : Color(.systemBackground), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
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
