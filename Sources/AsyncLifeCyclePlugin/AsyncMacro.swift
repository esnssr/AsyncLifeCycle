import SwiftCompilerPlugin
import SwiftDiagnostics
public import SwiftSyntax
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
                    message: AsyncLifeCycleDiagnostic("@Async can only be applied to a supported UIKit class.")
                )
            )
            return []
        }

        guard let profile = AsyncComponentRegistry.profile(for: classDeclaration) else {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: AsyncLifeCycleDiagnostic("@Async does not support this type yet. Use a supported UIKit type directly, or add a component profile for it.")
                )
            )
            return []
        }

        if diagnoseSuperCalls(in: declaration, profile: profile, context: context) {
            return []
        }

        // Member macros cannot merge generated overrides with user-written
        // overrides, so report a focused diagnostic before Swift reports a
        // duplicate method error.
        for hook in profile.hooks {
            guard containsAsyncMethod(matching: hook.signature, in: declaration),
                  containsSyncMethod(matching: hook.signature, in: declaration) else {
                continue
            }

            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: AsyncLifeCycleDiagnostic("@Async cannot generate \(hook.signature.name) because this class already defines a synchronous override. Move synchronous work into \(hook.signature.name)(...) async, or remove the async hook and manage that lifecycle method yourself.")
                )
            )
            return []
        }

        // The profile's cancellation hook is reserved even without a matching
        // async hook because task cancellation must stay under macro control.
        if let cancellationHook = profile.cancellationHook,
           containsSyncMethod(matching: cancellationHook, in: declaration) {
            context.diagnose(
                Diagnostic(
                    node: Syntax(node),
                    message: AsyncLifeCycleDiagnostic("@Async needs to generate \(cancellationHook.displayName) to manage task cancellation for \(profile.name). Remove your \(cancellationHook.displayName) override, or do not use this macro on this class.")
                )
            )
            return []
        }

        let enabledHooks = profile.hooks.filter { hook in
            containsAsyncMethod(matching: hook.signature, in: declaration)
        }
        return AsyncMemberGenerator.members(
            ownerType: classDeclaration.name.text,
            profile: profile,
            enabledHooks: enabledHooks
        )
    }

    private static func containsAsyncMethod(
        matching signature: AsyncHookSignature,
        in declaration: some DeclGroupSyntax
    ) -> Bool {
        containsMethod(matching: signature, in: declaration) { function in
            function.isAsyncFunction
        }
    }

    private static func containsSyncMethod(
        matching signature: AsyncHookSignature,
        in declaration: some DeclGroupSyntax
    ) -> Bool {
        containsMethod(matching: signature, in: declaration) { function in
            !function.isAsyncFunction
        }
    }

    private static func containsMethod(
        matching signature: AsyncHookSignature,
        in declaration: some DeclGroupSyntax,
        where predicate: (FunctionDeclSyntax) -> Bool = { _ in true }
    ) -> Bool {
        declaration.memberBlock.members.contains { member in
            guard let function = member.decl.as(FunctionDeclSyntax.self) else {
                return false
            }

            return signature.matches(function.asyncHookSignature)
                && predicate(function)
        }
    }

    private static func diagnoseSuperCalls(
        in declaration: some DeclGroupSyntax,
        profile: AsyncComponentProfile,
        context: some MacroExpansionContext
    ) -> Bool {
        var diagnosed = false

        for member in declaration.memberBlock.members {
            guard let function = member.decl.as(FunctionDeclSyntax.self),
                  profile.hook(matching: function.asyncHookSignature) != nil,
                  function.isAsyncFunction else {
                continue
            }

            for statement in superCallStatements(in: function) {
                // UIKit super calls must stay in the generated synchronous override.
                // Calling them from an async hook would run them later, outside
                // UIKit's original call stack.
                context.diagnose(
                    Diagnostic(
                        node: Syntax(statement),
                        message: AsyncLifeCycleDiagnostic("Do not call super from async UIKit hooks. @Async calls UIKit super methods synchronously in the generated override."),
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
