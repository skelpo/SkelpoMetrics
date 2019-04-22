// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SkelpoMetrics",
    products: [
        .library(name: "SkelpoMetrics", targets: ["SkelpoMetrics"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-metrics", .branch("master"))
    ],
    targets: [
        .target(name: "SkelpoMetrics", dependencies: ["Metrics"]),
        .testTarget(name: "SkelpoMetricsTests", dependencies: ["SkelpoMetrics"]),
    ]
)
