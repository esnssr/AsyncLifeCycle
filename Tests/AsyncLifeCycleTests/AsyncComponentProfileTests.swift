import XCTest

@testable import AsyncLifeCyclePlugin

final class AsyncComponentProfileTests: XCTestCase {
    func testRegistryContainsViewControllerProfile() {
        XCTAssertTrue(AsyncComponentRegistry.profiles.contains(.uiViewController))
    }

    func testRegistryContainsViewProfile() {
        XCTAssertTrue(AsyncComponentRegistry.profiles.contains(.uiView))
    }

    func testViewControllerProfileSupportsQualifiedAndUnqualifiedBaseTypes() {
        let supportedBaseTypes = AsyncComponentProfile.uiViewController.supportedBaseTypes

        XCTAssertTrue(supportedBaseTypes.contains("UIViewController"))
        XCTAssertTrue(supportedBaseTypes.contains("UIKit.UIViewController"))
    }

    func testViewProfileSupportsQualifiedAndUnqualifiedBaseTypes() {
        let supportedBaseTypes = AsyncComponentProfile.uiView.supportedBaseTypes

        XCTAssertTrue(supportedBaseTypes.contains("UIView"))
        XCTAssertTrue(supportedBaseTypes.contains("UIKit.UIView"))
    }

    func testViewProfileSupportsOnlyInitialViewHooks() {
        let hookNames = AsyncComponentProfile.uiView.hooks.map(\.signature.displayName)

        XCTAssertEqual(
            hookNames,
            [
                "didMoveToWindow()",
                "didMoveToSuperview()",
                "layoutSubviews()"
            ]
        )
    }

    func testEveryProfileDeclaresBaseTypesAndHooks() {
        for profile in AsyncComponentRegistry.profiles {
            XCTAssertFalse(profile.supportedBaseTypes.isEmpty, "\(profile.name) must declare at least one supported base type.")
            XCTAssertFalse(profile.hooks.isEmpty, "\(profile.name) must declare at least one async hook.")
        }
    }

    func testEveryProfileHasUniqueHookSignatures() {
        for profile in AsyncComponentRegistry.profiles {
            let signatures = profile.hooks.map(\.signature)
            XCTAssertEqual(
                Set(signatures).count,
                signatures.count,
                "\(profile.name) has duplicate hook signatures."
            )
        }
    }

    func testEveryCancellationHookBelongsToItsProfile() {
        for profile in AsyncComponentRegistry.profiles {
            guard let cancellationHook = profile.cancellationHook else {
                continue
            }

            XCTAssertNotNil(
                profile.hook(matching: cancellationHook),
                "\(profile.name) cancellation hook must be declared in its hook list."
            )
        }
    }

    func testGeneratedOverrideSourcesReferenceMatchingHookNames() {
        for profile in AsyncComponentRegistry.profiles {
            for hook in profile.hooks {
                XCTAssertTrue(hook.overrideSource.contains("override func \(hook.signature.name)"))
                XCTAssertTrue(hook.overrideSource.contains("super.\(hook.signature.name)"))
                XCTAssertTrue(hook.overrideSource.contains("await self?.\(hook.signature.name)"))
            }
        }
    }
}
