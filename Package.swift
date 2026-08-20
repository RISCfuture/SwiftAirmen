// swift-tools-version:6.0

import PackageDescription

let approachableConcurrency: [SwiftSetting] = [
  .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
  .enableUpcomingFeature("InferIsolatedConformances")
]

let package = Package(
  name: "SwiftAirmen",
  defaultLocalization: "en",
  platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9), .tvOS(.v16), .visionOS(.v1)],
  products: [
    // Products define the executables and libraries a package produces, and make them visible to other packages.
    .library(
      name: "SwiftAirmen",
      targets: ["SwiftAirmen"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/RISCfuture/StreamingCSV", from: "2.1.0"),
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.5.0"),
    .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.8.2"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20"),
    .package(url: "https://github.com/jkandzi/Progress.swift.git", from: "0.4.0")
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages this package depends on.
    .target(
      name: "SwiftAirmen",
      dependencies: [
        .product(name: "StreamingCSV", package: "StreamingCSV"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation")
      ],
      resources: [.process("Localizable.xcstrings")],
      swiftSettings: approachableConcurrency
    ),
    .testTarget(
      name: "SwiftAirmenTests",
      dependencies: ["SwiftAirmen"],
      resources: [.copy("TestResources")],
      swiftSettings: approachableConcurrency
    ),
    .executableTarget(
      name: "SwiftAirmenE2E",
      dependencies: [
        "SwiftAirmen",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
        .product(name: "Progress", package: "Progress.swift")
      ],
      swiftSettings: approachableConcurrency
    )
  ],
  swiftLanguageModes: [.v5, .v6]
)
