# W09b T3 회귀 RED — 기록 행 ID·태그 표시

Status: DONE_WITH_CONCERNS — 작성 완료, 실행 증거 없음.

## intended RED
추가3케이스: unit2 + UI1. 의도한 RED2케이스, 원문 보존 호환 회귀1케이스.
- Row ID: U+00E9와 U+0065 U+0301의 서로 다른 기록으로 RecordsAnalyticsRow를 만들고 Set(ids).count == 2 검사. Swift String canonical equality로 행 ID가 충돌하면 assertion RED.
- Row 원문 보존: .record.id UTF16 [[233],[101,769]], task/memo 각각 독립 literal 검사. 이미 원문을 보존하면 통과하는 호환 회귀이며 RED 수에 넣지 않는다.
- UI: analyticsManyTags(A40/B30/C20/D10)에서100분4회. analytics.tag.remainder는 staticText이고 버튼이 아니며 기타10분을 표시. analytics.tag.D는 전체태그필터의 실제 버튼으로 선택 가능하고 선택 뒤 상단100분4회 유지. remainder 누락/버튼화, D 누락, 상단이D10분으로 좁혀지면 assertion RED.

## 실행 상태
테스트·빌드·시뮬레이터·브라우저를 실행하지 않았다. 생산 소스 읽기/쓰기 없음. 부모가 승인된 Row scaffold/analyticsManyTags seed로 focused 실행한다. 실제 컴파일·실패 메시지 미확보. seed 미등록 같은 fixture 부재는 의도한 RED로 세지 않는다.
기존 UI4테스트 본문 변경 없이 private openAnalytics helper 앞에 새 함수만 추가했다. 기존 T1/T2/W17 테스트 변경 없음.

## 부모 승인 인터페이스
RecordsAnalyticsRow.init(record:RecordSnapshot), Identifiable.id, internal let record:RecordSnapshot. 원문 관찰을 위한 .record 계약은 부모에게 확인하여 명시 승인받았다. 생산 파일을 읽지 않았다.

## 참조한 파일 전체
- .dev/codex-system-surfaces-w09b/prd.md (앞선 동일 agent 작업에서 읽은 계약 재사용)
- .dev/codex-system-surfaces-w09b/design.md (앞선 동일 agent 작업에서 읽은 계약 재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md (역할 재사용)
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md (규칙 재사용)
- ios/FocusMateUITests/RecordsAnalyticsUITests.swift
- ios/FocusMateTests/RecordsAnalyticsAdapterTests.swift (RecordSnapshot fixture 관례)
- ios/FocusMateTests/RecordsAnalyticsRowTests.swift (신규)
- .dev/codex-system-surfaces-w09b 하위 md의 Row/seed/remainder 검색은 결과 없음. 생산 탐색 없음.

## 테스트 전문

### ios/FocusMateTests/RecordsAnalyticsRowTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

final class RecordsAnalyticsRowTests: XCTestCase {
    private func record(_ id: String, task: String, memo: String) -> RecordSnapshot {
        RecordSnapshot(
            id: id, completedAt: "2026-10-14T12:00:00Z", date: "2026-10-14",
            bus: "버스2014", tag: "독서", tagColor: "#12ABef", task: task,
            minutes: 25, sound: "빗소리", from: "성수역", to: "서울숲 입구", memo: memo
        )
    }

    // 깨짐: Swift String canonical equality를 행ID로 사용하여 서로다른 원문기록을 한행으로 합친다.
    func testW09b_canonical동등해도_UTF16다른_기록행ID는_두개다() {
        let first = RecordsAnalyticsRow(record: record("\u{00E9}", task: "첫 할 일", memo: "첫 메모"))
        let second = RecordsAnalyticsRow(record: record("e\u{0301}", task: "둘째 할 일", memo: "둘째 메모"))

        XCTAssertEqual(Set([first.id, second.id]).count, 2)
    }

    // 깨짐: 행생성시 원문ID를정규화하거나 canonical동등한 다른기록의할일·메모로 덮는다.
    func testW09b_각기록행은_원본ID와_할일메모를_보존한다() {
        let rows = [
            RecordsAnalyticsRow(record: record("\u{00E9}", task: "첫 할 일", memo: "첫 메모")),
            RecordsAnalyticsRow(record: record("e\u{0301}", task: "둘째 할 일", memo: "둘째 메모"))
        ]

        XCTAssertEqual(rows.map { Array($0.record.id.utf16) }, [[233], [101, 769]])
        XCTAssertEqual(rows.map { $0.record.task }, ["첫 할 일", "둘째 할 일"])
        XCTAssertEqual(rows.map { $0.record.memo }, ["첫 메모", "둘째 메모"])
    }
}

```

### ios/FocusMateUITests/RecordsAnalyticsUITests.swift
```swift
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

```
