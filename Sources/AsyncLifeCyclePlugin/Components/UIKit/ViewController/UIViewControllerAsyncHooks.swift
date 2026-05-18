enum UIViewControllerAsyncHooks {
    static let viewDidLoad = AsyncHook(
        signature: AsyncHookSignature("viewDidLoad"),
        overrideParameters: "",
        superArguments: "",
        asyncArguments: "",
        cancelsExistingTasksBeforeStart: false
    )

    static let viewWillAppear = animatedHook(named: "viewWillAppear")

    static let viewIsAppearing = animatedHook(named: "viewIsAppearing")

    static let viewDidAppear = animatedHook(named: "viewDidAppear")

    static let viewWillDisappear = animatedHook(named: "viewWillDisappear")

    static let viewDidDisappear = animatedHook(
        named: "viewDidDisappear",
        cancelsExistingTasksBeforeStart: true
    )

    static let all: [AsyncHook] = [
        viewDidLoad,
        viewWillAppear,
        viewIsAppearing,
        viewDidAppear,
        viewWillDisappear,
        viewDidDisappear
    ]

    private static func animatedHook(
        named name: String,
        cancelsExistingTasksBeforeStart: Bool = false
    ) -> AsyncHook {
        AsyncHook(
            signature: AsyncHookSignature(
                name,
                parameters: [
                    AsyncHookParameterSignature(externalLabel: nil, acceptedTypes: ["Bool", "Swift.Bool"])
                ]
            ),
            overrideParameters: "_ animated: Bool",
            superArguments: "animated",
            asyncArguments: "animated",
            cancelsExistingTasksBeforeStart: cancelsExistingTasksBeforeStart
        )
    }
}
