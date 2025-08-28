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
            url: "https://github.com/cashubtc/cdk-swift/releases/download/v0.0.1/cdkFFI.xcframework.zip",
            checksum: "b867c6f174061bbbf1ac2c9009e7fc2d352029b73c30be19269afb88cbcc7009"
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