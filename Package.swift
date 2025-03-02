// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MinIOPhotoSync",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "MinIOPhotoSync",
            targets: ["MinIOPhotoSync"]),
    ],
    dependencies: [
        // Dependencies go here
    ],
    targets: [
        .target(
            name: "MinIOPhotoSync",
            dependencies: [],
            path: ".",
            exclude: ["README.md", "Tests"],
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                .unsafeFlags(["-import-objc-header", "MinIOPhotoSync-Bridging-Header.h"])
            ]
        ),
        .testTarget(
            name: "MinIOPhotoSyncTests",
            dependencies: ["MinIOPhotoSync"],
            path: "Tests"
        ),
    ]
)
