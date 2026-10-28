import Domain
import Foundation
import LibraryFeature
import Services

enum Composition {
    private static let trailCount = 10_000

    static func libraryModel() -> LibraryModel {
        let directory = StorageLocation.directory(environment: ProcessInfo.processInfo.environment)
        return LibraryModel(
            repository: GeneratedTrailRepository(count: trailCount),
            favoritesStore: FileFavoritesStore(url: directory.appending(path: "favorites.json"))
        )
    }
}
