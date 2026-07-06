// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MnemoMemory",
    platforms: [
        .iOS("18.0"),
        .macOS("14.0"),
    ],
    products: [
        .library(name: "MnemoMemory", targets: ["MnemoMemory"]),
    ],
    dependencies: [
        .package(path: "../MnemoCore"),
        .package(path: "../MnemoSecurity"),
    ],
    targets: [
        .target(
            name: "MnemoMemory",
            dependencies: ["MnemoCore", "MnemoSecurity"],
            path: "Sources/MnemoMemory"
        ),
        .testTarget(
            name: "MnemoMemoryTests",
            dependencies: ["MnemoMemory"],
            path: "Tests/MnemoMemoryTests"
        ),
    ]
)
