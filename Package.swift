// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftHTTPClient",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "SwiftHTTPClient",
            targets: ["SwiftHTTPClient"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftHTTPClient"
        ),
        .testTarget(
            name: "SwiftHTTPClientTests",
            dependencies: ["SwiftHTTPClient"]
        ),
    ]
)
