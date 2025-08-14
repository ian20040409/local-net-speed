// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LocalNetSpeed",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "LocalNetSpeedCore",
            targets: ["LocalNetSpeedCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "LocalNetSpeedCore",
            dependencies: []
        ),
        .testTarget(
            name: "LocalNetSpeedCoreTests",
            dependencies: ["LocalNetSpeedCore"]
        ),
    ]
)