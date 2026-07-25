// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyToolbox",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "MyToolbox",
            targets: ["MyToolbox"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.0")
    ],
    targets: [
        .target(
            name: "MyToolbox",
            dependencies: [
                .product(name: "ZIPFoundation", package: "ZIPFoundation")
            ],
            path: "Sources/MyToolbox",
            resources: []
        )
    ]
)
