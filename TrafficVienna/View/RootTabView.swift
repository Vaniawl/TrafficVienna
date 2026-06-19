//
//  RootTabView.swift
//  TrafficVienna
//
//  App root: three tabs (Nearby / Search / Favourites) sharing a single
//  StationStore and LocationManager so the station JSON loads only once.
//

import SwiftUI

struct RootTabView: View {
    @StateObject private var store = StationStore()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var favoritesVM = FavoritesListViewModel()
    @AppStorage("hasOnboarded") private var hasOnboarded = false

    var body: some View {
        tabs
            .tint(Color(hex: 0xE20917))
            .fullScreenCover(isPresented: .constant(!hasOnboarded)) {
                OnboardingView {
                    locationManager.requestLocationIfNeeded()
                    hasOnboarded = true
                }
            }
    }

    private var tabs: some View {
        TabView {
            NavigationStack {
                NearbyView(store: store, locationManager: locationManager)
            }
            .tabItem { Label("Nearby", systemImage: "location.fill") }

            NavigationStack {
                SearchView(store: store)
            }
            .tabItem { Label("Search", systemImage: "magnifyingglass") }

            NavigationStack {
                MapStationsView(store: store, locationManager: locationManager)
            }
            .tabItem { Label("Map", systemImage: "map.fill") }

            NavigationStack {
                FavoritesView(vm: favoritesVM)
            }
            .tabItem { Label("Favourites", systemImage: "star.fill") }
        }
    }
}

#Preview {
    RootTabView()
}
