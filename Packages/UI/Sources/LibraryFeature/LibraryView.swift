import Domain
public import SwiftUI

public struct LibraryView: View {
    @Bindable private var model: LibraryModel
    @State private var selection: Trail.ID?

    public init(model: LibraryModel) {
        self.model = model
    }

    public var body: some View {
        NavigationSplitView {
            content
                .navigationTitle(Text("Trails", bundle: .module))
                .searchable(text: $model.query, prompt: Text("Search trails", bundle: .module))
        } detail: {
            if let trail = model.trail(withID: selection) {
                TrailDetailView(trail: trail, model: model)
            } else {
                ContentUnavailableView(String(localized: "Choose a trail", bundle: .module), systemImage: "map")
            }
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
            List(model.results, selection: $selection) { trail in
                NavigationLink(value: trail.id) {
                    TrailRow(trail: trail, isFavorite: model.isFavorite(trail))
                }
            }
            .listStyle(.plain)
            .accessibilityIdentifier("trail-list")
        }
    }
}
