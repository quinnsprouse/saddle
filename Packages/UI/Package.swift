// swift-tools-version: 6.2

import PackageDescription

let strict: [SwiftSetting] = [
    .treatAllWarnings(as: .error),
    .strictMemorySafety(),
    .defaultIsolation(MainActor.self),
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
    name: "UI",
    defaultLocalization: "en",
    platforms: [.iOS("26.0")],
    products: [
        .library(name: "DesignSystem", targets: ["DesignSystem"]),
        .library(name: "LibraryFeature", targets: ["LibraryFeature"]),
    ],
    dependencies: [.package(path: "../Core")],
    targets: [
        .target(name: "DesignSystem", swiftSettings: strict),
        .target(
            name: "LibraryFeature",
            dependencies: ["DesignSystem", .product(name: "Domain", package: "Core")],
            resources: [.process("Resources")],
            swiftSettings: strict
        ),
    ]
)
