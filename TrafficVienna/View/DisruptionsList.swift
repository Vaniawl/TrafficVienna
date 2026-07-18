import SwiftUI

struct DisruptionsList: View {
    @Bindable var viewModel: DisruptionsViewModel

    var body: some View {
        List {
            DisruptionKindPicker(
                selection: viewModel.selectedKind,
                onSelect: viewModel.selectKind
            )
            .listRowInsets(EdgeInsets(top: Spacing.xs, leading: 0, bottom: Spacing.xs, trailing: 0))
            .listRowBackground(Color.clear)

            if let message = viewModel.refreshErrorMessage {
                Label(message, systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.orange.opacity(0.12))
            }

            if viewModel.availableCategories.count > 1 {
                FilterChips(
                    categories: viewModel.availableCategories,
                    selection: $viewModel.categoryFilter
                )
                .listRowInsets(EdgeInsets(top: Spacing.xs, leading: 0, bottom: Spacing.xs, trailing: 0))
                .listRowBackground(Color.clear)
            }

            if !viewModel.hasAlertsForSelectedKind {
                ContentUnavailableView(
                    "No alerts in this category",
                    systemImage: "checkmark.circle.fill",
                    description: Text("Choose another alert type to see other service information.")
                )
                .listRowBackground(Color.clear)
            } else if viewModel.filteredInfos.isEmpty {
                ContentUnavailableView {
                    Label("No matching alerts", systemImage: "line.3.horizontal.decrease.circle")
                } description: {
                    Text("Try another alert type, line, or search term.")
                } actions: {
                    if viewModel.hasActiveFilters {
                        Button("Clear filters", action: viewModel.clearFilters)
                            .buttonStyle(.bordered)
                    }
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(viewModel.filteredInfos) { info in
                        NavigationLink(value: info) {
                            DisruptionRow(info: info)
                        }
                    }
                } header: {
                    Text("Alerts: \(viewModel.filteredInfos.count)")
                }
            }
        }
        .listStyle(.plain)
    }
}
