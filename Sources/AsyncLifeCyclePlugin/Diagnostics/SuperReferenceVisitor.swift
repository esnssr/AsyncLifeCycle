import SwiftSyntax

final class SuperReferenceVisitor: SyntaxVisitor {
    private(set) var foundSuperReference = false

    override func visit(_ node: SuperExprSyntax) -> SyntaxVisitorContinueKind {
        foundSuperReference = true
        return .skipChildren
    }
}
