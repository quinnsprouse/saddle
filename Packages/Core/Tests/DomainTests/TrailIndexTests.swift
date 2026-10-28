import Domain
import Testing

struct TrailIndexTests {
    private static let trails = [
        trail(1, "Copper Ridge Loop", region: "Sierra"),
        trail(2, "Lone Copper Pass", region: "Cascades"),
        trail(3, "Sage Creek Trail", region: "Copper Basin"),
        trail(4, "Mesa Rim Spur", region: "Wasatch"),
    ]

    private static func trail(_ id: Int, _ name: String, region: String) -> Trail {
        Trail(
            id: id,
            name: name,
            region: region,
            difficulty: .easy,
            stats: TrailStats(distanceKilometers: 5, elevationGainMeters: 100)
        )
    }

    @Test func anEmptyQueryReturnsEveryTrailInOrder() throws {
        let index = TrailIndex(trails: Self.trails)
        #expect(try index.search("   ") == Self.trails)
    }

    @Test func prefixMatchesRankBeforeOtherMatches() throws {
        let index = TrailIndex(trails: Self.trails)
        #expect(try index.search("copper").map(\.id) == [1, 2, 3])
    }

    @Test func searchIgnoresCaseAndDiacritics() throws {
        let index = TrailIndex(trails: [Self.trail(9, "Pásó Ñandú Draw", region: "Mogollon")])
        #expect(try index.search("paso nandu").map(\.id) == [9])
    }

    @Test func aQueryWithNoMatchesReturnsNothing() throws {
        let index = TrailIndex(trails: Self.trails)
        #expect(try index.search("glacier").isEmpty)
    }

    @Test func aCancelledSearchThrowsInsteadOfFinishing() async {
        let index = TrailIndex(trails: TrailCatalog.generate(count: 50_000))
        let task = Task {
            while !Task.isCancelled {
                await Task.yield()
            }
            return try index.search("ridge")
        }
        task.cancel()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}
