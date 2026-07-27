// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "TjnEngineKit",
    platforms: [.iOS(.v13), .macOS(.v11)],
    products: [
        .library(name: "TjnEngineKit", targets: ["TjnEngineKit"])
    ],
    targets: [
        .binaryTarget(
            name: "TjnEngineCore",
            url: "https://github.com/spawn66336/threejsnative-sdk/releases/download/1.0.0/TjnEngineKit-1.0.0.xcframework.zip",
            checksum: "c5ab750904d65f8b2d6340937eb8ce6646fb80952a767c219bf825f3d92b4103"
        ),
        .target(
            name: "TjnEngineKit",
            dependencies: ["TjnEngineCore"],
            path: "Sources/Swift",
            linkerSettings: [
                .linkedFramework("Metal"),
                .linkedFramework("QuartzCore"),
                .linkedFramework("UIKit", .when(platforms: [.iOS])),
                .linkedFramework("AppKit", .when(platforms: [.macOS])),
            ]
        )
    ]
)
