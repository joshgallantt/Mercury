// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

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
    ],
    targets: [
        .target(
            name: "Mercury"
        ),
        .testTarget(
            name: "MercuryTests",
            dependencies: ["Mercury"]
        ),
    ]
)
