// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "locheck",
    products: [
        .executable(name: "locheck", targets: ["locheck"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .upToNextMinor(from: "0.4.0")),
        .package(url: "https://github.com/johnsundell/Files.git", .upToNextMinor(from: "4.2.0")),
    ],
    targets: [
        .target(
            name: "locheck",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Files", package: "Files"),
                .target(name: "LocheckLogic"),
            ]),
        .target(
            name: "LocheckLogic",
            dependencies: [
                .product(name: "Files", package: "Files"),
            ]),
        .testTarget(
            name: "locheckTests",
            dependencies: ["locheck"]),
    ])
