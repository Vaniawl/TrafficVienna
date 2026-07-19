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

    init(location: CLLocation) {
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
        store.stations(near: center, radiusInMeters: radius)
            .map { station in
                (
                    station: station,
                    distance: CLLocation(latitude: station.lat, longitude: station.lon).distance(from: center)
                )
            }
            .sorted { ($0.distance, $0.station.id) < ($1.distance, $1.station.id) }
            .prefix(limit)
            .map(\.station)
    }
}

struct MapStationsView: View {
    @ObservedObject var store: StationStore
    @ObservedObject var locationManager: LocationManager

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedID: Int?
    @State private var sheetStation: Station?
    @State private var stations: [Station] = []
    @State private var markerCenter = CLLocation(latitude: 48.2082, longitude: 16.3738)
    @State private var didCenterOnUser = false

    // Vienna city centre, used until a real location is available.
    private static let viennaCenter = CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738)
    private let radius: Double = 1500
    private let maxMarkers = 60

    private var markerCenterKey: MapCenterKey { MapCenterKey(location: markerCenter) }
    private var userLocationKey: MapCenterKey? { locationManager.userLocation.map(MapCenterKey.init) }

    var body: some View {
        ZStack(alignment: .top) {
            Map(position: $position, selection: $selectedID) {
                UserAnnotation()
                ForEach(stations) { station in
                    Marker(station.name, systemImage: "tram.fill",
                           coordinate: CLLocationCoordinate2D(latitude: station.lat, longitude: station.lon))
                        .tint(NeoDesign.accent)
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

            VStack(spacing: 8) {
                if locationManager.userLocation == nil {
                    Text("Showing Vienna centre — enable location to see stops near you.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.regularMaterial, in: Capsule())
                }
                Label("Stops in view: \(stations.count)", systemImage: "tram.fill")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .accessibilityElement(children: .combine)
                    .accessibilityIdentifier("map.visibleStops")
            }
            .padding(.top, 8)
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
            sheetStation = stations.first { $0.id == newValue }
        }
        .sheet(item: $sheetStation, onDismiss: { selectedID = nil }) { station in
            NavigationStack {
                StationDetailView(station: station)
            }
            .presentationDetents([.medium, .large])
        }
    }
}

#Preview {
    let lm = LocationManager()
    lm.userLocation = CLLocation(latitude: 48.2008, longitude: 16.3695)
    return NavigationStack {
        MapStationsView(store: StationStore(), locationManager: lm)
    }
}
