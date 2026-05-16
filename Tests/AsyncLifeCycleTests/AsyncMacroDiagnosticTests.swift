import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import AsyncLifeCyclePlugin

final class AsyncMacroDiagnosticTests: XCTestCase {
    private let macros: [String: any Macro.Type] = [
        "Async": AsyncMacro.self
    ]

    func testDiagnosesUseOnNonDirectUIViewControllerSubclass() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: BaseViewController {
            }
            """,
            expandedSource:
            """
            final class DemoViewController: BaseViewController {
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Async can only be applied to direct UIViewController subclasses. Macros cannot safely prove that another superclass is a UIViewController subclass.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }

    func testDiagnosesSynchronousOverrideForAsyncLifecycleHook() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIViewController {
                override func viewDidLoad() {
                }

                func viewDidLoad() async {
                }
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIViewController {
                override func viewDidLoad() {
                }

                func viewDidLoad() async {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Async cannot generate viewDidLoad because this class already defines a synchronous override. Move synchronous work into viewDidLoad(...) async, or remove the async hook and manage that lifecycle method yourself.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }

    func testDiagnosesReservedViewDidDisappearOverride() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIViewController {
                override func viewDidDisappear(_ animated: Bool) {
                }
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIViewController {
                override func viewDidDisappear(_ animated: Bool) {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Async needs to generate viewDidDisappear(_:) to cancel active tasks. Remove your viewDidDisappear(_:) override, or do not use this macro on this class.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }

    func testDiagnosesSuperCallsInsideAsyncLifecycleHooks() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIViewController {
                func viewDidLoad() async {
                    super.viewDidLoad()
                }
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIViewController {
                func viewDidLoad() async {
                    super.viewDidLoad()
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "Do not call super from async lifecycle hooks. @Async calls UIKit super methods synchronously in the generated lifecycle override.",
                    line: 4,
                    column: 9,
                    fixIts: [
                        FixItSpec(message: "Remove super call")
                    ]
                )
            ],
            macros: macros
        )
    }
}
