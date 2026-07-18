//
//  FavoritesView.swift
//  TrafficVienna
//
//  "Favourites" tab: pinned whole stations (reorderable) plus saved
//  line + destination pairs with their live departures.
//

import SwiftUI

struct FavoritesView: View {
    @Bindable var viewModel: FavoritesListViewModel
    @State private var showAccount = false
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty && viewModel.stations.isEmpty {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if viewModel.isEmpty {
                ContentUnavailableView(
                    "No favourites yet",
                    systemImage: "star",
                    description: Text("Star a station, or tap the heart on a line, to save it here.")
                )
            } else {
                List {
                    if !viewModel.stations.isEmpty { stationsSection }
                    if !viewModel.items.isEmpty { linesSection }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Favourites")
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Account", systemImage: "person.crop.circle", action: showAccountView)
                    .labelStyle(.iconOnly)
            }
            if !viewModel.stations.isEmpty {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
        .navigationDestination(for: Station.self) { station in
            StationDetailView(station: station)
        }
        .sheet(isPresented: $showAccount) { AccountView() }
        .refreshable {
            viewModel.loadStations()
            await viewModel.loadFavorites(forceRefresh: true)
        }
        .background(Color(.systemBackground))
    }

    private var stationsSection: some View {
        Section("Stations") {
            ForEach(viewModel.stations) { station in
                NavigationLink(value: Station(
                    id: station.id,
                    diva: station.diva,
                    name: station.name,
                    lat: 0,
                    lon: 0
                )) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "tram.fill")
                            .foregroundStyle(.secondary)
                        Text(station.name)
                            .font(.body)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
            .onMove { viewModel.moveStations(fromOffsets: $0, toOffset: $1) }
            .onDelete { offsets in
                offsets.map { viewModel.stations[$0].id }.forEach(viewModel.removeStation)
            }
        }
    }

    private var linesSection: some View {
        Section("Lines") {
            ForEach(viewModel.items) { item in
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    DepartureLineRow(
                        lineName: item.route.lineName,
                        destination: item.route.destination,
                        minutes: item.departures.map { $0.liveMinutes },
                        nextIsLive: item.departures.first?.isRealtime ?? false
                    )

                    if item.state == .unavailable {
                        Button("Retry departures", systemImage: "arrow.clockwise") {
                            Task { await viewModel.refresh(item.route) }
                        }
                        .font(.footnote)
                    } else if item.state == .cached {
                        Label("Saved departures", systemImage: "clock.badge.exclamationmark")
                            .font(.footnote)
                            .foregroundStyle(.orange)
                    }
                }
                .padding(.vertical, Spacing.xs)
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        viewModel.remove(item.route)
                    } label: {
                        Label("Remove", systemImage: "trash")
                    }
                }
            }
        }
    }

    private func showAccountView() {
        showAccount = true
    }
}

#Preview {
    NavigationStack { FavoritesView(viewModel: FavoritesListViewModel()) }
}
