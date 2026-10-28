import Domain
import Testing

struct TrailCatalogTests {
    @Test func theSameSeedProducesTheSameCatalog() {
        let first = TrailCatalog.generate(count: 200, seed: 7)
        let second = TrailCatalog.generate(count: 200, seed: 7)
        #expect(first == second)
    }

    @Test func differentSeedsProduceDifferentCatalogs() {
        #expect(TrailCatalog.generate(count: 200, seed: 7) != TrailCatalog.generate(count: 200, seed: 8))
    }

    @Test func everyTrailHasAUniqueIdentifierAndPlausibleStats() {
        let trails = TrailCatalog.generate(count: 5_000)
        #expect(Set(trails.map(\.id)).count == trails.count)
        #expect(trails.allSatisfy { $0.stats.distanceKilometers > 0 && $0.stats.elevationGainMeters > 0 })
        #expect(Set(trails.map(\.difficulty)) == Set(Difficulty.allCases))
    }
}
