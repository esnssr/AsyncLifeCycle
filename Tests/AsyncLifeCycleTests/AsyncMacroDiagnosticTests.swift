import SwiftSyntaxMacros
import SwiftSyntaxMacrosTestSupport
import XCTest

@testable import AsyncLifeCyclePlugin

final class AsyncMacroDiagnosticTests: XCTestCase {
    private let macros: [String: any Macro.Type] = [
        "Async": AsyncMacro.self
    ]

    func testDiagnosesUnsupportedCustomBaseClass() {
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
                    message: "@Async does not support this type yet. Use a supported UIKit type directly, or add a component profile for it.",
                    line: 1,
                    column: 1
                )
            ],
            macros: macros
        )
    }

    func testDiagnosesUnsupportedUIKitComponent() {
        assertMacroExpansion(
            """
            @Async
            final class DemoView: UIView {
                func didMoveToWindow() async {
                }
            }
            """,
            expandedSource:
            """
            final class DemoView: UIView {
                func didMoveToWindow() async {
                }
            }
            """,
            diagnostics: [
                DiagnosticSpec(
                    message: "@Async does not support this type yet. Use a supported UIKit type directly, or add a component profile for it.",
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
                    message: "@Async needs to generate viewDidDisappear(_:) to manage task cancellation for UIViewController. Remove your viewDidDisappear(_:) override, or do not use this macro on this class.",
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
                    message: "Do not call super from async UIKit hooks. @Async calls UIKit super methods synchronously in the generated override.",
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
