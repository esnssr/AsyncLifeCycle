import ObjectiveC
import UIKit

/// Replaces three `UIViewController` methods once, on the base class. Every subclass must call
/// `super`, so the hooks run for all screens; screens without tasks return at once.
///
/// Each original implementation is called with its own selector, so UIKit and other packages that
/// swizzle the same methods, before or after, keep working.
@MainActor
enum LifeCycleSwizzler {
    static func installOnce() {
        _ = installed
    }

    private static let installed: Void = {
        replaceAnimatedMethod(#selector(UIViewController.viewWillDisappear(_:))) { screen in
            screen.existingTaskStore?.cancel([.disappear])
        }
        replaceAnimatedMethod(#selector(UIViewController.viewDidDisappear(_:))) { screen in
            if screen.isBeingRemoved {
                screen.cancelTasksIncludingChildren([.disappear, .removal])
            } else {
                screen.existingTaskStore?.cancel([.disappear])
            }
        }
        replaceDidMoveToParent()
    }()

    /// `viewWillDisappear(_:)` and `viewDidDisappear(_:)`: calls the original, then `after`.
    private static func replaceAnimatedMethod(
        _ selector: Selector,
        after: @escaping @MainActor (UIViewController) -> Void
    ) {
        guard let method = class_getInstanceMethod(UIViewController.self, selector) else {
            assertionFailure("\(selector) not found")
            return
        }
        typealias Implementation = @convention(c) (UIViewController, Selector, Bool) -> Void
        let original = unsafeBitCast(method_getImplementation(method), to: Implementation.self)
        let replacement: @convention(block) (UIViewController, Bool) -> Void = { screen, animated in
            original(screen, selector, animated)
            MainActor.assumeIsolated {
                after(screen)
            }
        }
        method_setImplementation(method, imp_implementationWithBlock(replacement))
    }

    /// `didMove(toParent:)`: a screen removed from its parent while it's off screen, such as one in
    /// the middle of a stack after `popToRootViewController`, gets no `viewDidDisappear(_:)`.
    /// Containers that move a screen to another parent, such as a collapsing split view, remove and
    /// add it in one pass, so the check waits a turn and skips screens that have a parent again.
    private static func replaceDidMoveToParent() {
        let selector = #selector(UIViewController.didMove(toParent:))
        guard let method = class_getInstanceMethod(UIViewController.self, selector) else {
            assertionFailure("\(selector) not found")
            return
        }
        typealias Implementation = @convention(c) (UIViewController, Selector, UIViewController?) -> Void
        let original = unsafeBitCast(method_getImplementation(method), to: Implementation.self)
        let replacement: @convention(block) (UIViewController, UIViewController?) -> Void = { screen, parent in
            original(screen, selector, parent)
            guard parent == nil else { return }
            MainActor.assumeIsolated {
                screen.cancelTasksIfStillRemoved()
            }
        }
        method_setImplementation(method, imp_implementationWithBlock(replacement))
    }
}
