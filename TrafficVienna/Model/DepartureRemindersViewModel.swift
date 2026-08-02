import Foundation
import Observation

@MainActor
@Observable
final class DepartureRemindersViewModel {
    private(set) var permission: DepartureReminderPermission = .notDetermined
    private(set) var reminders: [ScheduledDepartureReminder] = []
    private(set) var isLoading = true

    private let client: DepartureReminderClient
    private var reminderRevision = 0
    private var isLoadInProgress = false
    private var isReloadQueued = false
    private var isCancellingAll = false

    init(client: DepartureReminderClient = .live) {
        self.client = client
    }

    func load() async {
        guard !isCancellingAll else {
            isReloadQueued = true
            return
        }
        guard !isLoadInProgress else {
            isReloadQueued = true
            return
        }

        isLoadInProgress = true
        defer {
            isReloadQueued = false
            isLoadInProgress = false
        }

        repeat {
            isReloadQueued = false
            let capturedRevision = reminderRevision
            async let loadedPermission = client.permission()
            async let loadedReminders = client.scheduled()
            let (nextPermission, nextReminders) = await (
                loadedPermission,
                loadedReminders
            )

            guard !Task.isCancelled else { return }
            permission = nextPermission
            if reminderRevision == capturedRevision {
                reminders = nextReminders
            }
            isLoading = false
        } while isReloadQueued && !isCancellingAll
    }

    func cancel(at offsets: IndexSet) {
        let identifiers = offsets.map { reminders[$0].id }
        reminderRevision += 1
        for index in offsets.sorted(by: >) {
            reminders.remove(at: index)
        }
        identifiers.forEach(client.cancel)
    }

    func cancelAll() async {
        guard !isCancellingAll else { return }
        isCancellingAll = true
        reminderRevision += 1
        reminders = []
        await client.cancelAll()
        isCancellingAll = false
        await load()
    }
}
