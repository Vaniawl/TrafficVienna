import SwiftUI

struct SearchResultsList: View {
    let stations: [Station]
    let isFavorite: (Station) -> Bool
    let distanceText: (Station) -> String?

    var body: some View {
        Section("Stops") {
            ForEach(stations) { station in
                NavigationLink(value: station) {
                    SearchStationRow(
                        station: station,
                        systemImage: "tram.fill",
                        isFavorite: isFavorite(station),
                        distanceText: distanceText(station)
                    )
                }
                .accessibilityIdentifier("search.station.\(station.id)")
            }
        }
    }
}
