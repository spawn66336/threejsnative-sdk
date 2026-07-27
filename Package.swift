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
            url: "https://github.com/spawn66336/threejsnative-sdk/releases/download/1.0.1/TjnEngineKit-1.0.1.xcframework.zip",
            checksum: "234b8b344678f6fe9890976b1808824f8fac9e2ac55a9f134793c6d28f22e6eb"
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
