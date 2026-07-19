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
    @ObservedObject var store: StationStore
    @Environment(\.scenePhase) private var scenePhase
    var isActive = true
    @State private var showAbout = false
    @State private var showAccount = false
    @State private var editMode: EditMode = .inactive
    @State private var showClearConfirmation = false

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
                    if editMode == .active { clearAllSection }
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
                    .accessibilityIdentifier("favourites.account")
            }
            if !vm.stations.isEmpty || !vm.favoriteRoutes.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    EditButton()
                        .accessibilityIdentifier("favourites.edit")
                }
            }
        }
        .environment(\.editMode, $editMode)
        .confirmationDialog(
            "Clear all favourites?",
            isPresented: $showClearConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear all", role: .destructive) {
                vm.clearTravelFavorites()
                editMode = .inactive
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all saved stations and routes from this device.")
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
            await vm.loadFavorites(forceRefresh: true)
        }
    }

    private var shouldPoll: Bool { isActive && scenePhase == .active }

    private var stationsSection: some View {
        Section("Stations") {
            ForEach(vm.stations) { station in
                NavigationLink {
                    StationDetailView(station: station.resolved(in: store))
                } label: {
                    HStack(spacing: 14) {
                        NeoIcon(systemName: "tram.fill")
                        Text(station.name).font(.headline)
                        Spacer()
                        Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                    }
                    .neoCard()
                }
                .accessibilityIdentifier("favourites.station.\(station.id)")
                .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onMove { vm.moveStations(fromOffsets: $0, toOffset: $1) }
            .onDelete(perform: vm.removeStations)
        }
    }

    private var linesSection: some View {
        Section("Lines") {
            ForEach(vm.items) { item in
                routeRow(item)
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
            .onMove { vm.moveFavoriteRoutes(fromOffsets: $0, toOffset: $1) }
            .onDelete(perform: vm.removeFavoriteRoutes)
        }
    }

    @ViewBuilder
    private func routeRow(_ item: FavoriteWithDeparture) -> some View {
        if let station = item.route.station(in: store) {
            NavigationLink {
                StationDetailView(station: station)
            } label: {
                routeCard(item)
            }
            .accessibilityIdentifier(
                "favourites.route.\(item.route.diva).\(item.route.lineName).\(item.route.destination)"
            )
        } else {
            routeCard(item)
        }
    }

    private func routeCard(_ item: FavoriteWithDeparture) -> some View {
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
            } else if !item.stopName.isEmpty {
                Label(item.stopName, systemImage: "tram.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .neoCard()
    }

    private var clearAllSection: some View {
        Section {
            Button(role: .destructive) {
                showClearConfirmation = true
            } label: {
                Label("Clear all favourites", systemImage: "trash")
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .neoCard()
            }
            .accessibilityIdentifier("favourites.clearAll")
            .listRowInsets(EdgeInsets(top: 10, leading: 18, bottom: 12, trailing: 18))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
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
    return NavigationStack { FavoritesView(vm: vm, store: StationStore()) }
}
