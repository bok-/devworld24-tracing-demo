// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Core",

    // MARK: - Platforms

    platforms: [
        .iOS(.v17),
    ],

    // MARK: - Products

    products: [
        .library(name: "Core", targets: [ "Core" ]),
    ],

    // MARK: - Dependencies

    dependencies: [
        .package(name: "Server", path: "../../Server"),

        .package(url: "https://github.com/hummingbird-project/hummingbird-websocket.git", from: "2.0.0-beta.1"),
        .package(url: "https://github.com/apple/swift-distributed-tracing.git", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-distributed-tracing-extras.git", from: "1.0.0-beta.1"),
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.27.0"),
        .package(url: "https://github.com/bok-/swift-otel.git", branch: "main"),
        .package(url: "https://github.com/swift-server/async-http-client.git", from: "1.21.1"),
    ],

    // MARK: - Targets

    targets: [
        .target(
            name: "Core",
            dependencies: [
                .target(name: "Cache"),
                .target(name: "Client"),

                .product(name: "OTel", package: "swift-otel"),
                .product(name: "OTLPGRPC", package: "swift-otel"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
            ]
        ),
        .target(
            name: "Client",
            dependencies: [
                .target(name: "Cache"),

                .product(name: "Models", package: "Server"),

                .product(name: "AsyncHTTPClient", package: "async-http-client"),
                .product(name: "HummingbirdWSClient", package: "hummingbird-websocket"),
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "TracingOpenTelemetrySemanticConventions", package: "swift-distributed-tracing-extras"),
            ]
        ),
        .target(
            name: "Cache",
            dependencies: [
                .product(name: "Models", package: "Server"),

                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "OTel", package: "swift-otel"),
                .product(name: "Tracing", package: "swift-distributed-tracing"),
                .product(name: "TracingOpenTelemetrySemanticConventions", package: "swift-distributed-tracing-extras"),
            ]
        ),
    ]

)
