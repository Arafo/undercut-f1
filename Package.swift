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
        .testTarget(
            name: "UndercutF1DataTests",
            dependencies: ["UndercutF1Data"],
            path: "Tests/UndercutF1DataTests"
        ),
    ]
)
