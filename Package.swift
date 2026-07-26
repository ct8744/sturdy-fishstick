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
        .package(url: "https://github.com/CoreOffice/CoreXLSX.git", from: "0.14.0")
    ],
    targets: [
        .target(
            name: "MyToolbox",
            dependencies: [
                .product(name: "CoreXLSX", package: "CoreXLSX")
            ],
            path: "Sources/MyToolbox",
            resources: []
        )
    ]
)
