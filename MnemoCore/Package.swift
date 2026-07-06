// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MnemoCore",
    platforms: [.iOS("18.0")],
    products: [
        .library(name: "MnemoCore", targets: ["MnemoCore"]),
    ],
    targets: [
        .target(
            name: "MnemoCore",
            dependencies: [],
            path: "Sources/MnemoCore"
        ),
        .testTarget(
            name: "MnemoCoreTests",
            dependencies: ["MnemoCore"],
            path: "Tests/MnemoCoreTests"
        ),
    ]
)
