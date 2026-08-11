import SwiftUI

struct StationDepartureRow: View {
    @Bindable var viewModel: StationDetailViewModel
    let group: StationDepartureGroup

    var body: some View {
        HStack(spacing: Spacing.sm) {
            DepartureLineRow(
                lineName: group.line,
                destination: group.destination,
                minutes: group.minutes,
                hasDisruption: viewModel.hasDisruption(lineName: group.line),
                nextIsLive: group.isLive
            )

            Menu {
                Button("Track on Lock Screen", systemImage: "bell.badge") {
                    viewModel.startTracking(group)
                }

                Button(
                    viewModel.isFavorite(group) ? "Remove favourite" : "Add to favourites",
                    systemImage: viewModel.isFavorite(group) ? "heart.slash" : "heart"
                ) {
                    viewModel.toggleFavorite(group)
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .frame(width: 44, height: 44)
                    .contentShape(.rect)
            }
            .accessibilityLabel("More actions for line \(group.line) to \(group.destination)")
            .accessibilityIdentifier("departure-actions-\(group.line)-\(group.destination)")
        }
        .padding(.vertical, Spacing.xs)
    }
}
