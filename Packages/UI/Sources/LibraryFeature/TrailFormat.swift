import DesignSystem
import Domain
import Foundation

enum TrailFormat {
    static func distance(_ stats: TrailStats) -> String {
        Measurement(value: stats.distanceKilometers, unit: UnitLength.kilometers)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    static func elevation(_ stats: TrailStats) -> String {
        Measurement(value: Double(stats.elevationGainMeters), unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided))
    }
}

extension Difficulty {
    var title: LocalizedStringResource {
        switch self {
        case .easy:
            LocalizedStringResource("Easy", bundle: .atURL(Bundle.module.bundleURL))
        case .moderate:
            LocalizedStringResource("Moderate", bundle: .atURL(Bundle.module.bundleURL))
        case .hard:
            LocalizedStringResource("Hard", bundle: .atURL(Bundle.module.bundleURL))
        }
    }

    var tone: Tone {
        switch self {
        case .easy:
            .calm
        case .moderate:
            .caution
        case .hard:
            .alert
        }
    }
}
