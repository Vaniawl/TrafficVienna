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
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(Spacing.lg)
        .background(.regularMaterial, in: .rect(cornerRadius: CornerRadius.xl))
        .shadow(
            color: Shadow.lg.color,
            radius: Shadow.lg.radius,
            x: Shadow.lg.x,
            y: Shadow.lg.y
        )
        .accessibilityElement(children: .contain)
    }
}
