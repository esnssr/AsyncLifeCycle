import SwiftCompilerPlugin
import SwiftDiagnostics
public import SwiftSyntax
import SwiftSyntaxBuilder
public import SwiftSyntaxMacros

@main
struct AsyncLifeCyclePlugin: CompilerPlugin {
    let providingMacros: [any Macro.Type] = [
        AsyncMacro.self
    ]
}

public struct AsyncMacro: MemberMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let classDeclaration = declaration.as(ClassDeclSyntax.self) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: AsyncLifeCycleDiagnostic("@Async can only be applied to a UIViewController subclass.")
                )
            )
            return []
        }

        guard inheritsDirectlyFromUIViewController(classDeclaration) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: AsyncLifeCycleDiagnostic("@Async can only be applied to direct UIViewController subclasses. Macros cannot safely prove that another superclass is a UIViewController subclass.")
                )
            )
            return []
        }

        if diagnoseSuperCalls(in: declaration, context: context) {
            return []
        }

        // Member macros cannot merge generated overrides with user-written
        // overrides, so report a focused diagnostic before Swift reports a
        // duplicate method error.
        for hook in lifeCycleHooks {
            guard containsAsyncMethod(named: hook.methodName, parameterCount: hook.parameterCount, in: declaration),
                  containsSyncMethod(named: hook.methodName, parameterCount: hook.parameterCount, in: declaration) else {
                continue
            }

            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: AsyncLifeCycleDiagnostic("@Async cannot generate \(hook.methodName) because this class already defines a synchronous override. Move synchronous work into \(hook.methodName)(...) async, or remove the async hook and manage that lifecycle method yourself.")
                )
            )
            return []
        }

        // viewDidDisappear is reserved even without an async viewDidDisappear
        // because cancellation must run when the controller leaves the screen.
        if containsSyncMethod(named: "viewDidDisappear", parameterCount: 1, in: declaration) {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: AsyncLifeCycleDiagnostic("@Async needs to generate viewDidDisappear(_:) to cancel active tasks. Remove your viewDidDisappear(_:) override, or do not use this macro on this class.")
                )
            )
            return []
        }

        var members = taskStorageMembers(ownerType: classDeclaration.name.text)
        members += lifeCycleHooks.compactMap { hook in
            guard containsAsyncMethod(named: hook.methodName, parameterCount: hook.parameterCount, in: declaration) else {
                return nil
            }

            return DeclSyntax(stringLiteral: hook.overrideSource)
        }

        if !containsAsyncMethod(named: "viewDidDisappear", parameterCount: 1, in: declaration) {
            members.append(DeclSyntax(stringLiteral: cancellationOnlyViewDidDisappearSource))
        }

        return members
    }

    private static func containsAsyncMethod(
        named name: String,
        parameterCount: Int,
        in declaration: some DeclGroupSyntax
    ) -> Bool {
        containsMethod(named: name, parameterCount: parameterCount, in: declaration, where: isAsyncFunction)
    }

    private static func containsSyncMethod(
        named name: String,
        parameterCount: Int,
        in declaration: some DeclGroupSyntax
    ) -> Bool {
        containsMethod(named: name, parameterCount: parameterCount, in: declaration) { function in
            !isAsyncFunction(function)
        }
    }


    private static func isAsyncFunction(_ function: FunctionDeclSyntax) -> Bool {
        function.signature.effectSpecifiers?.asyncSpecifier != nil
    }
    private static func containsMethod(
        named name: String,
        parameterCount: Int,
        in declaration: some DeclGroupSyntax,
        where predicate: (FunctionDeclSyntax) -> Bool = { _ in true }
    ) -> Bool {
        declaration.memberBlock.members.contains { member in
            guard let function = member.decl.as(FunctionDeclSyntax.self) else {
                return false
            }

            return function.name.text == name
                && function.signature.parameterClause.parameters.count == parameterCount
                && predicate(function)
        }
    }

    private static func inheritsDirectlyFromUIViewController(_ declaration: ClassDeclSyntax) -> Bool {
        // Macros do not receive semantic type information, so this check is
        // intentionally limited to direct UIViewController inheritance.
        declaration.inheritanceClause?.inheritedTypes.contains { inheritedType in
            let typeName = inheritedType.type.trimmedDescription
            return typeName == "UIViewController" || typeName == "UIKit.UIViewController"
        } ?? false
    }

    private static func diagnoseSuperCalls(
        in declaration: some DeclGroupSyntax,
        context: some MacroExpansionContext
    ) -> Bool {
        var diagnosed = false

        for member in declaration.memberBlock.members {
            guard let function = member.decl.as(FunctionDeclSyntax.self),
                  lifeCycleHooks.contains(where: { hook in
                      function.name.text == hook.methodName
                          && function.signature.parameterClause.parameters.count == hook.parameterCount
                          && isAsyncFunction(function)
                  }) else {
                continue
            }

            for statement in superCallStatements(in: function) {
                // UIKit super calls must stay in the generated synchronous
                // override. Calling them from the async hook would run them
                // later, outside UIKit's lifecycle call stack.
                context.diagnose(
                    Diagnostic(
                        node: Syntax(statement),
                        message: AsyncLifeCycleDiagnostic("Do not call super from async lifecycle hooks. @Async calls UIKit super methods synchronously in the generated lifecycle override."),
                        fixIts: [
                            FixIt(
                                message: AsyncLifeCycleFixItMessage("Remove super call"),
                                changes: [
                                    .replace(
                                        oldNode: Syntax(statement),
                                        newNode: Syntax(CodeBlockItemListSyntax([]))
                                    )
                                ]
                            )
                        ]
                    )
                )
                diagnosed = true
            }
        }

        return diagnosed
    }

    private static func superCallStatements(in function: FunctionDeclSyntax) -> [CodeBlockItemSyntax] {
        guard let body = function.body else {
            return []
        }

        // Attach diagnostics to the whole statement so the fix-it can remove
        // `super.viewDidLoad()` cleanly.
        return body.statements.filter { statement in
            let visitor = SuperReferenceVisitor(viewMode: .sourceAccurate)
            visitor.walk(statement)
            return visitor.foundSuperReference
        }
    }
}

private final class SuperReferenceVisitor: SyntaxVisitor {
    private(set) var foundSuperReference = false

    override func visit(_ node: SuperExprSyntax) -> SyntaxVisitorContinueKind {
        foundSuperReference = true
        return .skipChildren
    }
}

private struct AsyncLifeCycleFixItMessage: FixItMessage {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var fixItID: MessageID {
        MessageID(domain: "AsyncLifeCycle", id: "fix-it")
    }
}

private struct LifeCycleHook {
    let methodName: String
    let parameterCount: Int
    let overrideSource: String
}

private let lifeCycleHooks: [LifeCycleHook] = [
    LifeCycleHook(
        methodName: "viewDidLoad",
        parameterCount: 0,
        overrideSource: """
        override func viewDidLoad() {
            super.viewDidLoad()
            __asyncLifeCycleStartTask(methodName: "viewDidLoad") { @MainActor [weak self] in
                await self?.viewDidLoad()
            }
        }
        """
    ),
    LifeCycleHook(
        methodName: "viewWillAppear",
        parameterCount: 1,
        overrideSource: """
        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            __asyncLifeCycleStartTask(methodName: "viewWillAppear") { @MainActor [weak self] in
                await self?.viewWillAppear(animated)
            }
        }
        """
    ),
    LifeCycleHook(
        methodName: "viewIsAppearing",
        parameterCount: 1,
        overrideSource: """
        override func viewIsAppearing(_ animated: Bool) {
            super.viewIsAppearing(animated)
            __asyncLifeCycleStartTask(methodName: "viewIsAppearing") { @MainActor [weak self] in
                await self?.viewIsAppearing(animated)
            }
        }
        """
    ),
    LifeCycleHook(
        methodName: "viewDidAppear",
        parameterCount: 1,
        overrideSource: """
        override func viewDidAppear(_ animated: Bool) {
            super.viewDidAppear(animated)
            __asyncLifeCycleStartTask(methodName: "viewDidAppear") { @MainActor [weak self] in
                await self?.viewDidAppear(animated)
            }
        }
        """
    ),
    LifeCycleHook(
        methodName: "viewWillDisappear",
        parameterCount: 1,
        overrideSource: """
        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            __asyncLifeCycleStartTask(methodName: "viewWillDisappear") { @MainActor [weak self] in
                await self?.viewWillDisappear(animated)
            }
        }
        """
    ),
    LifeCycleHook(
        methodName: "viewDidDisappear",
        parameterCount: 1,
        overrideSource: """
        override func viewDidDisappear(_ animated: Bool) {
            super.viewDidDisappear(animated)
            __asyncLifeCycleCancelTasks()
            __asyncLifeCycleStartTask(methodName: "viewDidDisappear") { @MainActor [weak self] in
                await self?.viewDidDisappear(animated)
            }
        }
        """
    )
]

private func taskStorageMembers(ownerType: String) -> [DeclSyntax] {
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

private let cancellationOnlyViewDidDisappearSource = """
override func viewDidDisappear(_ animated: Bool) {
    super.viewDidDisappear(animated)
    __asyncLifeCycleCancelTasks()
}
"""

private struct AsyncLifeCycleDiagnostic: DiagnosticMessage {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var diagnosticID: MessageID {
        MessageID(domain: "AsyncLifeCycle", id: "invalid-async-lifecycle-controller")
    }

    var severity: DiagnosticSeverity {
        .error
    }
}
