import SwiftUI

struct SearchView: View {
    @ObservedObject var store: StationStore
    @StateObject private var recents = RecentSearchesStore()
    @State private var query = ""
    @State private var results: [Station] = []
    @State private var isSearching = false

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
            results = Array(store.stationsSuggestion(matching: query).prefix(50))
            isSearching = false
        }
    }

    @ViewBuilder private var recentContent: some View {
        if recentStations.isEmpty {
            emptyCard(icon: "magnifyingglass", title: "Find your station", text: "Start typing to see live departures anywhere in Vienna.")
        } else {
            HStack { Text("Recent").font(.title3.bold()); Spacer(); Button("Clear") { recents.clear() }.font(.subheadline.bold()) }
            ForEach(recentStations) { station in stationCard(station, icon: "clock.arrow.circlepath") }
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

    private func stationCard(_ station: Station, icon: String) -> some View {
        NavigationLink { StationDetailView(station: station) } label: {
            HStack(spacing: 14) {
                NeoIcon(systemName: icon)
                VStack(alignment: .leading, spacing: 3) {
                    Text(station.name).font(.headline).foregroundStyle(.primary)
                    Text(station.diva == nil ? "Schedule only" : "Live departures").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
            }.neoCard()
        }
        .buttonStyle(.plain)
        .simultaneousGesture(TapGesture().onEnded { recents.record(station.id) })
    }

    private func emptyCard(icon: String, title: String, text: String) -> some View {
        VStack(spacing: 14) {
            NeoIcon(systemName: icon)
            Text(title).font(.title3.bold())
            Text(text).font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity).padding(.vertical, 34).neoCard()
    }
}

#Preview { NavigationStack { SearchView(store: StationStore()) } }
