// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MnemoSync",
    platforms: [
        .iOS("18.0"),
        .macOS(.v14),
    ],
    products: [
        .library(name: "MnemoSync", targets: ["MnemoSync"]),
    ],
    dependencies: [
        .package(path: "../MnemoCore"),
        .package(path: "../MnemoMemory"),
        .package(path: "../MnemoSecurity"),
    ],
    targets: [
        .target(
            name: "MnemoSync",
            dependencies: ["MnemoCore", "MnemoMemory", "MnemoSecurity"],
            path: "Sources/MnemoSync"
        ),
        .testTarget(
            name: "MnemoSyncTests",
            dependencies: ["MnemoSync"],
            path: "Tests/MnemoSyncTests"
        ),
    ]
)
