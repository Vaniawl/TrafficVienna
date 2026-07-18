import SwiftUI

struct FavoriteStationsQuickAccessView: View {
    let stations: [FavoriteStation]

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick access")
                .font(.headline)

            ScrollView(.horizontal) {
                HStack(spacing: Spacing.xs) {
                    ForEach(stations) { station in
                        NavigationLink {
                            StationDetailView(
                                station: Station(
                                    id: station.id,
                                    diva: station.diva,
                                    name: station.name,
                                    lat: 0,
                                    lon: 0
                                )
                            )
                        } label: {
                            Label(station.name, systemImage: "star.fill")
                                .font(.subheadline)
                                .bold()
                                .padding(.horizontal, Spacing.sm)
                                .frame(minHeight: 44)
                                .background(DesignColor.cardBackground, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .scrollIndicators(.hidden)
        }
        .accessibilityElement(children: .contain)
    }
}
