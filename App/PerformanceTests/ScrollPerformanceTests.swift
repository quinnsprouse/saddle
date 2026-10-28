import XCTest

@MainActor
final class ScrollPerformanceTests: XCTestCase {
    func testFlingThroughTheList() {
        let app = XCUIApplication.isolated()
        app.launchToList()
        let options = XCTMeasureOptions()
        options.invocationOptions = [.manuallyStop]
        measure(metrics: [XCTOSSignpostMetric.scrollDecelerationMetric], options: options) {
            app.trailList.swipeUp(velocity: .fast)
            stopMeasuring()
            app.trailList.swipeDown(velocity: .fast)
        }
    }
}
