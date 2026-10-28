public struct Trail: Identifiable, Hashable, Sendable {
    public let id: Int
    public let name: String
    public let region: String
    public let difficulty: Difficulty
    public let stats: TrailStats

    public init(id: Int, name: String, region: String, difficulty: Difficulty, stats: TrailStats) {
        self.id = id
        self.name = name
        self.region = region
        self.difficulty = difficulty
        self.stats = stats
    }
}

public struct TrailStats: Hashable, Sendable {
    public let distanceKilometers: Double
    public let elevationGainMeters: Int

    public init(distanceKilometers: Double, elevationGainMeters: Int) {
        self.distanceKilometers = distanceKilometers
        self.elevationGainMeters = elevationGainMeters
    }
}

public enum Difficulty: String, CaseIterable, Sendable {
    case easy
    case moderate
    case hard
}
