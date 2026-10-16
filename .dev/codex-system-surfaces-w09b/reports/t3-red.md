# W09b T3 UI RED 사전작성

Status: DONE_WITH_CONCERNS. 작성만 완료, 실행하지 않음. T2 완료 후 부모가 기계 RED를 실행한다.

## 작성 범위
- 신규 RecordsAnalyticsUITests.swift, 4개 동작 테스트. production 읽기/수정 없음.
- 분석 진입/주월/미래 차단, 태그 선택 뒤 빈 기간 전체 fallback, 메모 편집 왕복과 재진입 갱신, 최대 글자의 빈 분석 조작/뒤로가기.
- analytics 시드: 오늘 startOfDay 완료 6건, 각25분=150분/6회, id analytics-0...5, 짝수 독서/홀수 공부, 메모1...4. 같은 시각의 입력 순서에서 최신 메모3개는1/2/3이므로 analytics-1을 선택한다.
- ready 시드는 정상 빈 기록. recordsMemo 시드는 사용하지 않는다.

## 실패 확인 인계
- 명령: python3 scripts/check-ios.py test RecordsAnalyticsUITests
- 실제 실패 메시지: 미실행이므로 없음. RED 확인 완료로 기록하지 않는다.
- 예상: UI 미연결 상태에서 4개 테스트가 records.analytics.open 부재 assertion으로 실패. analytics 시드 추가 전에는 앱 설정 실패가 선행할 수 있으며 이는 유효한 기능 RED로 집계하지 않는다.
- 실제 실행시간 미측정. 짧은 경로3개와 메모 왕복1개이며 XCTest 시스템 대기/스크롤 때문에 전체20~60초 목표를 초과할 수 있다.

## selector 및 사용자 의미 계약
- records.analytics.open: 기록에서 분석 진입 버튼.
- screen.analytics: 분석 화면 식별자.
- analytics.period.week/month: 선택 시 isSelected를 노출하는 기간 버튼.
- analytics.previous/next/today: 이전/다음/오늘 이동. 현재 기간의 next disabled.
- analytics.summary: 화면의 전체 합계 분과 횟수를 접근성 label/value에 제공. 예150분/6회, 빈0분/0회. 색/장식/문장 전체 일치 assert 없음.
- analytics.tag.독서 및 analytics.clearTag: 선택 상태와 필터 해제 컨트롤. 이전 빈 기간에는 없어지고 오늘 복귀에서 독서는 미선택.
- analytics.memo.analytics-1: 원본 메모 내용이 접근성 이름에 들어가는 실제 메모 열기 버튼. 회고1에서 새 회고로 갱신.
- analytics.empty: 정상 빈 분석 안내. unavailable을 대신하는 테스트용 진단 아님.
- 기존 recordMemo.field/save, screen.records, records.empty, open.records는 기존 테스트 계약 재사용.
- native navigation back는 RecordsUITests와 같은 navigationBars.firstMatch.buttons.firstMatch 사용.

## 한계와 누락 경계
- 존재하지 않는 태그를 UI에서 직접 주입할 수 없으므로 테스트 전용 production hook을 요구하지 않는다. 선택 후 기록 없는 기간으로 이동하는 실제 사용자 경로에서 fallback/해제를 검사한다. 임의 없는 이름의 직접 거절은 T2 Browser 단위 검사 소유.
- 최근 여행 별도 탭과 메모 탭이 같은 onOpenRecord 계약이므로 이번4개는 메모 탭 왕복에 집중한다. 최근5/메모4/최신3의 값은 T2 adapter 단위 검사 소유이며 UI 레이아웃 개수 assert를 추가하지 않는다.
- 최대 글자 실행 인자를 사용하지만 실제 VoiceOver/기기 렌더 또는 OS 글자 설정 반영 완료를 주장하지 않는다.
- 프로덕션 파일을 이번 red-writer 전환 이후 읽지 않았다. 이전 역할에서 읽은 자료는 이번 테스트 인터페이스 근거로 사용하지 않았다.

## 참조 목록
- .dev/codex-system-surfaces-w09b/prd.md
- .dev/codex-system-surfaces-w09b/design.md
- ios/FocusMateUITests/RecordsUITests.swift
- ios/FocusMateUITests/UITestLaunchSupport.swift (FocusMateUIHarness 실제 위치)
- gx-dev/references/codex-roles/red-writer.md
- gx-tdd/references/testing-anti-patterns.md
- gx-tdd/references/frontend-testing.md
- 요청한 FocusMateUIHarness.swift는 부재. rg --files ios/FocusMateUITests로 하네스 위치만 탐색했다.

## 코드 전문
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

## 부모 직접 RED
analytics 전용정상시드추가후4건모두 records.analytics.open 부재 assertion으로실패. seed생성/앱진입/기록진입은성공. runner/compiler오류아님. t3-red-run.log(exit65).

## 기존 UI 하네스 결함 수리 (T3 검증 후)
- 근거: reports/t3-existing-records.log:138~152. recordMemo.save는 NavigationBar의 Other 래퍼와 실제 Button 한 개에 같이 노출된다. 기존 descendants(.any)[identifier].tap()은 두 노드를 찾아 모호성 오류로 실패했다.
- 변경: UITestLaunchSupport.swift의 tap(_:)만 수정. 기존 target 및 waitForExistence assertion을 유지하고 정확한 Button role 조회 결과가 단 하나일 때만 buttons.element.tap()한다. 0개 또는 2개 이상이면 기존 target.tap()으로 돌아간다.
- firstMatch로 중복을 숨기지 않는다. 실제 Button이 두 개면 기존 모호성 실패가 유지된다. 없는 selector의 존재 assertion도 그대로다.
- production, 기존 테스트 메서드/assertion, 잠긴 신규 RecordsAnalyticsUITests.swift는 수정하지 않았다.
- 테스트 실행은 하지 않았다. 부모가 기존 RecordsUITests만 재실행해 확인한다.

## 시각 QA 캡처 도구 추가
- 신규 ios/FocusMateUITests/RecordsAnalyticsVisualCaptureTests.swift에 단 1개 capture case를 추가했다.
- 기존 하네스로 analytics 시드→기록→분석에 진입하고 화면 존재를 확인한 뒤 실제 app.screenshot()을 XCTAttachment(.keepAlways)로 남긴다.
- 첨부 이름: w09b-analysis-normal, 두 번 swipeUp 이후 w09b-analysis-insights.
- 새 기능 RED 또는 색/여백/스타일 합격 검사가 아니다. 승인 시안과 직접 대조할 실제 네이티브 캡처 도구다. 두 번째 이미지의 정확한 위치·내용도 추출 후 직접 확인해야 한다.
- production 파일과 기존 잠긴 테스트는 읽거나 수정하지 않았다. 이번 신규 파일은 실행하지 않았으며 부모가 focused 실행 및 xcresult 이미지 추출·직접 대조를 수행한다.
