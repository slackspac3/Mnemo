// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MnemoCapture",
    platforms: [
        .iOS("18.0"),
        .macOS("14.0"),
    ],
    products: [
        .library(name: "MnemoCapture", targets: ["MnemoCapture"]),
    ],
    dependencies: [
        .package(path: "../MnemoCore"),
        .package(path: "../MnemoIntelligence"),
    ],
    targets: [
        .target(
            name: "MnemoCapture",
            dependencies: ["MnemoCore", "MnemoIntelligence"],
            path: "Sources/MnemoCapture"
        ),
        .testTarget(
            name: "MnemoCaptureTests",
            dependencies: ["MnemoCapture"],
            path: "Tests/MnemoCaptureTests"
        ),
    ]
)
