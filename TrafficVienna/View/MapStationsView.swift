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

struct MapStationsView: View {
    @ObservedObject var store: StationStore
    @ObservedObject var locationManager: LocationManager

    @State private var position: MapCameraPosition = .automatic
    @State private var selectedID: Int?
    @State private var sheetStation: Station?

    // Vienna city centre, used until a real location is available.
    private static let viennaCenter = CLLocationCoordinate2D(latitude: 48.2082, longitude: 16.3738)
    private let radius: Double = 1500
    private let maxMarkers = 60

    private var center: CLLocation {
        locationManager.userLocation ?? CLLocation(latitude: Self.viennaCenter.latitude,
                                                    longitude: Self.viennaCenter.longitude)
    }

    private var stations: [Station] {
        store.stations(near: center, radiusInMeters: radius)
            .sorted {
                CLLocation(latitude: $0.lat, longitude: $0.lon).distance(from: center) <
                CLLocation(latitude: $1.lat, longitude: $1.lon).distance(from: center)
            }
            .prefix(maxMarkers)
            .map { $0 }
    }

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

            if locationManager.userLocation == nil {
                Text("Showing Vienna centre — enable location to see stops near you.")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                    .padding(.top, 8)
            }
        }
        .navigationTitle("Map")
        .tint(NeoDesign.accent)
        .navigationBarTitleDisplayMode(.inline)
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
