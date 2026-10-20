/// When a screen's task is cancelled.
public enum TaskLifetime: Sendable {
    /// When the screen leaves for good: popped, dismissed, removed from its parent or from the
    /// window.
    case removal
    /// When the screen starts to disappear (`viewWillDisappear(_:)`): another screen pushed on top,
    /// a tab switch, a swipe back (even one the user abandons), or removal.
    case willDisappear
}
