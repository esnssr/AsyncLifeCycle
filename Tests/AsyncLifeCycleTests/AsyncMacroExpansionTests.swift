import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import AsyncLifeCyclePlugin

final class AsyncMacroExpansionTests: XCTestCase {
    private let macros: [String: any Macro.Type] = [
        "Async": AsyncMacro.self
    ]

    func testViewDidLoadExpansionAddsTaskStorageAndCancellationOverride() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIViewController {
                func viewDidLoad() async {}
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIViewController {
                func viewDidLoad() async {}

                private let __asyncLifeCycleTaskBag = _AsyncLifeCycleTaskBag(ownerType: "DemoViewController")

                private func __asyncLifeCycleStartTask(
                    methodName: String,
                    _ operation: @escaping @MainActor @Sendable () async -> Void
                ) {
                    __asyncLifeCycleTaskBag.start(methodName: methodName, operation)
                }

                private func __asyncLifeCycleCancelTasks() {
                    __asyncLifeCycleTaskBag.cancelAll()
                }

                override func viewDidLoad() {
                    super.viewDidLoad()
                    __asyncLifeCycleStartTask(methodName: "viewDidLoad") { @MainActor [weak self] in
                        await self?.viewDidLoad()
                    }
                }

                override func viewDidDisappear(_ animated: Bool) {
                    super.viewDidDisappear(animated)
                    __asyncLifeCycleCancelTasks()
                }
            }
            """,
            macros: macros
        )
    }

    func testViewDidDisappearExpansionCancelsBeforeStartingDisappearHook() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIViewController {
                func viewDidDisappear(_ animated: Bool) async {}
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIViewController {
                func viewDidDisappear(_ animated: Bool) async {}

                private let __asyncLifeCycleTaskBag = _AsyncLifeCycleTaskBag(ownerType: "DemoViewController")

                private func __asyncLifeCycleStartTask(
                    methodName: String,
                    _ operation: @escaping @MainActor @Sendable () async -> Void
                ) {
                    __asyncLifeCycleTaskBag.start(methodName: methodName, operation)
                }

                private func __asyncLifeCycleCancelTasks() {
                    __asyncLifeCycleTaskBag.cancelAll()
                }

                override func viewDidDisappear(_ animated: Bool) {
                    super.viewDidDisappear(animated)
                    __asyncLifeCycleCancelTasks()
                    __asyncLifeCycleStartTask(methodName: "viewDidDisappear") { @MainActor [weak self] in
                        await self?.viewDidDisappear(animated)
                    }
                }
            }
            """,
            macros: macros
        )
    }
}
