import SwiftUI

struct DisruptionsView: View {
    @Bindable var viewModel: DisruptionsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading alerts…")
                    .controlSize(.large)

            case .failed(let message):
                ContentUnavailableView {
                    Label("Alerts unavailable", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again", systemImage: "arrow.clockwise", action: retry)
                        .buttonStyle(.borderedProminent)
                }

            case .loaded where viewModel.infos.isEmpty:
                ContentUnavailableView(
                    "All clear",
                    systemImage: "checkmark.circle.fill",
                    description: Text("All lines are running normally.")
                )

            case .loaded:
                DisruptionsList(viewModel: viewModel)
            }
        }
        .id(viewModel.state)
        .transition(Motion.stateTransition(reduceMotion: reduceMotion))
        .navigationTitle("Alerts")
        .navigationDestination(for: TrafficInfo.self, destination: DisruptionDetailView.init)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Refresh alerts", systemImage: "arrow.clockwise", action: refresh)
                    .labelStyle(.iconOnly)
                    .disabled(viewModel.isLoadingRequest)
            }
        }
        .searchable(
            text: $viewModel.lineFilter,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search line or alert"
        )
        .refreshable {
            await viewModel.load(force: true)
        }
        .background(DesignColor.background)
        .animation(Motion.quick(reduceMotion: reduceMotion), value: viewModel.state)
    }

    private func refresh() {
        Task {
            await viewModel.load(force: true)
        }
    }

    private func retry() {
        Task {
            await viewModel.load(force: true)
        }
    }
}

#Preview {
    NavigationStack {
        DisruptionsView(viewModel: DisruptionsViewModel())
    }
}
