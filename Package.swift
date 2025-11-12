// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UndercutF1CLI",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "undercutf1",
            targets: ["UndercutF1CLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "UndercutF1CLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/UndercutF1CLI"
        )
    ]
)
