import Synchronization

/// Global runtime configuration for generated async hook code.
public struct AsyncLifeCycleConfiguration: Sendable {
    /// Controls whether essential async hook task events are emitted to `OSLog`.
    public var isLoggingEnabled: Bool

    /// Creates a runtime configuration.
    public init(isLoggingEnabled: Bool = false) {
        self.isLoggingEnabled = isLoggingEnabled
    }

    private static let storage = Mutex(AsyncLifeCycleConfiguration())

    /// The active runtime configuration used by generated async lifecycle code.
    ///
    /// This value is protected by a mutex so apps can update configuration from
    /// startup code without relying on actor isolation.
    public static var current: AsyncLifeCycleConfiguration {
        get {
            storage.withLock { configuration in
                configuration
            }
        }
        set {
            storage.withLock { configuration in
                configuration = newValue
            }
        }
    }
}
