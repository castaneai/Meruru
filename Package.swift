// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Meruru",
    platforms: [
        .macOS(.v14)
    ],
    dependencies: [
        .package(url: "https://github.com/tylerjonesio/vlckit-spm", .upToNextMajor(from: "3.6.0"))
    ],
    targets: [
        .executableTarget(
            name: "Meruru",
            dependencies: [
                .product(name: "VLCKitSPM", package: "vlckit-spm")
            ]
        )
    ]
)
