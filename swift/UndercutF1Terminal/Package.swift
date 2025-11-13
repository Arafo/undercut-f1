// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UndercutF1Terminal",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "UndercutF1Terminal",
            targets: ["UndercutF1Terminal"]
        ),
        .executable(
            name: "undercutf1-terminal-preview",
            targets: ["UndercutF1TerminalPreview"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/migueldeicaza/SwiftTerm.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "UndercutF1Terminal",
            dependencies: [
                .product(name: "SwiftTerm", package: "SwiftTerm"),
            ],
            path: "Sources/UndercutF1Terminal",
            resources: [
                .process("Resources/ThirdParty")
            ]
        ),
        .executableTarget(
            name: "UndercutF1TerminalPreview",
            dependencies: ["UndercutF1Terminal"],
            path: "Sources/UndercutF1TerminalPreview"
        ),
        .testTarget(
            name: "UndercutF1TerminalTests",
            dependencies: ["UndercutF1Terminal"],
            path: "Tests/UndercutF1TerminalTests"
        ),
    ]
)
