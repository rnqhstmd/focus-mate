import Foundation
import XCTest

@MainActor
final class DesignSyncRulerUITests: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐 명명: wheel 유지, 범위/단위 오류, 시간 변경 시 후보 선택 유지.
    func testNativeRulerAdjustsMinuteBoundariesAndClearsSelectionAtSixtyOne() throws {
        let harness = openTimeScreen()
        let ruler = harness.app.sliders["time.ruler"]
        XCTAssertTrue(ruler.waitForExistence(timeout: 5), "시간 눈금자는 native accessibility Slider로 노출되어야 함")
        XCTAssertEqual(harness.app.pickerWheels.count, 0)
        XCTAssertEqual(try harness.diagnostic("time.minutesLabel"), "25")
        XCTAssertEqual(ruler.value as? String, "25분")

        harness.app.setJourneyMinutes(15)
        XCTAssertTrue(harness.waitForValue("time.minutesLabel", "15"))
        XCTAssertEqual(ruler.value as? String, "15분")

        harness.app.setJourneyMinutes(360)
        XCTAssertTrue(harness.waitForValue("time.minutesLabel", "360"))
        XCTAssertEqual(ruler.value as? String, "360분")

        harness.app.setJourneyMinutes(60)
        XCTAssertTrue(harness.waitForValue("time.minutesLabel", "60"))
        XCTAssertEqual(ruler.value as? String, "60분")
        let candidate = harness.element("time.candidate.2014")
        XCTAssertTrue(candidate.waitForExistence(timeout: 5))
        candidate.tap()
        XCTAssertTrue(candidate.isSelected)
        XCTAssertTrue(harness.element("time.proceed").isEnabled)

        harness.app.setJourneyMinutes(61)
        XCTAssertTrue(harness.waitForValue("time.minutesLabel", "61"))
        XCTAssertEqual(ruler.value as? String, "61분")
        XCTAssertTrue(candidate.exists, "61분에도 ±1분 후보는 남아 있어야 함")
        XCTAssertFalse(candidate.isSelected)
        XCTAssertFalse(harness.element("time.proceed").isEnabled)
    }

    // 깨짐 명명: 드래그 미연결/방향 반전, 드래그 후 후보 선택 또는 진행 가능 상태 유지.
    func testDraggingRulerLeftIncreasesMinutesAndClearsSelection() throws {
        let harness = openTimeScreen()
        let ruler = harness.app.sliders["time.ruler"]
        XCTAssertTrue(ruler.waitForExistence(timeout: 5))
        harness.app.setJourneyMinutes(60)
        XCTAssertTrue(harness.waitForValue("time.minutesLabel", "60"))
        let candidate = harness.element("time.candidate.2014")
        XCTAssertTrue(candidate.waitForExistence(timeout: 5))
        candidate.tap()
        XCTAssertTrue(candidate.isSelected)
        XCTAssertTrue(harness.element("time.proceed").isEnabled)

        let start = ruler.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5))
        let end = ruler.coordinate(withNormalizedOffset: CGVector(dx: 0.3, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)

        XCTAssertTrue(harness.waitUntil {
            guard let text = harness.value("time.minutesLabel"), let minutes = Int(text) else { return false }
            return minutes > 60
        }, "눈금자를 왼쪽으로 드래그하면 선택 시간이 증가해야 함")
        let minutes = try XCTUnwrap(Int(try harness.diagnostic("time.minutesLabel")))
        XCTAssertGreaterThan(minutes, 60)
        XCTAssertLessThanOrEqual(minutes, 360)
        let selected = harness.app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND selected == true", "time.candidate.")
        )
        XCTAssertEqual(selected.count, 0)
        XCTAssertFalse(harness.element("time.proceed").isEnabled)
    }

    // 작은 화면의 가장 큰 글자에서도 첫/마지막 후보를 실제로 선택하고 고정 CTA로 진행한다.
    func testLargestTextCanSelectFirstAndLastCandidateAndProceed() throws {
        let harness = FocusMateUIHarness.launch(seed: "cardOnly", extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        let app = harness.app
        app.typeStationQuery("성수역")
        let result = harness.element("search.result.seongsu")
        XCTAssertTrue(result.waitForExistence(timeout: 5))
        if app.keyboards.count > 0 { app.typeText("\n") }
        for _ in 0..<3 where !result.isHittable {
            let scroll = app.scrollViews["search.scroll"]
            let viewport = scroll.frame
            let distance = min(max(result.frame.midY - viewport.midY, -viewport.height * 0.6), viewport.height * 0.6)
            let center = scroll.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            let start = center.withOffset(CGVector(dx: 0, dy: distance / 2))
            let end = center.withOffset(CGVector(dx: 0, dy: -distance / 2))
            start.press(forDuration: 0.1, thenDragTo: end)
        }
        XCTAssertTrue(result.isHittable)
        result.tap()
        let confirm = harness.element("search.confirm")
        XCTAssertTrue(confirm.waitForExistence(timeout: 5))
        XCTAssertTrue(confirm.isHittable)
        confirm.tap()
        XCTAssertTrue(harness.element("screen.time").waitForExistence(timeout: 5))
        XCTAssertEqual(try harness.diagnostic("time.origin"), "성수역")

        // Each actual +/- sequence remains within the helper's existing 90-second budget.
        app.setJourneyMinutes(60)
        app.setJourneyMinutes(90)
        app.setJourneyMinutes(120)
        XCTAssertEqual(try harness.diagnostic("time.minutesLabel"), "120")
        let first = harness.element("time.candidate.2014")
        let middle = harness.element("time.candidate.302")
        let last = harness.element("time.candidate.421")
        XCTAssertTrue(first.waitForExistence(timeout: 5))
        XCTAssertTrue(middle.exists)
        XCTAssertTrue(last.exists)
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "time.candidate.")).count, 3)

        XCTAssertTrue(app.revealTimeContent(first, maxAttempts: 8))
        XCTAssertTrue(first.isHittable)
        first.tap()
        XCTAssertTrue(first.isSelected)
        XCTAssertFalse(last.isSelected)
        let proceed = harness.element("time.proceed")
        XCTAssertTrue(proceed.isHittable)
        XCTAssertTrue(proceed.isEnabled)

        XCTAssertTrue(app.revealTimeContent(last, maxAttempts: 8))
        XCTAssertTrue(last.isHittable)
        last.tap()
        XCTAssertTrue(last.isSelected)
        XCTAssertFalse(first.isSelected)
        XCTAssertTrue(proceed.isHittable)
        XCTAssertTrue(proceed.isEnabled)
        proceed.tap()
        XCTAssertTrue(harness.element("screen.preparation").waitForExistence(timeout: 5))
        let raw = try harness.diagnostic("test.journeySelection")
        let data = try XCTUnwrap(raw.data(using: .utf8))
        let selection = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(selection["minutes"] as? Int, 120)
        XCTAssertEqual(selection["busID"] as? String, "421")
    }

    private func openTimeScreen() -> FocusMateUIHarness {
        let harness = FocusMateUIHarness.launch(seed: "cardOnly")
        harness.app.typeStationQuery("성수역")
        harness.tap("search.result.seongsu")
        harness.tap("search.confirm")
        XCTAssertTrue(harness.element("screen.time").waitForExistence(timeout: 5))
        return harness
    }
}
