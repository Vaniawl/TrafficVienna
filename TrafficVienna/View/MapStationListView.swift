import CoreLocation
import SwiftUI

enum MapStationListSearch {
    static func matching(_ stations: [Station], query: String) -> [Station] {
        let tokens = normalized(query).split(separator: " ")
        guard !tokens.isEmpty else { return stations }

        return stations.filter { station in
            let name = normalized(station.name)
            return tokens.allSatisfy(name.contains)
        }
    }

    static func matching(_ items: [MapStationListItem], query: String) -> [MapStationListItem] {
        let tokens = normalized(query).split(separator: " ")
        guard !tokens.isEmpty else { return items }

        return items.filter { item in
            tokens.allSatisfy(item.normalizedName.contains)
        }
    }

    static func normalized(_ text: String) -> String {
        text.folding(
            options: [.caseInsensitive, .diacriticInsensitive],
            locale: Locale(identifier: "de_AT")
        )
    }
}

struct MapStationListItem: Identifiable {
    let station: Station
    let distance: CLLocationDistance?
    let normalizedName: String
    let walkingEstimate: WalkingEstimate?

    init(station: Station, distance: CLLocationDistance?) {
        self.station = station
        self.distance = distance
        self.normalizedName = MapStationListSearch.normalized(station.name)
        self.walkingEstimate = distance.map(WalkingEstimate.init(distanceMeters:))
    }

    var id: Int { station.id }
}

struct MapStationListPresentation {
    let items: [MapStationListItem]
    let hasQuery: Bool

    init(items: [MapStationListItem], query: String) {
        self.items = MapStationListSearch.matching(items, query: query)
        self.hasQuery = !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct MapStationListInputKey: Equatable {
    let stationIDs: [Int]
    let latitude: Double?
    let longitude: Double?

    init(stations: [Station], origin: CLLocation?) {
        stationIDs = stations.map(\.id)
        latitude = origin?.coordinate.latitude
        longitude = origin?.coordinate.longitude
    }
}

enum MapStationListOrder {
    static func items(_ stations: [Station], from origin: CLLocation?) -> [MapStationListItem] {
        guard let origin else {
            return stations.map { MapStationListItem(station: $0, distance: nil) }
        }

        return stations.enumerated()
            .map { offset, station in
                let location = CLLocation(latitude: station.lat, longitude: station.lon)
                return (
                    offset: offset,
                    item: MapStationListItem(
                        station: station,
                        distance: location.distance(from: origin)
                    )
                )
            }
            .sorted { (($0.item.distance ?? 0), $0.offset) < (($1.item.distance ?? 0), $1.offset) }
            .map(\.item)
    }

    static func nearest(_ stations: [Station], to origin: CLLocation?) -> [Station] {
        items(stations, from: origin).map(\.station)
    }
}

struct MapStationListView: View {
    let stations: [Station]
    @ObservedObject var favoritesVM: FavoritesListViewModel
    @Binding var favoritesOnly: Bool
    let walkingOrigin: CLLocation?
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var orderedItems: [MapStationListItem]

    init(
        stations: [Station],
        favoritesVM: FavoritesListViewModel,
        favoritesOnly: Binding<Bool>,
        walkingOrigin: CLLocation?
    ) {
        self.stations = stations
        _favoritesVM = ObservedObject(wrappedValue: favoritesVM)
        _favoritesOnly = favoritesOnly
        self.walkingOrigin = walkingOrigin
        _orderedItems = State(initialValue: MapStationListOrder.items(stations, from: walkingOrigin))
    }

    private var inputKey: MapStationListInputKey {
        MapStationListInputKey(stations: stations, origin: walkingOrigin)
    }

    var body: some View {
        let presentation = MapStationListPresentation(items: orderedItems, query: query)

        NavigationStack {
            Group {
                if presentation.items.isEmpty {
                    ContentUnavailableView {
                        Label(
                            presentation.hasQuery
                                ? "No matching stops"
                                : favoritesOnly ? "No favourite stops in view" : "No stops in view",
                            systemImage: presentation.hasQuery ? "magnifyingglass" : favoritesOnly ? "star.slash" : "tram"
                        )
                    } description: {
                        Text(presentation.hasQuery ? "Try another station name." : "Move the map or show all stops.")
                    } actions: {
                        if favoritesOnly {
                            Button("Show all stops") { favoritesOnly = false }
                                .buttonStyle(.glassProminent)
                        }
                    }
                } else {
                    List(presentation.items) { item in
                        MapStationListRow(item: item, favoritesVM: favoritesVM)
                            .accessibilityIdentifier("map.station.\(item.id)")
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Visible stops")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $query, prompt: "Search visible stops")
            .autocorrectionDisabled()
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Closest first")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .tint(NeoDesign.accent)
        .onChange(of: inputKey) { _, _ in
            orderedItems = MapStationListOrder.items(stations, from: walkingOrigin)
        }
    }
}

private struct MapStationListRow: View {
    let item: MapStationListItem
    @ObservedObject var favoritesVM: FavoritesListViewModel

    var body: some View {
        let station = item.station
        let isFavorite = favoritesVM.isStationFavorite(id: station.id)

        HStack(spacing: 8) {
            NavigationLink {
                StationDetailView(station: station)
            } label: {
                HStack(spacing: 14) {
                    NeoIcon(
                        systemName: isFavorite ? "star.fill" : "tram.fill",
                        tint: isFavorite ? NeoDesign.favorite : NeoDesign.accent
                    )
                    VStack(alignment: .leading, spacing: 3) {
                        Text(station.name)
                            .font(.headline)
                        Text(station.diva == nil ? "Schedule only" : "Live departures")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        if let walkingEstimate = item.walkingEstimate {
                            Label(walkingEstimate.text, systemImage: "figure.walk")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                withAnimation(.snappy) { favoritesVM.toggleStation(station) }
            } label: {
                Image(systemName: isFavorite ? "star.fill" : "star")
                    .foregroundStyle(isFavorite ? NeoDesign.favorite : .secondary)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(
                isFavorite
                    ? "Remove station from favourites"
                    : "Add station to favourites"
            )
            .accessibilityHint(Text(verbatim: station.name))
            .accessibilityIdentifier("map.favorite.\(station.id)")
        }
        .padding(.vertical, 4)
    }
}
