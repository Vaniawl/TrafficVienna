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

            Menu("More actions", systemImage: "ellipsis.circle") {
                Button("Track on Lock Screen", systemImage: "bell.badge") {
                    viewModel.startTracking(group)
                }

                Button(
                    viewModel.isFavorite(group) ? "Remove favourite" : "Add to favourites",
                    systemImage: viewModel.isFavorite(group) ? "heart.slash" : "heart"
                ) {
                    viewModel.toggleFavorite(group)
                }
            }
            .labelStyle(.iconOnly)
            .frame(minWidth: 44, minHeight: 44)
        }
        .padding(.vertical, Spacing.xs)
    }
}
