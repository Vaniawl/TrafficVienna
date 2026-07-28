import SwiftUI

struct DisruptionsView: View {
    @ObservedObject var vm: DisruptionsViewModel
    @EnvironmentObject private var router: AppRouter
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLowDataMode) private var isLowDataMode
    @Environment(\.isLowPowerMode) private var isLowPowerMode
    @Environment(\.isThermallyConstrained) private var isThermallyConstrained
    var isActive = true

    var body: some View {
        List {
            NeoHeader(eyebrow: "Network", title: "Service alerts", subtitle: "Live changes across Vienna")
                .listRowInsets(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

            content
        }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .neoScreen()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.load(force: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.isLoading || vm.isRefreshing)
                    .accessibilityLabel("Refresh alerts")
                }
            }
            .refreshable { await vm.load(force: true) }
            .searchable(text: $vm.lineFilter, placement: .navigationBarDrawer(displayMode: .always), prompt: "Filter")
            .task(id: pollingContext) {
                guard pollingContext.isActive else { return }
                while !Task.isCancelled {
                    await vm.load()
                    try? await Task.sleep(for: .seconds(
                        PollingFeed.serviceAlerts.seconds(usesConstrainedCadence: usesConstrainedCadence)
                    ))
                }
            }
    }

    private var shouldPoll: Bool { isActive && scenePhase == .active }

    private var pollingContext: PollingContext {
        PollingContext(isActive: shouldPoll, usesConstrainedCadence: usesConstrainedCadence)
    }

    private var usesConstrainedCadence: Bool {
        EnergyPolicy(
            isLowDataMode: isLowDataMode,
            isLowPowerMode: isLowPowerMode,
            isThermallyConstrained: isThermallyConstrained
        )
            .usesConstrainedPolling
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.infos.isEmpty {
            VStack(alignment: .leading, spacing: 12) {
                Label("Checking the network…", systemImage: "wave.3.right")
                    .font(.headline)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.16))
                    .frame(height: 16)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.10))
                    .frame(width: 180, height: 12)
            }
            .neoCard()
            .redacted(reason: .placeholder)
            .shimmer()
            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else if let error = vm.errorMessage, vm.infos.isEmpty {
            NeoEmptyState(
                icon: "wifi.exclamationmark",
                title: "Couldn’t check the network",
                message: LocalizedStringKey(error),
                tint: .orange,
                actionTitle: "Retry",
                action: { Task { await vm.load(force: true) } }
            )
            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else if vm.infos.isEmpty {
            NeoEmptyState(
                icon: "checkmark.circle.fill",
                title: "All clear",
                message: "All lines are running normally. Save the lines you use and Traffic Vienna will prioritise changes that affect you.",
                tint: .green,
                actionTitle: "Review favourites",
                action: { router.navigate(to: .favourites) }
            )
            .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
        } else {
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
            if vm.availableCategories.count > 1 {
                FilterChips(categories: vm.availableCategories, selection: $vm.categoryFilter)
                    .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                    .listRowBackground(Color.clear)
            }

            ForEach(vm.filteredInfos) { info in
                VStack(alignment: .leading, spacing: 10) {
                    if vm.isRelevant(info) {
                        Label("Affects your favourites", systemImage: "star.fill")
                            .font(.caption.bold()).foregroundStyle(NeoDesign.accent)
                    }
                    DisruptionRow(info: info)
                }.neoCard()
                    .listRowInsets(EdgeInsets(top: 6, leading: 18, bottom: 6, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
    }

}

#Preview {
    NavigationStack { DisruptionsView(vm: DisruptionsViewModel()) }
}
