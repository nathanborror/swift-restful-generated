// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "swift-restful-generated",
    platforms: [
        .iOS(.v18),
        .macOS(.v15),
    ],
    products: [
        .library(name: "Restful", targets: ["Restful"]),
    ],
    dependencies: [
        .package(url: "https://github.com/mattt/JSONSchema", from: "1.3.0"),
    ]
    targets: [
        .target(name: "Restful"),
        .testTarget(name: "RestfulTests", dependencies: ["Restful"]),
    ]
)
