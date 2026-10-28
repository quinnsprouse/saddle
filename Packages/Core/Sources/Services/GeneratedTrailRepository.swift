public import Domain

public actor GeneratedTrailRepository: TrailRepository {
    private let count: Int
    private let seed: UInt64

    public init(count: Int, seed: UInt64 = TrailCatalog.defaultSeed) {
        self.count = count
        self.seed = seed
    }

    public func trails() -> [Trail] {
        TrailCatalog.generate(count: count, seed: seed)
    }
}
