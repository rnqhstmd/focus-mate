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

    private func openTimeScreen() -> FocusMateUIHarness {
        let harness = FocusMateUIHarness.launch(seed: "cardOnly")
        harness.app.typeStationQuery("성수역")
        harness.tap("search.result.seongsu")
        harness.tap("search.confirm")
        XCTAssertTrue(harness.element("screen.time").waitForExistence(timeout: 5))
        return harness
    }
}
