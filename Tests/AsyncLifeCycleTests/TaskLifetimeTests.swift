import ObjectiveC
import Testing
import UIKit
@testable import AsyncLifeCycle

/// Real screens in a real window, with transitions run by UIKit. Serialized: the screens share the
/// main run loop, and the swizzles installed here stay installed for the rest of the run.
///
/// Sheets, tab switches, stacks dismissed from below and full-screen covers need an app's window
/// scene: without one, presented screens and tabs get no appearance callbacks. Those cases are
/// checked in an app.
@MainActor
@Suite(.serialized)
struct TaskLifetimeTests {
    @Test func pushingAScreenOnTopCancelsOnlyDisappearTasks() async {
        let screen = UIViewController()
        let navigation = UINavigationController(rootViewController: screen)
        let window = await show(navigation)
        let removal = longTask(on: screen, until: .removal)
        let disappear = longTask(on: screen, until: .willDisappear)

        let next = UIViewController()
        navigation.pushViewController(next, animated: false)
        await settle { next.viewIfLoaded?.window != nil && screen.viewIfLoaded?.window == nil }

        #expect(!removal.isCancelled)
        #expect(disappear.isCancelled)
        window.isHidden = true
    }

    @Test func poppingCancelsAllTasks() async {
        let screen = UIViewController()
        let navigation = UINavigationController(rootViewController: UIViewController())
        let window = await show(navigation)
        navigation.pushViewController(screen, animated: false)
        await settle { screen.viewIfLoaded?.window != nil }
        let removal = longTask(on: screen, until: .removal)
        let disappear = longTask(on: screen, until: .willDisappear)

        navigation.popViewController(animated: false)
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
        #expect(disappear.isCancelled)
        window.isHidden = true
    }

    @Test func poppingToRootCancelsTasksOfScreensInTheMiddle() async {
        let screen = UIViewController()
        let navigation = UINavigationController(rootViewController: UIViewController())
        let window = await show(navigation)
        navigation.pushViewController(screen, animated: false)
        await settle { screen.viewIfLoaded?.window != nil }
        let removal = longTask(on: screen, until: .removal)
        let top = UIViewController()
        navigation.pushViewController(top, animated: false)
        await settle { top.viewIfLoaded?.window != nil }

        navigation.popToRootViewController(animated: false)
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
        window.isHidden = true
    }

    @Test func replacingTheStackCancelsTasksOfScreensLeftOut() async {
        let screen = UIViewController()
        let navigation = UINavigationController(rootViewController: screen)
        let window = await show(navigation)
        let removal = longTask(on: screen, until: .removal)
        let top = UIViewController()
        navigation.pushViewController(top, animated: false)
        await settle { top.viewIfLoaded?.window != nil }

        navigation.setViewControllers([top], animated: false)
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
        window.isHidden = true
    }

    @Test func replacingTheWindowRootCancelsItsTasks() async {
        let screen = UIViewController()
        let window = await show(screen)
        let removal = longTask(on: screen, until: .removal)

        window.rootViewController = UIViewController()
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
        window.isHidden = true
    }

    @Test func replacingTheWindowRootCancelsTasksOfScreensLowerInItsStack() async {
        let lower = UIViewController()
        let navigation = UINavigationController(rootViewController: lower)
        let window = await show(navigation)
        let removal = longTask(on: lower, until: .removal)
        let top = UIViewController()
        navigation.pushViewController(top, animated: false)
        await settle { top.viewIfLoaded?.window != nil }

        window.rootViewController = UIViewController()
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
        window.isHidden = true
    }

    @Test func poppingToRootCancelsTasksOfChildrenOfScreensInTheMiddle() async {
        let container = UIViewController()
        let child = UIViewController()
        container.addChild(child)
        container.view.addSubview(child.view)
        child.didMove(toParent: container)
        let navigation = UINavigationController(rootViewController: UIViewController())
        let window = await show(navigation)
        navigation.pushViewController(container, animated: false)
        await settle { child.viewIfLoaded?.window != nil }
        let removal = longTask(on: child, until: .removal)
        let top = UIViewController()
        navigation.pushViewController(top, animated: false)
        await settle { top.viewIfLoaded?.window != nil }

        navigation.popToRootViewController(animated: false)
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
        window.isHidden = true
    }

    @Test func movingAScreenToAnotherParentKeepsItsTasks() async {
        let first = UIViewController()
        let second = UIViewController()
        let screen = UIViewController()
        first.addChild(screen)
        screen.didMove(toParent: first)
        let removal = longTask(on: screen, until: .removal)

        screen.willMove(toParent: nil)
        screen.removeFromParent()
        second.addChild(screen)
        screen.didMove(toParent: second)
        try? await Task.sleep(for: .milliseconds(200))

        #expect(!removal.isCancelled)
        screen.cancelTasks()
    }

    @Test func anAbandonedInteractivePopLeavesOneAppearanceTask() async {
        let screen = RefreshingScreen()
        let navigation = UINavigationController(rootViewController: UIViewController())
        let pop = InteractivePop()
        navigation.delegate = pop
        let window = await show(navigation)
        navigation.pushViewController(screen, animated: false)
        await settle { screen.viewIfLoaded?.window != nil }
        let removal = longTask(on: screen, until: .removal)

        navigation.popViewController(animated: true)
        await settle { navigation.transitionCoordinator != nil }
        pop.interaction.update(0.3)
        pop.interaction.cancel()
        await settle { navigation.transitionCoordinator == nil && screen.refreshes.count == 2 }

        #expect(navigation.topViewController === screen)
        #expect(!removal.isCancelled)
        #expect(screen.refreshes.count(where: { !$0.isCancelled }) == 1)
        window.isHidden = true
    }

    @Test func removingAChildCancelsAllItsTasks() async {
        let parent = UIViewController()
        let window = await show(parent)
        let screen = UIViewController()
        parent.addChild(screen)
        parent.view.addSubview(screen.view)
        screen.didMove(toParent: parent)
        await settle { screen.viewIfLoaded?.window != nil }
        let removal = longTask(on: screen, until: .removal)
        let disappear = longTask(on: screen, until: .willDisappear)

        screen.willMove(toParent: nil)
        screen.view.removeFromSuperview()
        screen.removeFromParent()
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
        #expect(disappear.isCancelled)
        window.isHidden = true
    }

    @Test func aStoredTaskIsCancelledWithItsLifetime() async {
        let screen = UIViewController()
        let navigation = UINavigationController(rootViewController: screen)
        let window = await show(navigation)
        let stored = Task { try? await Task.sleep(for: .seconds(60)) }
        screen.storeTask(stored, until: .willDisappear)

        navigation.pushViewController(UIViewController(), animated: false)
        await settle { stored.isCancelled }

        #expect(stored.isCancelled)
        window.isHidden = true
    }

    @Test func cancelTasksCancelsTheGivenLifetimeOrAll() {
        let screen = UIViewController()
        let removal = longTask(on: screen, until: .removal)
        let disappear = longTask(on: screen, until: .willDisappear)

        screen.cancelTasks(.willDisappear)
        #expect(!removal.isCancelled)
        #expect(disappear.isCancelled)

        screen.cancelTasks()
        #expect(removal.isCancelled)
    }

    @Test func finishedTasksLeaveTheStore() async {
        let screen = UIViewController()
        screen.task {}
        screen.storeTask(Task {})
        await settle { screen.existingTaskStore?.count == 0 }

        #expect(screen.existingTaskStore?.count == 0)
    }

    @Test func freeingAScreenCancelsItsTasks() async {
        var screen: UIViewController? = UIViewController()
        let removal = longTask(on: screen!, until: .removal)

        screen = nil
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
    }

    @Test func tasksAreCancelledWhenOtherSwizzlesWrapOurs() async {
        LifeCycleSwizzler.installOnce()
        OtherSwizzles.installWrapping()
        OtherSwizzles.installExchanging()
        let screen = UIViewController()
        let navigation = UINavigationController(rootViewController: UIViewController())
        let window = await show(navigation)
        navigation.pushViewController(screen, animated: false)
        await settle { screen.viewIfLoaded?.window != nil }
        let removal = longTask(on: screen, until: .removal)
        let wrappedCalls = OtherSwizzles.wrappedCalls
        let exchangedCalls = OtherSwizzles.exchangedCalls

        navigation.popViewController(animated: false)
        await settle { removal.isCancelled }

        #expect(removal.isCancelled)
        #expect(OtherSwizzles.wrappedCalls > wrappedCalls)
        #expect(OtherSwizzles.exchangedCalls > exchangedCalls)
        window.isHidden = true
    }

    @Test func aSubclassCanDeclareItsOwnTaskProperty() {
        let screen = ScreenWithTaskProperty()
        let removal = screen.task(until: .removal) { try? await Task.sleep(for: .seconds(60)) }
        screen.task = removal

        screen.cancelTasks()

        #expect(screen.task?.isCancelled == true)
    }
}

// MARK: - Helpers

@MainActor
private func show(_ root: UIViewController) async -> UIWindow {
    let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
    window.rootViewController = root
    window.makeKeyAndVisible()
    // The view joins the window at once, but its appearance callbacks finish on a later pass;
    // a screen pushed over before then gets no disappear callbacks.
    try? await Task.sleep(for: .milliseconds(300))
    return window
}

/// Lets UIKit run until `condition` holds, for at most three seconds.
@MainActor
private func settle(until condition: () -> Bool) async {
    let deadline = ContinuousClock.now + .seconds(3)
    while !condition(), ContinuousClock.now < deadline {
        try? await Task.sleep(for: .milliseconds(20))
    }
}

/// A task that runs until it's cancelled and captures nothing, so it never keeps the screen alive.
@MainActor
private func longTask(on screen: UIViewController, until lifetime: TaskLifetime) -> Task<Void, Never> {
    screen.task(until: lifetime) {
        try? await Task.sleep(for: .seconds(60))
    }
}

/// Starts a refresh on every appearance, as the README suggests.
private final class RefreshingScreen: UIViewController {
    var refreshes: [Task<Void, Never>] = []

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        refreshes.append(task(until: .willDisappear) { try? await Task.sleep(for: .seconds(60)) })
    }
}

private final class ScreenWithTaskProperty: UIViewController {
    var task: Task<Void, Never>?
}

/// A pop the test drives by hand, like a swipe back.
@MainActor
private final class InteractivePop: NSObject, UINavigationControllerDelegate, UIViewControllerAnimatedTransitioning {
    let interaction = UIPercentDrivenInteractiveTransition()

    func navigationController(
        _ navigationController: UINavigationController,
        animationControllerFor operation: UINavigationController.Operation,
        from fromVC: UIViewController,
        to toVC: UIViewController
    ) -> (any UIViewControllerAnimatedTransitioning)? {
        operation == .pop ? self : nil
    }

    func navigationController(
        _ navigationController: UINavigationController,
        interactionControllerFor animationController: any UIViewControllerAnimatedTransitioning
    ) -> (any UIViewControllerInteractiveTransitioning)? {
        interaction
    }

    func transitionDuration(using transitionContext: (any UIViewControllerContextTransitioning)?) -> TimeInterval {
        0.3
    }

    func animateTransition(using transitionContext: any UIViewControllerContextTransitioning) {
        guard let from = transitionContext.view(forKey: .from), let to = transitionContext.view(forKey: .to) else {
            transitionContext.completeTransition(false)
            return
        }
        transitionContext.containerView.insertSubview(to, belowSubview: from)
        UIView.animate(withDuration: 0.3) {
            from.frame.origin.x = from.frame.width
        } completion: { _ in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        }
    }
}

/// Stand-ins for other packages that swizzle `viewDidDisappear(_:)` after this one: one replaces
/// the implementation and one exchanges it.
@MainActor
private enum OtherSwizzles {
    static var wrappedCalls = 0
    static var exchangedCalls = 0

    static func installWrapping() {
        _ = wrapping
    }

    static func installExchanging() {
        _ = exchanging
    }

    private static let wrapping: Void = {
        let selector = #selector(UIViewController.viewDidDisappear(_:))
        let method = class_getInstanceMethod(UIViewController.self, selector)!
        typealias Implementation = @convention(c) (UIViewController, Selector, Bool) -> Void
        let original = unsafeBitCast(method_getImplementation(method), to: Implementation.self)
        let replacement: @convention(block) (UIViewController, Bool) -> Void = { screen, animated in
            MainActor.assumeIsolated { wrappedCalls += 1 }
            original(screen, selector, animated)
        }
        method_setImplementation(method, imp_implementationWithBlock(replacement))
    }()

    private static let exchanging: Void = {
        let original = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.viewDidDisappear(_:)))!
        let replacement = class_getInstanceMethod(UIViewController.self, #selector(UIViewController.otherPackage_viewDidDisappear(_:)))!
        method_exchangeImplementations(original, replacement)
    }()
}

extension UIViewController {
    @objc dynamic fileprivate func otherPackage_viewDidDisappear(_ animated: Bool) {
        OtherSwizzles.exchangedCalls += 1
        otherPackage_viewDidDisappear(animated)
    }
}
