// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CombineAsyncually",

    // MARK: - Platform Support

    platforms: [
        .iOS("15.0"),
        .macOS("12.0"),
        .watchOS("8.0"),
        .tvOS("15.0")
    ],

    // MARK: - Products

    products: [
        .library(name: "CombineAsyncually", targets: [ "CombineAsyncually" ]),
    ],

    // MARK: - Package Dependencies

    dependencies: [
    ],

    // MARK: - Targets
    targets: [

        // Main Target
        .target(
            name: "CombineAsyncually",
            dependencies: [
            ]
        ),

        // Main Test Target
        .testTarget(
            name: "CombineAsyncuallyTests",
            dependencies: [
                .target(name: "CombineAsyncually")
            ]
        ),

    ]
)
