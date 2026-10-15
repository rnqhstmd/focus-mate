# 설계: W09a 하차 태그·요약·기록·메모 (+ 마이페이지 큰 글자 회귀)

설계 규모: 대형. PRD AC-1~34. 저장 형식 v4 불변. architect 초안 기준(2026-10-15).

## 변경 범위
신규(ios/FocusMate): JourneyAlighting.swift, AppModel+Alighting.swift, ArrivalBriefingController.swift, ArrivalBriefingView.swift, CardTagScreen.swift, AlightingTagView.swift, AlightingSummaryView.swift, RecordMemoDraft.swift, RecordsCalendar.swift, RecordsView.swift, RecordMemoEditor.swift
수정: AppModel.swift(Destination .alighting/.alightingSummary, alightingSummary 메모리 상태, init recordClock, open/goBack 가드), AppModel+JourneyLifecycle.swift(confirmNewJourney 도착 거부, mainMenuDestinations), RecordSection.swift(RecordMemoLimit 추출, 동작 불변), BoardingTagController.swift(commit 클로저 일반화, CardTagCopy, finishesAfterInterruption), BoardingTagView.swift(CardTagScreen(spec:.boarding), 식별자 불변), JourneyView.swift(도착 안내 오버레이·생명주기), JourneyTimerView.swift(journey.arrived 2곳 제거), JourneyServices.swift(JourneyAlighting, ArrivalConfirming 채택), ActiveJourneyCardContent.swift(showsAlight), MainActiveJourneyView.swift(open.alighting), RootView.swift(메뉴 필터·beginAlighting), DestinationScreen.swift(.alighting/.alightingSummary/.records), UITestBootstrap.swift(시드 4종)
영향 없음(확인): JourneyLiveActivityPolicy/Sync/Cleanup, AppModel+Profile, SnapshotCodec

## 컨벤션
- 저장: 최신 snapshot → 순수 updating/ending → save 또는 saveHandlingFailure(AppModel.swift:209, 화면 내 실패 안내 시 일반 saveFailure 미설정, W07).
- 결과: LifecycleActionResult(done/rejected/saveFailed). 연타는 시간 아닌 상태(path·active)로 차단.
- 확장 AppModel+기능.swift, 저장 프로퍼티는 본문(abandonNotice 선례).
- 컨트롤러: @MainActor @Observable final class, @ObservationIgnored 의존, sleep 주입, 프로토콜 경계.
- 식별자: screen.<이름>, <화면>.<요소>. DEBUG 진단 test.<이름> JSON(accessibilityValue). #if DEBUG.
- 문구 enum 집중. 저장 실패 문구 JourneyTimerDisplay.transitionFailureText("저장하지 못했어요. 다시 눌러주세요.").

## 컴포넌트

### 1. JourneyAlighting.swift (순수)
```swift
enum AlightingIssue: Error, Equatable { case noActiveJourney, notArrived, unknownCatalog }
extension AppSnapshot {
    func alightingActiveJourney(completedAt: Date, timeZone: TimeZone) throws -> (snapshot: AppSnapshot, record: RecordCompletionInput)
}
extension RecordCompletionInput { init?(alighting journey: JourneySnapshot, completedAt: Date) }
extension PreparationTagColor { var recordHex: String }  // sand #d7b378, blue #82aaf2, purple #b49ce1, green #91b9ab, pink #d596a6
struct RecordClock { var now: () -> Date; var timeZone: () -> TimeZone; static let live: RecordClock }
```
- endingActiveJourney(at:) + RecordSection.recordingCompletion 합성 → 한 후보(BR-3). 미도착 → .notArrived. 도착지 = reachedStation(방향 유지).
- 필드: id=journey.id, completedAt=UTC ISO8601 밀리초 24자(RecordDates.instant), bus=bus.number, tag=tag.name, tagColor=recordHex, task, minutes, sound=sound.title, from=originName, to=destinationName, date=localKey(timeZone:)(BR-5).

### 2. AppModel+Alighting.swift
```swift
@MainActor protocol JourneyAlighting: AnyObject { func alightJourney() -> Bool }
@MainActor protocol ArrivalConfirming: AnyObject { func confirmArrival(timerArrived: Bool) -> LifecycleActionResult }
struct AlightingSummary: Equatable { let recordID, task, destinationName: String; let minutes: Int; var minutesText: String } // ProfileTimeText.display "25 min"
extension AppModel: JourneyAlighting, ArrivalConfirming {
    func beginAlighting() -> LifecycleActionResult        // .ready(.main), path.isEmpty, active.isArrived → path=[.journey], 저장 없음
    func confirmArrival(timerArrived: Bool) -> LifecycleActionResult // timerArrived, path.last == .journey, active.phase == .departed; 저장본 미도착이면 saveHandlingFailure로 (총 시간, paused) 재저장, 실패 .saveFailed; path.append(.alighting); 연타 .rejected
    func alightJourney() -> Bool                          // path.last == .alighting, active.isArrived; recordClock으로 후보 → saveHandlingFailure; 성공 시 alightingSummary 설정; 이후 호출 false
    func finishAlightingTransition()                      // path.last == .alighting && alightingSummary != nil → path=[.alightingSummary]
    func finishAlightingSummary(memo: String) -> LifecycleActionResult // 다듬어 비면 저장 0회; 아니면 updateRecordMemo; 성공 시 alightingSummary=nil, path=[]; 실패 .saveFailed 상태 불변
    func updateRecordMemo(_ memo: String, forJourneyID id: String) -> LifecycleActionResult // saveRecordMemo 후보 계산 헬퍼 재사용, saveHandlingFailure, 변경 없으면 .done
    var mainMenuDestinations: [Destination]               // 도착 여정이면 .preparation 제외
}
```
- AppModel.swift: Destination .alighting("하차 태그"), .alightingSummary("요약"); `var alightingSummary: AlightingSummary?`(메모리, Alighting 확장에서만 설정; 재실행 시 소멸 AC-13); `init(..., recordClock: RecordClock = .live)`; open(_:)은 .alighting/.alightingSummary 불가, activeJourney?.isArrived면 .time/.preparation/.board/.boarding 거부(BR-6); goBack은 path.last가 .alighting/.alightingSummary면 거부.
- JourneyLifecycle.confirmNewJourney: active.isArrived면 .rejected. 기존 saveRecordMemo 유지(W08).

### 3. ArrivalBriefingController.swift
```swift
struct ArrivalBriefingContent: Equatable {
    let routeText: String     // "2014 · 서울숲 입구 도착"
    let sentences: [String]   // ["곧 서울숲 입구에 도착합니다", "버스가 멈추면 일어나주세요", "카드를 찍고 내려주세요"]
    init?(journey: JourneySnapshot)
}
@MainActor @Observable final class ArrivalBriefingController {
    enum FocusTarget: Equatable { case confirmButton }
    let content: ArrivalBriefingContent
    private(set) var visibleIndex: Int
    private(set) var showsAll: Bool
    private(set) var showsConfirm: Bool
    private(set) var showsSaveFailure: Bool
    private(set) var focusTarget: FocusTarget?
    init(content: ArrivalBriefingContent, confirmer: ArrivalConfirming,
         interval: Duration = .milliseconds(1700), sleep: @escaping (Duration) async -> Void = ...)
    func begin(reduceMotion: Bool) async
    func reset()
    @discardableResult func confirm(timerArrived: Bool) -> LifecycleActionResult
}
```
- DepartureBriefingController와 같은 규칙(1.7초, 마지막 유지, 동작 줄이기면 한꺼번에). 출발 컨트롤러는 미변경.

### 4. BoardingTagController 일반화
- 내부 의존 `commit: @MainActor () -> Bool`. 기존 init(boarder:...) 유지(감싸기) → BoardingTagControllerTests 무수정.
```swift
struct CardTagCopy: Equatable {
    let recognizedAnnouncement, failedAnnouncement: String
    static let boarding: CardTagCopy
    static let alighting: CardTagCopy  // "집중동행카드 인식됨, 하차했습니다" / transitionFailureText
}
init(alighter: JourneyAlighting, haptics:, announcer:, geometry: = .init(), timing: = .standard, sleep:, holdSleep:, onFinished:)
// copy = .alighting, finishesAfterInterruption = true
```
- finishesAfterInterruption: returnToForeground()에서 .abandoned이면 phase=.finished, onFinished() 호출(저장 성공 후 백그라운드 복귀 시 요약으로).
- BoardingGeometry/Timing(30%, 300/1400/450ms) 재사용. 기존 static 문구는 .boarding 값으로 호환.

### 5. CardTagScreen.swift / AlightingTagView.swift
- BoardingTagScreen(BoardingTagView.swift:31) → CardTagScreen(model:services:controller:spec:).
- CardTagScreenSpec: idPrefix "boarding"/"alighting", screenID "screen.boarding"/"alighting.tag", title, readyLCDText "승차 준비"/"하차 준비", cardHint, failureText, hidesBackButton(하차 true: navigationBarBackButtonHidden + NavigationPopBlocker), focusesCardOnAppear(하차 true, AC-6), debugActivateID test.activateBoardingCard/test.activateAlightingCard. 승차 spec은 기존 식별자·문구 동일.
- LCD 인식 시 PassIdentity.displayName + 체크만(AC-7). 터치 안내 <prefix>.tapHint(AC-8).
- AlightingTagView: 컨트롤러 1회 생성, onFinished → model.finishAlightingTransition(). DEBUG test.alighting.failNextSave.

### 6. 여행 화면 도착 안내 (JourneyView.swift, ArrivalBriefingView.swift)
- @State arrival: ArrivalBriefingController?, ensureTimer() 직후 생성.
- timer.status == .arrived: 기존 JourneyTimerView는 .accessibilityHidden(true).allowsHitTesting(false), 위에 ArrivalBriefingView(alighting.route, alighting.sentence, alighting.confirm, alighting.saveFailure, 표지 alighting.briefing).
- 지도 도구·테마 시트는 오버레이 아래(BR-7, AC-23). 계산 도착지와 다르면 CourseJourney nil. 일시정지·포기는 arrived에서 이미 없음(AC-22).
- .task(id: timer?.status) arrived → arrival.begin(reduceMotion:). scenePhase background → reset, active 복귀 시 확인 미노출이면 begin. 타이머 enterBackground/retryArrivalIfNeeded 유지.
- focusTarget .confirmButton → @AccessibilityFocusState. JourneyTimerView .arrived 분기 journey.arrived 텍스트 제거. DEBUG test.arrivalBriefing JSON(index, showsAll, showsConfirm, focus).

### 7. AlightingSummaryView.swift
- model.alightingSummary: summary.task, summary.minutes("25 min"), summary.destination, TextField(axis: .vertical) summary.memo, summary.memoCounter, summary.home, summary.saveFailure, 표지 screen.alightingSummary.
- @State RecordMemoDraft, Binding(set: draft.update). 메인으로 → finishAlightingSummary(memo: draft.text), .saveFailed면 입력 유지·안내. ScrollView, 뒤로 숨김, NavigationPopBlocker. DEBUG test.summary.failNextSave.

### 8. RecordMemoDraft.swift / RecordMemoLimit
```swift
enum RecordMemoLimit { static let maxUTF16 = 200; static func prefix(_ text: String) -> String }
struct RecordMemoDraft: Equatable {
    private(set) var text: String
    init(text: String = "")
    mutating func update(_ input: String)   // prefix만
    var counterText: String                 // "N / 200"
    var savedValue: String                  // trim 후 prefix
    var isBlank: Bool
}
```
- RecordSection.updatingMemo(RecordSection.swift:71-79) 반복문 → RecordMemoLimit.prefix(동작 동일).

### 9. RecordsCalendar.swift (순수)
```swift
struct RecordDay: Hashable, Comparable { let year, month, day: Int; init?(key: String); var key: String
    static func from(_ date: Date, timeZone: TimeZone) -> RecordDay; static func january1(_ year: Int) -> RecordDay }
enum RecordHeatLevel { static func level(minutes: Int) -> Int }   // 0 / 1~30 / 31~60 / 61~120 / 121+
struct RecordDayCell: Equatable, Identifiable { let day: RecordDay; let count, minutes, level: Int; let isFuture, isToday: Bool
    var accessibilityLabel: String }  // "10월 15일 · 1회 · 25분"
struct RecordYearSummary: Equatable { let count, days, minutes: Int; var text: String } // "N회 여행 · N일 · 1 h 5 min", 0분이면 "0회 여행 · 0일"
enum RecordsCalendar {
    static func leadingBlanks(year: Int) -> Int
    static func cells(year: Int, records: [RecordSnapshot], today: RecordDay) -> [RecordDayCell]
    static func summary(year: Int, records: [RecordSnapshot], today: RecordDay) -> RecordYearSummary
    static func records(on day: RecordDay, in records: [RecordSnapshot]) -> [RecordSnapshot]   // completedAt 최신순
    static func latestRecordDay(year: Int, records: [RecordSnapshot], today: RecordDay) -> RecordDay?
    static func yearOptions(records: [RecordSnapshot], today: RecordDay, selectedYear: Int) -> [Int]
}
enum RecordsEmptyState: Equatable { case noRecords, noRecordsOnDay }
struct RecordsBrowser: Equatable {
    static let pageSize = 10
    let today: RecordDay
    private(set) var year: Int, selectedDay: RecordDay, listLimit: Int
    init(today: RecordDay)
    @discardableResult mutating func select(_ day: RecordDay) -> Bool   // 미래 거부, limit 10 리셋
    mutating func moveYear(by delta: Int, records: [RecordSnapshot])
    mutating func selectYear(_ year: Int, records: [RecordSnapshot])
    var canGoNextYear: Bool; var canGoPreviousYear: Bool
    mutating func showMore()
    func visibleRecords(in: [RecordSnapshot]) -> [RecordSnapshot]
    func hasMore(in: [RecordSnapshot]) -> Bool
    func emptyState(records: [RecordSnapshot]) -> RecordsEmptyState?
}
struct RecordListItemContent: Equatable { init(record: RecordSnapshot, timeZone: TimeZone)
    let task, minutesText, timeText, routeText, tag, memo: String; var memoButtonTitle: String } // "메모 남기기"/"메모 수정"
```
- 오늘 이후 기록은 집계 제외. 연도 변경 시 선택일: 올해면 오늘, 아니면 그 해 최근 기록일, 없으면 1/1.

### 10. RecordsView.swift / RecordMemoEditor.swift
- 오늘은 model.recordClock. records.year.previous / records.year.next / records.year.picker / records.summary. 잔디 가로 ScrollView 7행×주, 셀 records.day.<yyyy-MM-dd>(낭독 cell.accessibilityLabel, 미래 .disabled). 목록 records.item.<id>, records.memo.<id>, 더 보기 records.more. 빈 안내 records.empty.
- 메모 시트: recordMemo.field / recordMemo.counter / recordMemo.save / recordMemo.cancel / recordMemo.saveFailure. 저장은 updateRecordMemo, 실패 시 시트·입력 유지.
- 예시 경로 없음(AC-31). DEBUG test.records JSON(year, selected, visibleCount, hasMore), test.records.failNextSave.

### 11. 메인 도착 카드
- ActiveJourneyCardContent.showsAlight(kind == .arrived). ActiveJourneyCardView(content:onResume:onAlight:) arrived면 하차하기(open.alighting, 44pt) 하나.
- RootView ForEach(model.mainMenuDestinations), 하차하기 → apply(model.beginAlighting()), newJourneyConfirmation은 미도착 여정만. JourneyLifecycleText.alightButton = "하차하기".

### 12. W15 Live Activity — 코드 변경 없음
- 도착: Policy.request(.arrived) nil → Sync 종료(Policy:43, Sync:33-36). 도착 재실행: launchPlan isArrived 전부 종료(:60, FocusMateApp:118). 하차 후 journey nil → 전부 종료. 검증만 추가.

### 13. DEBUG 시드
- alightPaused1499, alightArrived: 2014번 25분, 성수역→서울숲 입구(정방향), 태그 독서(sand), 할 일 "논문", 현재 정류장 성수역, 기록 0. lifecycleSnapshot 일반화(할 일·기록 인자).
- recordsMemo: 오늘 기록 2건(memo "" / "집중 잘됨"). recordsTwoYears: 올해 오늘 1건 + 작년 3월·6월 각 1건.

## 데이터 흐름
도착 arrive() 1회 저장(AC-3) → Live Activity 종료(AC-5), arrival.begin → 확인 confirmArrival → path [.journey, .alighting] → 태그 recognize → 300ms → commit → alightJourney → saveHandlingFailure 1회 → 성공 시 summary, 1400+450ms 뒤 finishAlightingTransition → [.alightingSummary] / 실패 시 상태 불변·재태그 → 메인으로 finishAlightingSummary → path [] → 재실행 시 요약 소멸. 도착 여정 재진입: 카드 하차하기 → beginAlighting → [.journey]. 기록 화면: snapshot.records + RecordsBrowser + RecordsCalendar, 메모 updateRecordMemo, 마이페이지 ProfileStats.from 자동(AC-32).

## 의존성 및 영향도 — 기존 구조와의 차이
| 차이 | 근거 |
|---|---|
| open()으로 열 수 없는 Destination 2개 | 진입 조건이 도착 저장·메모리 요약에 묶임(BR-6, AC-21). finishBoardingTransition 선례 |
| 메모리 상태 alightingSummary | AC-13을 저장 형식 변경 없이. isHoldingIssuedCard 패턴 |
| init recordClock | BR-5·기록 '오늘' 결정적 테스트. ActiveJourneyFactory(now:) 선례 |
| BoardingTagController 클로저 + CardTagScreen 추출 | FR-3 재사용, 승차 API·식별자 불변 |
| updateRecordMemo(LifecycleActionResult) | AC-20 화면 내 실패 안내, W07 규칙. saveRecordMemo 유지 |

동작 변경: 도착 여정 새 여정 시작 제거, journey.arrived 제거, 도착 타이머 화면 접근성 숨김.
갱신 대상 테스트: JourneyLifecycleModelTests.swift:283(done→rejected), ActiveJourneyCardContentTests.swift:50, MainActiveJourneyCardUITests.swift:86,95, NewJourneyUITests.swift:312,325(폐기·대체), journey.arrived 7곳(JourneyTimerUITests:138,150,192, JourneyTimerLifecycleUITests:107, JourneyAbandonUITests:99,395, JourneyMapUITests:176) → alighting.briefing, 도착 후 타이머 값·도구 3건(JourneyMapUITests:172, 257-259, JourneyTimerAccessibilityUITests:26) → 도착 안내 기준.

## 구현 순서
1. T1 순수 하차 저장 — AC-10(데이터), AC-28, BR-2/3/5. 신규 JourneyAlighting.swift. 테스트 AlightingSnapshotTests.swift
2. T2 메모 제한 — AC-18, AC-19, BR-4. RecordSection.swift, RecordMemoDraft.swift. 테스트 RecordMemoDraftTests.swift(+회귀 RecordSectionTests)
3. T3 도착 안내 컨트롤러 — AC-1, AC-2. ArrivalBriefingController.swift. 테스트 ArrivalBriefingControllerTests.swift
4. T4 태그 컨트롤러 일반화 — AC-8, AC-9, AC-11. BoardingTagController.swift. 테스트 AlightingTagControllerTests.swift(+회귀 BoardingTagControllerTests)
5. T5 기록 계산 — AC-24(문구), AC-25, AC-26, AC-27, AC-28(셀), AC-30(문구). RecordsCalendar.swift. 테스트 RecordsCalendarTests.swift, RecordsBrowserTests.swift
6. T6 DEBUG 시드 — UITestBootstrap.swift. 테스트 LifecycleSeedTests.swift
7. T7 모델 하차·메모·가드 — AC-10~13, 16, 17, 19, 20(모델), 21(가드), 32, BR-1, BR-6 (의존 1~4). AppModel+Alighting.swift, AppModel.swift, AppModel+JourneyLifecycle.swift, JourneyServices.swift. 테스트 AlightingModelTests.swift, JourneyLifecycleModelTests.swift 수정
8. T8 여행 화면 도착 안내 — AC-1~3, 6(이동), 22, 23 (의존 3, 7). JourneyView, JourneyTimerView, ArrivalBriefingView
9. T9 하차 태그 화면 — AC-6(포커스), 7, 8, 9, 12, 14, 21(뒤로 없음) (의존 4, 7). CardTagScreen, AlightingTagView, BoardingTagView, DestinationScreen
10. T10 요약 화면 — AC-13, 15~18, 20 (의존 2, 7, 9). AlightingSummaryView, DestinationScreen
11. T11 메인 도착 카드 — AC-4, 21 (의존 7). ActiveJourneyCardContent, MainActiveJourneyView, RootView, JourneyLifecycleText. 테스트 ActiveJourneyCardContentTests 수정
12. T12 기록 화면 + 메모 편집 — AC-20(기록), 24, 29, 30, 31 (의존 2, 5, 7, 10). RecordsView, RecordMemoEditor, DestinationScreen
13. T13 흐름별 UI 테스트 7건 (의존 6, 8~12)
    - AlightingFlowUITests: ① 정상 E2E(alightPaused1499, 수동 시계: AC-1, 22, 6, 21, 8, 7, 9, 15, 17, 10, 5) ② 동작 줄이기(AC-2, AC-3) ③ 복원(alightArrived: AC-21, 4, 14, 13) ④ 실패(AC-12, 18, 20)
    - RecordsUITests: ① 빈 상태·마이페이지 0(AC-24, 31) ② 메모(recordsMemo: AC-29, 30, 20) ③ 연도(recordsTwoYears: AC-27)
    - AC-11, 16, 19, 25, 26, 28, 32는 단위만.
14. T14 Live Activity 검증 — AC-5. JourneyLiveActivityPolicyTests(하차 후 journey nil 전부 종료)
15. T15 기존 테스트 갱신(위 목록) (의존 7, 8, 11)
16. T16 문서·인계 — FLOWS, context/journey|records architecture·status, plan.md W09 인계·출시 게이트 해제
17. T-last 마이페이지 큰 글자 — AC-33, AC-34. 조사 결과(reports/profile-ac20-investigation.md): 테스트 결함. ProfileUITests.swift:280~281, 304~305의 `XCTAssertTrue(entry.isHittable, …)`를 `try reachVisible(entry, h)`로 교체, 305행 테스트에 throws 추가. 수정 후 첫 실행에서 후속 단계(내비바 겹침·3회 스와이프)에서 화면 결함이 드러나면 화면 쪽 수정 추가.

병렬: T1~T6 독립. T7 뒤 T8·T9·T11. DestinationScreen 공유로 T9 → T10 → T12. focused만 실행, 전체는 마지막 1회.

## 위험
1. JourneyView.onDisappear timer.leave() — 하차 후 saveJourneyProgress 쓰기 증가 없음을 T7에서 확인.
2. 도착 저장 실패 상태의 확인 — confirmArrival 재저장, 실패 시 오버레이 실패 안내가 유일 표시.
3. TextField 길이 제한 한 프레임 201자 가능 — 값은 항상 ≤200, UI 테스트는 값 기준.
4. 잔디 365개 버튼 접근성 부담 — W14 실기기.
5. CardTagScreen 추출 승차 회귀 — 승차 UI 테스트는 마지막 전체 실행.
6. 출발·도착 안내 로직 약 40줄 중복 — 유예.
7. UI 시드 실제 날짜 의존(자정·1/1) — 날짜 경계는 단위 테스트.
8. 도착 타이머 화면 접근성 숨김 → W05·W06 UI 테스트 3건 의도적 교체(T15).

## 가정
- bus = BusLine.number(prototype index.html:698). 연도 목록·이전 연도 하한은 프로토타입(index.html:748-749). 요약 줄 0분이면 시간 생략. 하차 LCD 대기 "하차 준비". 날짜 재선택 시 목록 10개로 리셋.

---

# 2회차 변경 (위 1회차 내용보다 우선) — design-critic MUST 1 + CONSIDER 6 + testability 보완 4 반영

## C2. AppModel+Alighting (교체)
```swift
extension AppModel: JourneyAlighting, ArrivalConfirming {
    func beginAlighting() -> LifecycleActionResult                    // 변경 없음
    func confirmArrival(timerArrived: Bool) -> LifecycleActionResult  // 재저장 안 함
    func alightJourney() -> Bool                                      // 이미 저장됐으면 성공 응답
    @discardableResult func finishAlightingTransition() -> Bool       // 하차 저장 후 모든 중단 경로의 단일 출구
    func finishAlightingSummary(memo: String) -> LifecycleActionResult
    func updateRecordMemo(_ memo: String, forJourneyID id: String) -> LifecycleActionResult
    var mainMenuDestinations: [Destination]
}
```
- confirmArrival: 가드 `.ready(.main)`, `path.last == .journey`, `timerArrived`, `active.phase == .departed` 어긋나면 .rejected. 저장본 미도착이면 .saveFailed(저장 안 함). 도착이면 path.append(.alighting) .done, 쓰기 0회. 도착 저장 재시도는 JourneyTimerController 한 곳.
- alightJourney: `path.last == .alighting && alightingSummary != nil`이면 저장 없이 true(재커밋에도 실패 안내 없이 정상 전환, AC-11 쓰기 1회 유지).
- finishAlightingTransition: 가드 path.last == .alighting && alightingSummary != nil → path=[.alightingSummary], true. 그 외 false(멱등).
- finishAlightingSummary: 성공 시 **path=[] 먼저, 그다음 alightingSummary=nil**. AlightingSummaryView는 summary nil이면 Color.clear.
- 메모 API 단일화: saveRecordMemo 삭제, updateRecordMemo 하나(AppModel.swift:250-258 후보 계산 재사용, saveHandlingFailure, 변경 없으면 쓰기 없이 .done). 준비 안 됨 .rejected(snapshotForRecordChange의 writeBlocked saveFailure 유지), 검증·쓰기 실패 .saveFailed(일반 saveFailure 미변경).
- W08 테스트 이전: RecordStorageTests.swift:21,81,176,204,272 / CardCustomizationAppModelTests.swift:156의 XCTAssertTrue/False(saveRecordMemo…) → XCTAssertEqual(updateRecordMemo…, .done/.rejected/.saveFailed). :82 유지, :274 → XCTAssertNil(model.saveFailure). 파일·snapshot 불변 단언 유지.

## C3. ArrivalBriefingController (교체)
```swift
@MainActor protocol ArrivalProgress: AnyObject { var isArrived: Bool { get }; func ensureArrivalSaved() -> Bool }
init(content: ArrivalBriefingContent, progress: ArrivalProgress, confirmer: ArrivalConfirming,
     interval: Duration = .milliseconds(1700), sleep: ...)
@discardableResult func confirm() -> LifecycleActionResult
// guard showsConfirm → _ = progress.ensureArrivalSaved() → confirmer.confirmArrival(timerArrived: progress.isArrived)
// .saveFailed면 showsSaveFailure = true, 다시 누르면 처음부터 재시도
```
- JourneyTimerController: ArrivalProgress 채택. isArrived = status == .arrived, ensureArrivalSaved()는 private retryArrivalIfNeeded()를 감싼 internal(도착 상태에서만, arrivalPersisted 반환). JourneyView는 타이머 생성 뒤 progress: timer로 컨트롤러 생성.
- 테스트: FakeArrivalProgress(1차 실패→2차 성공), FakeArrivalConfirmer.

## C4. 태그 컨트롤러 (교체) — finishesAfterInterruption 삭제
- 남는 변경: 내부 의존 `commit: @MainActor () -> Bool` 클로저, `init(alighter: JourneyAlighting, …)`(CardTagCopy.alighting). phase 전이는 승차와 동일.
```swift
enum AlightingTagRecovery {
    /// 하차 저장됨 && 늦은 전환(.contacting/.held/.fading) 진행 중 아님 → 즉시 요약
    static func shouldFinish(phase: BoardingTagController.Phase, alightingSaved: Bool) -> Bool
    // alightingSaved && ![.contacting, .held, .fading].contains(phase)
}
```

## C5. CardTagScreen / AlightingTagView (교체)
```swift
enum CardTagKind: Equatable {
    case boarding, alighting
    var idPrefix: String        // "boarding" / "alighting"
    var screenID: String        // "screen.boarding" / "alighting.tag"
    var readyLCDText: String    // "승차 준비" / "하차 준비"
    var failureText: String     // 기존 승차 문구 / JourneyTimerDisplay.transitionFailureText
    var locksNavigation: Bool   // alighting만: 뒤로 숨김 + NavigationPopBlocker + 첫 포커스 카드
}
struct CardTagScreen: View { init(model:, services:, controller:, kind: CardTagKind, title: String) }
```
- 카드 포커스 @AccessibilityFocusState cardFocused, locksNavigation이면 onAppear에서 on.
- DEBUG test.<prefix> JSON에 "focus": "card" | null (AC-6). 승차는 항상 null.
- AlightingTagView.reconcile(): AlightingTagRecovery.shouldFinish(phase: controller.phase, alightingSaved: model.alightingSummary != nil)이면 model.finishAlightingTransition()(애니메이션 없음). 호출 시점: (1) onAppear (2) scenePhase .active에서 controller.returnToForeground() 직후 (3) .onChange(of: controller.phase). 정상 경로는 onFinished → finishAlightingTransition (1400+450ms).

## C10. 기록 화면 (추가)
- 잔디: 격자 전체 접근성 요소 1개 `records.heatmap`, .adjustable, 라벨 "YYYY년 날짜별 여행 시간", 값 = 선택 칸 accessibilityLabel, increment 다음 날 / decrement 전날. 칸은 .accessibilityHidden(true), 탭(onTapGesture → browser.select), 미래 칸 탭 무시.
```swift
extension RecordsBrowser { @discardableResult mutating func stepDay(by delta: Int) -> Bool } // 선택 연도 안, 오늘 이후 거부, 성공 시 listLimit=10
```
- UI 테스트: records.heatmap increment()/decrement() + test.records selected. T12 착수 직후 스파이크로 동작 확인, 안 되면 test.records에 grid{originX, originY, cell, gap, leadingBlanks} 추가해 좌표 탭. 날짜별 DEBUG 버튼 금지.
- test.records JSON: {year, selected, visibleCount, hasMore, canNext, canPrevious}.
- RecordMemoEditor: @State draft: RecordMemoDraft(기존 메모로 초기화), Binding(get: draft.text, set: draft.update), 카운터 draft.counterText, 저장 model.updateRecordMemo(draft.text, forJourneyID:), .saveFailed면 시트·입력 유지 + recordMemo.saveFailure.

## C13. DEBUG 시드 (교체)
- alightMismatchArrived(추가): alightArrived와 같되 destinationStopID = ttukseom(뚝섬역), 도착(elapsed 1500), 기록 0 → CourseJourney nil.
- recordsMemo(변경): 오늘 기록 12건(1건 "", 1건 "집중 잘됨", 나머지 10건 ""), completedAt 1분씩 차이 → 10개, 더 보기 1회 후 12개.
- alightArrived 유지(하차→요약→메인 시작점).

## 영향도 추가
- RecordStorageTests / CardCustomizationAppModelTests 이전(T7). JourneyMapUITests.swift:172 단언 반전(T15). BoardingTagControllerTests 무수정.

## 위험 교체/추가
1. 1850ms 전환 중 activeJourney nil인 JourneyView 렌더: awaitingDeparture 옵셔널 비교 false, 타이머·지도·안내 내용은 생성 시점 값 고정, ensureTimer 기존 timer 반환, leave()는 도착 상태라 retryArrivalIfNeeded만(이미 저장, 쓰기 없음). T7 단위 + T9 코드 점검.
2. 도착 저장 실패: 확인마다 ensureArrivalSaved()로 타이머 1회 재시도, 실패 시 안내 화면 유지 + alighting.saveFailure. 저장 주체 단일.
4. 잔디 접근성 요소 1개. UI 테스트 increment() 의존 → 스파이크 선행, 대안 좌표 탭.
9. alightJourney 이미-저장 응답은 path.last == .alighting일 때만.

## 구현 순서 변경분
- T3: ArrivalBriefingController(ArrivalConfirming, ArrivalProgress). 테스트: 순서, 동작 줄이기, 확인 연타, 실패 후 재클릭 시 ensureArrivalSaved 재호출.
- T4: BoardingTagController 클로저화, CardTagCopy, init(alighter:), AlightingTagRecovery. 테스트 AlightingTagControllerTests: 터치 0회, 활성화 1회, 0.5초 내 3회 재접촉 1회, 실패 후 재태그, shouldFinish 전 phase 표, 커밋 대기 중 백그라운드→복귀→커밋 성공→phase .ready && shouldFinish true. 회귀 BoardingTagControllerTests.
- T6: 시드 alightPaused1499, alightArrived, alightMismatchArrived, recordsMemo(12), recordsTwoYears. LifecycleSeedTests: 디코드, CourseJourney(journey:) alightArrived non-nil / alightMismatchArrived nil, recordsMemo 12건.
- T7: + JourneyTimerController ArrivalProgress 채택, saveRecordMemo 제거·updateRecordMemo 통합, RecordStorageTests·CardCustomizationAppModelTests 이전. AlightingModelTests 추가: confirmArrival 미도착 .saveFailed 쓰기 0, 저장 후 alightJourney 쓰기 0 true, finishAlightingTransition 2회째 false, finishAlightingSummary path 먼저 비움, 하차 후 saveJourneyProgress false·쓰기 불변.
- T9: CardTagScreen(CardTagKind), AlightingTagView(reconcile 3시점). focused UI 회귀 함께 실행: BoardingTagUITests, BoardingFlowUITests, BoardingLargeTextUITests(존재하는 파일). 점검: JourneyView/JourneyScreen activeJourney 강제 언래핑 없음.
- T12: RecordsView(records.heatmap adjustable, 칸 탭), RecordMemoEditor(RecordMemoDraft). 착수 직후 increment() 스파이크. RecordsBrowserTests에 stepDay(미래 거부, 연도 경계, limit 초기화).
- T13: AlightingFlowUITests 6건 — ① 도착 안내→하차 태그(alightPaused1499: AC-1, 22, 6(focus card), 21, 8, 7, 9) ② 하차→요약→메인(alightArrived: AC-15, 17, 10, 5) ③ 동작 줄이기(AC-2, 3) ④ 복원(AC-21, 4, 14, 13) ⑤ 실패(AC-12, 18, 20) ⑥ 지도 생략(alightMismatchArrived: AC-23 — alighting.confirm 있음, test.map·지도 요소 없음, journey.map.follow/theme 없음 또는 비활성, 테마 시트 없음). RecordsUITests 3건 — ① 빈 상태(AC-24, 31) ② recordsMemo 12건: 10개→records.more→12개·더 보기 사라짐(AC-26), 메모 문구·수정·201자·재실행 유지·실패 입력 유지(AC-29, 30, 20) ③ recordsTwoYears(AC-27, 오늘에서 increment해도 selected 불변). 합계 9건.
- T15: + JourneyMapUITests.swift:172 반전.

---

## Testability 평가 (test-architect)

Score 8/10 ✅ TESTABILITY PASS (1회차 기준, 보완 4건은 2회차에 반영).

러너: XCTest(ios/FocusMateTests), XCUITest(ios/FocusMateUITests). `FOCUSMATE_SIMULATOR_ID=<udid> python3 scripts/check-ios.py test <files>` (메서드 단위는 xcodebuild -only-testing). 셀렉터는 accessibilityIdentifier(screen.*, <화면>.<요소>)와 보이는 문구만.

재사용 하네스: JourneyLifecycleTestDoubles.swift(FakeJourneyAbandoner, LifecycleProbe — 쓰기 횟수·실패 주입), UITestLaunchSupport.swift(launchLifecycle, writeAttempts, failNextSave, persistedState, persistedCurrentStation, persistedRecordCount, recordCount, relaunch, goBackground, waitForValue, diagnostic), RootView 진단(test.snapshot, test.writeAttempts, test.liveActivity, test.reduceMotion), BoardingTagView 진단(test.boarding, test.activateBoardingCard), DepartureBriefingControllerTests(sleep 주입 패턴), BoardingTagControllerTests(가짜 haptics/announcer/sleep).

| 컴포넌트 | 레이어 | 테스트 | 격리 | AC |
|---|---|---|---|---|
| JourneyAlighting | 동작(순수) | AlightingSnapshotTests: 기록 1건·필드 11개·completedAt 24자·recordHex, currentStation=도착지·방향 유지·journey nil, .notArrived/.noActiveJourney, 기록된 id 중복, TimeZone 고정 12/31 23:50 | 값 입출력 | 10, 28, BR-2/3/5 |
| AppModel+Alighting·가드 | 동작 | AlightingModelTests + LifecycleProbe + RecordClock 주입: 저장 1회·재호출, 실패 시 불변·재시도, 메모 0/1회·실패, open/goBack/confirmNewJourney 가드, mainMenuDestinations, 통계 3·"1 h 30 min", 재로드 summary nil | store·clock 주입 | 10~13, 16, 17, 19, 20, 21, 32, BR-1, BR-6 |
| ArrivalBriefingController | 동작 | 기록형 sleep: index 0→1→2·showsConfirm·focus, reduceMotion 즉시, reset→begin, confirm 결과별 | 프로토콜·sleep 주입 | 1, 2, 4 |
| BoardingTagController 일반화 | 동작 | AlightingTagControllerTests(가짜 alighter): 30%→300ms commit 1회, 3회 재접촉 1회, 터치 0회·tapHint, activate, false→실패 안내·재태그, 1400+450ms onFinished, 하차 인식 문구 | 가짜 재사용 | 8, 9, 11, 12, 15 |
| RecordMemoDraft/Limit | 동작(순수) | 201→200·"200 / 200", 공백→blank·"", trim, UTF-16 이모지, RecordSectionTests 회귀 | 값 | 18, 19, 29, BR-4 |
| RecordsCalendar/Browser/ListItem | 동작(순수) | 경계 0,1,2,2,3,3,4·라벨, 25건 10/20/25·select 리셋, moveYear·canGoNext·미래 거부, 12/31↔1/1, emptyState·"0회 여행 · 0일", 메모 버튼 문구, 미래 제외·leadingBlanks·윤년 | today·timeZone 인자 | 24~28, 30 |
| DEBUG 시드 | 동작(인프라) | LifecycleSeedTests: 필드·기존 시드 회귀 | — | 간접 |
| JourneyView 오버레이 | 동작+표현 | UI ①③: 순서·확인·pause/abandon/arrived 없음·recordCount 0·writeAttempts 1·focus·reduceMotion·liveActivity | 로직은 컨트롤러 | 1, 2, 3, 5, 6, 22, 23 |
| CardTagScreen/AlightingTagView | 동작+표현 | UI: alighting.tag·뒤로 없음·tapHint·LCD·failNextSave·relaunch | UITestNextSaveFailure, testRecorder | 6, 7, 8, 9, 12, 14, 21, 22 |
| AlightingSummaryView | 동작+표현 | UI: 내용·메모 저장·201자 값 기준·실패 유지·relaunch | 판단은 Draft·모델 | 13, 15~18, 20 |
| 메인 도착 카드 | 동작 | ActiveJourneyCardContentTests + UI ④ | — | 4, 21 |
| RecordsView/MemoEditor | 동작+표현 | RecordsUITests ①②③ | 판단은 Browser·Calendar | 20, 24, 26, 27, 29~31 |
| Live Activity | 동작(검증) | JourneyLiveActivityPolicyTests(journey nil 전부 종료) + UI ② | — | 5 |
| ProfileUITests | 동작 | reachVisible 교체 | — | 33, 34 |
| 표현(범위 밖) | 표현 | 잔디 색·레이아웃·카드/LCD 모양·오버레이 배치·페이드·hex 렌더 | — | — |

단위만으로 검증: AC-11, 16, 19, 25, 26(로직; 연결은 Records②), 28, 32.
