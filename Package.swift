// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SkelpoMetrics",
    products: [
        .library(name: "SkelpoMetrics", targets: ["SkelpoMetrics"]),
        .library(name: "VaporSkelpoMetrics", targets: ["VaporSkelpoMetrics", "SkelpoMetrics"])
    ],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "3.3.0"),
        .package(url: "https://github.com/apple/swift-metrics", from: "1.0.0-convergence.1")
    ],
    targets: [
        .target(name: "SkelpoMetrics", dependencies: ["Metrics"]),
        .target(name: "VaporSkelpoMetrics", dependencies: ["SkelpoMetrics", "Vapor"]),
        .testTarget(name: "SkelpoMetricsTests", dependencies: ["SkelpoMetrics"]),
    ]
)
