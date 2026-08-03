import SwiftUI

struct DisruptionsView: View {
    @Bindable var viewModel: DisruptionsViewModel
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
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
                if viewModel.isShowingSavedData {
                    ContentUnavailableView {
                        Label(
                            "No alerts in saved data",
                            systemImage: "clock.badge.exclamationmark"
                        )
                    } description: {
                        VStack(spacing: Spacing.sm) {
                            Text("The last successful update contained no service alerts.")
                            if let message = viewModel.refreshErrorMessage {
                                Text(message)
                                    .font(.footnote)
                            }
                        }
                    } actions: {
                        Button("Try again", systemImage: "arrow.clockwise", action: retry)
                            .buttonStyle(.borderedProminent)
                    }
                    .accessibilityIdentifier("alerts.saved-empty")
                } else {
                    ContentUnavailableView(
                        "All clear",
                        systemImage: "checkmark.circle.fill",
                        description: Text("All lines are running normally.")
                    )
                }

            case .loaded:
                DisruptionsList(viewModel: viewModel)
            }
        }
        .transition(Motion.stateTransition(reduceMotion: reduceMotion))
        .navigationTitle("Alerts")
        .navigationDestination(for: TrafficInfo.self, destination: DisruptionDetailView.init)
        .searchable(
            text: $viewModel.lineFilter,
            placement: .automatic,
            prompt: "Search line or alert"
        )
        .refreshable {
            await viewModel.load(force: true)
        }
        .background(DesignColor.background)
        .animation(Motion.quick(reduceMotion: reduceMotion), value: viewModel.state)
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
