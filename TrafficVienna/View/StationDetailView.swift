import SwiftUI

struct StationDetailView: View {
    @State private var viewModel: StationDetailViewModel

    init(station: Station) {
        _viewModel = State(initialValue: StationDetailViewModel(station: station))
    }

    var body: some View {
        Group {
            switch viewModel.state {
            case .loading:
                ProgressView("Loading departures…")
                    .controlSize(.large)

            case .failed(let message):
                ContentUnavailableView {
                    Label("Departures unavailable", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(message)
                } actions: {
                    Button("Try again", systemImage: "arrow.clockwise", action: retry)
                        .buttonStyle(.borderedProminent)
                }

            case .empty:
                ContentUnavailableView(
                    "No departures",
                    systemImage: "tram",
                    description: Text("Nothing is scheduled right now.")
                )

            case .loaded:
                StationDeparturesList(viewModel: viewModel)
            }
        }
        .navigationTitle(viewModel.station.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: TrafficInfo.self, destination: DisruptionDetailView.init)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button(
                    viewModel.isStationFavorited
                        ? "Remove station from favourites"
                        : "Add station to favourites",
                    systemImage: viewModel.isStationFavorited ? "star.fill" : "star",
                    action: viewModel.toggleStationFavorite
                )
                .labelStyle(.iconOnly)
                .foregroundStyle(viewModel.isStationFavorited ? .yellow : .secondary)

                Button("Refresh departures", systemImage: "arrow.clockwise", action: refresh)
                    .labelStyle(.iconOnly)
                    .disabled(viewModel.isLoadingRequest)
            }
        }
        .alert(item: $viewModel.notice) { notice in
            Alert(
                title: Text("Live Activity"),
                message: Text(notice.message)
            )
        }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isStationFavorited)
        .sensoryFeedback(.success, trigger: viewModel.trackedDepartureID)
        .task {
            await viewModel.load()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(30))
                } catch {
                    break
                }
                await viewModel.load()
            }
        }
        .refreshable {
            await viewModel.load(forceRefresh: true)
        }
        .background(DesignColor.background)
    }

    private func refresh() {
        Task { await viewModel.load(forceRefresh: true) }
    }

    private func retry() {
        Task { await viewModel.load(forceRefresh: true) }
    }
}

#Preview {
    NavigationStack {
        StationDetailView(
            station: Station(
                id: 1,
                diva: 60201468,
                name: "Praterstern",
                lat: 48.218,
                lon: 16.392
            )
        )
    }
}
