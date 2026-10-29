import DesignSystem
import Domain
import SwiftUI

struct TrailRow: View {
    let trail: Trail
    let isFavorite: Bool

    var body: some View {
        HStack(spacing: Spacing.medium) {
            VStack(alignment: .leading, spacing: Spacing.xSmall) {
                Text(trail.name)
                    .font(.headline)
                Text(verbatim: "\(trail.region) · \(TrailFormat.distance(trail.stats))")
                    .font(.subheadline)
                    .foregroundStyle(Palette.secondaryText)
            }
            Spacer(minLength: Spacing.small)
            if isFavorite {
                Image(systemName: "star.fill")
                    .foregroundStyle(Palette.favorite)
                    .accessibilityLabel(Text("Favorite", bundle: .module))
            }
            Badge(trail.difficulty.title, tone: trail.difficulty.tone)
        }
        .accessibilityElement(children: .combine)
    }
}
