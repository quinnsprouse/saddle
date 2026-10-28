import Foundation

public struct TrailIndex: Sendable {
    private struct Entry: Sendable {
        let trail: Trail
        let name: String
        let region: String
    }

    private static let cancellationStride = 1_024

    private let entries: [Entry]

    public var trails: [Trail] {
        entries.map(\.trail)
    }

    public init(trails: [Trail]) {
        entries = trails.map { trail in
            Entry(trail: trail, name: Self.normalize(trail.name), region: Self.normalize(trail.region))
        }
    }

    public func search(_ query: String) throws(CancellationError) -> [Trail] {
        let needle = Self.normalize(query.trimmingCharacters(in: .whitespacesAndNewlines))
        guard !needle.isEmpty else {
            return trails
        }
        var prefixMatches: [Trail] = []
        var otherMatches: [Trail] = []
        for (offset, entry) in entries.enumerated() {
            if offset.isMultiple(of: Self.cancellationStride), Task.isCancelled {
                throw CancellationError()
            }
            if entry.name.hasPrefix(needle) {
                prefixMatches.append(entry.trail)
            } else if entry.name.contains(needle) || entry.region.contains(needle) {
                otherMatches.append(entry.trail)
            }
        }
        return prefixMatches + otherMatches
    }

    private static func normalize(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }
}
