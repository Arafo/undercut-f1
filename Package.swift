// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UndercutF1Swift",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "UndercutF1Data",
            targets: ["UndercutF1Data"]
        ),
        .executable(
            name: "undercutf1",
            targets: ["UndercutF1CLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
    ],
    targets: [
        .target(
            name: "CZlibShim",
            path: "Sources/CZlibShim",
            publicHeadersPath: "include",
            linkerSettings: [
                .linkedLibrary("z")
            ]
        ),
        .target(
            name: "UndercutF1Data",
            dependencies: ["CZlibShim"],
            path: "Sources/UndercutF1Data"
        ),
        .executableTarget(
            name: "UndercutF1CLI",
            dependencies: [
                "UndercutF1Data",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log"),
            ],
            path: "Sources/UndercutF1CLI"
        ),
        .testTarget(
            name: "UndercutF1DataTests",
            dependencies: ["UndercutF1Data"],
            path: "Tests/UndercutF1DataTests"
        ),
        .testTarget(
            name: "UndercutF1CLITests",
            dependencies: ["UndercutF1CLI"],
            path: "Tests/UndercutF1CLITests"
        ),
    ]
)
