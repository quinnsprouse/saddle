import Domain
import Foundation
import Services
import Testing

struct FileFavoritesStoreTests {
    private let directory = FileManager.default.temporaryDirectory
        .appending(path: UUID().uuidString, directoryHint: .isDirectory)

    @Test func aMissingFileLoadsAsNoFavorites() async throws {
        let store = FileFavoritesStore(url: directory.appending(path: "favorites.json"))
        #expect(try await store.load().isEmpty)
    }

    @Test func savedFavoritesLoadInANewStore() async throws {
        let url = directory.appending(path: "nested/favorites.json")
        try await FileFavoritesStore(url: url).save([3, 1, 2])
        #expect(try await FileFavoritesStore(url: url).load() == [1, 2, 3])
    }

    @Test func aCorruptFileFailsToLoad() async throws {
        let url = directory.appending(path: "favorites.json")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: url)
        await #expect(throws: DecodingError.self) {
            try await FileFavoritesStore(url: url).load()
        }
    }
}
