// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "PendingPower",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "PendingPower",
            path: "Sources/PendingPower",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Foundation"),
                .linkedFramework("CoreFoundation"),
            ]
        )
    ]
)
