import SwiftUI

struct SearchStationRow: View {
    let station: Station
    let systemImage: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(station.name)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(DesignColor.primaryText)

                Text("Live departures")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(DesignColor.brandDark)
                .frame(width: 36, height: 36)
                .background(DesignColor.brand.opacity(0.12), in: .circle)
                .accessibilityHidden(true)
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .combine)
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
