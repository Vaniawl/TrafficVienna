import SwiftUI

struct FavoriteStationQuickAccessCard: View {
    let station: FavoriteStation
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            if !dynamicTypeSize.isAccessibilitySize {
                Image(systemName: "star.fill")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DesignColor.brand)
                    .frame(width: 44, height: 44)
                    .background(DesignColor.brand.opacity(0.12), in: Circle())
                    .accessibilityHidden(true)
            }

            Text(station.name)
                .font(dynamicTypeSize.isAccessibilitySize ? .body : .headline)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? 1 : 2)
                .minimumScaleFactor(dynamicTypeSize.isAccessibilitySize ? 0.7 : 1)
                .fixedSize(horizontal: false, vertical: true)

            if !dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: Spacing.xs)
            }

            Label {
                Group {
                    if dynamicTypeSize.isAccessibilitySize {
                        Text("Departures")
                    } else {
                        Text("View departures")
                    }
                }
                .font(.subheadline)
            } icon: {
                Image(systemName: "arrow.right")
                    .font(.system(size: 14, weight: .semibold))
            }
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 132, alignment: .topLeading)
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
