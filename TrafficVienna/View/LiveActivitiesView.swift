import SwiftUI

struct LiveActivitiesView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var activities: [TrackedLiveActivity] = []
    @State private var showingEndAll = false

    var body: some View {
        Group {
            if activities.isEmpty {
                ContentUnavailableView(
                    "No Live Activities",
                    systemImage: "dot.radiowaves.left.and.right",
                    description: Text("Track a live departure to see it on your Lock Screen.")
                )
                .accessibilityIdentifier("liveActivities.empty")
            } else {
                List {
                    ForEach(activities) { activity in
                        activityRow(activity)
                    }
                }
                .refreshable { load() }
            }
        }
        .neoScreen()
        .navigationTitle("Live Activities")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !activities.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("End all", role: .destructive) { showingEndAll = true }
                }
            }
        }
        .confirmationDialog(
            "End all Live Activities?",
            isPresented: $showingEndAll,
            titleVisibility: .visible
        ) {
            Button("End all activities", role: .destructive) {
                Task {
                    await LiveActivityController.stopAll()
                    load()
                }
            }
            Button("Keep activities", role: .cancel) {}
        } message: {
            Text("This removes every Traffic Vienna departure from your Lock Screen.")
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            load()
        }
    }

    private func activityRow(_ activity: TrackedLiveActivity) -> some View {
        HStack(spacing: 12) {
            NeoIcon(systemName: "dot.radiowaves.left.and.right")
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "\(activity.line) → \(activity.destination)")
                    .font(.headline)
                Text(activity.stop)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    Circle()
                        .fill(activity.isLive ? .green : .secondary)
                        .frame(width: 6, height: 6)
                    Text(activity.departureDate, format: .dateTime.hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("liveActivities.item.\(activity.id)")
        .swipeActions(edge: .trailing) {
            Button("End", role: .destructive) {
                end(id: activity.id)
            }
        }
    }

    private func load() {
        activities = LiveActivityController.activeDepartures
    }

    private func end(id: String) {
        activities.removeAll { $0.id == id }
        Task {
            await LiveActivityController.stop(id: id)
            load()
        }
    }
}

#Preview {
    NavigationStack { LiveActivitiesView() }
}
