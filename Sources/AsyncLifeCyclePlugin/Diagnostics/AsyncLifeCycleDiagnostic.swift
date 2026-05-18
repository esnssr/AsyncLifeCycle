import SwiftDiagnostics

struct AsyncLifeCycleDiagnostic: DiagnosticMessage {
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

struct AsyncLifeCycleFixItMessage: FixItMessage {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    var fixItID: MessageID {
        MessageID(domain: "AsyncLifeCycle", id: "fix-it")
    }
}
