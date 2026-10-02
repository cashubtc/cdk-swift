// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "cdk-swift",
    platforms: [.iOS(.v14), .macOS(.v13)],
    products: [
        .library(name: "Cdk", targets: ["Cdk"]),
    ],
    targets: [
        .binaryTarget(
            name: "CashuDevKitFFI",
            url: "https://github.com/cashubtc/cdk-swift/releases/download/v0.18.0-nightly.20261002.g42ef19e/CashuDevKitFFI.xcframework.zip",
            checksum: "962c1a6188b64a856426d56712810ac09430c64577323b3e198c25fa86428807"
        ),
        .target(
            name: "Cdk",
            dependencies: ["CashuDevKitFFI"],
            path: "Sources/Cdk"
        ),
    ]
)
