import SwiftUI

struct SearchView: View {
    @ObservedObject var store: StationStore
    @EnvironmentObject private var recents: RecentSearchesStore
    @EnvironmentObject private var favoritesVM: FavoritesListViewModel
    @State private var query = ""
    @State private var results: [Station] = []
    @State private var isSearching = false
    @State private var showingClearRecentsConfirmation = false

    private var recentStations: [Station] { recents.ids.compactMap(store.station(id:)) }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                NeoHeader(eyebrow: "Discover", title: "Where to next?", subtitle: "Search every station across Vienna")
                    .padding(.bottom, 8)

                if query.isEmpty { recentContent } else { resultContent }
            }
            .padding(.horizontal, 18).padding(.top, 12).padding(.bottom, 28)
        }
        .neoScreen()
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "Station or stop")
        .scrollDismissesKeyboard(.immediately)
        .task(id: query) {
            guard !query.isEmpty else {
                results = []
                isSearching = false
                return
            }
            isSearching = true
            results = []
            try? await Task.sleep(for: .milliseconds(250))
            guard !Task.isCancelled else { return }
            results = store.stationsSuggestion(matching: query, limit: 50)
            isSearching = false
        }
        .confirmationDialog(
            "Clear recent searches?",
            isPresented: $showingClearRecentsConfirmation,
            titleVisibility: .visible
        ) {
            Button("Clear all", role: .destructive) { recents.clear() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes all recent stations from this device.")
        }
    }

    @ViewBuilder private var recentContent: some View {
        if recentStations.isEmpty {
            emptyCard(icon: "magnifyingglass", title: "Find your station", text: "Start typing to see live departures anywhere in Vienna.")
        } else {
            HStack {
                Text("Recent").font(.title3.bold())
                Spacer()
                Button("Clear all") { showingClearRecentsConfirmation = true }
                    .font(.subheadline.bold())
                    .accessibilityIdentifier("search.clearRecents")
            }
            ForEach(recentStations) { station in
                stationCard(station, icon: "clock.arrow.circlepath", showsRecentRemoval: true)
            }
        }
    }

    @ViewBuilder private var resultContent: some View {
        if isSearching {
            ProgressView()
                .frame(maxWidth: .infinity)
                .padding(.vertical, 34)
                .neoCard()
        } else if results.isEmpty {
            emptyCard(icon: "tram.fill", title: "No matching stops", text: "Try another station name.")
        } else {
            HStack { Text("Stations").font(.title3.bold()); Spacer(); Text("\(results.count)").foregroundStyle(.secondary) }
            ForEach(results) { station in stationCard(station, icon: "tram.fill") }
        }
    }

    private func stationCard(_ station: Station, icon: String, showsRecentRemoval: Bool = false) -> some View {
        HStack(spacing: 8) {
            NavigationLink { StationDetailView(station: station) } label: {
                HStack(spacing: 14) {
                    NeoIcon(systemName: icon)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(station.name).font(.headline).foregroundStyle(.primary)
                        Text(station.diva == nil ? "Schedule only" : "Live departures").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .simultaneousGesture(TapGesture().onEnded { recents.record(station.id) })

            if showsRecentRemoval {
                Button {
                    withAnimation { recents.remove(station.id) }
                } label: {
                    Image(systemName: "xmark")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "\(String(localized: "Remove from recent")): \(station.name)"))
                .accessibilityIdentifier("search.removeRecent.\(station.id)")
            }

            let isFavorite = favoritesVM.isStationFavorite(id: station.id)
            Button {
                favoritesVM.toggleStation(station)
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? .yellow : .secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(isFavorite ? "Remove station from favourites" : "Add station to favourites")
            .accessibilityHint(Text(verbatim: station.name))
            .accessibilityIdentifier("search.favorite.\(station.id)")
        }
        .neoCard()
    }

    private func emptyCard(icon: String, title: LocalizedStringKey, text: LocalizedStringKey) -> some View {
        VStack(spacing: 14) {
            NeoIcon(systemName: icon)
            Text(title).font(.title3.bold())
            Text(text).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 34).neoCard()
    }
}

#Preview {
    NavigationStack { SearchView(store: StationStore()) }
        .environmentObject(RecentSearchesStore())
        .environmentObject(FavoritesListViewModel())
}
