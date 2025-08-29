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
            url: "https://github.com/cashubtc/cdk-swift/releases/download/v0.0.6/cdkFFI.xcframework.zip",
            checksum: "b976e4320e7696e1c416e3fc972260bbd94a5e6632db1bc374514e203c0badf5"
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