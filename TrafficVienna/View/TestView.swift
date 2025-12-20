//
//  TestView.swift
//  TrafficVienna
//
//  Created by Ivan Dovhosheia on 11.11.25.
//

import SwiftUI
import CoreLocation

struct TestView: View {
    @StateObject private var favoritesVM = FavoritesListViewModel()
    @StateObject private var vm: SearchViewModel
    @StateObject var locationManager: LocationManager

    @State private var diva: Int? = nil

    init(locationManager: LocationManager = LocationManager()) {
        let store = StationStore()
        let vm = SearchViewModel(
            store: store,
            locationManager: locationManager
        )

        _vm = StateObject(wrappedValue: vm)
        _locationManager = StateObject(wrappedValue: locationManager)
    }


    var body: some View {
        VStack(spacing: 0) {
            if vm.query.isEmpty {
                // Original content when there's no active query
                VStack(spacing: 20) {
                    NavigationLink {
                        FavView(vm: favoritesVM)
                    } label: {
                        Image(systemName: "heart.fill")
                            .foregroundStyle(.red)
                        Text("View favourites")
                    }

                    if !vm.nearbyStations.isEmpty {
                        Text("Stops near me")
                        ScrollView {
                            VStack {
                                ForEach(vm.nearbyStations, id: \.id) { station in
                                    NavigationLink {
                                        TestView2(station: station)
                                    } label: {
                                        Text(station.name)
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            } else {
                // Full-screen suggestions when user is typing
                List(vm.suggestions.prefix(50), id: \.id) { station in
                    NavigationLink {
                        TestView2(station: station)
                    } label: {
                        Text(station.name)
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Traffic Vienna")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(
            text: $vm.query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Enter stop name..."
        )
    }
}

#Preview {
    let lm = LocationManager()
    lm.userLocation = CLLocation(latitude: 48.226242, longitude: 16.391295)

    return NavigationStack { // Preview inside NavigationStack to reflect runtime
        TestView(locationManager: lm)
    }
}
