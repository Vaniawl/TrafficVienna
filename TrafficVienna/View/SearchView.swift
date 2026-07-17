//
//  SearchView.swift
//  TrafficVienna
//
//  "Search" tab: type a stop name, tap a result to open its live departures.
//  Recently opened stations are offered when the search field is empty.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var store: StationStore
    @StateObject private var recents = RecentSearchesStore()
    @State private var query = ""
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var results: [Station] {
        guard !query.isEmpty else { return [] }
        return Array(store.stationsSuggestion(matching: query).prefix(50))
    }

    private var recentStations: [Station] {
        recents.ids.compactMap { id in store.stations.first { $0.id == id } }
    }

    var body: some View {
        Group {
            if query.isEmpty {
                if recentStations.isEmpty {
                    ContentUnavailableView(
                        "Search for a stop",
                        systemImage: "magnifyingglass",
                        description: Text("Enter a station name to see live departures.")
                    )
                } else {
                    recentList
                }
            } else if results.isEmpty {
                ContentUnavailableView.search(text: query)
            } else {
                resultList
            }
        }
        .navigationTitle("Search")
        .searchable(
            text: $query,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Enter stop name…"
        )
        .scrollDismissesKeyboard(.immediately)
        .background(Color(.systemBackground))
    }

    private var resultList: some View {
        List {
            ForEach(results) { station in
                NavigationLink {
                    StationDetailView(station: station)
                } label: {
                    HStack(spacing: Spacing.sm) {
                        Image(systemName: "tram.fill")
                            .foregroundStyle(.secondary)
                        Text(station.name)
                            .font(.body)
                    }
                    .padding(.vertical, Spacing.xs)
                }
            }
        }
        .listStyle(.plain)
    }

    private var recentList: some View {
        List {
            Section {
                ForEach(recentStations) { station in
                    stationLink(station, icon: "clock.arrow.circlepath")
                }
            } header: {
                HStack {
                    Text("Recent")
                        .font(.headline)
                    Spacer()
                    Button("Clear") { recents.clear() }
                        .font(.caption)
                        .textCase(nil)
                }
                .padding(.vertical, Spacing.xs)
            }
        }
        .listStyle(.insetGrouped)
    }

    private func stationLink(_ station: Station, icon: String = "tram.fill") -> some View {
        NavigationLink {
            StationDetailView(station: station)
        } label: {
            HStack(spacing: Spacing.sm) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(station.name)
                    .font(.body)
            }
            .padding(.vertical, Spacing.xs)
        }
        .simultaneousGesture(TapGesture().onEnded {
            recents.record(station.id)
        })
    }
}

#Preview {
    NavigationStack {
        SearchView(store: StationStore())
    }
}
