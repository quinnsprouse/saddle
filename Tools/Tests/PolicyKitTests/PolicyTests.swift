import Foundation
import PolicyKit
import Testing

struct PolicyTests {
    struct Case: CustomTestStringConvertible, Sendable {
        let source: String
        let rule: Rule?
        var path = "Packages/UI/Sources/LibraryFeature/Example.swift"

        var testDescription: String {
            source
        }
    }

    private static let configuration = Configuration(allow: [
        .init(
            rule: .worldAccess,
            paths: ["Packages/Core/Sources/Services/"],
            why: "Services own the outside world for every other module."
        ),
        .init(
            rule: .unitTest,
            paths: ["App/UITests/"],
            why: "Journeys drive the running app through its interface end to end."
        ),
        .init(
            rule: .designToken,
            paths: ["Packages/UI/Sources/DesignSystem/"],
            why: "The design system defines the literal values that screens reference by name."
        ),
    ])

    static let rejected: [Case] = [
        Case(source: "// explains the obvious\nlet value = 1\n", rule: .comment),
        Case(source: "/// Documents the value.\nlet value = 1\n", rule: .comment),
        Case(source: "/* block */\nlet value = 1\n", rule: .comment),
        Case(source: "let value = 1 // trailing note\n", rule: .comment),
        Case(source: "// why: too short\nlet value = 1\n", rule: .comment),
        Case(source: "// swiftlint:disable:next force_unwrapping\nlet value = optional!\n", rule: .lintEscape),
        Case(source: "// swift-format-ignore\nlet value = 1\n", rule: .lintEscape),
        Case(source: "@testable import Domain\n", rule: .testableImport),
        Case(source: "import Testing\n", rule: .unitTest),
        Case(source: "import XCTest\n", rule: .unitTest),
        Case(source: "@diagnose(DeprecatedDeclaration, as: ignored) func legacy() {}\n", rule: .lintEscape),
        Case(source: "let width = UIScreen.main.bounds.width\n", rule: .deviceAssumption),
        Case(source: "let isPad = UIDevice.current.userInterfaceIdiom == .pad\n", rule: .deviceAssumption),
        Case(source: "let rotated = UIDevice.current.orientation.isLandscape\n", rule: .deviceAssumption),
        Case(source: "@Test(.disabled(\"flaky\")) func works() {}\n", rule: .skippedTest),
        Case(source: "func works() throws { throw XCTSkip(\"later\") }\n", rule: .skippedTest),
        Case(source: "let session = URLSession.shared\n", rule: .worldAccess),
        Case(source: "let defaults = UserDefaults.standard\n", rule: .worldAccess),
        Case(source: "let stamp = Date()\n", rule: .worldAccess),
        Case(source: "let stamp = Date.now\n", rule: .worldAccess),
        Case(source: "let bundle = Bundle.main\n", rule: .worldAccess),
        Case(source: "func wait() { Thread.sleep(forTimeInterval: 1) }\n", rule: .blockingCall),
        Case(source: "let gate = DispatchSemaphore(value: 0)\n", rule: .blockingCall),
        Case(source: "final class Box: @unchecked Sendable {}\n", rule: .concurrencyEscape),
        Case(source: "nonisolated(unsafe) var shared = 0\n", rule: .concurrencyEscape),
        Case(source: "@preconcurrency import Combine\n", rule: .concurrencyEscape),
        Case(source: "func run() { Task.detached { await work() } }\n", rule: .detachedTask),
        Case(source: "final class Model: ObservableObject {}\n", rule: .legacyObservation),
        Case(source: "struct Screen { @StateObject var model = Model() }\n", rule: .legacyObservation),
        Case(source: "let erased = AnyView(content)\n", rule: .typeErasedView),
        Case(source: "let tint = Color(red: 1, green: 0, blue: 0)\n", rule: .designToken),
        Case(source: "let font = Font.system(size: 13)\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").font(.system(size: 13))\n", rule: .designToken),
        Case(source: "func log() { print(\"x\") }\n", rule: .print),
        Case(
            source: "// swift-tools-version: 6.2\n// extra\nimport PackageDescription\n", rule: .comment,
            path: "Package.swift"),
        Case(source: "@Test(.enabled(if: false)) func works() {}\n", rule: .skippedTest),
        Case(source: "let font = UIFont(name: \"Avenir\", size: 13)\n", rule: .designToken),
        Case(source: "let font = Font.custom(\"Avenir\", fixedSize: 13)\n", rule: .designToken),
        Case(source: "let font = UIFont.boldSystemFont(ofSize: 17)\n", rule: .designToken),
        Case(source: "func read() { queue.sync { work() } }\n", rule: .blockingCall),
        Case(source: "func run() { Task<Void, Never>.detached { await work() } }\n", rule: .detachedTask),
        Case(source: "let view = Text(\"x\").onAppear { Task { await load() } }\n", rule: .onAppearTask),
        Case(source: "let view = Text(\"x\").padding(16)\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").padding(.horizontal, 12)\n", rule: .designToken),
        Case(source: "let stack = VStack(spacing: 8) { content }\n", rule: .designToken),
        Case(source: "let grid = Grid(horizontalSpacing: -4) { content }\n", rule: .designToken),
        Case(source: "let shape = RoundedRectangle(cornerRadius: 12)\n", rule: .designToken),
        Case(source: "let shape = UnevenRoundedRectangle(topLeadingRadius: 12.5)\n", rule: .designToken),
        Case(source: "let edge = shape.stroke(.primary, lineWidth: 2)\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").shadow(radius: 4)\n", rule: .designToken),
        Case(source: "let motion = Animation.easeInOut(duration: 0.3)\n", rule: .designToken),
        Case(source: "let motion = Animation.spring(duration: 0.4, bounce: 0.2)\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").animation(.snappy(duration: 0.2), value: on)\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").foregroundStyle(.yellow)\n", rule: .designToken),
        Case(source: "let tint = Color.blue.opacity(0.5)\n", rule: .designToken),
        Case(source: "let scrim = Color.black\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").tracking(1.5)\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").lineSpacing(4)\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").foregroundStyle(.blue.opacity(0.5))\n", rule: .designToken),
        Case(source: "let view = Text(\"x\").foregroundStyle(.blue.gradient)\n", rule: .designToken),
        Case(source: "let motion = Animation.default.delay(0.2)\n", rule: .designToken),
    ]

    static let accepted: [Case] = [
        Case(source: "let value = 1\n", rule: nil),
        Case(
            source: "// why: SwiftUI drops the first update on iOS 26, so the model\n"
                + "// publishes twice until Apple fixes FB00000.\nlet value = 1\n",
            rule: nil
        ),
        Case(source: "// swift-tools-version: 6.2\n\nimport PackageDescription\n", rule: nil, path: "Package.swift"),
        Case(source: "let session = URLSession.shared\n", rule: nil, path: "Packages/Core/Sources/Services/Live.swift"),
        Case(source: "let string = \"// not a comment\"\n", rule: nil),
        Case(source: "let stamp = Date(timeIntervalSince1970: 0)\n", rule: nil),
        Case(source: "let tint = Color.accentColor.opacity(0.5)\n", rule: nil),
        Case(source: "let font = Font.body.weight(.semibold)\n", rule: nil),
        Case(source: "let view = Text(\"x\").task { await load() }\n", rule: nil),
        Case(source: "let view = Text(\"x\").onAppear { counter += 1 }\n", rule: nil),
        Case(source: "@Test func works() {}\n", rule: nil),
        Case(source: "func run() async { await withTaskGroup(of: Void.self) { _ in } }\n", rule: nil),
        Case(source: "let value = model.print\n", rule: nil),
        Case(source: "@Test(arguments: [Mode.enabled, .disabled]) func works(mode: Mode) {}\n", rule: nil),
        Case(source: "let view = Text(\"x\").onAppear { label = \"Task\" }\n", rule: nil),
        Case(source: "let view = Text(\"x\").onAppear { guard !Task.isCancelled else { return } }\n", rule: nil),
        Case(source: "func refresh() async { await store.sync() }\n", rule: nil),
        Case(source: "import Testing\n", rule: nil, path: "App/UITests/LibraryJourneyTests.swift"),
        Case(source: "let screen = window?.windowScene?.screen\n", rule: nil),
        Case(source: "let angle = image.orientation\n", rule: nil),
        Case(source: "let view = Text(\"x\").padding(Spacing.small)\n", rule: nil),
        Case(source: "let view = Text(\"x\").padding()\n", rule: nil),
        Case(source: "let stack = VStack(spacing: 0) { content }\n", rule: nil),
        Case(source: "let view = Text(\"x\").frame(width: 44, height: 44)\n", rule: nil),
        Case(source: "let view = Text(\"x\").foregroundStyle(.secondary)\n", rule: nil),
        Case(source: "let view = Text(\"x\").fontWeight(.black)\n", rule: nil),
        Case(source: "let signal = Signal.red\n", rule: nil),
        Case(source: "let delay = ContinuousClock().sleep(for: .seconds(1))\n", rule: nil),
        Case(source: "let view = Text(\"x\").animation(Motion.small, value: on)\n", rule: nil),
        Case(
            source: "let shape = RoundedRectangle(cornerRadius: 12)\n",
            rule: nil,
            path: "Packages/UI/Sources/DesignSystem/Card.swift"
        ),
    ]

    @Test(arguments: rejected)
    func rejectsTheViolation(_ example: Case) {
        let violations = Policy.check(source: example.source, path: example.path, configuration: Self.configuration)
        #expect(violations.map(\.rule) == [example.rule].compactMap(\.self))
    }

    @Test(arguments: accepted)
    func acceptsTheSource(_ example: Case) {
        let violations = Policy.check(source: example.source, path: example.path, configuration: Self.configuration)
        #expect(violations.isEmpty, "\(violations)")
    }

    @Test func violationsPointAtTheOffendingLine() throws {
        let violations = Policy.check(
            source: "let value = 1\nlet stamp = Date()\n",
            path: "Example.swift",
            configuration: Self.configuration
        )
        let violation = try #require(violations.first)
        #expect((violation.line, violation.column) == (2, 13))
        #expect(violation.description.hasPrefix("Example.swift:2:13: error: "))
    }

    @Test func styleViolationsPointAtTheLiteral() throws {
        let violations = Policy.check(
            source: "let view = Text(\"x\")\n    .bold()\n    .padding(.vertical, 6)\n",
            path: "Example.swift",
            configuration: Self.configuration
        )
        let violation = try #require(violations.first)
        #expect((violation.line, violation.column) == (3, 25))
        let labeled = Policy.check(
            source: "let stack = HStack(spacing: 8) {}\n", path: "Example.swift", configuration: Self.configuration)
        #expect(labeled.map(\.column) == [29])
    }

    @Test func anAllowanceNeedsAReason() throws {
        let url = URL.temporaryDirectory.appending(path: "policy-\(UInt64.random(in: 0...UInt64.max)).json")
        try Data(#"{"allow":[{"rule":"print","paths":["Tools/"],"why":"needed"}]}"#.utf8).write(to: url)
        #expect(throws: Configuration.Problem.self) {
            try Configuration.load(from: url)
        }
    }
}
