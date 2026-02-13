// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "cdk-swift",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CashuDevKit",
            targets: ["CashuDevKit"]
        )
    ],
    dependencies: [],
    targets: [
        .binaryTarget(
            name: "cdkFFI",
            url: "https://github.com/cashubtc/cdk-swift/releases/download/v0.15.0-rc.1/cdkFFI.xcframework.zip",
            checksum: "7f753efa1ec332186b692e132c9e1d20bfd475b1c0568e879f2e66b53ff31cc5"
        ),
        .target(
            name: "CashuDevKit",
            dependencies: ["cdkFFI"],
            linkerSettings: [
                .linkedLibrary("resolv")
            ]
        ),
        .testTarget(
            name: "CashuDevKitTests",
            dependencies: ["CashuDevKit"]
        )
    ]
)