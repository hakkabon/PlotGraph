// swift-tools-version:5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PlotGraph",
    platforms: [.iOS(.v13)],
    products: [
        .library(name: "PlotGraph", targets: ["PlotGraph"]),
    ],
    dependencies: [
        .package(url: "https://github.com/hakkabon/Dimensional.git", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "PlotGraph"),
        .testTarget(
            name: "PlotGraphTests",
            dependencies: ["PlotGraph"]),
    ]
)
