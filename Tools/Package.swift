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
    name: "Tools",
    platforms: [.macOS("26.0")],
    products: [.executable(name: "policy", targets: ["policy"])],
    dependencies: [.package(url: "https://github.com/swiftlang/swift-syntax.git", exact: "604.0.0")],
    targets: [
        .target(
            name: "PolicyKit",
            dependencies: [
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
            ],
            swiftSettings: strict
        ),
        .executableTarget(name: "policy", dependencies: ["PolicyKit"], swiftSettings: strict),
        .testTarget(name: "PolicyKitTests", dependencies: ["PolicyKit"], swiftSettings: strict),
    ]
)
