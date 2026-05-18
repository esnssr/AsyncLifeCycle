import SwiftSyntax

struct AsyncHookParameterSignature: Hashable {
    let externalLabel: String?
    let acceptedTypes: Set<String>

    init(externalLabel: String?, acceptedTypes: Set<String>) {
        self.externalLabel = externalLabel
        self.acceptedTypes = acceptedTypes
    }

    init(externalLabel: String?, type: String) {
        self.init(externalLabel: externalLabel, acceptedTypes: [type])
    }

    var displayLabel: String {
        externalLabel ?? "_"
    }

    func accepts(_ candidate: AsyncHookParameterSignature) -> Bool {
        externalLabel == candidate.externalLabel
            && !acceptedTypes.isDisjoint(with: candidate.acceptedTypes)
    }
}

struct AsyncHookSignature: Hashable {
    let name: String
    let parameters: [AsyncHookParameterSignature]

    init(_ name: String, parameters: [AsyncHookParameterSignature] = []) {
        self.name = name
        self.parameters = parameters
    }

    var displayName: String {
        guard !parameters.isEmpty else {
            return "\(name)()"
        }

        let labels = parameters.map { "\($0.displayLabel):" }.joined()
        return "\(name)(\(labels))"
    }

    func matches(_ candidate: AsyncHookSignature) -> Bool {
        name == candidate.name
            && parameters.count == candidate.parameters.count
            && zip(parameters, candidate.parameters).allSatisfy { expected, candidate in
                expected.accepts(candidate)
            }
    }
}

extension FunctionDeclSyntax {
    var asyncHookSignature: AsyncHookSignature {
        AsyncHookSignature(
            name.text,
            parameters: signature.parameterClause.parameters.map { parameter in
                AsyncHookParameterSignature(
                    externalLabel: parameter.firstName.text == "_" ? nil : parameter.firstName.text,
                    type: parameter.type.trimmedDescription
                )
            }
        )
    }

    var isAsyncFunction: Bool {
        signature.effectSpecifiers?.asyncSpecifier != nil
    }
}
