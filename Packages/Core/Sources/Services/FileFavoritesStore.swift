public import Domain
public import Foundation

public actor FileFavoritesStore: FavoritesStore {
    private let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func load() throws -> Set<Trail.ID> {
        guard FileManager.default.fileExists(atPath: url.path(percentEncoded: false)) else {
            return []
        }
        let data = try Data(contentsOf: url)
        return Set(try JSONDecoder().decode([Trail.ID].self, from: data))
    }

    public func save(_ favorites: Set<Trail.ID>) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let data = try JSONEncoder().encode(favorites.sorted())
        try data.write(to: url, options: [.atomic])
    }
}
