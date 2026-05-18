extension AsyncComponentProfile {
    static let uiView = AsyncComponentProfile(
        name: "UIView",
        supportedBaseTypes: [
            "UIView",
            "UIKit.UIView"
        ],
        hooks: UIViewAsyncHooks.all,
        // UIView calls didMoveToWindow() after the window changes for both
        // attachment and removal. The hook itself guards cancellation with
        // window == nil so active tasks are canceled only when the view leaves
        // its window, not when it is added to one.
        cancellationHook: UIViewAsyncHooks.didMoveToWindow.signature
    )
}
