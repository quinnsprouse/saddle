import LibraryFeature
import SwiftUI

@main
struct MainApp: App {
    @State private var model = Composition.libraryModel()

    init() {
        MetricsObserver.start()
    }

    var body: some Scene {
        WindowGroup {
            LibraryView(model: model)
        }
    }
}
