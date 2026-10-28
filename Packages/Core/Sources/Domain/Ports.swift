public protocol TrailRepository: Sendable {
    func trails() async throws -> [Trail]
}

public protocol FavoritesStore: Sendable {
    func load() async throws -> Set<Trail.ID>
    func save(_ favorites: Set<Trail.ID>) async throws
}
