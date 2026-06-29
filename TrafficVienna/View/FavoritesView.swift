//
//  FavoritesView.swift
//  TrafficVienna
//
//  "Favourites" tab: pinned whole stations (reorderable) plus saved
//  line + destination pairs with their live departures.
//

import SwiftUI

struct FavoritesView: View {
    @ObservedObject var vm: FavoritesListViewModel
    @EnvironmentObject private var themeManager: ThemeManager
    @State private var showAbout = false

    var body: some View {
        Group {
            if vm.isLoading && vm.items.isEmpty && vm.stations.isEmpty {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = vm.errorMessage, vm.items.isEmpty {
                ContentUnavailableView(
                    "Couldn't load departures",
                    systemImage: "wifi.exclamationmark",
                    description: Text(error)
                )
            } else if vm.isEmpty {
                ContentUnavailableView(
                    "No favourites yet",
                    systemImage: "star",
                    description: Text("Star a station, or tap the heart on a line, to save it here.")
                )
            } else {
                if themeManager.preset.backgroundStyle == .grouped {
                    List {
                        if !vm.stations.isEmpty { stationsSection }
                        if !vm.items.isEmpty { linesSection }
                    }
                    .listStyle(.insetGrouped)
                } else {
                    List {
                        if !vm.stations.isEmpty { stationsSection }
                        if !vm.items.isEmpty { linesSection }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Favourites")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAbout = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About")
            }
            if !vm.stations.isEmpty {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
        .sheet(isPresented: $showAbout) { AboutView() }
        .task {
            vm.loadStations()
            while !Task.isCancelled {
                await vm.loadFavorites()
                try? await Task.sleep(for: .seconds(60))
            }
        }
        .refreshable {
            vm.loadStations()
            await vm.loadFavorites()
        }
    }

    private var stationsSection: some View {
        Section("Stations") {
            ForEach(vm.stations) { station in
                NavigationLink {
                    StationDetailView(
                        station: Station(id: station.id, diva: station.diva,
                                         name: station.name, lat: 0, lon: 0)
                    )
                } label: {
                    Label(station.name, systemImage: "tram.fill")
                }
            }
            .onMove { vm.moveStations(fromOffsets: $0, toOffset: $1) }
            .onDelete { offsets in
                offsets.map { vm.stations[$0].id }.forEach(vm.removeStation)
            }
        }
    }

    private var linesSection: some View {
        Section("Lines") {
            ForEach(vm.items) { item in
                DepartureLineRow(
                    lineName: item.route.lineName,
                    destination: item.route.destination,
                    minutes: item.departures.map { $0.liveMinutes },
                    nextIsLive: item.departures.first?.isRealtime ?? false
                )
                .padding(.vertical, 4)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        vm.remove(item.route)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
    }
}

#Preview {
    let vm = FavoritesListViewModel()
    vm.stations = [
        FavoriteStation(id: 1, diva: 60200657, name: "Karlsplatz"),
        FavoriteStation(id: 2, diva: 60201468, name: "Praterstern")
    ]
    vm.items = [
        FavoriteWithDeparture(
            route: FavoriteRoute(diva: "60200135", lineName: "U1", destination: "Leopoldau"),
            stopName: "Stephansplatz",
            departures: [
                DepartureInfo(countdown: 2, planned: "12:47", real: "12:47", isRealtime: true),
                DepartureInfo(countdown: 5, planned: "12:50", real: nil, isRealtime: false)
            ]
        )
    ]
    return NavigationStack { FavoritesView(vm: vm) }
}
