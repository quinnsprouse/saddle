import ProjectDescription
import ProjectDescriptionHelpers

let destinations: Destinations = [.iPhone, .iPad]
let deploymentTargets: DeploymentTargets = .iOS(Identity.deploymentTarget)

let app: Target = .target(
    name: Identity.name,
    destinations: destinations,
    product: .app,
    bundleId: Identity.bundleID,
    deploymentTargets: deploymentTargets,
    infoPlist: .extendingDefault(with: [
        "CFBundleDisplayName": .string(Identity.name),
        "UILaunchScreen": .dictionary([:]),
        "ITSAppUsesNonExemptEncryption": .boolean(false),
    ]),
    sources: ["App/Sources/**"],
    resources: ["App/Resources/**"],
    dependencies: [
        .package(product: "Domain"),
        .package(product: "Services"),
        .package(product: "LibraryFeature"),
    ]
)

func testTarget(_ name: String) -> Target {
    .target(
        name: name,
        destinations: destinations,
        product: .uiTests,
        bundleId: "\(Identity.bundleID).\(name.lowercased())",
        deploymentTargets: deploymentTargets,
        sources: ["App/\(name)/**", "App/TestSupport/**"],
        dependencies: [.target(name: Identity.name)],
        settings: .settings(base: BuildSettings.testing)
    )
}

let project = Project(
    name: Identity.name,
    options: .options(automaticSchemesOptions: .disabled),
    packages: [
        .package(path: "Packages/Core"),
        .package(path: "Packages/UI"),
    ],
    settings: BuildSettings.project,
    targets: [app, testTarget("UITests"), testTarget("PerformanceTests")],
    schemes: [
        .scheme(
            name: Identity.name,
            buildAction: .buildAction(targets: [.target(Identity.name)]),
            testAction: .targets(
                [
                    .testableTarget(target: .target("UITests")),
                    .testableTarget(target: .target("PerformanceTests"), isSkipped: true),
                ],
                configuration: .debug
            ),
            runAction: .runAction(configuration: .debug, executable: .target(Identity.name))
        ),
        .scheme(
            name: "Performance",
            buildAction: .buildAction(targets: [.target(Identity.name)]),
            testAction: .targets(
                [.testableTarget(target: .target("PerformanceTests"))],
                configuration: .release
            )
        ),
    ],
    resourceSynthesizers: []
)
