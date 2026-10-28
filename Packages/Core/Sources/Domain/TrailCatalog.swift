public enum TrailCatalog {
    public static let defaultSeed: UInt64 = 0x5ADD_1E

    private static let adjectives = [
        "Copper", "Juniper", "Granite", "Sage", "Cinder", "Aspen", "Coyote", "Mesa", "Silver", "Thunder",
        "Lone", "Hollow", "Painted", "Quiet", "Red", "Saddle", "Timber", "Willow", "Dusty", "Falcon",
    ]
    private static let features = [
        "Ridge", "Canyon", "Creek", "Pass", "Basin", "Bluff", "Meadow", "Spring", "Butte", "Gulch",
        "Hollow", "Peak", "Draw", "Flats", "Notch", "Rim", "Narrows", "Divide", "Saddle", "Wash",
    ]
    private static let routes = ["Loop", "Trail", "Traverse", "Path", "Spur", "Climb"]
    private static let regions = [
        "Sierra", "Cascades", "Wasatch", "San Juans", "Big Horn", "Ozarks", "Smokies", "Mogollon", "Absaroka",
    ]

    public static func generate(count: Int, seed: UInt64 = defaultSeed) -> [Trail] {
        var generator = SplitMix64(seed: seed)
        return (0..<count).map { index in
            makeTrail(id: index, using: &generator)
        }
    }

    private static func makeTrail(id: Int, using generator: inout SplitMix64) -> Trail {
        let name = [adjectives, features, routes]
            .map { $0[Int.random(in: 0..<$0.count, using: &generator)] }
            .joined(separator: " ")
        let distance = Double(Int.random(in: 15...420, using: &generator)) / 10
        let elevation = Int.random(in: 20...1_800, using: &generator)
        return Trail(
            id: id,
            name: name,
            region: regions[Int.random(in: 0..<regions.count, using: &generator)],
            difficulty: difficulty(distance: distance, elevation: elevation),
            stats: TrailStats(distanceKilometers: distance, elevationGainMeters: elevation)
        )
    }

    private static func difficulty(distance: Double, elevation: Int) -> Difficulty {
        let effort = distance + Double(elevation) / 100
        if effort < 12 {
            return .easy
        }
        return effort < 30 ? .moderate : .hard
    }
}

private struct SplitMix64: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E37_79B9_7F4A_7C15
        var mixed = state
        mixed = (mixed ^ (mixed >> 30)) &* 0xBF58_476D_1CE4_E5B9
        mixed = (mixed ^ (mixed >> 27)) &* 0x94D0_49BB_1331_11EB
        return mixed ^ (mixed >> 31)
    }
}
