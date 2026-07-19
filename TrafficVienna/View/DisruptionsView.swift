import SwiftUI

struct DisruptionsView: View {
    @ObservedObject var vm: DisruptionsViewModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.isLowDataMode) private var isLowDataMode
    @Environment(\.isLowPowerMode) private var isLowPowerMode
    var isActive = true

    var body: some View {
        content
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
        EnergyPolicy(isLowDataMode: isLowDataMode, isLowPowerMode: isLowPowerMode)
            .usesConstrainedPolling
    }

    @ViewBuilder
    private var content: some View {
        if vm.isLoading && vm.infos.isEmpty {
            ProgressView("Loading...")
                .tint(.secondary)
                .font(.caption)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let error = vm.errorMessage, vm.infos.isEmpty {
            VStack(spacing: 8) {
                Text("Error")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.red)
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Button("Retry") { Task { await vm.load(force: true) } }
                    .font(.caption.weight(.medium))
                    .buttonStyle(.borderedProminent)
                    .tint(.appAccent)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if vm.infos.isEmpty {
            VStack(spacing: 8) {
                Image(systemName: "checkmark.circle")
                    .font(.title2)
                    .foregroundStyle(.green)
                Text("All clear")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.green)
                Text("All lines are running normally.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            List {
                NeoHeader(eyebrow: "Network", title: "Service alerts", subtitle: "Live changes across Vienna")
                    .listRowInsets(EdgeInsets(top: 12, leading: 18, bottom: 12, trailing: 18))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
        }
    }

}

#Preview {
    NavigationStack { DisruptionsView(vm: DisruptionsViewModel()) }
}
