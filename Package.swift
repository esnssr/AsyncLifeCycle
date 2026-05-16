// swift-tools-version: 6.2

import CompilerPluginSupport
import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault")
]

let package = Package(
    name: "AsyncLifeCycle",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "AsyncLifeCycle",
            targets: ["AsyncLifeCycle"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "602.0.0")
    ],
    targets: [
        .macro(
            name: "AsyncLifeCyclePlugin",
            dependencies: [
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxBuilder", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax")
            ],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "AsyncLifeCycle",
            dependencies: ["AsyncLifeCyclePlugin"],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AsyncLifeCycleTests",
            dependencies: [
                "AsyncLifeCycle",
                "AsyncLifeCyclePlugin",
                .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax")
            ],
            swiftSettings: swiftSettings
        )
    ]
)
