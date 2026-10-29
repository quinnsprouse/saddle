import SwiftSyntax

final class PolicyVisitor: SyntaxVisitor {
    private static let worldTypes: Set = [
        "URLSession", "FileManager", "UserDefaults", "ProcessInfo", "NotificationCenter", "DispatchQueue",
        "UIApplication",
    ]
    private static let blockingTypes: Set = ["DispatchSemaphore", "DispatchGroup"]
    private static let legacyObservation: Set = [
        "ObservableObject", "Published", "StateObject", "ObservedObject", "EnvironmentObject",
    ]
    private static let skippedTests: Set = ["XCTSkip", "XCTSkipIf", "XCTSkipUnless", "withKnownIssue"]

    private(set) var findings: [Finding] = []

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ImportDeclSyntax) -> SyntaxVisitorContinueKind {
        if let module = node.path.first?.name.text, ["Testing", "XCTest"].contains(module) {
            flag(node.path, .unitTest)
        }
        for attribute in node.attributes.compactMap({ $0.as(AttributeSyntax.self) }) {
            let name = attribute.attributeName.trimmedDescription
            if name == "testable" {
                flag(attribute, .testableImport)
            } else if name == "preconcurrency" {
                flag(attribute, .concurrencyEscape)
            }
        }
        return .visitChildren
    }

    override func visit(_ node: AttributeSyntax) -> SyntaxVisitorContinueKind {
        let name = node.attributeName.trimmedDescription
        if name == "unchecked" || name == "preconcurrency" && node.parent?.parent?.is(ImportDeclSyntax.self) != true {
            flag(node, .concurrencyEscape)
        }
        if name == "diagnose" {
            flag(node, .lintEscape)
        }
        if ["Test", "Suite"].contains(name), case .argumentList(let arguments) = node.arguments,
            arguments.contains(where: { $0.label == nil && CallChecks.isConditionTrait($0.expression) })
        {
            flag(node, .skippedTest)
        }
        return .visitChildren
    }

    override func visit(_ node: DeclModifierSyntax) -> SyntaxVisitorContinueKind {
        if ["nonisolated", "unowned"].contains(node.name.text), node.detail?.detail.text == "unsafe" {
            flag(node, .concurrencyEscape)
        }
        return .visitChildren
    }

    override func visit(_ node: IdentifierTypeSyntax) -> SyntaxVisitorContinueKind {
        checkName(node.name.text, at: node)
        return .visitChildren
    }

    override func visit(_ node: DeclReferenceExprSyntax) -> SyntaxVisitorContinueKind {
        if node.parent?.is(MemberAccessExprSyntax.self) != true
            || node.parent?.as(MemberAccessExprSyntax.self)?
                .base?.id == node.id
        {
            checkName(node.baseName.text, at: node)
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let rule = CallChecks.rule(forMember: node) ?? StyleChecks.rule(forMember: node) {
            flag(node, rule)
        }
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let rule = CallChecks.rule(forCall: node) {
            flag(node, rule)
        } else if let literal = StyleChecks.literalArgument(in: node) {
            flag(literal.expression, .designToken)
        }
        return .visitChildren
    }

    private func checkName(_ name: String, at node: some SyntaxProtocol) {
        if Self.worldTypes.contains(name) {
            flag(node, .worldAccess)
        } else if Self.blockingTypes.contains(name) {
            flag(node, .blockingCall)
        } else if Self.legacyObservation.contains(name) {
            flag(node, .legacyObservation)
        } else if name == "AnyView" {
            flag(node, .typeErasedView)
        } else if Self.skippedTests.contains(name) {
            flag(node, .skippedTest)
        }
    }

    private func flag(_ node: some SyntaxProtocol, _ rule: Rule) {
        findings.append(Finding(position: node.positionAfterSkippingLeadingTrivia, rule: rule))
    }
}
