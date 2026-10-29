import DesignSystem
import Domain
import SwiftUI

struct TrailDetailView: View {
    let trail: Trail
    let model: LibraryModel

    var body: some View {
        List {
            Section {
                LabeledContent {
                    Text(TrailFormat.distance(trail.stats))
                        .foregroundStyle(Palette.secondaryText)
                } label: {
                    Text("Distance", bundle: .module)
                }
                LabeledContent {
                    Text(TrailFormat.elevation(trail.stats))
                        .foregroundStyle(Palette.secondaryText)
                } label: {
                    Text("Elevation gain", bundle: .module)
                }
                LabeledContent {
                    Badge(trail.difficulty.title, tone: trail.difficulty.tone)
                } label: {
                    Text("Difficulty", bundle: .module)
                }
            } header: {
                Text(trail.region)
                    .foregroundStyle(Palette.secondaryText)
            }
        }
        .navigationTitle(trail.name)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                FavoriteButton(isFavorite: model.isFavorite(trail)) {
                    model.toggleFavorite(trail)
                }
            }
        }
    }
}

private struct FavoriteButton: View {
    let isFavorite: Bool
    let toggle: () -> Void

    private var title: String {
        isFavorite
            ? String(localized: "Remove from favorites", bundle: .module)
            : String(localized: "Add to favorites", bundle: .module)
    }

    var body: some View {
        Button(title, systemImage: isFavorite ? "star.fill" : "star", action: toggle)
            .accessibilityIdentifier("favorite-button")
            .sensoryFeedback(.selection, trigger: isFavorite)
    }
}
