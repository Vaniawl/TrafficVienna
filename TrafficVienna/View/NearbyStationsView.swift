//
//  NearbyStationsView.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 28.12.25.
//

import SwiftUI
import CoreLocation


struct NearbyStationsView: View {
    @StateObject private var vm: SearchViewModel

    init(locationManager: LocationManager, store: StationStore) {
        _vm = StateObject(wrappedValue: SearchViewModel(store: store, locationManager: locationManager))
    }
    
    var body: some View {
        Group {
            if vm.nearbyStations.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "location.circle")
                        .font(.largeTitle)
                        .foregroundStyle(.secondary)
                    Text("No near stops")
                        .font(.headline)
                }
                .padding()
            } else {
                List {
                    ForEach(vm.nearbyStations) { station in
                        StationCardView(station: station)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowSeparator(.hidden)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Near me")
    }
}





#Preview {
    let lm = LocationManager()
    lm.userLocation = CLLocation(latitude: 48.226242, longitude: 16.391295)

    return NearbyStationsView(
        locationManager: lm,
        store: StationStore()
    )
}
