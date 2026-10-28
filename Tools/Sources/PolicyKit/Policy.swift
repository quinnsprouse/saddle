import SwiftParser
import SwiftSyntax

public enum Policy {
    public static func check(source: String, path: String, configuration: Configuration) -> [Violation] {
        let tree = Parser.parse(source: source)
        let converter = SourceLocationConverter(fileName: path, tree: tree)
        let visitor = PolicyVisitor()
        visitor.walk(tree)
        let isManifest = path == "Package.swift" || path.hasSuffix("/Package.swift")
        let findings = CommentScanner.findings(in: tree, isManifest: isManifest) + visitor.findings
        return
            findings
            .filter { !configuration.allows($0.rule, at: path) }
            .map { finding in
                let location = converter.location(for: finding.position)
                return Violation(path: path, line: location.line, column: location.column, rule: finding.rule)
            }
            .sorted { ($0.line, $0.column) < ($1.line, $1.column) }
    }
}

struct Finding {
    let position: AbsolutePosition
    let rule: Rule
}
