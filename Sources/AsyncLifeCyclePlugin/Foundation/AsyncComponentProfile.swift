struct AsyncComponentProfile: Hashable {
    let name: String
    let supportedBaseTypes: Set<String>
    let hooks: [AsyncHook]
    let cancellationHook: AsyncHookSignature?

    func hook(matching signature: AsyncHookSignature) -> AsyncHook? {
        hooks.first { $0.signature.matches(signature) }
    }
}
