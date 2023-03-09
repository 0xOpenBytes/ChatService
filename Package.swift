// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ChatService",
    platforms: [
        .macOS(.v11),
        .iOS(.v14),
        .watchOS(.v7),
        .tvOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "ChatService",
            targets: ["ChatService"]
        )
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
         .package(url: "https://github.com/0xLeif/Plugin", from: "2.0.0"),
         .package(url: "https://github.com/0xOpenBytes/Cache", from: "0.1.0"),
         .package(url: "https://github.com/0xOpenBytes/Network", from: "0.1.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "ChatService",
            dependencies: [
                "Plugin",
                "Cache",
                "Network"
            ]
        ),
        .testTarget(
            name: "ChatServiceTests",
            dependencies: ["ChatService"]
        )
    ]
)
