import SwiftUI

struct DepartureRemindersView: View {
    @State private var reminders: [ScheduledDepartureReminder] = []
    @State private var isLoading = true
    @State private var showingCancelAll = false

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if reminders.isEmpty {
                ContentUnavailableView(
                    "No departure reminders",
                    systemImage: "bell.slash",
                    description: Text("Set a reminder from any live departure to see it here.")
                )
                .accessibilityIdentifier("reminders.empty")
            } else {
                List {
                    ForEach(reminders) { reminder in
                        reminderRow(reminder)
                    }
                    .onDelete(perform: cancel)
                }
                .refreshable { await load() }
            }
        }
        .navigationTitle("Departure reminders")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !reminders.isEmpty {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel all", role: .destructive) { showingCancelAll = true }
                }
            }
        }
        .confirmationDialog(
            "Cancel all reminders?",
            isPresented: $showingCancelAll,
            titleVisibility: .visible
        ) {
            Button("Cancel all reminders", role: .destructive) {
                Task {
                    await DepartureReminderScheduler.cancelAllScheduled()
                    reminders = []
                }
            }
            Button("Keep reminders", role: .cancel) {}
        } message: {
            Text("This removes every pending departure reminder from this device.")
        }
        .task { await load() }
    }

    private func reminderRow(_ reminder: ScheduledDepartureReminder) -> some View {
        HStack(spacing: 12) {
            NeoIcon(systemName: "bell.fill")
            VStack(alignment: .leading, spacing: 4) {
                Text(verbatim: "\(reminder.line) → \(reminder.destination)")
                    .font(.headline)
                Text(reminder.stop)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let fireDate = reminder.fireDate {
                    Text(fireDate, format: .dateTime.weekday(.abbreviated).hour().minute())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .accessibilityElement(children: .combine)
    }

    private func load() async {
        reminders = await DepartureReminderScheduler.scheduled()
        isLoading = false
    }

    private func cancel(at offsets: IndexSet) {
        let identifiers = offsets.map { reminders[$0].id }
        reminders.remove(atOffsets: offsets)
        identifiers.forEach(DepartureReminderScheduler.cancel(identifier:))
    }
}

#Preview {
    NavigationStack { DepartureRemindersView() }
}
