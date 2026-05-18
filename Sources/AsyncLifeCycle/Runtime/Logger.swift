import struct OSLog.Logger

/// Minimal package-internal logger for async hook task events.
///
/// The logger intentionally reads `AsyncLifeCycleConfiguration.current` at each
/// call site so logging can be toggled at runtime without recreating task bags.
final class Logger: Sendable {
    private let osLogger = OSLog.Logger(subsystem: "AsyncLifeCycle", category: "Lifecycle")

    init() {}

    /// Logs task creation.
    func taskStarted(ownerType: String, methodName: String, taskID: Int) {
        guard AsyncLifeCycleConfiguration.current.isLoggingEnabled else { return }
        osLogger.debug("Started \(methodName, privacy: .public) task #\(taskID, privacy: .public) for \(ownerType, privacy: .public)")
    }

    /// Logs normal task completion.
    func taskCompleted(ownerType: String, methodName: String, taskID: Int) {
        guard AsyncLifeCycleConfiguration.current.isLoggingEnabled else { return }
        osLogger.debug("Completed \(methodName, privacy: .public) task #\(taskID, privacy: .public) for \(ownerType, privacy: .public)")
    }

    /// Logs the tasks selected for cancellation.
    func tasksCanceled(ownerType: String, methodNames: [String], count: Int) {
        guard AsyncLifeCycleConfiguration.current.isLoggingEnabled else { return }
        osLogger.debug("Canceled \(count, privacy: .public) task(s) for \(ownerType, privacy: .public): \(methodNames.joined(separator: ", "), privacy: .public)")
    }

    /// Logs that the bag finished the cancel-all pass.
    func allTasksCanceled(ownerType: String) {
        guard AsyncLifeCycleConfiguration.current.isLoggingEnabled else { return }
        osLogger.debug("All tracked tasks canceled for \(ownerType, privacy: .public)")
    }

    /// Logs owner deinitialization cleanup.
    func taskBagDeinitialized(ownerType: String) {
        guard AsyncLifeCycleConfiguration.current.isLoggingEnabled else { return }
        osLogger.debug("Task bag deinitialized for \(ownerType, privacy: .public)")
    }
}
