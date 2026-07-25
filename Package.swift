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
    targets: [
        .target(
            name: "MyToolbox",
            path: "Sources/MyToolbox",
            resources: []
        )
    ]
)
