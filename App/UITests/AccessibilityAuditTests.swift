import XCTest

@MainActor
final class AccessibilityAuditTests: XCTestCase {
    func testLibraryPassesTheAudit() throws {
        let app = XCUIApplication.isolated()
        app.launchToList()
        app.search(for: "Copper Ridge Loop\n")
        XCTAssertTrue(app.firstTrail.waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
    }

    func testDetailPassesTheAudit() throws {
        let app = XCUIApplication.isolated()
        app.launchToList()
        app.firstTrail.tap()
        XCTAssertTrue(app.buttons["favorite-button"].waitForExistence(timeout: 5))
        try app.performAccessibilityAudit()
    }

    func testLibraryPassesTheAuditAtTheLargestTextSize() throws {
        let app = XCUIApplication.isolated()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launchToList()
        try app.performAccessibilityAudit(for: .dynamicType)
    }
}
