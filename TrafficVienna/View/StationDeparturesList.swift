import SwiftUI

struct StationDeparturesList: View {
    @Bindable var viewModel: StationDetailViewModel

    var body: some View {
        List {
            if let message = viewModel.refreshErrorMessage {
                Label(message, systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.orange.opacity(0.12))
            }

            if !viewModel.trafficInfos.isEmpty {
                Section("Service alerts") {
                    ForEach(viewModel.trafficInfos) { info in
                        NavigationLink(value: info) {
                            DisruptionRow(info: info)
                        }
                    }
                }
            }

            if viewModel.availableCategories.count > 1 {
                FilterChips(
                    categories: viewModel.availableCategories,
                    selection: $viewModel.categoryFilter
                )
                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: 0, bottom: Spacing.xs, trailing: 0))
                .listRowBackground(Color.clear)
            }

            Section("Departures") {
                if viewModel.groups.isEmpty {
                    ContentUnavailableView(
                        "No matching departures",
                        systemImage: "line.3.horizontal.decrease.circle",
                        description: Text("Choose another transport type.")
                    )
                    .listRowBackground(Color.clear)
                } else {
                    ForEach(viewModel.groups) { group in
                        StationDepartureRow(viewModel: viewModel, group: group)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .safeAreaInset(edge: .bottom) {
            if let lastUpdated = viewModel.lastUpdated {
                StationFreshnessBar(
                    lastUpdated: lastUpdated,
                    isStale: viewModel.refreshErrorMessage != nil
                )
            }
        }
    }
}
