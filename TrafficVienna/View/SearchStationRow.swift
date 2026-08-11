import SwiftUI

struct SearchStationRow: View {
    let station: Station
    let systemImage: String
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                stationDetails
            } else {
                Label {
                    stationDetails
                } icon: {
                    Image(systemName: systemImage)
                        .foregroundStyle(DesignColor.accentText)
                        .frame(width: 36, height: 36)
                        .background(DesignColor.brand.opacity(0.12), in: .circle)
                        .accessibilityHidden(true)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
    }

    private var stationDetails: some View {
        VStack(alignment: .leading, spacing: Spacing.xxs) {
            Text(station.name)
                .font(.body.weight(.semibold))
                .foregroundStyle(DesignColor.primaryText)
                .fixedSize(horizontal: false, vertical: true)

            Text("Live departures")
                .font(.subheadline)
                .foregroundStyle(DesignColor.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    SearchStationRow(
        station: Station(
            id: 1,
            diva: 60201435,
            name: "Stephansplatz",
            lat: 48.2083,
            lon: 16.3731
        ),
        systemImage: "tram.fill"
    )
    .padding()
}
