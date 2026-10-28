import os

nonisolated enum LibrarySignposts {
    static let subsystem = "LibraryFeature"
    static let category = "Library"
    static let search: StaticString = "search"

    static let signposter = OSSignposter(subsystem: subsystem, category: category)
}
