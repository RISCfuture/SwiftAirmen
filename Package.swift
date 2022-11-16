// swift-tools-version:5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftAirmen",
    platforms: [.macOS(.v12), .iOS(.v15), .tvOS(.v14), .watchOS(.v8)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftAirmen",
            targets: ["SwiftAirmen"]),
    ],
    dependencies: [
        .package(url: "https://github.com/RISCfuture/csv.swift.git", branch: "master"),
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftAirmen",
            dependencies: [
                .product(name: "CSV", package: "csv.swift")
            ]),
        .testTarget(
            name: "SwiftAirmenTests",
            dependencies: ["SwiftAirmen"]),
        .executableTarget(
            name: "SwiftAirmenE2E",
            dependencies: ["SwiftAirmen"])
    ],
    swiftLanguageVersions: [.v5]
)
