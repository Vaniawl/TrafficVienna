import SwiftUI

struct SearchResultsList: View {
    let stations: [Station]

    var body: some View {
        List(stations) { station in
            NavigationLink(value: station) {
                SearchStationRow(station: station, systemImage: "tram.fill")
            }
            .accessibilityIdentifier("station-row-\(station.id)")
            .listRowBackground(DesignColor.cardBackground)
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(Spacing.md)
        .scrollContentBackground(.hidden)
        .background(DesignColor.background)
    }
}
