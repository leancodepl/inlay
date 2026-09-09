// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "example_module_native",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    // Plugin names containing `_` must expose a `-`-separated library name.
    .library(name: "example-module-native", targets: ["example_module_native"])
  ],
  dependencies: [
    // Flutter lays every plugin package out as a sibling of `FlutterFramework`
    // (`Packages/<plugin>`), so plugin-to-plugin dependencies use the same
    // relative-path convention as the framework itself.
    .package(name: "FlutterFramework", path: "../FlutterFramework"),
    .package(name: "inlay", path: "../inlay"),
  ],
  targets: [
    .target(
      name: "example_module_native",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework"),
        .product(name: "inlay", package: "inlay"),
      ]
    )
  ]
)
