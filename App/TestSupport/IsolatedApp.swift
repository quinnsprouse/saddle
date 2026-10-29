import Foundation
import XCTest

@MainActor
extension XCUIApplication {
    static func isolated(dataDirectory: URL? = nil) -> XCUIApplication {
        let app = XCUIApplication()
        let directory =
            dataDirectory
            ?? FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        app.launchEnvironment["APP_DATA_DIRECTORY"] = directory.path(percentEncoded: false)
        app.launchEnvironment["TSAN_OPTIONS"] = "halt_on_error=1"
        return app
    }

    var trailList: XCUIElement {
        collectionViews["trail-list"]
    }

    var firstTrail: XCUIElement {
        trailList.buttons.firstMatch
    }

    @discardableResult
    func openSearch(file: StaticString = #filePath, line: UInt = #line) -> XCUIElement {
        let field = searchFields.firstMatch
        let collapsedSearch = toolbars.buttons["Search"]
        if !field.exists, collapsedSearch.exists {
            collapsedSearch.tap()
        }
        XCTAssertTrue(field.waitForExistence(timeout: 5), "The search field did not appear", file: file, line: line)
        return field
    }

    func search(for query: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = openSearch(file: file, line: line)
        field.tap()
        field.typeText(query)
    }

    func launchToList(file: StaticString = #filePath, line: UInt = #line) {
        launch()
        XCTAssertTrue(trailList.waitForExistence(timeout: 15), "The trail list did not appear", file: file, line: line)
    }
}
