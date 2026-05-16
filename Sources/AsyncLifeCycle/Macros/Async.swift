/// Adds cancellable async UIKit lifecycle hooks to a `UIViewController` subclass.
///
/// Define async hook methods such as `viewDidLoad() async` or
/// `viewDidAppear(_:) async` and the macro generates the matching UIKit
/// lifecycle override. Generated overrides call UIKit `super` synchronously,
/// then start the async hook in a tracked task that is canceled from
/// `viewDidDisappear(_:)` and from the task bag's deinitializer.
///
/// Async hooks run on the main actor. Do not call UIKit `super` methods from
/// async hooks; the macro diagnoses this and offers a fix-it.
///
/// The macro currently supports direct `UIViewController` subclasses only.
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
        named(viewDidDisappear)
)
public macro Async() = #externalMacro(
    module: "AsyncLifeCyclePlugin",
    type: "AsyncMacro"
)
