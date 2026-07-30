import SwiftUI

struct DisruptionFilterBar: View {
    @Bindable var viewModel: DisruptionsViewModel

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(viewModel.filterSummary)
                    .font(.headline)

                Text("Alerts: \(viewModel.filteredInfos.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Spacing.xs)

            Menu {
                Section("Show") {
                    ForEach(DisruptionScope.allCases) { scope in
                        Button {
                            viewModel.selectScope(scope)
                        } label: {
                            if viewModel.selectedScope == scope {
                                Label(scope.title, systemImage: "checkmark")
                            } else {
                                Label(scope.title, systemImage: scope.symbol)
                            }
                        }
                        .disabled(scope == .relevant && !viewModel.hasRelevantLines)
                    }
                }

                Section("Alert type") {
                    ForEach(DisruptionKind.allCases) { kind in
                        Button {
                            viewModel.selectKind(kind)
                        } label: {
                            if viewModel.selectedKind == kind {
                                Label(kind.title, systemImage: "checkmark")
                            } else {
                                Label(kind.title, systemImage: kind.symbol)
                            }
                        }
                    }
                }

                if !viewModel.availableCategories.isEmpty {
                    Section("Transport") {
                        Button {
                            viewModel.categoryFilter = nil
                        } label: {
                            if viewModel.categoryFilter == nil {
                                Label("All transport", systemImage: "checkmark")
                            } else {
                                Label("All transport", systemImage: "circle.grid.2x2")
                            }
                        }

                        ForEach(viewModel.availableCategories) { category in
                            Button {
                                viewModel.categoryFilter = category
                            } label: {
                                if viewModel.categoryFilter == category {
                                    Label(category.rawValue, systemImage: "checkmark")
                                } else {
                                    Label(category.rawValue, systemImage: category.symbol)
                                }
                            }
                        }
                    }
                }

                if viewModel.hasActiveFilters {
                    Section {
                        Button("Reset filters", systemImage: "arrow.counterclockwise") {
                            viewModel.clearFilters()
                        }
                    }
                }
            } label: {
                Label("Filters", systemImage: "line.3.horizontal.decrease")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("alerts.filters")
        }
        .padding(.vertical, Spacing.xs)
        .accessibilityElement(children: .contain)
    }
}
