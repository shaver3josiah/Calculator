// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "BloomCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v13)
    ],
    products: [
        .library(name: "BloomCore", targets: ["BloomCore"])
    ],
    targets: [
        .target(
            name: "BloomCore",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "BloomCoreTests",
            dependencies: ["BloomCore"],
            resources: [.process("Resources")]
        )
    ]
)
