public enum Rule: String, CaseIterable, Sendable, Decodable {
    case comment
    case lintEscape = "lint-escape"
    case skippedTest = "skipped-test"
    case testableImport = "testable-import"
    case unitTest = "unit-test"
    case worldAccess = "world-access"
    case blockingCall = "blocking-call"
    case concurrencyEscape = "concurrency-escape"
    case detachedTask = "detached-task"
    case legacyObservation = "legacy-observation"
    case typeErasedView = "type-erased-view"
    case designToken = "design-token"
    case print
    case onAppearTask = "on-appear-task"
    case deviceAssumption = "device-assumption"

    public var message: String {
        switch self {
        case .comment:
            "Comments are banned. Say it in code with a clearer name, a smaller function, or a type. For a constraint "
                + "outside the code that you cannot fix, write `// why: <cause>` in 6 to 30 words."
        case .lintEscape:
            "Inline lint, format, and diagnostic escapes, including @diagnose, are banned. Fix the cause. If a rule "
                + "is wrong for a directory, prove it with a minimal example and add an allowance with a why to "
                + "policy.json."
        case .skippedTest:
            "Skipped and known-issue tests are banned. Fix the behavior or delete the test."
        case .testableImport:
            "Tests use the public API only. Remove @testable and test through the module's public types."
        case .unitTest:
            "App code has no unit tests. Verify the behavior end to end with an XCUITest journey in App/UITests/."
        case .worldAccess:
            "Reach files, defaults, the network, clocks, the environment, and queues through a Domain port that "
                + "Services implements, and inject it from the App composition root."
        case .blockingCall:
            "Blocking calls stall a thread. Use Task.sleep(for:), an actor, or an AsyncStream instead of sleeps "
                + "and semaphores."
        case .concurrencyEscape:
            "@unchecked Sendable, nonisolated(unsafe), unowned(unsafe), and @preconcurrency switch off the compiler's "
                + "checks. Make the type Sendable, isolate it to an actor, or pass values instead."
        case .detachedTask:
            "Task.detached drops priority and task locals and escapes structured concurrency. Use a @concurrent "
                + "async function or a task group."
        case .legacyObservation:
            "Use Observation: @Observable models with @State, @Bindable, and @Environment. ObservableObject "
                + "invalidates every view that reads any of its properties."
        case .typeErasedView:
            "AnyView hides view identity from SwiftUI and defeats diffing. Use @ViewBuilder, generics, or a switch "
                + "over concrete views."
        case .designToken:
            "Colors, font sizes, spacing, radii, strokes, and animation timings belong in DesignSystem. Use a "
                + "token from GUI.md, a semantic style, or a Dynamic Type text style."
        case .print:
            "Use os.Logger with a privacy level instead of print, so logs reach Console and sysdiagnoses."
        case .onAppearTask:
            "Use .task { } instead of starting a Task in .onAppear. SwiftUI cancels .task work when the view "
                + "disappears."
        case .deviceAssumption:
            "Lay out from size classes and the space SwiftUI provides. iPhone Duo has two displays, so UIScreen.main, "
                + "device orientation, and idiom checks describe the wrong one."
        }
    }
}
