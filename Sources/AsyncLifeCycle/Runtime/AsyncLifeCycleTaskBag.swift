import Synchronization

/// Tracks async hook tasks for a single generated owner instance.
///
/// This type is public only because generated macro code lives in the client
/// module. It is hidden from generated documentation and should be treated as
/// implementation detail.
@_documentation(visibility: private)
public final class _AsyncLifeCycleTaskBag: Sendable {

    /// Stores the method name beside the task so cancellation logs can report
    /// which async hooks were still running.
    private struct TaskRecord: Sendable {
        var methodName: String
        var task: Task<Void, Never>
    }

    /// Mutable task state protected by `Mutex`.
    private struct State: Sendable {
        var tasks: [Int: TaskRecord] = [:]
        var nextTaskID = 0
    }

    private let ownerType: String
    private let logger: Logger
    private let state = Mutex(State())

    /// Creates a task bag for a generated async hook owner.
    public init(ownerType: String) {
        self.ownerType = ownerType
        self.logger = Logger()
    }

    deinit {
        logger.taskBagDeinitialized(ownerType: ownerType)
        cancelAll()
    }

    /// Starts and tracks a main-actor async hook task.
    ///
    /// Completed tasks remove themselves from the bag so later cancellation
    /// logs only include work that was still active.
    public func start(
        methodName: String,
        _ operation: @escaping @MainActor @Sendable () async -> Void
    ) {
        let taskID = reserveTaskID()
        logger.taskStarted(ownerType: ownerType, methodName: methodName, taskID: taskID)

        let task = Task { @MainActor [weak self] in
            await operation()
            guard let self else { return }
            self.removeTask(id: taskID)
            self.logger.taskCompleted(ownerType: self.ownerType, methodName: methodName, taskID: taskID)
        }

        state.withLock { state in
            state.tasks[taskID] = TaskRecord(methodName: methodName, task: task)
        }
    }

    /// Cancels every task currently tracked by the bag.
    ///
    /// The bag clears its state before calling `Task.cancel()` so cancellation
    /// handlers cannot observe stale active tasks.
    public func cancelAll() {
        let recordsToCancel = state.withLock { state in
            let records = Array(state.tasks.values)
            state.tasks.removeAll()
            return records
        }

        logger.tasksCanceled(
            ownerType: ownerType,
            methodNames: recordsToCancel.map(\.methodName),
            count: recordsToCancel.count
        )
        recordsToCancel.forEach { record in
            record.task.cancel()
        }
        logger.allTasksCanceled(ownerType: ownerType)
    }

    /// Returns a unique task identifier for this bag.
    private func reserveTaskID() -> Int {
        state.withLock { state in
            state.nextTaskID += 1
            return state.nextTaskID
        }
    }

    /// Removes a task after its async hook returns.
    private func removeTask(id: Int) {
        state.withLock { state in
            _ = state.tasks.removeValue(forKey: id)
        }
    }
}
