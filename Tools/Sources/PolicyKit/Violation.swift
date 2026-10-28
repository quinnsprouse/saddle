public struct Violation: Hashable, Sendable, CustomStringConvertible {
    public let path: String
    public let line: Int
    public let column: Int
    public let rule: Rule

    public var description: String {
        "\(path):\(line):\(column): error: \(rule.message) [\(rule.rawValue)]"
    }
}
