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
        return app
    }

    var trailList: XCUIElement {
        collectionViews["trail-list"]
    }

    var firstTrail: XCUIElement {
        trailList.buttons.firstMatch
    }

    func search(for query: String) {
        let field = searchFields.firstMatch
        field.tap()
        field.typeText(query)
    }

    func launchToList(file: StaticString = #filePath, line: UInt = #line) {
        launch()
        XCTAssertTrue(trailList.waitForExistence(timeout: 15), "The trail list did not appear", file: file, line: line)
    }
}
