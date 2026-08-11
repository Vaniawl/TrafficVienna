import SwiftUI

struct MapStationSelectionCard: View {
    let station: Station
    let close: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            HStack(alignment: .top, spacing: Spacing.sm) {
                VStack(alignment: .leading, spacing: Spacing.xxs) {
                    Text("Selected stop")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(station.name)
                        .font(.title3)
                        .bold()
                        .foregroundStyle(DesignColor.primaryText)
                        .accessibilityAddTraits(.isHeader)
                }

                Spacer()

                Button("Close", systemImage: "xmark", action: close)
                    .labelStyle(.iconOnly)
                    .frame(minWidth: 44, minHeight: 44)
            }

            NavigationLink(value: station) {
                Label("View departures", systemImage: "clock.arrow.circlepath")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(PremiumPrimaryButtonStyle())
        }
        .padding(Spacing.lg)
        .premiumSurface(cornerRadius: CornerRadius.xl, elevated: true)
        .accessibilityElement(children: .contain)
    }
}
