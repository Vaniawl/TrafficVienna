import SwiftUI
import UIKit

struct StationDetailView: View {
    @Environment(\.openURL) private var openURL
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
                if viewModel.isShowingStaleData {
                    ContentUnavailableView {
                        Label(
                            "No departures in saved data",
                            systemImage: "clock.badge.exclamationmark"
                        )
                    } description: {
                        VStack(spacing: Spacing.sm) {
                            Text("The last successful update contained no upcoming departures.")
                            if let message = viewModel.refreshErrorMessage {
                                Text(message)
                                    .font(.footnote)
                            }
                        }
                    } actions: {
                        Button("Try again", systemImage: "arrow.clockwise", action: retry)
                            .buttonStyle(.borderedProminent)
                    }
                    .accessibilityIdentifier("station-detail.saved-empty")
                } else {
                    ContentUnavailableView {
                        Label("No departures", systemImage: "tram")
                    } description: {
                        Text("Nothing is scheduled right now.")
                    } actions: {
                        Button("Refresh departures", systemImage: "arrow.clockwise", action: retry)
                            .buttonStyle(.bordered)
                    }
                    .accessibilityIdentifier("station-detail.empty")
                }

            case .loaded:
                StationDeparturesList(viewModel: viewModel)
            }
        }
        .navigationTitle(viewModel.station.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: TrafficInfo.self, destination: DisruptionDetailView.init)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(
                    viewModel.isStationFavorited
                        ? "Remove station from favourites"
                        : "Add station to favourites",
                    systemImage: viewModel.isStationFavorited ? "star.fill" : "star",
                    action: viewModel.toggleStationFavorite
                )
                .labelStyle(.iconOnly)
                .foregroundStyle(viewModel.isStationFavorited ? .yellow : .secondary)
            }
        }
        .alert(item: $viewModel.notice) { notice in
            if notice.offersSettings {
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message),
                    primaryButton: .default(Text("Open Settings"), action: openSettings),
                    secondaryButton: .cancel()
                )
            } else {
                Alert(
                    title: Text(notice.title),
                    message: Text(notice.message)
                )
            }
        }
        .sensoryFeedback(.impact(weight: .light), trigger: viewModel.isStationFavorited)
        .sensoryFeedback(.success, trigger: viewModel.trackedDepartureID)
        .task {
            await viewModel.load()
            while !Task.isCancelled {
                do {
                    try await Task.sleep(for: .seconds(60))
                } catch {
                    break
                }
                await viewModel.load()
            }
        }
        .refreshable {
            await viewModel.load(forceRefresh: true)
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoriteStationsDidChange)) { _ in
            viewModel.reloadStationFavorite()
        }
        .onReceive(NotificationCenter.default.publisher(for: .favoriteRoutesDidChange)) { _ in
            viewModel.reloadRouteFavorites()
        }
        .background(DesignColor.background)
    }

    private func retry() {
        Task { await viewModel.load(forceRefresh: true) }
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        openURL(url)
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
