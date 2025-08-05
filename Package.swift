// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Mercury",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .watchOS(.v9),
        .tvOS(.v16),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "Mercury",
            targets: ["Mercury"]
        ),
        .library(
            name: "MercuryTesting",
            targets: ["MercuryTesting"]
        ),
    ],
    targets: [
        .target(
            name: "Mercury"
        ),
        .target(
            name: "MercuryTesting",
            dependencies: ["Mercury"],
            path: "Sources/MercuryTesting"
        ),
        .testTarget(
            name: "MercuryTests",
            dependencies: ["Mercury", "MercuryTesting"]
        ),
    ]
)
