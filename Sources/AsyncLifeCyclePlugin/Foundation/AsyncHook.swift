struct AsyncHook: Hashable {
    let signature: AsyncHookSignature
    let overrideParameters: String
    let superArguments: String
    let asyncArguments: String
    let cancelsExistingTasksBeforeStart: Bool
    let cancellationCondition: String?

    init(
        signature: AsyncHookSignature,
        overrideParameters: String,
        superArguments: String,
        asyncArguments: String,
        cancelsExistingTasksBeforeStart: Bool,
        cancellationCondition: String? = nil
    ) {
        self.signature = signature
        self.overrideParameters = overrideParameters
        self.superArguments = superArguments
        self.asyncArguments = asyncArguments
        self.cancelsExistingTasksBeforeStart = cancelsExistingTasksBeforeStart
        self.cancellationCondition = cancellationCondition
    }

    var overrideSource: String {
        var lines = [
            "override func \(signature.name)\(parameterClause) {",
            "    super.\(signature.name)(\(superArguments))"
        ]

        if cancelsExistingTasksBeforeStart {
            lines += cancellationLines
        }

        lines += [
            "    __asyncLifeCycleStartTask(methodName: \"\(signature.name)\") { @MainActor [weak self] in",
            "        await self?.\(signature.name)(\(asyncArguments))",
            "    }",
            "}"
        ]

        return lines.joined(separator: "\n")
    }

    var cancellationOnlyOverrideSource: String {
        var lines = [
            "override func \(signature.name)\(parameterClause) {",
            "    super.\(signature.name)(\(superArguments))"
        ]
        lines += cancellationLines
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private var parameterClause: String {
        overrideParameters.isEmpty ? "()" : "(\(overrideParameters))"
    }

    private var cancellationLines: [String] {
        guard let cancellationCondition else {
            return ["    __asyncLifeCycleCancelTasks()"]
        }

        return [
            "    if \(cancellationCondition) {",
            "        __asyncLifeCycleCancelTasks()",
            "    }"
        ]
    }
}
