enum UIViewAsyncHooks {
    static let didMoveToWindow = AsyncHook(
        signature: AsyncHookSignature("didMoveToWindow"),
        overrideParameters: "",
        superArguments: "",
        asyncArguments: "",
        cancelsExistingTasksBeforeStart: true,
        cancellationCondition: "window == nil"
    )

    static let didMoveToSuperview = parameterlessHook(named: "didMoveToSuperview")

    static let layoutSubviews = parameterlessHook(named: "layoutSubviews")

    static let updateConstraints = parameterlessHook(named: "updateConstraints")

    static let safeAreaInsetsDidChange = parameterlessHook(named: "safeAreaInsetsDidChange")

    static let layoutMarginsDidChange = parameterlessHook(named: "layoutMarginsDidChange")

    static let tintColorDidChange = parameterlessHook(named: "tintColorDidChange")

    static let traitCollectionDidChange = AsyncHook(
        signature: AsyncHookSignature(
            "traitCollectionDidChange",
            parameters: [
                AsyncHookParameterSignature(
                    externalLabel: nil,
                    acceptedTypes: ["UITraitCollection?", "UIKit.UITraitCollection?"]
                )
            ]
        ),
        overrideParameters: "_ previousTraitCollection: UIKit.UITraitCollection?",
        superArguments: "previousTraitCollection",
        asyncArguments: "previousTraitCollection",
        cancelsExistingTasksBeforeStart: false
    )

    static let all: [AsyncHook] = [
        didMoveToWindow,
        didMoveToSuperview,
        layoutSubviews,
        updateConstraints,
        safeAreaInsetsDidChange,
        layoutMarginsDidChange,
        tintColorDidChange,
        traitCollectionDidChange
    ]

    private static func parameterlessHook(named name: String) -> AsyncHook {
        AsyncHook(
            signature: AsyncHookSignature(name),
            overrideParameters: "",
            superArguments: "",
            asyncArguments: "",
            cancelsExistingTasksBeforeStart: false
        )
    }
}
