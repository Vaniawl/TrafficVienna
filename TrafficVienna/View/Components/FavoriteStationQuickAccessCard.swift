import SwiftUI

struct FavoriteStationQuickAccessCard: View {
    let station: FavoriteStation

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            Image(systemName: "star.fill")
                .font(.headline)
                .foregroundStyle(DesignColor.brand)
                .frame(width: 36, height: 36)
                .background(DesignColor.brand.opacity(0.12), in: Circle())
                .accessibilityHidden(true)

            Text(station.name)
                .font(.headline)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: Spacing.xs)

            Label("View departures", systemImage: "arrow.right")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .labelStyle(.titleAndIcon)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
        .padding(Spacing.md)
        .background(DesignColor.cardBackground, in: .rect(cornerRadius: CornerRadius.lg))
        .overlay {
            RoundedRectangle(cornerRadius: CornerRadius.lg)
                .stroke(DesignColor.border, lineWidth: 1)
        }
        .contentShape(.rect(cornerRadius: CornerRadius.lg))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    FavoriteStationQuickAccessCard(
        station: FavoriteStation(id: 1, diva: 60201040, name: "Stephansplatz")
    )
    .padding()
}
