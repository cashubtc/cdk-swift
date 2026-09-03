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
            url: "https://github.com/cashubtc/cdk-swift/releases/download/v0.18.0-nightly.20260903.gd3dec24/CashuDevKitFFI.xcframework.zip",
            checksum: "1b929a2fe008588933e997fc9112349e75f079d3b919ec634f9e4e78df08820b"
        ),
        .target(
            name: "Cdk",
            dependencies: ["CashuDevKitFFI"],
            path: "Sources/Cdk"
        ),
    ]
)
