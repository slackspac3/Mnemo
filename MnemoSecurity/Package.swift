// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MnemoSecurity",
    platforms: [
        .iOS("18.0"),
        .macOS("11.0"),
    ],
    products: [
        .library(name: "MnemoSecurity", targets: ["MnemoSecurity"]),
    ],
    dependencies: [
        .package(path: "../MnemoCore"),
    ],
    targets: [
        .target(
            name: "MnemoSecurity",
            dependencies: ["MnemoCore"],
            path: "Sources/MnemoSecurity"
        ),
        .testTarget(
            name: "MnemoSecurityTests",
            dependencies: ["MnemoSecurity"],
            path: "Tests/MnemoSecurityTests"
        ),
    ]
)
