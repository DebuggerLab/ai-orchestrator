// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "AI Orchestrator Manager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "AI Orchestrator Manager", targets: ["AI Orchestrator Manager"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "AI Orchestrator Manager",
            dependencies: [],
            path: "Sources"
        )
    ]
)
