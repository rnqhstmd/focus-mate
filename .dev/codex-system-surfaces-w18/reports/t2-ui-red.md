# W18 T2 UI RED 작성

Status: DONE_WITH_CONCERNS. 신규 WidgetEntryUITests.swift 5건 작성. 실행하지 않았으므로 RED/컴파일 성공을 주장하지 않는다.

## 격리 자기신고
이 에이전트는 이전 W09b 리뷰에서 RecordsView/RecordsAnalyticsView 등 생산 코드를 본 이력이 있다. 이번 RED 턴에서는 생산 파일을 읽지 않고 W18 PRD/design과 기존 테스트만 참조했다. 완전히 새 에이전트의 생산 코드 비노출 조건과는 다르다.

## 계약과 범위
부모 승인 DEBUG --fm-ui-widget-url 인자를 launch/relaunch에 전달한다. codec query id는 부모가 명시 확인했다. URLComponents로 v=1/issuedAt 현재 정수 epoch, analytics day/tag/period, journey/new id를 구성한다. lifePaused90 시드의 실제 ID는 기존 snapshot 진단으로 읽고 같은 저장소를 재실행한다. 저장 시도는 프로세스 간 차감하지 않고 재실행 후0과 기존 바이트 불변을 검증한다. 수동 clock을 사용하지 않아 현재 epoch와 고정 clock의 TTL 충돌을 피한다.

실제 OS URL 전달/위젯 탭 검증이 아니다. DEBUG 인자에서 실제 앱 entry 경계까지 연결한 계약 검사다. resume token 전용 공개 UI 진단은 기존 테스트에 없어 직접 assert하지 않는다. 메인 유지/타이머 미진입/paused 유지/elapsed90/쓰기0으로 자동재개 부작용을 검증하며 token 자체는 단위 Navigation 테스트 소관이다.

## 예상 RED와 호환 구분
- 분석 week/독서/전체150분6회 진입: 미연결이면 screen.analytics 부재 assertion RED 예상.
- new 링크 기존 확인 및 취소 원본 보존: 미연결이면 confirmation 부재 assertion RED 예상.
- unknown/expired/paused 링크3건: 미연결에서도 안전 메인 그대로면 통과할 수 있으므로 호환 회귀로 분류하며 신규 RED 수에 포함하지 않는다.
- bootstrap이 인자를 거부해 앱 시작 자체가 실패하면 유효한 행동 RED가 아니다. 부모가 승인된 인자 수용 scaffold를 먼저 제공해야 한다.

## 실행 명령/결과
부모 실행: python3 scripts/check-ios.py test WidgetEntryUITests
실패 메시지: 미실행, 미확보. 전체 테스트/빌드 실행하지 않음. 기존 테스트 변경 없음.

## 참조 파일
- .dev/codex-system-surfaces-w18/prd.md
- .dev/codex-system-surfaces-w18/design.md
- ios/FocusMateUITests/UITestLaunchSupport.swift
- ios/FocusMateUITests/JourneyLifecycleSafetyUITests.swift
- ios/FocusMateUITests/JourneyTimerLifecycleUITests.swift (검색)
- ios/FocusMateUITests/JourneyResumeUITests.swift (검색)
- ios/FocusMateTests/WidgetLinkTests.swift (검색)
- gx-dev/references/codex-roles/red-writer.md
- 이전 턴에서 읽은 testing-anti-patterns.md 규칙 유지

## 테스트 전문
```swift
import Foundation
import XCTest

/// DEBUG URL entry injection only; this does not verify OS URL delivery or a real widget tap.
@MainActor
final class WidgetEntryUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func url(_ path: String, age: TimeInterval = 0, items: [URLQueryItem] = []) throws -> String {
        var value = URLComponents()
        value.scheme = "focusmate"
        value.host = "widget"
        value.path = "/" + path
        value.queryItems = [URLQueryItem(name: "v", value: "1"),
                           URLQueryItem(name: "issuedAt", value: String(Int(Date().timeIntervalSince1970 - age)))] + items
        return try XCTUnwrap(value.url?.absoluteString)
    }

    private func dayToday() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }

    // Break: widget analytics entry loses its week/tag context or filters the upper total.
    func testAC5_분석링크는_주간과독서필터로열고_전체150분6회를유지한다() throws {
        let link = try url("analytics", items: [URLQueryItem(name: "day", value: dayToday()),
                                               URLQueryItem(name: "tag", value: "독서"),
                                               URLQueryItem(name: "period", value: "week")])
        let h = FocusMateUIHarness.launch(seed: "analytics", extraArguments: ["--fm-ui-widget-url", link])
        XCTAssertTrue(h.element("screen.analytics").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("analytics.period.week").isSelected)
        XCTAssertTrue(h.element("analytics.tag.독서").isSelected)
        XCTAssertTrue(h.element("analytics.clearTag").exists)
        let summary = h.element("analytics.summary")
        let text = summary.label + " " + ((summary.value as? String) ?? "")
        XCTAssertNotNil(text.range(of: "(?<![0-9])150분", options: .regularExpression))
        XCTAssertNotNil(text.range(of: "(?<![0-9])6회", options: .regularExpression))
    }

    private func assertSafeHome(_ link: String) throws {
        let h = FocusMateUIHarness.launch(seed: "ready")
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let bytes = try h.persistedBytes()
        h.relaunch(extraArguments: ["--fm-ui-widget-url", link])
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.analytics").exists)
        XCTAssertFalse(h.element("screen.time").exists)
        XCTAssertEqual(try h.persistedBytes(), bytes)
        XCTAssertEqual(try h.writeAttempts(), 0)
    }

    // Compatibility guard: malformed entry must not navigate or change persisted data.
    func testAC5_잘못된경로링크는_메인과저장을유지한다() throws {
        try assertSafeHome(url("unknown"))
    }

    // Compatibility guard: expired analytics entry must not open old context.
    func testAC5_24시간지난분석링크는_메인과저장을유지한다() throws {
        try assertSafeHome(url("analytics", age: 90_000))
    }

    // Compatibility guard: journey link must not resume the paused timer or save.
    func testAC5_정지여정링크는_기존카드만보이고_자동재개하거나저장하지않는다() throws {
        let h = FocusMateUIHarness.launch(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let id = try XCTUnwrap(try h.memoryActive()?["id"] as? String)
        let bytes = try h.persistedBytes()
        h.relaunch(extraArguments: ["--fm-ui-widget-url", try url("journey", items: [URLQueryItem(name: "id", value: id)])])
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("main.activeJourney").exists)
        XCTAssertTrue(h.app.buttons["main.resumeJourney"].exists)
        XCTAssertFalse(h.element("journey.timer.remaining").exists)
        XCTAssertEqual(try h.memoryElapsed(), 90)
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
        XCTAssertEqual(try h.writeAttempts(), 0)
        XCTAssertEqual(try h.persistedBytes(), bytes)
    }

    // Break: new-journey link bypasses confirmation or cancellation destroys the old journey.
    func testAC5_새여정링크는_기존확인을열고_취소하면원본을유지한다() throws {
        let h = FocusMateUIHarness.launch(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let id = try XCTUnwrap(try h.memoryActive()?["id"] as? String)
        let bytes = try h.persistedBytes()
        h.relaunch(extraArguments: ["--fm-ui-widget-url", try url("new", items: [URLQueryItem(name: "id", value: id)])])
        let alert = h.alert(titled: "새 여정을 시작할까요?")
        XCTAssertTrue(alert.waitForExistence(timeout: timeout))
        let confirmExists = h.alertButton("main.newJourney.confirm", label: "새 여정 시작").waitForExistence(timeout: timeout)
        if !confirmExists {
            let tree = XCTAttachment(string: h.app.debugDescription)
            tree.name = "widget-entry-alert-tree"
            tree.lifetime = .keepAlways
            add(tree)
        }
        XCTAssertTrue(confirmExists)
        XCTAssertEqual(try h.writeAttempts(), 0)
        let keep = h.alertButton("main.newJourney.keep", label: "이전 여정 유지하기")
        XCTAssertTrue(keep.waitForExistence(timeout: timeout))
        keep.tap()
        XCTAssertTrue(h.waitUntil { !alert.exists })
        XCTAssertTrue(h.element("main.activeJourney").exists)
        XCTAssertEqual(try h.memoryActive()?["id"] as? String, id)
        XCTAssertEqual(try h.memoryElapsed(), 90)
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
        XCTAssertEqual(try h.writeAttempts(), 0)
        XCTAssertEqual(try h.persistedBytes(), bytes)
    }
}

```

## 후속 하네스 동기화 보완 (2026-10-16)

`t3-red-t2-ui-green.log:1786–1791`에서 alert 존재 대기는 성공했지만 확인 버튼은 즉시 exists 조회에서 실패했다. 기존 `NewJourneyUITests.swift:41–42,62`와 동일하게 확인·취소 버튼에 `waitForExistence(timeout:)`를 적용했다. 기존 `alertButton`의 ID와 정확한 label 동시 매칭 및 저장/취소 결과 기대는 유지했다. 다른 네 테스트 본문과 공용 helper는 변경하지 않았다.

부모는 실패 녹화에서 두 버튼이 표시됨을 확인했다고 전달했다. 이 수정만으로 실제 원인이 timing인지 ID 전달인지 확정할 수 없으며, 재실행에서 계속 실패하면 AX hierarchy로 쿼리 계약을 확인해야 한다. 이번 보완에서는 테스트·빌드 실행 및 생산 코드 열람을 하지 않았다. 후속 GREEN은 미확인이다.

### AX 진단 첨부 보완

후속 실행에서도 확인 버튼 대기가 실패했다는 부모 관측에 따라, 같은 ID+label 쿼리의 대기 결과가 false일 때만 `h.app.debugDescription`을 `widget-entry-alert-tree` 이름의 keepAlways 첨부로 남긴다. 첨부 뒤 동일한 true 기대를 검증한다. 공용 helper와 다른 테스트 본문은 유지했으며, 실행 및 생산 코드 열람은 하지 않았다. 원인은 아직 확정하지 않았다.

### 실제 AX 증거에 따른 공용 alert 조회 수리

`/tmp/w18-alert-tree/9DB73CC5-0D59-467E-93BF-82B2B4621831.txt:59–81`을 직접 읽었다. 시스템 Alert 제목과 두 Button의 정확한 label은 존재하지만 두 Button 모두 identifier 속성이 없다. 따라서 ID+label 교집합만 사용하는 기존 공용 조회는 보이는 정상 버튼을 찾지 못한다.

`UITestLaunchSupport.alertButton`은 ID+정확한 label 매칭이 1개면 이를 우선하고, 0개일 때만 앱의 alert가 정확히 1개이며 그 안에 정확한 label의 Button이 정확히 1개인 경우 대체 조회한다. 복수 alert/복수 label에는 fallback하지 않으며 ID 중복도 임의 firstMatch로 선택하지 않는다. 기존 helper를 쓰는 다른 시스템 alert 테스트에도 같은 AX 누락 조건이 적용되므로 공용 helper에서 보완했다. 신규 WidgetEntry 테스트 본문·label·취소 동작·저장 바이트 기대는 변경하지 않았다. 생산 코드 열람이나 테스트 실행은 하지 않았으며 후속 GREEN은 미확인이다.
