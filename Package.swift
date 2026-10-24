// swift-tools-version: 6.2

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault")
]

let package = Package(
    name: "AsyncLifeCycle",
    platforms: [
        .iOS(.v18)
    ],
    products: [
        .library(
            name: "AsyncLifeCycle",
            targets: ["AsyncLifeCycle"]
        )
    ],
    targets: [
        .target(
            name: "AsyncLifeCycle",
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "AsyncLifeCycleTests",
            dependencies: ["AsyncLifeCycle"],
            swiftSettings: swiftSettings
        )
    ]
)
