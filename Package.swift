// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MSCaptureView",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .library(
            name: "MSCaptureView",
            targets: ["MSCaptureView"]),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "MSCaptureView",
            dependencies: []),
        .testTarget(
            name: "MSCaptureViewTests",
            dependencies: ["MSCaptureView"]),
    ]
)
