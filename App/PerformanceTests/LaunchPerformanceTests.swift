import XCTest

@MainActor
final class LaunchPerformanceTests: XCTestCase {
    func testLaunchToResponsiveList() {
        measure(metrics: [XCTApplicationLaunchMetric(waitUntilResponsive: true)]) {
            XCUIApplication.isolated().launch()
        }
    }
}
