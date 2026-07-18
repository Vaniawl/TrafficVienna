import SwiftUI

struct SearchResultsList: View {
    let stations: [Station]

    var body: some View {
        List(stations) { station in
            NavigationLink(value: station) {
                SearchStationRow(station: station, systemImage: "tram.fill")
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.visible)
    }
}
