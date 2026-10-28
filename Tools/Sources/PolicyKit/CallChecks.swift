import SwiftSyntax

enum CallChecks {
    private static let printFunctions: Set = ["print", "debugPrint", "dump", "NSLog"]
    private static let sleepFunctions: Set = ["sleep", "usleep", "nanosleep"]
    private static let colorTypes: Set = ["Color", "UIColor"]
    private static let rawColorLabels: Set = ["red", "hue", "white", "displayP3Red"]
    private static let fontTypes: Set = ["Font", "UIFont"]
    private static let fontFactories: Set = [
        "system", "custom", "systemFont", "boldSystemFont", "italicSystemFont", "monospacedSystemFont",
    ]
    private static let fontSizeLabels: Set = ["size", "ofSize", "fixedSize"]
    private static let blockingQueueCalls: Set = ["sync", "asyncAndWait"]
    private static let conditionTraits: Set = ["disabled", "enabled"]

    static func isConditionTrait(_ expression: ExprSyntax) -> Bool {
        guard let call = expression.as(FunctionCallExprSyntax.self),
            let member = call.calledExpression.as(MemberAccessExprSyntax.self)
        else {
            return false
        }
        return conditionTraits.contains(member.declName.baseName.text)
    }

    static func calleeName(_ expression: ExprSyntax) -> String? {
        if let generic = expression.as(GenericSpecializationExprSyntax.self) {
            return calleeName(generic.expression)
        }
        return expression.as(DeclReferenceExprSyntax.self)?.baseName.text
    }

    static func rule(forMember node: MemberAccessExprSyntax) -> Rule? {
        let base = node.base.flatMap(calleeName)
        switch (base, node.declName.baseName.text) {
        case ("Task", "detached"):
            return .detachedTask
        case ("Thread", "sleep"):
            return .blockingCall
        case ("Date", "now"), ("Bundle", "main"):
            return .worldAccess
        default:
            return nil
        }
    }

    static func rule(forCall node: FunctionCallExprSyntax) -> Rule? {
        let labels = Set(node.arguments.compactMap { $0.label?.text })
        if let callee = calleeName(node.calledExpression) {
            return rule(forFunction: callee, labels: labels, isEmpty: node.arguments.isEmpty)
        }
        guard let member = node.calledExpression.as(MemberAccessExprSyntax.self) else {
            return nil
        }
        let name = member.declName.baseName.text
        if fontFactories.contains(name), !labels.isDisjoint(with: fontSizeLabels) {
            return .designToken
        }
        if blockingQueueCalls.contains(name), node.trailingClosure != nil || labels.contains("execute") {
            return .blockingCall
        }
        if name == "onAppear", startsTask(node) {
            return .onAppearTask
        }
        return nil
    }

    private static func rule(forFunction callee: String, labels: Set<String>, isEmpty: Bool) -> Rule? {
        if printFunctions.contains(callee) {
            return .print
        }
        if sleepFunctions.contains(callee) {
            return .blockingCall
        }
        if callee == "Date", isEmpty {
            return .worldAccess
        }
        if colorTypes.contains(callee), !labels.isDisjoint(with: rawColorLabels) {
            return .designToken
        }
        if fontTypes.contains(callee), !labels.isDisjoint(with: fontSizeLabels) {
            return .designToken
        }
        return nil
    }

    private static func startsTask(_ node: FunctionCallExprSyntax) -> Bool {
        let closures =
            [node.trailingClosure].compactMap(\.self)
            + node.additionalTrailingClosures.map(\.closure)
            + node.arguments.compactMap { $0.expression.as(ClosureExprSyntax.self) }
        return closures.contains { closure in
            let finder = TaskCallFinder()
            finder.walk(closure)
            return finder.found
        }
    }
}

private final class TaskCallFinder: SyntaxVisitor {
    private(set) var found = false

    init() {
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if CallChecks.calleeName(node.calledExpression) == "Task" {
            found = true
            return .skipChildren
        }
        return .visitChildren
    }
}
