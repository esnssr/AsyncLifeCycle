extension AsyncComponentProfile {
    static let uiView = AsyncComponentProfile(
        name: "UIView",
        supportedBaseTypes: [
            "UIView",
            "UIKit.UIView"
        ],
        hooks: UIViewAsyncHooks.all,
        cancellationHook: UIViewAsyncHooks.didMoveToWindow.signature
    )
}
