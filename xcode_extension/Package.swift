// swift-tools-version:5.9
// AI Orchestrator for Xcode - Source Editor Extension

import PackageDescription

let package = Package(
    name: "AIOrchestratorXcode",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "AIOrchestratorXcode",
            targets: ["AIOrchestratorXcode"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "AIOrchestratorXcode",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "AIOrchestratorXcodeTests",
            dependencies: ["AIOrchestratorXcode"],
            path: "Tests"
        )
    ]
)
