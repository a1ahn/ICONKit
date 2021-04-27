// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ICONKit",
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "ICONKit",
            targets: ["ICONKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.3.8"),
        .package(url: "https://github.com/attaswift/BigInt.git", from: "5.2.1"),
        .package(url: "https://github.com/greymass/secp256k1.git", from: "0.0.3"),
        .package(url: "https://github.com/greymass/swift-scrypt.git", from: "1.0.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "ICONKit",
            dependencies: [
                "CryptoSwift",
                "secp256k1",
                "BigInt",
                .product(name: "Scrypt", package: "swift-scrypt"),
            ],
            path: "Source"
        ),
    ]
)
