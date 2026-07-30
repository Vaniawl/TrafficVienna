import SwiftUI

struct DisruptionsList: View {
    @Bindable var viewModel: DisruptionsViewModel

    var body: some View {
        List {
            DisruptionFilterBar(viewModel: viewModel)

            if let message = viewModel.refreshErrorMessage {
                Label(message, systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .listRowBackground(Color.orange.opacity(0.12))
            }

            if !viewModel.hasAlertsForSelectedKind {
                ContentUnavailableView(
                    "No alerts in this category",
                    systemImage: "checkmark.circle.fill",
                    description: Text("Choose another alert type to see other service information.")
                )
                .listRowBackground(Color.clear)
            } else if viewModel.filteredInfos.isEmpty {
                if viewModel.isShowingRelevantScope {
                    ContentUnavailableView {
                        Label("Your saved lines are clear", systemImage: "checkmark.circle.fill")
                    } description: {
                        Text("No current alerts affect \(viewModel.relevantLineSummary).")
                    }
                    .listRowBackground(Color.clear)
                } else {
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
                }
            } else {
                ForEach(viewModel.filteredInfos) { info in
                    NavigationLink(value: info) {
                        DisruptionRow(info: info)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}
