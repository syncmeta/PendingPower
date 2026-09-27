// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PendingPower",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0"),
    ],
    targets: [
        .executableTarget(
            name: "PendingPower",
            dependencies: [.product(name: "Sparkle", package: "Sparkle")],
            path: "Sources/PendingPower",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("CoreFoundation"),
                .unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"]),
            ]
        )
    ]
)
