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
  dependencies: [],
  targets: [
    .target(
      name: "inlay",
      dependencies: []
    )
  ]
)
