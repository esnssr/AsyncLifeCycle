# AsyncLifeCycle

AsyncLifeCycle adds cancellable async lifecycle hooks to UIKit view controllers with an `@Async` macro.

```swift
import AsyncLifeCycle
import UIKit

@Async
final class ProfileViewController: UIViewController {
    func viewDidLoad() async {
        await loadProfile()
    }

    func viewDidAppear(_ animated: Bool) async {
        await startRefreshing()
    }
}
```

Generated UIKit overrides call `super` synchronously, then start the matching async hook in a tracked task. Active tasks are canceled automatically from `viewDidDisappear(_:)` and when the task bag deinitializes.

## Requirements

- iOS 18+
- Swift 6.2+
- Xcode 26+

The package declares a macOS host platform so SwiftPM can build the compiler
plugin and test target. The lifecycle API itself is intended for UIKit view
controllers on iOS.

## Installation

Add this package to your project:

```swift
.package(url: "git@github.com:esnssr/AsyncLifeCycle.git", from: "0.1.0")
```

Then add `AsyncLifeCycle` to the target that uses UIKit view controllers.

## Usage

Apply `@Async` to a direct `UIViewController` subclass and implement any supported async lifecycle hook:

```swift
@Async
final class FeedViewController: UIViewController {
    func viewDidLoad() async {}
    func viewWillAppear(_ animated: Bool) async {}
    func viewIsAppearing(_ animated: Bool) async {}
    func viewDidAppear(_ animated: Bool) async {}
    func viewWillDisappear(_ animated: Bool) async {}
    func viewDidDisappear(_ animated: Bool) async {}
}
```

Do not call UIKit `super` methods from async lifecycle hooks. The macro calls `super` from the generated synchronous override so UIKit lifecycle behavior stays in UIKit's call stack.

## Logging

Logging is disabled by default. Enable it during app startup:

```swift
AsyncLifeCycleConfiguration.current = AsyncLifeCycleConfiguration(isLoggingEnabled: true)
```

The package logs essential task start, completion, cancellation, and task bag deinitialization events.
