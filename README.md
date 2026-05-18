# AsyncLifeCycle

AsyncLifeCycle adds cancellable async hooks to supported UIKit components with an `@Async` macro.

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

Generated UIKit overrides call `super` synchronously, then start the matching async hook in a tracked task. Active tasks are canceled automatically from each component's cancellation hook and when the task bag deinitializes.

## Requirements

- iOS 18+
- Swift 6.2+
- Xcode 26+

The package declares a macOS host platform so SwiftPM can build the compiler
plugin and test target. The async hook API itself is intended for UIKit
components on iOS.

## Installation

Add this package to your project:

```swift
.package(url: "git@github.com:esnssr/AsyncLifeCycle.git", from: "0.1.0")
```

Then add `AsyncLifeCycle` to the target that uses UIKit components.

## Usage

Apply `@Async` to a direct supported UIKit subclass and implement any supported async hook:

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

Do not call UIKit `super` methods from async hooks. The macro calls `super` from the generated synchronous override so UIKit behavior stays in UIKit's call stack.

## Supported UIKit Hooks

| Component | Async hook | Support | Cancellation behavior |
| --- | --- | --- | --- |
| `UIViewController` | `viewDidLoad()` | ✅ | Starts a tracked task. |
| `UIViewController` | `viewWillAppear(_ animated: Bool)` | ✅ | Starts a tracked task. |
| `UIViewController` | `viewIsAppearing(_ animated: Bool)` | ✅ | Starts a tracked task. |
| `UIViewController` | `viewDidAppear(_ animated: Bool)` | ✅ | Starts a tracked task. |
| `UIViewController` | `viewWillDisappear(_ animated: Bool)` | ✅ | Starts a tracked task. |
| `UIViewController` | `viewDidDisappear(_ animated: Bool)` | ✅ | Cancels active tasks, then starts the async hook if provided. |
| `UIView` | `didMoveToWindow()` | ✅ | Cancels active tasks when `window == nil`, then starts the async hook if provided. |
| `UIView` | `didMoveToSuperview()` | ✅ | Starts a tracked task. |
| `UIView` | `layoutSubviews()` | ✅ | Starts a tracked task. |

`viewDidDisappear(_:)` is generated even when no async `viewDidDisappear(_:)` hook is implemented, because the macro uses it to cancel active tasks.
`didMoveToWindow()` is generated for `UIView` subclasses even when no async `didMoveToWindow()` hook is implemented, because the macro uses it to cancel active tasks when a view leaves its window.

## Not Yet Supported

| Component | Essential hooks to support later | Support |
| --- | --- | --- |
| `UITableViewCell` | `prepareForReuse()`, `didMoveToWindow()`, `layoutSubviews()` | Not yet |
| `UICollectionViewCell` | `prepareForReuse()`, `didMoveToWindow()`, `layoutSubviews()` | Not yet |
| `UITableViewHeaderFooterView` | `prepareForReuse()`, `didMoveToWindow()`, `layoutSubviews()` | Not yet |
| `UIControl` | `beginTracking(_:with:)`, `continueTracking(_:with:)`, `endTracking(_:with:)`, `cancelTracking(with:)` | Not yet |
| `UIGestureRecognizer` | `reset()`, touch handling hooks | Not yet |

## Logging

Logging is disabled by default. Enable it during app startup:

```swift
AsyncLifeCycleConfiguration.current = AsyncLifeCycleConfiguration(isLoggingEnabled: true)
```

The package logs essential task start, completion, cancellation, and task bag deinitialization events.

## Package Internals

See [Documentation/Architecture.md](Documentation/Architecture.md) for the macro structure and the process for adding future UIKit component support.
