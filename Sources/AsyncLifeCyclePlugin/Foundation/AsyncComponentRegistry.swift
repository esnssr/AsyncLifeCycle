import SwiftSyntax

enum AsyncComponentRegistry {
    static let profiles: [AsyncComponentProfile] = [
        .uiViewController
    ]

    static func profile(for declaration: ClassDeclSyntax) -> AsyncComponentProfile? {
        let directBaseTypes = directBaseTypeNames(in: declaration)
        return profiles.first { profile in
            directBaseTypes.contains { profile.supportedBaseTypes.contains($0) }
        }
    }

    static func directBaseTypeNames(in declaration: ClassDeclSyntax) -> [String] {
        declaration.inheritanceClause?.inheritedTypes.map { inheritedType in
            inheritedType.type.trimmedDescription
        } ?? []
    }
}
