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
    @Environment(\.scenePhase) private var scenePhase
    var isActive = true
    @State private var showAbout = false
    @State private var showAccount = false

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
                List {
                    NeoHeader(eyebrow: "Your city", title: "Favourites", subtitle: "The departures you care about")
                        .listRowInsets(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                    if let staleMessage = vm.staleMessage {
                        StaleDataBanner(message: staleMessage)
                            .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 8, trailing: 18))
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                    }
                    if !vm.stations.isEmpty { stationsSection }
                    if !vm.items.isEmpty { linesSection }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .neoScreen()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    showAbout = true
                } label: {
                    Image(systemName: "info.circle")
                }
                .accessibilityLabel("About")
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button { showAccount = true } label: { Image(systemName: "person.crop.circle") }
                    .accessibilityLabel("Account")
            }
            if !vm.stations.isEmpty {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
        .sheet(isPresented: $showAbout) { AboutView() }
        .sheet(isPresented: $showAccount) { AccountView() }
        .task(id: shouldPoll) {
            guard shouldPoll else { return }
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

    private var shouldPoll: Bool { isActive && scenePhase == .active }

    private var stationsSection: some View {
        Section("Stations") {
            ForEach(vm.stations) { station in
                NavigationLink {
                    StationDetailView(
                        station: Station(id: station.id, diva: station.diva,
                                         name: station.name, lat: 0, lon: 0)
                    )
                } label: {
                    HStack(spacing: 14) {
                        NeoIcon(systemName: "tram.fill")
                        Text(station.name).font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                    }
                    .neoCard()
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
                VStack(alignment: .leading, spacing: 8) {
                    DepartureLineRow(
                        lineName: item.route.lineName,
                        destination: item.route.destination,
                        minutes: item.departures.map { $0.liveMinutes },
                        nextIsLive: item.departures.first?.isRealtime ?? false
                    )
                    if let loadError = item.loadError {
                        Label(loadError, systemImage: "wifi.exclamationmark")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
                .neoCard()
                .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
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
