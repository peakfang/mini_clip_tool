// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClipMini",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClipMini", targets: ["ClipMini"])
    ],
    targets: [
        .executableTarget(
            name: "ClipMini",
            path: "Sources/ClipMini",
            resources: [.copy("Resources")]
        ),
        .testTarget(name: "ClipMiniTests", dependencies: ["ClipMini"])
    ]
)
