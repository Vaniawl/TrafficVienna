import Foundation

@MainActor
final class LiveActivityOperationQueue {
    private struct PendingOperation {
        let generation: Int
        let task: Task<Void, Never>
    }

    private var operations: [String: PendingOperation] = [:]
    private var nextGeneration = 0

    @discardableResult
    func enqueue(
        for activityID: String,
        operation: @escaping @MainActor @Sendable () async -> Void
    ) -> Task<Void, Never> {
        nextGeneration += 1
        let generation = nextGeneration
        let predecessor = operations[activityID]?.task
        let task = Task { @MainActor [weak self] in
            await predecessor?.value
            guard !Task.isCancelled else {
                self?.finish(activityID: activityID, generation: generation)
                return
            }
            await operation()
            self?.finish(activityID: activityID, generation: generation)
        }
        operations[activityID] = PendingOperation(
            generation: generation,
            task: task
        )
        return task
    }

    private func finish(activityID: String, generation: Int) {
        guard operations[activityID]?.generation == generation else {
            return
        }
        operations[activityID] = nil
    }
}
