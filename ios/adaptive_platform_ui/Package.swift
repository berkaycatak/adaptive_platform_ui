// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "adaptive_platform_ui",
    platforms: [
        .iOS("13.0")
    ],
    products: [
        .library(name: "adaptive-platform-ui", targets: ["adaptive_platform_ui"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "adaptive_platform_ui",
            dependencies: []
        )
    ]
)
