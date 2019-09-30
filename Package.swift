// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "assetgen",
    platforms: [
        .macOS(.v10_13)
    ],
    products: [
        .executable(name: "assetgen", targets: ["assetgen"])        
    ],
    dependencies: [
        .package(url: "https://github.com/sebskuse/Discourse", .branch("master"))
    ],
    targets: [
        .target(name: "assetgen", dependencies: ["Discourse"])
    ]
)
