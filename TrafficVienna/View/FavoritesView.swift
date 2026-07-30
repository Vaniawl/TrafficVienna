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
    @ObservedObject var store: StationStore
    let onDiscover: () -> Void

    var body: some View {
        List {
            if let featuredDeparture = viewModel.featuredDeparture {
                Section("My commute") {
                    if let station = station(diva: featuredDeparture.route.diva) {
                        NavigationLink(value: station) {
                            SavedCommuteRow(item: featuredDeparture)
                        }
                    } else {
                        SavedCommuteRow(item: featuredDeparture)
                    }
                }
            }

            if !viewModel.stations.isEmpty { stationsSection }
            if !viewModel.items.isEmpty { linesSection }
        }
        .listStyle(.insetGrouped)
        .overlay {
            if viewModel.isLoading && viewModel.isEmpty {
                ProgressView("Loading saved stops…")
                    .controlSize(.large)
            } else if viewModel.isEmpty {
                ContentUnavailableView {
                    Label("Nothing saved yet", systemImage: "star")
                } description: {
                    Text("Save stops and lines to build your personal commute dashboard.")
                } actions: {
                    Button("Find a stop", systemImage: "magnifyingglass", action: onDiscover)
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationTitle("Saved")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Find a stop", systemImage: "plus", action: onDiscover)
                    .labelStyle(.iconOnly)
            }

            if !viewModel.stations.isEmpty {
                ToolbarItem(placement: .topBarTrailing) { EditButton() }
            }
        }
        .navigationDestination(for: Station.self) { station in
            StationDetailView(station: station)
        }
        .refreshable {
            viewModel.loadStations()
            await viewModel.loadFavorites(forceRefresh: true)
        }
        .background(Color(.systemBackground))
    }

    private var stationsSection: some View {
        Section("Saved stops") {
            ForEach(viewModel.stations) { station in
                NavigationLink(value: resolvedStation(station)) {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "tram.fill")
                            .foregroundStyle(.appAccent)
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
        Section("Saved lines") {
            ForEach(viewModel.items) { item in
                Group {
                    if let station = station(diva: item.route.diva),
                       item.state != .unavailable {
                        NavigationLink(value: station) {
                            savedLineContent(item)
                        }
                    } else {
                        savedLineContent(item)
                    }
                }
                .padding(.vertical, Spacing.xs)
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    if item.state == .unavailable {
                        Button("Retry", systemImage: "arrow.clockwise") {
                            Task { await viewModel.refresh(item.route) }
                        }
                        .tint(.appAccent)
                    }
                }
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

    private func resolvedStation(_ favorite: FavoriteStation) -> Station {
        store.stations.first { $0.id == favorite.id }
            ?? Station(
                id: favorite.id,
                diva: favorite.diva,
                name: favorite.name,
                lat: 0,
                lon: 0
            )
    }

    private func station(diva: String) -> Station? {
        store.stations.first { $0.diva.map(String.init) == diva }
    }

    private func savedLineContent(_ item: FavoriteWithDeparture) -> some View {
        VStack(alignment: .leading, spacing: Spacing.xs) {
            DepartureLineRow(
                lineName: item.route.lineName,
                destination: item.route.destination,
                minutes: item.departures.map { $0.liveMinutes },
                nextIsLive: item.departures.first?.isRealtime ?? false
            )

            if item.state == .unavailable {
                Label("Departures unavailable · swipe to retry", systemImage: "wifi.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else if item.state == .cached {
                Label("Saved departures", systemImage: "clock.badge.exclamationmark")
                    .font(.footnote)
                    .foregroundStyle(.orange)
            }
        }
    }
}

#Preview {
    NavigationStack {
        FavoritesView(
            viewModel: FavoritesListViewModel(),
            store: StationStore(),
            onDiscover: {}
        )
    }
}

private struct SavedCommuteRow: View {
    let item: FeaturedDeparture

    var body: some View {
        HStack(spacing: Spacing.md) {
            LineBadge(line: item.route.lineName)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(item.route.destination)
                    .font(.headline)
                Text(item.stopName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.xs)

            VStack(alignment: .trailing, spacing: Spacing.none) {
                Text(item.departure.liveMinutes <= 0 ? "now" : "\(item.departure.liveMinutes)")
                    .font(.title2.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(.appAccent)
                if item.departure.liveMinutes > 0 {
                    Text("min")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }
}
