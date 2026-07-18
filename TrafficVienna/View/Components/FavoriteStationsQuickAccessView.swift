import SwiftUI

struct FavoriteStationsQuickAccessView: View {
    let stations: [FavoriteStation]
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Text("Quick access")
                .font(.headline)

            ScrollView(.horizontal) {
                LazyHStack(spacing: Spacing.sm) {
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
                            FavoriteStationQuickAccessCard(station: station)
                        }
                        .buttonStyle(.plain)
                        .containerRelativeFrame(
                            .horizontal,
                            count: cardGridCount,
                            span: cardGridSpan,
                            spacing: Spacing.sm
                        )
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollTargetBehavior(.viewAligned)
        }
        .accessibilityElement(children: .contain)
    }

    private var cardGridCount: Int {
        if dynamicTypeSize.isAccessibilitySize { 1 }
        else if horizontalSizeClass == .regular { 2 }
        else { 12 }
    }

    private var cardGridSpan: Int {
        dynamicTypeSize.isAccessibilitySize || horizontalSizeClass == .regular ? 1 : 10
    }
}
