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
                Button {
                    Task { await viewModel.scheduleReminder(group) }
                } label: {
                    Label("Remind me before departure", systemImage: "bell.badge")
                }

                Button {
                    viewModel.startTracking(group)
                } label: {
                    Label(
                        viewModel.trackedDepartureID == group.id
                            ? "Stop Lock Screen tracking"
                            : "Track on Lock Screen",
                        systemImage: viewModel.trackedDepartureID == group.id
                            ? "livephoto.slash"
                            : "livephoto"
                    )
                }
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
            .accessibilityLabel("Departure options for \(group.line) to \(group.destination)")
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
            Button("Remind me before departure", systemImage: "bell.badge") {
                Task { await viewModel.scheduleReminder(group) }
            }

            Button(
                viewModel.trackedDepartureID == group.id
                    ? "Stop Lock Screen tracking"
                    : "Track on Lock Screen",
                systemImage: viewModel.trackedDepartureID == group.id
                    ? "livephoto.slash"
                    : "livephoto"
            ) {
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
