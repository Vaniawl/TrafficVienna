import SwiftUI

struct RecentStationsList: View {
    let stations: [Station]
    let onClear: () -> Void

    var body: some View {
        List {
            Section {
                ForEach(stations) { station in
                    NavigationLink(value: station) {
                        SearchStationRow(
                            station: station,
                            systemImage: "clock.arrow.circlepath"
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
        .listStyle(.insetGrouped)
        .scrollContentBackground(.visible)
    }
}
