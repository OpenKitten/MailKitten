// swift-tools-version:4.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MailKitten",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MailKitten",
            targets: ["MailKitten"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/OpenKitten/Lynx.git", .exact("1.0.0-beta1")),
        .package(url: "https://github.com/OpenKitten/Schrodinger.git", .exact("2.0.0-beta1")),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MailKitten",
            dependencies: ["Lynx", "Schrodinger"]),
        .testTarget(
            name: "MailKittenTests",
            dependencies: ["MailKitten"]),
    ]
)
