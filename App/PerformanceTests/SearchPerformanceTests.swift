import XCTest

@MainActor
final class SearchPerformanceTests: XCTestCase {
    func testSearchAcrossTheCatalog() {
        let app = XCUIApplication.isolated()
        app.launchToList()
        let search = app.searchFields.firstMatch
        search.tap()
        let metric = XCTOSSignpostMetric(subsystem: "LibraryFeature", category: "Library", name: "search")
        measure(metrics: [metric]) {
            search.typeText("ridge")
            search.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 5))
        }
    }
}
