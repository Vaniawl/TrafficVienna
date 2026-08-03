import SwiftUI
import UIKit

struct DepartureRemindersView: View {
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var viewModel: DepartureRemindersViewModel
    @State private var isShowingCancelAll = false

    init(client: DepartureReminderClient = .live) {
        _viewModel = State(
            initialValue: DepartureRemindersViewModel(client: client)
        )
    }

    var body: some View {
        List {
            permissionSection

            if viewModel.isLoading {
                Section {
                    ProgressView("Loading reminders…")
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            } else if viewModel.reminders.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No departure reminders",
                        systemImage: "bell.slash",
                        description: Text("Choose Remind me from a live departure to see it here.")
                    )
                    .listRowBackground(Color.clear)
                    .accessibilityIdentifier("reminders.empty")
                }
            } else {
                Section("Scheduled") {
                    ForEach(viewModel.reminders) { reminder in
                        reminderRow(reminder)
                    }
                    .onDelete(perform: cancel)
                }
            }
        }
        .navigationTitle("Departure reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !viewModel.reminders.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel all", role: .destructive) {
                        isShowingCancelAll = true
                    }
                }
            }
        }
        .confirmationDialog(
            "Cancel all reminders?",
            isPresented: $isShowingCancelAll,
            titleVisibility: .visible
        ) {
            Button("Cancel all reminders", role: .destructive) {
                Task {
                    await viewModel.cancelAll()
                }
            }
            Button("Keep reminders", role: .cancel) {}
        } message: {
            Text("This removes every pending departure reminder from this device.")
        }
        .task { await viewModel.load() }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active else { return }
            Task { await viewModel.load() }
        }
    }

    private var permissionSection: some View {
        Section("Notifications") {
            LabeledContent {
                Text(permissionTitle)
                    .foregroundStyle(permissionColor)
            } label: {
                Label("Permission", systemImage: permissionIcon)
            }

            if viewModel.permission == .disabled {
                Button("Open notification settings", systemImage: "gear") {
                    openSettings()
                }
            } else {
                Text("Traffic Vienna asks for permission only when you create your first reminder.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func reminderRow(
        _ reminder: ScheduledDepartureReminder
    ) -> some View {
        HStack(spacing: Spacing.md) {
            LineBadge(line: reminder.line)

            VStack(alignment: .leading, spacing: Spacing.xxs) {
                Text(reminder.destination)
                    .font(.headline)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 3 : 1)
                Text(reminder.stop)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
                if let fireDate = reminder.fireDate {
                    Text("Reminder \(fireDate, style: .relative)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, Spacing.xs)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
    }

    private var permissionTitle: LocalizedStringKey {
        switch viewModel.permission {
        case .notDetermined:
            "Not requested"
        case .enabled:
            "Enabled"
        case .disabled:
            "Disabled"
        }
    }

    private var permissionIcon: String {
        switch viewModel.permission {
        case .notDetermined:
            "bell"
        case .enabled:
            "bell.fill"
        case .disabled:
            "bell.slash"
        }
    }

    private var permissionColor: Color {
        switch viewModel.permission {
        case .notDetermined:
            .secondary
        case .enabled:
            .green
        case .disabled:
            .red
        }
    }

    private func cancel(at offsets: IndexSet) {
        viewModel.cancel(at: offsets)
    }

    private func openSettings() {
        guard let url = URL(string: UIApplication.openNotificationSettingsURLString) else {
            return
        }
        openURL(url)
    }
}

#Preview("No reminders") {
    NavigationStack {
        DepartureRemindersView(
            client: DepartureReminderClient(
                permission: { .notDetermined },
                schedule: { _ in throw DepartureReminderError.departureTooSoon },
                scheduled: { [] },
                cancel: { _ in },
                cancelAll: {}
            )
        )
    }
}
