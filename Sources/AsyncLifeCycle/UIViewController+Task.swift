public import UIKit

extension UIViewController {
    /// Starts `operation` on the main actor and cancels it when `lifetime` ends, like SwiftUI's
    /// `.task`. Call it from `viewWillAppear(_:)` with `.disappear` to run work on every appearance.
    ///
    /// - Start `.disappear` tasks in `viewWillAppear(_:)`: they end at `viewWillDisappear(_:)`, so
    ///   a swipe back the user abandons ends them and the next `viewWillAppear(_:)` starts them again.
    /// - A screen the app keeps and shows again doesn't rerun `viewDidLoad()`, so its `.removal`
    ///   tasks don't restart; start those in `viewWillAppear(_:)` with `.disappear` instead.
    /// - A task started on a screen that's never shown, or after the screen is removed, is cancelled
    ///   only when the screen is freed, and a task that captures `self` keeps it from being freed.
    ///   Check `Task.isCancelled` before starting follow-up work.
    @discardableResult
    public func task(
        until lifetime: TaskLifetime = .removal,
        priority: TaskPriority? = nil,
        _ operation: @escaping @MainActor () async -> Void
    ) -> Task<Void, Never> {
        LifeCycleSwizzler.installOnce()
        return taskStore.start(until: lifetime, priority: priority, operation)
    }

    /// Cancels `task` when `lifetime` ends, for tasks created elsewhere.
    public func storeTask<Success, Failure>(_ task: Task<Success, Failure>, until lifetime: TaskLifetime = .removal) {
        LifeCycleSwizzler.installOnce()
        taskStore.add(task, until: lifetime)
    }

    /// Cancels this screen's tasks for `lifetime` now, or all of them when `nil`.
    public func cancelTasks(_ lifetime: TaskLifetime? = nil) {
        existingTaskStore?.cancel(lifetime.map { [$0] } ?? [.removal, .disappear])
    }
}
