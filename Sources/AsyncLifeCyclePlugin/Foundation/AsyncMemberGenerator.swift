import SwiftSyntax

enum AsyncMemberGenerator {
    static func members(
        ownerType: String,
        profile: AsyncComponentProfile,
        enabledHooks: [AsyncHook]
    ) -> [DeclSyntax] {
        var members = taskStorageMembers(ownerType: ownerType)
        members += enabledHooks.map { DeclSyntax(stringLiteral: $0.overrideSource) }

        if let cancellationHook = profile.cancellationHook,
           !enabledHooks.contains(where: { $0.signature == cancellationHook }),
           let hook = profile.hook(matching: cancellationHook) {
            members.append(DeclSyntax(stringLiteral: hook.cancellationOnlyOverrideSource))
        }

        return members
    }

    private static func taskStorageMembers(ownerType: String) -> [DeclSyntax] {
        [
            DeclSyntax(stringLiteral: """
            private let __asyncLifeCycleTaskBag = _AsyncLifeCycleTaskBag(ownerType: "\(ownerType)")
            """),
            DeclSyntax(stringLiteral: """
            private func __asyncLifeCycleStartTask(
                methodName: String,
                _ operation: @escaping @MainActor @Sendable () async -> Void
            ) {
                __asyncLifeCycleTaskBag.start(methodName: methodName, operation)
            }
            """),
            DeclSyntax(stringLiteral: """
            private func __asyncLifeCycleCancelTasks() {
                __asyncLifeCycleTaskBag.cancelAll()
            }
            """)
        ]
    }
}
