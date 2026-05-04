// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RatifyeSDK",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "RatifyeSDK",
            targets: ["RatifyeSDK"]
        )
    ],
    targets: [
        .target(
            name: "RatifyeSDK",
            dependencies: [],
            path: "Sources/RatifyeSDK"
        ),
        .testTarget(
            name: "RatifyeSDKTests",
            dependencies: ["RatifyeSDK"],
            path: "Tests/RatifyeSDKTests"
        )
    ]
)
