public import Domain
import Foundation
public import Observation
import os

@Observable
public final class LibraryModel {
    public enum Phase: Equatable {
        case loading
        case ready
        case failed
    }

    public private(set) var phase = Phase.loading
    public private(set) var results: [Trail] = []
    public private(set) var favorites: Set<Trail.ID> = []
    public private(set) var saveFailed = false
    public var query = ""

    @ObservationIgnored private var index = TrailIndex(trails: [])
    @ObservationIgnored private var saveTask: Task<Void, Never>?
    @ObservationIgnored private let repository: any TrailRepository
    @ObservationIgnored private let favoritesStore: any FavoritesStore
    @ObservationIgnored private let logger = Logger(subsystem: LibrarySignposts.subsystem, category: "LibraryModel")

    public init(repository: any TrailRepository, favoritesStore: any FavoritesStore) {
        self.repository = repository
        self.favoritesStore = favoritesStore
    }

    public func load() async {
        guard phase != .ready else {
            return
        }
        do {
            async let saved = favoritesStore.load()
            index = await Self.buildIndex(try await repository.trails())
            favorites = try await saved
            phase = .ready
            await search()
        } catch {
            logger.error("Loading trails failed: \(error.localizedDescription, privacy: .public)")
            phase = .failed
        }
    }

    public func search() async {
        let query = query
        do {
            let found = try await Self.search(index, for: query)
            if query == self.query {
                results = found
            }
        } catch {
            return
        }
    }

    public func trail(withID id: Trail.ID?) -> Trail? {
        id.flatMap(index.trail(withID:))
    }

    public func isFavorite(_ trail: Trail) -> Bool {
        favorites.contains(trail.id)
    }

    public func toggleFavorite(_ trail: Trail) {
        if favorites.remove(trail.id) == nil {
            favorites.insert(trail.id)
        }
        let snapshot = favorites
        let previous = saveTask
        previous?.cancel()
        saveTask = Task { [favoritesStore, logger] in
            await previous?.value
            guard !Task.isCancelled else {
                return
            }
            do {
                try await favoritesStore.save(snapshot)
                saveFailed = false
            } catch {
                logger.error("Saving favorites failed: \(error.localizedDescription, privacy: .public)")
                saveFailed = true
            }
        }
    }

    @concurrent
    private static func buildIndex(_ trails: [Trail]) async -> TrailIndex {
        TrailIndex(trails: trails)
    }

    @concurrent
    private static func search(_ index: TrailIndex, for query: String) async throws(CancellationError) -> [Trail] {
        let signposter = LibrarySignposts.signposter
        let state = signposter.beginInterval(LibrarySignposts.search, id: signposter.makeSignpostID())
        defer { signposter.endInterval(LibrarySignposts.search, state) }
        return try index.search(query)
    }
}
