// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Server",

    // MARK: - Platforms

    platforms: [
        .iOS(.v17),
        .macOS(.v14),
    ],

    // MARK: - Products

    products: [
        .executable(name: "server", targets: [ "Server" ]),
        .library(name: "Models", targets: [ "Models" ]),
    ],

    // MARK: - Dependencies

    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.3.1"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing-extras.git", from: "1.0.0-beta.1"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.27.0"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0-beta.2"),
        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.0.0-beta.1"),
        .package(url: "https://github.com/bok-/swift-otel.git", branch: "main"),
    ],

    // MARK: - Targets

    targets: [
        .target(
            name: "Models",
            dependencies: [
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
            ]
        ),
        .executableTarget(
            name: "Server",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Storage"),
                .target(name: "Utilities"),

                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "HummingbirdWebSocket", package: "hummingbird-websocket"),
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "OTLPGRPC", package: "swift-otel"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
            ]
        ),
        .target(
            name: "Storage",
            dependencies: [
                .target(name: "Models"),
                .target(name: "Utilities"),

                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "TracingOpenTelemetrySemanticConventions", package: "swift-distributed-tracing-extras"),
            ]
        ),
        .target(
            name: "Utilities"
        )
    ]

)
