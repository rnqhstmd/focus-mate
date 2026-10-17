import Foundation
import XCTest

@MainActor
final class LargeTextUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSearchAtLargestTextSizeLetsUserReachResultAndConfirmWithoutScrolling() throws {
        let app = launchLargestText()

        app.typeStationQuery("성수역")

        let result = element("search.result.seongsu", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        try reach(result, in: app)
        result.tap()

        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        XCTAssertTrue(confirm.isHittable, "확인 버튼이 스크롤 없이 닿지 않음")
        confirm.tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        let station = try XCTUnwrap(try snapshot(in: app)["currentStation"] as? [String: Any])
        XCTAssertEqual(station["id"] as? String, "seongsu")
        XCTAssertEqual(station["name"] as? String, "성수역")
    }

    func testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow() throws {
        let app = launchLargestText()
        app.typeStationQuery("성수역")
        let result = element("search.result.seongsu", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        try reach(result, in: app)
        result.tap()
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        XCTAssertTrue(confirm.isHittable, "확인 버튼이 스크롤 없이 닿지 않음")
        confirm.tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))

        let proceed = element("time.proceed", in: app)
        XCTAssertTrue(proceed.waitForExistence(timeout: timeout))
        XCTAssertTrue(proceed.isHittable, "진행 버튼이 진입 직후 스크롤 없이 닿지 않음")

        app.setJourneyMinutes(60, timeout: timeout)
        XCTAssertEqual(try value("time.minutesLabel", in: app), "60")

        let candidate = element("time.candidate.2014", in: app)
        XCTAssertTrue(candidate.waitForExistence(timeout: timeout))
        try reach(candidate, in: app)
        candidate.tap()

        XCTAssertTrue(proceed.isHittable, "후보 선택 뒤 진행 버튼이 닿지 않음")
        XCTAssertEqual(proceed.label, "이 여정 준비하기")
        proceed.tap()

        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))
        let selection = try journeySelection(in: app)
        XCTAssertEqual(selection["minutes"] as? Int, 60)
        XCTAssertEqual(selection["busID"] as? String, "2014")
        XCTAssertEqual(selection["destination"] as? String, "성동구민체육센터")
    }

    // MARK: - Helpers

    private func launchLargestText() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--fm-ui-test-id", UUID().uuidString,
            "--fm-ui-seed", "cardOnly",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        return app
    }

    /// 사용자가 스크롤해서 닿는 경로. 최대 3회 위로 민다.
    private func reach(_ target: XCUIElement, in app: XCUIApplication) throws {
        if target.identifier.hasPrefix("search."), !target.isHittable, app.keyboards.count > 0 {
            app.typeText("\n")
        }
        if target.identifier.hasPrefix("time.") {
            _ = app.revealTimeContent(target, maxAttempts: 8, timeout: timeout)
            if !target.isHittable {
                let screenshot = XCTAttachment(screenshot: app.screenshot())
                screenshot.name = "diagnostic-large-text-reach-\(target.identifier)"
                screenshot.lifetime = .keepAlways
                add(screenshot)
            }
            XCTAssertTrue(target.isHittable, "스크롤해도 닿지 않음: \(target.identifier)")
            return
        }
        var attempts = 0
        while !target.isHittable && attempts < 3 {
            if target.identifier.hasPrefix("search.") {
                let scroll = app.scrollViews["search.scroll"]
                let viewport = scroll.frame
                let distance = min(max(target.frame.midY - viewport.midY, -viewport.height * 0.6), viewport.height * 0.6)
                let center = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                let start = center.withOffset(CGVector(dx: 0, dy: distance / 2))
                let end = center.withOffset(CGVector(dx: 0, dy: -distance / 2))
                start.press(forDuration: 0.1, thenDragTo: end)
            } else {
                app.swipeUp()
            }
            attempts += 1
        }
        if !target.isHittable {
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "diagnostic-large-text-reach-\(target.identifier)"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }
        XCTAssertTrue(target.isHittable, "스크롤해도 닿지 않음: \(target.identifier)")
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func diagnosticValue(_ identifier: String, in app: XCUIApplication) throws -> String {
        let diagnostic = element(identifier, in: app)
        XCTAssertTrue(diagnostic.waitForExistence(timeout: timeout), "Missing diagnostic: \(identifier)")
        return try XCTUnwrap(diagnostic.value as? String, "Diagnostic has no string value: \(identifier)")
    }

    private func value(_ identifier: String, in app: XCUIApplication) throws -> String {
        let observed = element(identifier, in: app)
        XCTAssertTrue(observed.waitForExistence(timeout: timeout), "Missing value element: \(identifier)")
        return try XCTUnwrap(observed.value as? String, "Element has no string value: \(identifier)")
    }

    private func snapshot(in app: XCUIApplication) throws -> [String: Any] {
        try parseObject(try diagnosticValue("test.snapshot", in: app))
    }

    private func journeySelection(in app: XCUIApplication) throws -> [String: Any] {
        try parseObject(try diagnosticValue("test.journeySelection", in: app))
    }

    private func parseObject(_ raw: String) throws -> [String: Any] {
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
