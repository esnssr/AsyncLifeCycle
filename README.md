# AsyncLifeCycle

> **Work in progress.** This package is public but still in development. Expect breaking changes
> in any release until 1.0.

SwiftUI's `.task` for UIKit screens: start async work from a lifecycle method, and it's cancelled
when the screen disappears or is removed.

```swift
import AsyncLifeCycle
import UIKit

final class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        task { await self.loadProfile() }                   // until the screen is removed
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        task(until: .willDisappear) { await self.refresh() }  // until viewWillDisappear
    }
}
```

- `.removal` (the default) ends when the screen is popped, dismissed, or removed from its parent
  or the window.
- `.willDisappear` ends at `viewWillDisappear(_:)`: another screen pushed on top, a tab
  switch, a swipe back (even an abandoned one), or removal.
- A screen kept and shown again doesn't rerun `viewDidLoad()`; start its work in
  `viewWillAppear(_:)` with `.willDisappear` instead.
- `storeTask(_:until:)` ties a task you created yourself to a lifetime; `cancelTasks(_:)` cancels
  early.

Requires iOS 18 and Swift 6.2. The first time a screen starts a task, the package swizzles
`viewWillDisappear(_:)`, `viewDidDisappear(_:)` and `didMove(toParent:)` on `UIViewController`.

## Installation

```swift
.package(url: "https://github.com/esnssr/AsyncLifeCycle.git", exact: "0.5.0")
```
