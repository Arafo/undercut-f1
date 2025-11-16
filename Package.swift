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
            name: "UndercutF1Terminal",
            targets: ["UndercutF1Terminal"]
        ),
        .executable(
            name: "undercutf1",
            targets: ["UndercutF1CLI"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        .package(url: "https://github.com/apple/swift-log.git", from: "1.5.0"),
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.0"),
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
        .target(
            name: "UndercutF1Terminal",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm")
            ],
            path: "swift/UndercutF1Terminal/Sources/UndercutF1Terminal"
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
            name: "UndercutF1TerminalTests",
            dependencies: ["UndercutF1Terminal"],
            path: "swift/UndercutF1Terminal/Tests/UndercutF1TerminalTests"
        ),
    ]
)
