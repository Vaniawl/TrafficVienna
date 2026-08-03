import SwiftUI

struct RecentStationsList: View {
    let stations: [Station]
    let isFavorite: (Station) -> Bool
    let distanceText: (Station) -> String?
    let onClear: () -> Void

    var body: some View {
        Section {
            ForEach(stations) { station in
                NavigationLink(value: station) {
                    SearchStationRow(
                        station: station,
                        systemImage: "clock.arrow.circlepath",
                        isFavorite: isFavorite(station),
                        distanceText: distanceText(station)
                    )
                }
            }
        } header: {
            HStack {
                Text("Recent")
                    .font(.headline)

                Spacer()

                Button("Clear", action: onClear)
                    .textCase(nil)
                    .frame(minHeight: 44)
            }
        }
    }
}
