extension AsyncComponentProfile {
    static let uiViewController = AsyncComponentProfile(
        name: "UIViewController",
        supportedBaseTypes: [
            "UIViewController",
            "UIKit.UIViewController"
        ],
        hooks: UIViewControllerAsyncHooks.all,
        cancellationHook: UIViewControllerAsyncHooks.viewDidDisappear.signature
    )
}
