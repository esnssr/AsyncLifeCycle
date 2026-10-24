import UIKit

extension UIViewController {
    /// True when this screen, or a parent of it, is being dismissed, or when it's a window's root
    /// that's been replaced (no parent, presenter or window left). A screen in a navigation
    /// controller shown as a sheet is never `isBeingDismissed` itself; its navigation controller is.
    /// Screens moving from their parent are left to `didMove(toParent:)`, since a container may
    /// add them to another parent straight away.
    var isBeingRemoved: Bool {
        if sequence(first: self, next: \.parent).contains(where: \.isBeingDismissed) {
            return true
        }
        return parent == nil && presentingViewController == nil && presentedViewController == nil
            && viewIfLoaded?.window == nil
    }

    /// Cancels this screen's tasks and its children's, all the way down. A container's off-screen
    /// children, such as the lower screens of a navigation stack, get no callbacks of their own
    /// when the container leaves.
    func cancelTasksIncludingChildren(_ lifetimes: Set<TaskLifetime>) {
        existingTaskStore?.cancel(lifetimes)
        for child in children {
            child.cancelTasksIncludingChildren(lifetimes)
        }
    }

    /// Cancels all tasks on the next main-actor turn, unless the screen is shown again by then: in
    /// another parent, as a window's root, or presented.
    func cancelTasksIfStillRemoved() {
        guard hasTasksIncludingChildren else { return }
        Task { @MainActor [weak self] in
            guard let self, parent == nil, presentingViewController == nil, viewIfLoaded?.window == nil else {
                return
            }
            cancelTasksIncludingChildren([.willDisappear, .removal])
        }
    }

    private var hasTasksIncludingChildren: Bool {
        existingTaskStore != nil || children.contains { $0.hasTasksIncludingChildren }
    }
}
