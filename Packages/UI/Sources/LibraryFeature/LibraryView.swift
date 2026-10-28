import Domain
public import SwiftUI

public struct LibraryView: View {
    @Bindable private var model: LibraryModel

    public init(model: LibraryModel) {
        self.model = model
    }

    public var body: some View {
        NavigationStack {
            content
                .navigationTitle(Text("Trails", bundle: .module))
                .navigationDestination(for: Trail.self) { trail in
                    TrailDetailView(trail: trail, model: model)
                }
                .searchable(text: $model.query, prompt: Text("Search trails", bundle: .module))
        }
        .task { await model.load() }
        .task(id: model.query) { await model.search() }
    }

    @ViewBuilder private var content: some View {
        switch model.phase {
        case .loading:
            ProgressView()
        case .failed:
            ContentUnavailableView(
                String(localized: "Trails unavailable", bundle: .module),
                systemImage: "exclamationmark.triangle",
                description: Text("Try again after restarting the app.", bundle: .module)
            )
        case .ready where model.results.isEmpty:
            ContentUnavailableView.search(text: model.query)
        case .ready:
            List(model.results) { trail in
                NavigationLink(value: trail) {
                    TrailRow(trail: trail, isFavorite: model.isFavorite(trail))
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("trail-list")
        }
    }
}
