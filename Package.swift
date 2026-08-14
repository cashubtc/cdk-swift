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
            url: "https://github.com/cashubtc/cdk-swift/releases/download/v0.17.4/CashuDevKitFFI.xcframework.zip",
            checksum: "0908c519ee72a0d80713dbb96d787fd5a3bd8ee1fb38074cc2e562b417911c96"
        ),
        .target(
            name: "Cdk",
            dependencies: ["CashuDevKitFFI"],
            path: "Sources/Cdk"
        ),
    ]
)
