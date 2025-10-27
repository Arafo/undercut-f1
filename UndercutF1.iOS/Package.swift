// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "UndercutF1iOS",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .iOSApplication(
            name: "UndercutF1 iOS",
            targets: ["AppModule"],
            bundleIdentifier: "com.undercutf1.app",
            teamIdentifier: "TEAMID",
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .asset("AppIcon"),
            accentColor: .asset("AccentColor"),
            supportedDeviceFamilies: [
                .phone,
                .pad
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .portraitUpsideDown,
                .landscapeLeft,
                .landscapeRight
            ]
        )
    ],
    targets: [
        .executableTarget(
            name: "AppModule",
            path: "Sources",
            resources: [
                .process("../Resources")
            ]
        )
    ]
)
