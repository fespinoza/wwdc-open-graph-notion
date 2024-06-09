// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "OpenGraphNotion",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
//        .package(url: "https://github.com/FiveSheepCo/SwiftyOpenGraph", from: "1.0.0"),
        .package(url: "https://github.com/pzmudzinski/OpenGraphReader", from: "1.0.1"),
        .package(url: "https://github.com/chojnac/NotionSwift", from: "0.8.0"),

    ],
    targets: [
        .executableTarget(
            name: "OpenGraphNotion",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
//                .product(name: "SwiftyOpenGraph", package: "SwiftyOpenGraph"),
                .product(name: "OpenGraphReader", package: "OpenGraphReader"),
                .product(name: "NotionSwift", package: "NotionSwift"),
            ]
        ),
    ]
)
