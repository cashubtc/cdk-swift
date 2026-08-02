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
            url: "https://github.com/cashubtc/cdk-swift/releases/download/v0.17.0-nightly.20260802.g795aec2/CashuDevKitFFI.xcframework.zip",
            checksum: "6750c801a708a13f05ce0861f970bcf20dab0ed19c4821f90e6a31f6cee8aa25"
        ),
        .target(
            name: "Cdk",
            dependencies: ["CashuDevKitFFI"],
            path: "Sources/Cdk"
        ),
    ]
)
