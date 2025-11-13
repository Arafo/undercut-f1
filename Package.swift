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
        .library(
            name: "UndercutF1Host",
            targets: ["UndercutF1Host"]
        ),
        .library(
            name: "UndercutF1Web",
            targets: ["UndercutF1Web"]
        ),
    ],
    dependencies: [],
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
            name: "Vapor",
            path: "Sources/Vapor"
        ),
        .target(
            name: "UndercutF1Data",
            dependencies: ["CZlibShim"],
            path: "Sources/UndercutF1Data"
        ),
        .target(
            name: "UndercutF1Host",
            dependencies: [
                "UndercutF1Data"
            ],
            path: "Sources/UndercutF1Host"
        ),
        .target(
            name: "UndercutF1Web",
            dependencies: [
                "UndercutF1Host",
                "Vapor"
            ],
            path: "Sources/UndercutF1Web"
        ),
        .testTarget(
            name: "UndercutF1DataTests",
            dependencies: ["UndercutF1Data"],
            path: "Tests/UndercutF1DataTests"
        ),
        .testTarget(
            name: "UndercutF1HostTests",
            dependencies: [
                "UndercutF1Host",
                "UndercutF1Web"
            ],
            path: "Tests/UndercutF1HostTests"
        ),
    ]
)
