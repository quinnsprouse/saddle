import Domain
import Services
import Testing

struct GeneratedTrailRepositoryTests {
    @Test func theRepositoryServesTheSeededCatalog() async {
        let trails = await GeneratedTrailRepository(count: 300, seed: 11).trails()
        #expect(trails == TrailCatalog.generate(count: 300, seed: 11))
    }
}
