// swift-tools-version: 6.2

import PackageDescription

let strict: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .strictMemorySafety(),
    .enableUpcomingFeature("ExistentialAny"),
    .enableUpcomingFeature("InternalImportsByDefault"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
    .enableUpcomingFeature("InferIsolatedConformances"),
    .unsafeFlags([
        "-Xfrontend", "-warn-long-function-bodies=150",
        "-Xfrontend", "-warn-long-expression-type-checking=150",
    ]),
]

let package = Package(
    name: "Core",
    platforms: [.iOS("26.0"), .macOS("26.0")],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Services", targets: ["Services"]),
    ],
    targets: [
        .target(name: "Domain", swiftSettings: strict),
        .target(name: "Services", dependencies: ["Domain"], swiftSettings: strict),
        .testTarget(name: "DomainTests", dependencies: ["Domain"], swiftSettings: strict),
        .testTarget(name: "ServicesTests", dependencies: ["Domain", "Services"], swiftSettings: strict),
    ]
)
