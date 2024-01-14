// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "GRDBMacros",
  platforms: [.macOS(.v10_15), .iOS(.v13), .tvOS(.v13), .watchOS(.v6), .macCatalyst(.v13)],
  products: [
    .library(
      name: "GRDBMacros",
      targets: ["GRDBMacros"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-syntax.git", from: "509.0.0"),
    .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.24.1"),
    .package(url: "https://github.com/pointfreeco/swift-macro-testing.git", from: "0.2.2")
  ],
  targets: [
    .macro(
      name: "GRDBMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(
      name: "GRDBMacros",
      dependencies: [
      "GRDBMacrosPlugin",
      .product(name: "GRDB", package: "GRDB.swift")
    ]),
    .testTarget(
      name: "GRDBMacrosTests",
      dependencies: [
        "GRDBMacrosPlugin",
        .product(name: "GRDB", package: "GRDB.swift"),
        .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
        .product(name: "MacroTesting", package: "swift-macro-testing")
      ]
    ),
  ]
)
