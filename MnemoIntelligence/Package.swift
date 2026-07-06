// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MnemoIntelligence",
    platforms: [
        .iOS("18.0"),
        .macOS("14.0"),
    ],
    products: [
        .library(name: "MnemoIntelligence", targets: ["MnemoIntelligence"]),
    ],
    dependencies: [
        .package(path: "../MnemoCore"),
        .package(path: "../MnemoMemory"),
    ],
    targets: [
        .target(
            name: "MnemoIntelligence",
            dependencies: ["MnemoCore", "MnemoMemory"],
            path: "Sources/MnemoIntelligence"
        ),
        .testTarget(
            name: "MnemoIntelligenceTests",
            dependencies: ["MnemoIntelligence"],
            path: "Tests/MnemoIntelligenceTests"
        ),
    ]
)
