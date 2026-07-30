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

            Button {
                viewModel.startTracking(group)
            } label: {
                Image(
                    systemName: viewModel.trackedDepartureID == group.id
                        ? "bell.fill"
                        : "bell.badge"
                )
                .foregroundStyle(
                    viewModel.trackedDepartureID == group.id
                        ? Color.appAccent
                        : Color.secondary
                )
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Track \(group.line) to \(group.destination) on the Lock Screen")
        }
        .padding(.vertical, Spacing.xs)
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button {
                viewModel.toggleFavorite(group)
            } label: {
                Label(
                    viewModel.isFavorite(group) ? "Remove favourite" : "Add to favourites",
                    systemImage: viewModel.isFavorite(group) ? "heart.slash" : "heart"
                )
            }
            .tint(viewModel.isFavorite(group) ? .gray : .pink)
        }
        .contextMenu {
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
    }
}
