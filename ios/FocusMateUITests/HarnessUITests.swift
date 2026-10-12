import XCTest

final class HarnessUITests: XCTestCase {
    @MainActor
    func testHarnessLaunches() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.staticTexts["Focus Mate"].waitForExistence(timeout: 5))
    }
}
