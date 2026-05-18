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

    static let all: [AsyncHook] = [
        didMoveToWindow,
        didMoveToSuperview,
        layoutSubviews
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
