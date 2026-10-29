import SwiftSyntax

enum StyleChecks {
    private static let tokenLabels: Set = [
        "spacing", "horizontalSpacing", "verticalSpacing", "minLength", "lineWidth", "radius", "cornerRadius",
        "topLeadingRadius", "topTrailingRadius", "bottomLeadingRadius", "bottomTrailingRadius",
    ]
    private static let positionalTokenMembers: Set = [
        "padding", "cornerRadius", "lineSpacing", "tracking", "kerning", "delay",
    ]
    private static let animationFactories: Set = [
        "easeIn", "easeOut", "easeInOut", "linear", "spring", "smooth", "snappy", "bouncy", "interpolatingSpring",
        "timingCurve",
    ]
    private static let timingLabels: Set = ["duration", "response", "bounce", "extraBounce", "dampingFraction"]
    private static let hues: Set = [
        "red", "orange", "yellow", "green", "mint", "teal", "cyan", "blue", "indigo", "purple", "pink", "brown", "gray",
    ]
    private static let explicitOnlyHues: Set = ["black", "white"]

    static func literalArgument(in node: FunctionCallExprSyntax) -> LabeledExprSyntax? {
        let member = node.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text ?? ""
        return node.arguments.first { argument in
            guard isNonZeroNumber(argument.expression) else {
                return false
            }
            guard let label = argument.label?.text else {
                return positionalTokenMembers.contains(member)
            }
            return tokenLabels.contains(label) || animationFactories.contains(member) && timingLabels.contains(label)
        }
    }

    static func rule(forMember node: MemberAccessExprSyntax) -> Rule? {
        let name = node.declName.baseName.text
        if let base = node.base {
            let isColor = CallChecks.calleeName(base) == "Color"
            return isColor && (hues.contains(name) || explicitOnlyHues.contains(name)) ? .designToken : nil
        }
        return hues.contains(name) && isArgument(node) ? .designToken : nil
    }

    private static func isArgument(_ node: MemberAccessExprSyntax) -> Bool {
        var current = Syntax(node)
        while let parent = current.parent,
            parent.is(MemberAccessExprSyntax.self) || parent.is(FunctionCallExprSyntax.self)
        {
            current = parent
        }
        return current.parent?.is(LabeledExprSyntax.self) == true
    }

    private static func isNonZeroNumber(_ expression: ExprSyntax) -> Bool {
        let value = expression.as(PrefixOperatorExprSyntax.self)?.expression ?? expression
        if let integer = value.as(IntegerLiteralExprSyntax.self) {
            return Int(integer.literal.text.filter { $0 != "_" }) != 0
        }
        if let float = value.as(FloatLiteralExprSyntax.self) {
            return Double(float.literal.text.filter { $0 != "_" }) != 0
        }
        return false
    }
}
