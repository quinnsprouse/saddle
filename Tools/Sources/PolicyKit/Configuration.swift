public import Foundation

public struct Configuration: Decodable, Sendable {
    public struct Allowance: Decodable, Sendable {
        public let rule: Rule
        public let paths: [String]
        public let why: String

        public init(rule: Rule, paths: [String], why: String) {
            self.rule = rule
            self.paths = paths
            self.why = why
        }
    }

    public enum Problem: Error, CustomStringConvertible {
        case missingReason(Rule)
        case missingPaths(Rule)

        public var description: String {
            switch self {
            case .missingReason(let rule):
                "policy.json: the \(rule.rawValue) allowance needs a why of at least 6 words."
            case .missingPaths(let rule):
                "policy.json: the \(rule.rawValue) allowance lists no paths."
            }
        }
    }

    private static let minimumReasonWords = 6

    public let allow: [Allowance]

    public init(allow: [Allowance]) {
        self.allow = allow
    }

    public static func load(from url: URL) throws -> Self {
        let configuration = try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
        try configuration.validate()
        return configuration
    }

    public func allows(_ rule: Rule, at path: String) -> Bool {
        allow.contains { allowance in
            allowance.rule == rule && allowance.paths.contains { path == $0 || path.hasPrefix($0) && $0.hasSuffix("/") }
        }
    }

    private func validate() throws(Problem) {
        for allowance in allow {
            if allowance.paths.isEmpty {
                throw .missingPaths(allowance.rule)
            }
            if allowance.why.split(separator: " ").count < Self.minimumReasonWords {
                throw .missingReason(allowance.rule)
            }
        }
    }
}
