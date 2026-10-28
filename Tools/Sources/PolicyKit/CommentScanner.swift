import SwiftSyntax

enum CommentScanner {
    private struct Comment {
        let position: AbsolutePosition
        let text: String
        let isLine: Bool
    }

    private static let escapeMarkers = ["swiftlint:", "swift-format-ignore", "periphery:ignore"]
    private static let reasonWords = 6...30
    private static let manifestHeader = "// swift-tools-version:"

    static func findings(in tree: SourceFileSyntax, isManifest: Bool) -> [Finding] {
        var findings: [Finding] = []
        for var block in blocks(in: tree) {
            if isManifest, let header = block.first, header.position.utf8Offset == 0,
                header.text.hasPrefix(manifestHeader)
            {
                block.removeFirst()
            }
            guard let first = block.first else {
                continue
            }
            if block.contains(where: { comment in escapeMarkers.contains { comment.text.contains($0) } }) {
                findings.append(Finding(position: first.position, rule: .lintEscape))
            } else if !isReason(block) {
                findings.append(Finding(position: first.position, rule: .comment))
            }
        }
        return findings
    }

    private static func isReason(_ block: [Comment]) -> Bool {
        guard block.allSatisfy(\.isLine), let first = block.first, first.text.hasPrefix("// why: ") else {
            return false
        }
        let words = block.flatMap { $0.text.dropFirst(2).split(separator: " ") }.count - 1
        return reasonWords.contains(words)
    }

    private static func blocks(in tree: SourceFileSyntax) -> [[Comment]] {
        var grouper = BlockGrouper()
        for token in tree.tokens(viewMode: .sourceAccurate) {
            grouper.consume(token.leadingTrivia, from: token.position)
            grouper.breakBlock()
            grouper.consume(token.trailingTrivia, from: token.endPositionBeforeTrailingTrivia)
            grouper.breakBlock()
        }
        return grouper.finish()
    }

    private struct BlockGrouper {
        private var blocks: [[Comment]] = []
        private var current: [Comment] = []

        mutating func consume(_ trivia: Trivia, from start: AbsolutePosition) {
            var position = start
            for piece in trivia {
                add(piece, at: position)
                position = position.advanced(by: piece.sourceLength.utf8Length)
            }
        }

        mutating func breakBlock() {
            if !current.isEmpty {
                blocks.append(current)
                current = []
            }
        }

        mutating func finish() -> [[Comment]] {
            breakBlock()
            return blocks
        }

        private mutating func add(_ piece: TriviaPiece, at position: AbsolutePosition) {
            switch piece {
            case .lineComment(let text):
                current.append(Comment(position: position, text: text, isLine: true))
            case .blockComment(let text), .docLineComment(let text), .docBlockComment(let text):
                breakBlock()
                current = [Comment(position: position, text: text, isLine: false)]
                breakBlock()
            case .newlines(let count) where count > 1, .carriageReturnLineFeeds(let count) where count > 1:
                breakBlock()
            case .spaces, .tabs, .newlines, .carriageReturnLineFeeds:
                return
            default:
                breakBlock()
            }
        }
    }
}
