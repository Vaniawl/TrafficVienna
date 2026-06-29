import SwiftUI

struct DisruptionsView: View {
    @ObservedObject var vm: DisruptionsViewModel

    var body: some View {
        content
            .navigationTitle("Alerts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await vm.load(force: true) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(vm.isLoading)
                    .accessibilityLabel("Refresh alerts")
                }
            }
            .refreshable { await vm.load(force: true) }
            .searchable(text: $vm.lineFilter, placement: .navigationBarDrawer(displayMode: .always), prompt: "Filter")
            .task {
                while !Task.isCancelled {
                    await vm.load()
                    try? await Task.sleep(for: .seconds(120))
                }
            }
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
                if vm.availableCategories.count > 1 {
                    FilterChips(categories: vm.availableCategories, selection: $vm.categoryFilter)
                        .listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 4, trailing: 0))
                        .listRowBackground(Color.clear)
                }

                ForEach(vm.filteredInfos) { DisruptionRow(info: $0) }
            }
                .listStyle(.plain)
        }
    }

}

#Preview {
    NavigationStack { DisruptionsView(vm: DisruptionsViewModel()) }
}
