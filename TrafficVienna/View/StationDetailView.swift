//
//  StationDetailView.swift
//  TrafficVienna
//
//  Live departures for a single station, grouped by platform. Each line shows
//  its next departures as tiles and can be added to favourites.
//

import SwiftUI
import MapKit

enum StationDetailPresentation: Equatable {
    case standard
    case mapSheet
}

struct StationDetailView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLowDataMode) private var isLowDataMode
    @Environment(\.isLowPowerMode) private var isLowPowerMode
    @Environment(\.isThermallyConstrained) private var isThermallyConstrained
    @EnvironmentObject private var favoritesVM: FavoritesListViewModel
    @StateObject private var vm: StationDetailViewModel
    @State private var lineFavoriteToggles = 0
    @State private var feedback: StationFeedback?
    private let presentation: StationDetailPresentation

    init(station: Station, presentation: StationDetailPresentation = .standard) {
        self.presentation = presentation
        _vm = StateObject(wrappedValue: StationDetailViewModel(station: station))
    }

    var body: some View {
        content
            .neoScreen()
            .navigationTitle(vm.station.name)
            .navigationBarTitleDisplayMode(.inline)
            .sensoryFeedback(.impact(weight: .light), trigger: isStationFavorited)
            .sensoryFeedback(.selection, trigger: lineFavoriteToggles)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        favoritesVM.toggleStation(vm.station)
                    } label: {
                        Image(systemName: isStationFavorited ? "star.fill" : "star")
                            .foregroundStyle(isStationFavorited ? NeoDesign.favorite : .secondary)
                    }
                    .accessibilityLabel(isStationFavorited ? "Remove station from favourites" : "Add station to favourites")
                }
                if StationDirections.isAvailable(for: vm.station) {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            StationDirections.openWalkingDirections(to: vm.station)
                        } label: {
                            Image(systemName: "figure.walk")
                        }
                        .accessibilityLabel("Walking directions")
                        .accessibilityIdentifier("station.walkingDirections.toolbar")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.load(forceRefresh: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.isLoading || vm.isRefreshing)
                    .accessibilityLabel("Refresh departures")
                }
            }
            .task(id: pollingContext) {
                guard pollingContext.isActive else { return }
                // Keep departures current while the screen is visible. Cancelled
                // automatically on disappear. Cached responses keep this cheap.
                while !Task.isCancelled {
                    await vm.load()
                    try? await Task.sleep(for: .seconds(
                        PollingFeed.stationDetail.seconds(usesConstrainedCadence: usesConstrainedCadence)
                    ))
                }
            }
            .refreshable { await vm.load(forceRefresh: true) }
            .alert(feedback?.title ?? "", isPresented: Binding(
                get: { feedback != nil },
                set: { if !$0 { feedback = nil } }
            )) {
                Button("OK", role: .cancel) { feedback = nil }
            } message: {
                Text(feedback?.message ?? "")
            }
    }

    private var pollingContext: PollingContext {
        PollingContext(isActive: scenePhase == .active, usesConstrainedCadence: usesConstrainedCadence)
    }

    private var usesConstrainedCadence: Bool {
        EnergyPolicy(
            isLowDataMode: isLowDataMode,
            isLowPowerMode: isLowPowerMode,
            isThermallyConstrained: isThermallyConstrained
        )
            .usesConstrainedPolling
    }

    private var isStationFavorited: Bool {
        favoritesVM.isStationFavorite(id: vm.station.id)
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.monitor == nil {
            ProgressView("Loading…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if !vm.groups.isEmpty {
            departuresList
        } else if let error = vm.errorMessage {
            ContentUnavailableView("Couldn’t load departures", systemImage: "wifi.exclamationmark", description: Text(error))
        } else {
            ContentUnavailableView("No departures", systemImage: "tram", description: Text("Nothing scheduled right now."))
        }
    }

    private var departuresList: some View {
        List {
            if presentation == .standard {
                NeoHeader(
                    eyebrow: "Live station",
                    title: LocalizedStringKey(vm.station.name),
                    subtitle: "Real-time departures and service updates"
                )
                .listRowInsets(EdgeInsets(top: 12, leading: 18, bottom: 8, trailing: 18))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }

            if let text = vm.lastUpdatedText {
                freshnessCard(text)
                    .listRowInsets(EdgeInsets(top: presentation == .mapSheet ? 12 : 4, leading: 18, bottom: 8, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if StationDirections.isAvailable(for: vm.station) {
                Button {
                    StationDirections.openWalkingDirections(to: vm.station)
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "figure.walk")
                            .font(.body.weight(.semibold))
                            .foregroundStyle(NeoDesign.accent)
                            .frame(width: 36, height: 36)
                            .background(NeoDesign.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Walking directions")
                                .font(.headline)
                            Text("Open this stop in Apple Maps")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.caption.bold())
                            .foregroundStyle(.tertiary)
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .neoCard()
                .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 8, trailing: 18))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .accessibilityIdentifier("station.walkingDirections.card")
            }

            if let staleMessage = vm.staleMessage {
                StaleDataBanner(message: staleMessage)
                    .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 8, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if let refreshError = vm.errorMessage {
                Label(refreshError, systemImage: "wifi.exclamationmark")
                    .font(.caption)
                    .foregroundStyle(.orange)
                    .neoCard()
                    .listRowInsets(EdgeInsets(top: 4, leading: 18, bottom: 8, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }

            if !vm.trafficInfos.isEmpty {
                Section {
                    ForEach(vm.trafficInfos) { info in
                        DisruptionRow(info: info).neoCard()
                    }
                } header: {
                    Label("Service alerts", systemImage: "exclamationmark.triangle.fill")
                        .foregroundStyle(.orange)
                }
            }

            if vm.availableCategories.count > 1 {
                Section {
                    FilterChips(categories: vm.availableCategories, selection: $vm.categoryFilter)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach(vm.groups) { group in
                    lineRow(group)
                        .neoCard()
                        .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
            } header: {
                Text("Departures")
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func freshnessCard(_ text: String) -> some View {
        let isStale = vm.freshness?.isStale == true
        return HStack(spacing: 12) {
            Image(systemName: isStale ? "wifi.slash" : "bolt.fill")
                .font(.caption.bold())
                .foregroundStyle(isStale ? .orange : NeoDesign.accent)
                .frame(width: 32, height: 32)
                .background(
                    (isStale ? Color.orange : NeoDesign.accent).opacity(0.10),
                    in: Circle()
                )
            Text(isStale ? LocalizedStringKey("Saved data") : LocalizedStringKey("Live departures"))
                .font(.subheadline.weight(.semibold))
            Spacer(minLength: 12)
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .multilineTextAlignment(.trailing)
        }
        .neoCard(padding: 12)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(isStale ? "Saved data, \(text)" : text)
        .accessibilityIdentifier("station.freshness")
    }

    private func lineRow(_ group: StationDetailViewModel.DepartureGroup) -> some View {
        let shareContent = DepartureShareContent.make(
            line: group.line,
            destination: group.destination,
            station: vm.station.name,
            minutes: group.minutes.first ?? 0
        )

        return VStack(alignment: .leading, spacing: 6) {
            DepartureLineRow(
                lineName: group.line,
                destination: group.destination,
                minutes: group.minutes,
                hasDisruption: vm.hasDisruption(lineName: group.line),
                nextIsLive: group.isLive
            )

            HStack(spacing: 8) {
                Button {
                    scheduleReminder(for: group)
                } label: {
                    Label("Remind", systemImage: "bell.badge")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(.quaternary, in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "\(String(localized: "Remind me before departure")): \(group.line), \(group.destination)"))

                Button {
                    startTracking(group)
                } label: {
                    Label("Track", systemImage: "dot.radiowaves.left.and.right")
                        .font(.caption.bold())
                        .foregroundStyle(NeoDesign.accent)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .background(NeoDesign.accent.opacity(0.10), in: Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "\(String(localized: "Track on Lock Screen")): \(group.line), \(group.destination)"))
                .accessibilityIdentifier("station.track.\(group.id)")

                ShareLink(item: shareContent.text, subject: Text(shareContent.subject)) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(.quaternary, in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(verbatim: "\(String(localized: "Share departure")): \(group.line), \(group.destination)"))
                .accessibilityIdentifier("station.share.\(group.id)")

                if vm.station.diva != nil {
                    let isFav = favoritesVM.isLineFavorite(
                        diva: vm.station.diva,
                        lineName: group.line,
                        destination: group.destination
                    )
                    Button {
                        favoritesVM.toggleLineFavorite(
                            diva: vm.station.diva,
                            lineName: group.line,
                            destination: group.destination
                        )
                        lineFavoriteToggles += 1
                    } label: {
                        Image(systemName: isFav ? "heart.fill" : "heart")
                            .foregroundStyle(isFav ? NeoDesign.favorite : .secondary)
                            .frame(width: 44, height: 44)
                            .background(.quaternary, in: Circle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(isFav ? "Remove \(group.line) from favourites" : "Save \(group.line) to favourites")
                    .accessibilityHint("Updates this line in your favourites")
                } else {
                    Color.clear
                        .frame(width: 44, height: 44)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button {
                scheduleReminder(for: group)
            } label: {
                Label("Remind me before departure", systemImage: "bell.badge")
            }

            Button {
                startTracking(group)
            } label: {
                Label("Track on Lock Screen", systemImage: "dot.radiowaves.left.and.right")
            }

            ShareLink(item: shareContent.text, subject: Text(shareContent.subject)) {
                Label("Share departure", systemImage: "square.and.arrow.up")
            }

            Button {
                favoritesVM.toggleLineFavorite(
                    diva: vm.station.diva,
                    lineName: group.line,
                    destination: group.destination
                )
                lineFavoriteToggles += 1
            } label: {
                Label(
                    favoritesVM.isLineFavorite(
                        diva: vm.station.diva,
                        lineName: group.line,
                        destination: group.destination
                    ) ? "Remove favourite" : "Add to favourites",
                    systemImage: "heart"
                )
            }
        }
    }

    private func scheduleReminder(for group: StationDetailViewModel.DepartureGroup) {
        Task {
            do {
                try await DepartureReminderScheduler.schedule(
                    line: group.line,
                    destination: group.destination,
                    stop: vm.station.name,
                    minutes: group.minutes.first ?? 0
                )
                feedback = StationFeedback(
                    title: String(localized: "Departure reminder"),
                    message: String(
                        format: String(localized: "We’ll notify you shortly before %@ departs."),
                        locale: .current,
                        group.line
                    )
                )
            } catch {
                feedback = StationFeedback(
                    title: String(localized: "Departure reminder"),
                    message: error.localizedDescription
                )
            }
        }
    }

    private func startTracking(_ group: StationDetailViewModel.DepartureGroup) {
        Task {
            let result = await LiveActivityController.track(
                line: group.line,
                destination: group.destination,
                stop: vm.station.name,
                minutes: group.minutes.first ?? 0,
                isLive: group.isLive
            )
            feedback = StationFeedback(
                title: String(localized: "Lock Screen tracking"),
                message: result.message(line: group.line)
            )
        }
    }
}

private struct StationFeedback {
    let title: String
    let message: String
}

#Preview {
    NavigationStack {
        StationDetailView(
            station: Station(id: 1, diva: 60201468, name: "Praterstern",
                             lat: 48.218, lon: 16.392)
        )
    }
    .environmentObject(FavoritesListViewModel())
}
