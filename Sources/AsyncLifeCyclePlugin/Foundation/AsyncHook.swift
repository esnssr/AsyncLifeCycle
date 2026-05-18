struct AsyncHook: Hashable {
    let signature: AsyncHookSignature
    let overrideParameters: String
    let superArguments: String
    let asyncArguments: String
    let cancelsExistingTasksBeforeStart: Bool

    var overrideSource: String {
        var lines = [
            "override func \(signature.name)\(parameterClause) {",
            "    super.\(signature.name)(\(superArguments))"
        ]

        if cancelsExistingTasksBeforeStart {
            lines.append("    __asyncLifeCycleCancelTasks()")
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
        [
            "override func \(signature.name)\(parameterClause) {",
            "    super.\(signature.name)(\(superArguments))",
            "    __asyncLifeCycleCancelTasks()",
            "}"
        ].joined(separator: "\n")
    }

    private var parameterClause: String {
        overrideParameters.isEmpty ? "()" : "(\(overrideParameters))"
    }
}
