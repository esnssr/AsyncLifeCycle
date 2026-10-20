/// A screen's tasks by lifetime. Attached to the screen as an associated object.
@MainActor
final class TaskStore {
    private struct Entry: Sendable {
        let lifetime: TaskLifetime
        let cancel: @Sendable () -> Void
    }

    private var entries: [Int: Entry] = [:]
    private var nextID = 0

    /// The number of tasks still running.
    var count: Int {
        entries.count
    }

    func start(
        until lifetime: TaskLifetime,
        priority: TaskPriority?,
        _ operation: @escaping @MainActor () async -> Void
    ) -> Task<Void, Never> {
        let id = reserveID()
        // Runs after this method returns, so the entry is always added before it's removed.
        let task = Task(priority: priority) { @MainActor [weak self] in
            await operation()
            self?.entries[id] = nil
        }
        entries[id] = Entry(lifetime: lifetime, cancel: { task.cancel() })
        return task
    }

    func add<Success, Failure>(_ task: Task<Success, Failure>, until lifetime: TaskLifetime) {
        let id = reserveID()
        entries[id] = Entry(lifetime: lifetime, cancel: { task.cancel() })
        // Drop the entry once the task finishes, so a long-lived screen doesn't collect them.
        Task { [weak self] in
            _ = await task.result
            self?.entries[id] = nil
        }
    }

    func cancel(_ lifetimes: Set<TaskLifetime>) {
        let ending = entries.filter { lifetimes.contains($0.value.lifetime) }
        for id in ending.keys {
            entries[id] = nil
        }
        for entry in ending.values {
            entry.cancel()
        }
    }

    private func reserveID() -> Int {
        defer { nextID += 1 }
        return nextID
    }

    // A safety net only: a task that captures its screen keeps it alive, so removal is what
    // cancels it. UIKit frees screens on the main thread, and nothing else holds the store here.
    deinit {
        for entry in entries.values {
            entry.cancel()
        }
    }
}
