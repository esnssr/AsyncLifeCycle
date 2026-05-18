/// Adds cancellable async hooks to supported UIKit subclasses.
///
/// Define async hook methods such as `viewDidLoad() async` or
/// `layoutSubviews() async` and the macro generates the matching UIKit
/// override. Generated overrides call UIKit `super` synchronously, then start
/// the async hook in a tracked task. Active tasks are canceled from the
/// supported component's cancellation hook and from the task bag's deinitializer.
///
/// Async hooks run on the main actor. Do not call UIKit `super` methods from
/// async hooks; the macro diagnoses this and offers a fix-it.
///
/// The macro currently supports direct `UIViewController` and `UIView` subclasses.
@attached(
    member,
    names:
        named(__asyncLifeCycleTaskBag),
        named(__asyncLifeCycleStartTask),
        named(__asyncLifeCycleCancelTasks),
        named(viewDidLoad),
        named(viewWillAppear),
        named(viewIsAppearing),
        named(viewDidAppear),
        named(viewWillDisappear),
        named(viewDidDisappear),
        named(didMoveToWindow),
        named(didMoveToSuperview),
        named(layoutSubviews)
)
public macro Async() = #externalMacro(
    module: "AsyncLifeCyclePlugin",
    type: "AsyncMacro"
)
