// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "inlay",
  platforms: [
    .iOS("13.0")
  ],
  products: [
    .library(name: "inlay", targets: ["inlay"])
  ],
  dependencies: [
    // `flutter build swift-package` lays every plugin package out as a sibling
    // of `FlutterFramework`; declaring the dependency here (as the Flutter
    // plugin template does) keeps the tool from injecting it with
    // `swift package add-dependency`, which fails on SwiftPM versions that
    // validate the path before the framework package exists.
    .package(name: "FlutterFramework", path: "../FlutterFramework")
  ],
  targets: [
    .target(
      name: "inlay",
      dependencies: [
        .product(name: "FlutterFramework", package: "FlutterFramework")
      ]
    )
  ]
)
