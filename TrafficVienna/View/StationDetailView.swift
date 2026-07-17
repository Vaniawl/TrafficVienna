//
//  StationDetailView.swift
//  TrafficVienna
//
//  Live departures for a single station, grouped by platform. Each line shows
//  its next departures as tiles and can be added to favourites.
//

import SwiftUI

struct StationDetailView: View {
    @StateObject private var vm: StationDetailViewModel
    @State private var lineFavoriteToggles = 0
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    init(station: Station) {
        _vm = StateObject(wrappedValue: StationDetailViewModel(station: station))
    }

    var body: some View {
        content
            .navigationTitle(vm.station.name)
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.impact(weight: .light), trigger: vm.isStationFavorited)
            .sensoryFeedback(.selection, trigger: lineFavoriteToggles)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        vm.toggleStationFavorite()
                    } label: {
                        Image(systemName: vm.isStationFavorited ? "star.fill" : "star")
                            .foregroundStyle(vm.isStationFavorited ? .yellow : .secondary)
                    }
                    .accessibilityLabel(vm.isStationFavorited ? "Remove station from favourites" : "Add station to favourites")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.load(forceRefresh: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.isLoading)
                }
            }
            .task {
                // Keep departures current while the screen is visible. Cancelled
                // automatically on disappear. Cached responses keep this cheap.
                while !Task.isCancelled {
                    await vm.load()
                    try? await Task.sleep(for: .seconds(30))
                }
            }
            .refreshable { await vm.load(forceRefresh: true) }
            .background(Color(.systemBackground))
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.monitor == nil {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = vm.errorMessage {
            ContentUnavailableView("Couldn't load departures", systemImage: "wifi.exclamationmark", description: Text(error))
        } else if !vm.groups.isEmpty {
            departuresList
        } else {
            ContentUnavailableView("No departures", systemImage: "tram", description: Text("Nothing scheduled right now."))
        }
    }

    private var departuresList: some View {
        List {
            if !vm.trafficInfos.isEmpty {
                Section {
                    ForEach(vm.trafficInfos) { DisruptionRow(info: $0) }
                } header: {
                    Label("Service alerts", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            if vm.availableCategories.count > 1 {
                Section {
                    FilterChips(categories: vm.availableCategories, selection: $vm.categoryFilter)
                        .listRowInsets(EdgeInsets(top: Spacing.xs, leading: 0, bottom: Spacing.xs, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach(vm.groups) { group in
                    lineRow(group)
                }
            } header: {
                Text("Departures")
                    .font(.headline)
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) { freshnessBar }
    }

    @ViewBuilder
    private var freshnessBar: some View {
        if let text = vm.lastUpdatedText {
            HStack(spacing: Spacing.xxs) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text(text)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Spacing.xs)
            .background(.bar)
        }
    }

    private func lineRow(_ group: StationDetailViewModel.DepartureGroup) -> some View {
        HStack(spacing: Spacing.sm) {
            DepartureLineRow(
                lineName: group.line,
                destination: group.destination,
                minutes: group.minutes,
                hasDisruption: vm.hasDisruption(lineName: group.line),
                nextIsLive: group.isLive
            )

            if vm.station.diva != nil {
                let isFav = vm.isFavorite(line: group.line, destination: group.destination)
                Button {
                    vm.toggleFavorite(line: group.line, destination: group.destination)
                    lineFavoriteToggles += 1
                } label: {
                    Image(systemName: isFav ? "heart.fill" : "heart")
                        .foregroundStyle(isFav ? .red : .secondary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(isFav ? "Remove \(group.line) from favourites" : "Save \(group.line) to favourites")
            } else {
                Color.clear
                    .frame(width: 44)
            }
        }
        .padding(.vertical, Spacing.xs)
        .contextMenu {
            Button {
                LiveActivityController.track(
                    line: group.line,
                    destination: group.destination,
                    stop: vm.station.name,
                    minutes: group.minutes.first ?? 0,
                    isLive: group.isLive
                )
            } label: {
                Label("Track on Lock Screen", systemImage: "bell.badge")
            }

            Button {
                vm.toggleFavorite(line: group.line, destination: group.destination)
                lineFavoriteToggles += 1
            } label: {
                Label(
                    vm.isFavorite(line: group.line, destination: group.destination) ? "Remove favourite" : "Add to favourites",
                    systemImage: "heart"
                )
            }
        }
    }
}

#Preview {
    NavigationStack {
        StationDetailView(
            station: Station(id: 1, diva: 60201468, name: "Praterstern",
                             lat: 48.218, lon: 16.392)
        )
    }
}
