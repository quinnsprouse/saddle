import Foundation
import XCTest

@MainActor
final class LibraryJourneyTests: XCTestCase {
    func testSearchNarrowsAndClearingRestoresTheList() {
        let app = XCUIApplication.isolated()
        app.launchToList()
        let firstUnfiltered = app.firstTrail.label

        app.search(for: "Copper Ridge")
        let match = app.firstTrail
        XCTAssertTrue(match.waitForExistence(timeout: 5))
        XCTAssertTrue(match.label.hasPrefix("Copper Ridge"), "Expected a prefix match, got \(match.label)")

        app.searchFields.firstMatch.buttons.firstMatch.tap()
        XCTAssertEqual(app.firstTrail.label, firstUnfiltered)
    }

    func testACorruptFavoritesFileShowsTheFailureState() throws {
        let dataDirectory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        try Data("not json".utf8).write(to: dataDirectory.appending(path: "favorites.json"))
        let app = XCUIApplication.isolated(dataDirectory: dataDirectory)
        app.launch()
        XCTAssertTrue(app.staticTexts["Trails unavailable"].waitForExistence(timeout: 15))
    }

    func testFavoriteSurvivesRelaunch() {
        let dataDirectory = FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let app = XCUIApplication.isolated(dataDirectory: dataDirectory)
        app.launchToList()
        app.firstTrail.tap()

        let favorite = app.buttons["favorite-button"]
        XCTAssertEqual(favorite.label, "Add to favorites")
        favorite.tap()
        XCTAssertEqual(favorite.label, "Remove from favorites")

        app.terminate()
        let relaunched = XCUIApplication.isolated(dataDirectory: dataDirectory)
        relaunched.launchToList()
        relaunched.firstTrail.tap()
        XCTAssertEqual(relaunched.buttons["favorite-button"].label, "Remove from favorites")
    }
}
