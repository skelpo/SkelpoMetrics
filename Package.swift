// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "SkelpoMetrics",
    products: [
        .library(name: "SkelpoMetrics", targets: ["SkelpoMetrics"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "SkelpoMetrics", dependencies: []),
        .testTarget(name: "SkelpoMetricsTests", dependencies: ["SkelpoMetrics"]),
    ]
)
