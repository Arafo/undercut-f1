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
            targets: ["UndercutF1TerminalCLI"]
        ),
    ],
    dependencies: [
        .package(path: "swift/UndercutF1Terminal")
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
            name: "UndercutF1TerminalCLI",
            dependencies: [
                "UndercutF1Data",
                .product(name: "UndercutF1Terminal", package: "UndercutF1Terminal")
            ],
            path: "Sources/UndercutF1TerminalCLI",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "UndercutF1DataTests",
            dependencies: ["UndercutF1Data"],
            path: "Tests/UndercutF1DataTests"
        ),
    ]
)
