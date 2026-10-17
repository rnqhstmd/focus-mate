import Foundation
import XCTest

@MainActor
final class RecordsAnalyticsUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐: 분석 진입이 없거나 주/월 이동이 미래 기간을 허용한다.
    func testAC1_분석은_선택월로_열리고_현재주와월의_미래이동을_차단한다() {
        let h = FocusMateUIHarness.launch(seed: "analytics")
        openAnalytics(h)
        XCTAssertTrue(h.element("analytics.period.month").isSelected)
        assertSummary(h, minutes: 150, count: 6)
        XCTAssertFalse(h.element("analytics.next").isEnabled)
        h.tap("analytics.period.week")
        XCTAssertTrue(h.element("analytics.period.week").isSelected)
        XCTAssertFalse(h.element("analytics.next").isEnabled)
        h.tap("analytics.previous")
        XCTAssertTrue(h.element("analytics.next").isEnabled)
        assertSummary(h, minutes: 0, count: 0)
        h.tap("analytics.today")
        assertSummary(h, minutes: 150, count: 6)
        XCTAssertFalse(h.element("analytics.next").isEnabled)
    }

    // 깨짐: 태그 필터가 전체 합계를 바꾸거나 기간 이동 후 사라진 태그를 유지한다.
    func testAC3_기록없는기간으로_이동하면_이전태그를_해제하고_전체로_돌아온다() {
        let h = FocusMateUIHarness.launch(seed: "analytics")
        openAnalytics(h)
        h.tap("analytics.tag.독서")
        XCTAssertTrue(h.element("analytics.tag.독서").isSelected)
        XCTAssertTrue(h.element("analytics.clearTag").exists)
        assertSummary(h, minutes: 150, count: 6)
        h.tap("analytics.previous")
        XCTAssertFalse(h.element("analytics.clearTag").exists)
        XCTAssertFalse(h.element("analytics.tag.독서").exists)
        assertSummary(h, minutes: 0, count: 0)
        h.tap("analytics.today")
        XCTAssertFalse(h.element("analytics.tag.독서").isSelected)
        assertSummary(h, minutes: 150, count: 6)
    }

    // 깨짐: 분석의 메모 선택이 기존 편집기를 열지 않거나 저장 후 분석이 이전 메모를 보여준다.
    func testAC5_분석메모에서_기존편집기로_돌아가_저장하면_재진입에_최신메모를_읽는다() {
        let h = FocusMateUIHarness.launch(seed: "analytics")
        openAnalytics(h)
        let memo = h.element("analytics.memo.analytics-1")
        reveal(memo, in: h.app)
        XCTAssertTrue(memo.label.contains("회고 1"))
        memo.tap()
        let field = h.app.textFields["recordMemo.field"]
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.analytics").exists)
        XCTAssertEqual(field.value as? String, "회고 1")
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4))
        field.typeText("새 회고")
        h.tap("recordMemo.save")
        XCTAssertTrue(h.waitUntil { !h.element("recordMemo.field").exists })
        XCTAssertTrue(h.element("screen.records").exists)
        h.tap("records.analytics.open")
        XCTAssertTrue(h.element("screen.analytics").waitForExistence(timeout: timeout))
        let updated = h.element("analytics.memo.analytics-1")
        reveal(updated, in: h.app)
        XCTAssertTrue(updated.label.contains("새 회고"))
        XCTAssertFalse(updated.label.contains("회고 1"))
    }

    // 깨짐: 빈 자료를 접근 불가로 처리하거나 최대 글자에서 기간 조작·기록 복귀가 막힌다.
    func testAC6_AC7_큰글자의_빈분석에서도_기간조작과_기록복귀가_가능하다() {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        openAnalytics(h)
        assertSummary(h, minutes: 0, count: 0)
        XCTAssertTrue(h.element("analytics.empty").exists)
        h.tap("analytics.period.week")
        XCTAssertFalse(h.element("analytics.next").isEnabled)
        h.tap("analytics.previous")
        h.tap("analytics.today")
        assertSummary(h, minutes: 0, count: 0)
        h.app.navigationBars.firstMatch.buttons.firstMatch.tap()
        XCTAssertTrue(h.element("screen.records").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("records.empty").exists)
    }

    // 깨짐: 상위3밖 D를 필터에서누락하거나 묶음기타를 실제태그버튼으로 취급한다.
    func testAC3_묶음기타는_정적10분이고_D태그는_전체합계를유지하며_선택된다() {
        let h = FocusMateUIHarness.launch(seed: "analyticsManyTags")
        openAnalytics(h)
        assertSummary(h, minutes: 100, count: 4)

        let remainder = h.element("analytics.tag.remainder")
        reveal(remainder, in: h.app)
        XCTAssertEqual(remainder.elementType, .staticText)
        XCTAssertFalse(h.app.buttons["analytics.tag.remainder"].exists)
        let text = remainder.label + " " + ((remainder.value as? String) ?? "")
        XCTAssertTrue(text.contains("기타"))
        XCTAssertNotNil(text.range(of: "(?<![0-9])10분", options: .regularExpression))

        let tagD = h.element("analytics.tag.D")
        reveal(tagD, in: h.app)
        XCTAssertEqual(tagD.elementType, .button)
        tagD.tap()
        XCTAssertTrue(tagD.isSelected)
        XCTAssertTrue(h.element("analytics.clearTag").exists)
        assertSummary(h, minutes: 100, count: 4)
    }

    private func openAnalytics(_ h: FocusMateUIHarness) {
        h.tap("open.records")
        XCTAssertTrue(h.element("screen.records").waitForExistence(timeout: timeout))
        h.tap("records.analytics.open")
        XCTAssertTrue(h.element("screen.analytics").waitForExistence(timeout: timeout))
    }

    private func assertSummary(_ h: FocusMateUIHarness, minutes: Int, count: Int,
                               file: StaticString = #filePath, line: UInt = #line) {
        let summary = h.element("analytics.summary")
        XCTAssertTrue(summary.waitForExistence(timeout: timeout), file: file, line: line)
        let text = summary.label + " " + ((summary.value as? String) ?? "")
        XCTAssertNotNil(text.range(of: "(?<![0-9])\(minutes)분", options: .regularExpression),
                        "합계 분 누락: \(text)", file: file, line: line)
        XCTAssertNotNil(text.range(of: "(?<![0-9])\(count)회", options: .regularExpression),
                        "합계 횟수 누락: \(text)", file: file, line: line)
    }

    private func reveal(_ element: XCUIElement, in app: XCUIApplication) {
        for _ in 0..<8 {
            if element.exists && element.isHittable { return }
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, "분석 항목에 도달할 수 없음")
    }
}
