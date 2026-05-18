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

    func testUIKitQualifiedViewControllerExpansion() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIKit.UIViewController {
                func viewDidLoad() async {}
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIKit.UIViewController {
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

    func testIgnoresAsyncHookWithWrongParameterType() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIViewController {
                func viewDidDisappear(_ animated: String) async {}
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIViewController {
                func viewDidDisappear(_ animated: String) async {}

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
                }
            }
            """,
            macros: macros
        )
    }

    func testIgnoresAsyncHookWithWrongExternalParameterLabel() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIViewController {
                func viewDidDisappear(animated: Bool) async {}
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIViewController {
                func viewDidDisappear(animated: Bool) async {}

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
                }
            }
            """,
            macros: macros
        )
    }

    func testAcceptsQualifiedBoolParameterType() {
        assertMacroExpansion(
            """
            @Async
            final class DemoViewController: UIViewController {
                func viewDidDisappear(_ animated: Swift.Bool) async {}
            }
            """,
            expandedSource:
            """
            final class DemoViewController: UIViewController {
                func viewDidDisappear(_ animated: Swift.Bool) async {}

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

    func testViewDidMoveToWindowExpansionCancelsWhenRemovedFromWindow() {
        assertMacroExpansion(
            """
            @Async
            final class DemoView: UIView {
                func didMoveToWindow() async {}
            }
            """,
            expandedSource:
            """
            final class DemoView: UIView {
                func didMoveToWindow() async {}

                private let __asyncLifeCycleTaskBag = _AsyncLifeCycleTaskBag(ownerType: "DemoView")

                private func __asyncLifeCycleStartTask(
                    methodName: String,
                    _ operation: @escaping @MainActor @Sendable () async -> Void
                ) {
                    __asyncLifeCycleTaskBag.start(methodName: methodName, operation)
                }

                private func __asyncLifeCycleCancelTasks() {
                    __asyncLifeCycleTaskBag.cancelAll()
                }

                override func didMoveToWindow() {
                    super.didMoveToWindow()
                    if window == nil {
                        __asyncLifeCycleCancelTasks()
                    }
                    __asyncLifeCycleStartTask(methodName: "didMoveToWindow") { @MainActor [weak self] in
                        await self?.didMoveToWindow()
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testViewLayoutSubviewsExpansionAddsWindowRemovalCancellationOverride() {
        assertMacroExpansion(
            """
            @Async
            final class DemoView: UIKit.UIView {
                func layoutSubviews() async {}
            }
            """,
            expandedSource:
            """
            final class DemoView: UIKit.UIView {
                func layoutSubviews() async {}

                private let __asyncLifeCycleTaskBag = _AsyncLifeCycleTaskBag(ownerType: "DemoView")

                private func __asyncLifeCycleStartTask(
                    methodName: String,
                    _ operation: @escaping @MainActor @Sendable () async -> Void
                ) {
                    __asyncLifeCycleTaskBag.start(methodName: methodName, operation)
                }

                private func __asyncLifeCycleCancelTasks() {
                    __asyncLifeCycleTaskBag.cancelAll()
                }

                override func layoutSubviews() {
                    super.layoutSubviews()
                    __asyncLifeCycleStartTask(methodName: "layoutSubviews") { @MainActor [weak self] in
                        await self?.layoutSubviews()
                    }
                }

                override func didMoveToWindow() {
                    super.didMoveToWindow()
                    if window == nil {
                        __asyncLifeCycleCancelTasks()
                    }
                }
            }
            """,
            macros: macros
        )
    }

    func testViewTraitCollectionDidChangeExpansion() {
        assertMacroExpansion(
            """
            @Async
            final class DemoView: UIView {
                func traitCollectionDidChange(_ previousTraitCollection: UIKit.UITraitCollection?) async {}
            }
            """,
            expandedSource:
            """
            final class DemoView: UIView {
                func traitCollectionDidChange(_ previousTraitCollection: UIKit.UITraitCollection?) async {}

                private let __asyncLifeCycleTaskBag = _AsyncLifeCycleTaskBag(ownerType: "DemoView")

                private func __asyncLifeCycleStartTask(
                    methodName: String,
                    _ operation: @escaping @MainActor @Sendable () async -> Void
                ) {
                    __asyncLifeCycleTaskBag.start(methodName: methodName, operation)
                }

                private func __asyncLifeCycleCancelTasks() {
                    __asyncLifeCycleTaskBag.cancelAll()
                }

                override func traitCollectionDidChange(_ previousTraitCollection: UIKit.UITraitCollection?) {
                    super.traitCollectionDidChange(previousTraitCollection)
                    __asyncLifeCycleStartTask(methodName: "traitCollectionDidChange") { @MainActor [weak self] in
                        await self?.traitCollectionDidChange(previousTraitCollection)
                    }
                }

                override func didMoveToWindow() {
                    super.didMoveToWindow()
                    if window == nil {
                        __asyncLifeCycleCancelTasks()
                    }
                }
            }
            """,
            macros: macros
        )
    }
}
