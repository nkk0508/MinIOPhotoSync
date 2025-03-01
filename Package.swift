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
            exclude: ["README.md"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "MinIOPhotoSyncTests",
            dependencies: ["MinIOPhotoSync"],
            path: "Tests"
        ),
    ]
)