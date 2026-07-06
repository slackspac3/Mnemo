// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MnemoUI",
    platforms: [.iOS("18.0")],
    products: [
        .library(name: "MnemoUI", targets: ["MnemoUI"]),
    ],
    dependencies: [
        .package(path: "../MnemoCore"),
        .package(path: "../MnemoMemory"),
        .package(path: "../MnemoIntelligence"),
    ],
    targets: [
        .target(
            name: "MnemoUI",
            dependencies: ["MnemoCore", "MnemoMemory", "MnemoIntelligence"],
            path: "Sources/MnemoUI"
        ),
        .testTarget(
            name: "MnemoUITests",
            dependencies: ["MnemoUI"],
            path: "Tests/MnemoUITests"
        ),
    ]
)
