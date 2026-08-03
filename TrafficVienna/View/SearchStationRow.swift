import SwiftUI

struct SearchStationRow: View {
    let station: Station
    let systemImage: String
    var isFavorite = false
    var distanceText: String?

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                HStack(spacing: Spacing.xs) {
                    Text(station.name)
                        .font(.body)
                        .foregroundStyle(.primary)

                    if isFavorite {
                        Image(systemName: "star.fill")
                            .font(.caption)
                            .foregroundStyle(.yellow)
                            .accessibilityLabel("Saved")
                    }
                }

                HStack(spacing: Spacing.xs) {
                    Text("Live departures")
                    if let distanceText {
                        Text("·")
                        Text(distanceText)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.appAccent)
                .frame(width: 36, height: 36)
                .background(.appChipBg, in: .circle)
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
        systemImage: "tram.fill",
        isFavorite: true,
        distanceText: "350 m"
    )
    .padding()
}
