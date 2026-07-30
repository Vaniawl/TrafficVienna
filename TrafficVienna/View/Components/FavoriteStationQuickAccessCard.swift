import SwiftUI

struct FavoriteStationQuickAccessCard: View {
    let station: FavoriteStation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        HStack(spacing: Spacing.md) {
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "star.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DesignColor.brand)
                    .frame(width: 44, height: 44)
                    .background(DesignColor.brand.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
            }

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(station.name)
                    .font(.headline)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text("View departures")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.xs)

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Spacing.md)
        .background(DesignColor.cardBackground, in: .rect(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(DesignColor.border, lineWidth: 1)
        }
        .contentShape(.rect(cornerRadius: CornerRadius.lg))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            Text(verbatim: station.name + ". " + String(localized: "View departures"))
        )
        .accessibilityInputLabels([Text(station.name), Text("View departures")])
    }
}

#Preview {
    FavoriteStationQuickAccessCard(
        station: FavoriteStation(id: 1, diva: 60201040, name: "Stephansplatz")
    )
    .padding()
}
