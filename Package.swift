// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "NetworkMonitor",
    platforms: [
        .iOS(.v12)
    ],
    products: [
        .library(
            name: "NetworkMonitor",
            targets: [
                "NetworkMonitor"
            ]
        ),
    ],
    dependencies: [
        // Dependencies
    ],
    targets: [
        .target(
            name: "NetworkMonitor",
            dependencies: []
        ),
        .testTarget(
            name: "NetworkMonitorTests",
            dependencies: ["NetworkMonitor"]
        ),
    ]
)
