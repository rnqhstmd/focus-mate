# 설계: W17 시스템 시간 기반 Live Activity

## 설계 규모
중형. 선택적 총 시간·순수 표시 모델·네 시스템 표면·테스트를 변경한다. 아래 PRD 변경은 2026-10-16 사용자 “ㄱㄱ”으로 승인되었고 prd.md에 반영했다.

## 승인된 PRD 변경

| 항목 | 기존 승인 PRD | 제안 |
|---|---|---|
| compact 장시간 | 120:00→2h, 360:00→6h | 모든 길이에 시스템 M:SS 카운트다운. 120:00·360:00도 유지 |
| 눈금 위 버스 | 진행률에 따라 현재 위치 표시 | 버스를 트랙 시작 옆 고정 여정 심볼로 사용. 현재 진행은 시스템 선형 진행 막대가 표시 |
| 일시정지 | 버스 위치 고정 | 진행 채움과 시간 고정. 버스는 위치 마커로 사용하지 않음 |
| AC-1·2 | 비율과 버스 좌표 | 같은 비율·native progress 날짜 범위·paused 값 검증. 버스 좌표 요구 제거 |
| AC-4 | compact 2h·6h | compact 120:00·360:00. 실제 공간의 가독성·잘림은 별도 검증 |

이유: 날짜 기반 ProgressView의 custom style은 지원되지 않으며 fractionCompleted도 nil이다. 자동 채움과 과거 버스 좌표가 같은 눈금에서 다른 진행량을 나타내는 설계를 피한다. 임의 HhMM 문자열이 백그라운드에서 시작 표본으로 고정되는 문제를 피한다. iOS17을 유지하며 iOS18 TimeDataSource 포맷을 추가하지 않는다.

## 요구사항·수용 기준

승인 PRD의 R1~3, BR1~6, QE1~2와 AC1~5를 위 제안 차이 외에는 유지한다. 시간·상태·전체 이름·정지 시간 제외·백그라운드 시간 진행·상태 변경 기반 동기화·stale fallback·정상 완료 immediate 종료는 보존한다. 총 시간 누락/0/음수이면 진행 표시를 생략한다. W09b/W18·저장 스키마·타이머 권위는 변경하지 않는다.

## 변경 범위·컨벤션

- 수정: ios/Shared/JourneyActivityAttributes.swift, JourneyActivityDisplay.swift.
- 수정: ios/FocusMate/JourneyLiveActivityPolicy.swift, JourneyLiveActivitySync.swift.
- 수정: ios/FocusMateWidgets/JourneyLiveActivityWidget.swift.
- 테스트: 기존 Display/Policy/Sync와 필요 시 Cleanup, 신규 JourneyActivityPresentationTests.swift.
- 신규 DEBUG 미리보기: ios/FocusMateWidgets/JourneyLiveActivityPreviews.swift.
- 기존 Swift5/iOS17, Foundation 순수 enum 함수·Equatable 값, MainActor sync, XCTest·고정 Date·수동 clock·recording gateway 관례. 동기화 폴더로 파일 등록.
- Controller/Gateway/앱 저장 스키마/홈 위젯/App Group은 변경하지 않는다.

## 상세 설계

### 1. 공유 상태·호환

ContentState에 totalSeconds:Int? 추가, immutable attributes 유지.
`init(status: JourneyActivityStatus, endDate: Date?, pausedRemainingSeconds: Int?, totalSeconds: Int? = nil)`.
기존 JSON 누락/null은 nil로 복원하고 시간/상태만 표시한다. 같은 journey 활동 재사용과 launch cleanup update로 total을 보강한다. 앱 저장 migration·schema version·강제 Activity 재생성은 추가하지 않는다. 기존7필드 제한 검사는 추가 필드만8로 바꾸고 카드·할 일·태그 미포함을 보존한다.

### 2. 정책·동기화

`request(status: JourneyTimerController.Status, remainingSeconds: Int, now: Date, totalSeconds: Int? = nil) -> JourneyActivityRequest?`.
`pausedRequest(remainingSeconds: Int, totalSeconds: Int? = nil) -> JourneyActivityRequest`.
Sync가 journey.totalSeconds를 보관·전달하며 launchPlan도 total을 전달한다. running의 end/stale은 now+remaining, paused는 nil end/stale·고정 잔여, arrived는 nil 요청으로 기존 종료. SentKey·observer 빈도·거절 재시도 없음·재사용/다른 활동 정리는 그대로다. resume의 새 endDate로 정지 경과를 제외한다.

### 3. 통합 표시 모델

기존 JourneyActivityTimeContent의 countdown(ClosedRange<Date>)/fixed(String) 유지.
새 JourneyActivityProgressContent:Equatable: timer(ClosedRange<Date>), fixed(Double), hidden.
새 JourneyActivityPresentation:Equatable: status:JourneyActivityStatus, time:JourneyActivityTimeContent, progress:JourneyActivityProgressContent, statusSymbol:String.
`presentation(state: JourneyActivityAttributes.ContentState, isStale: Bool, now: Date) -> JourneyActivityPresentation`.
`remainingSeconds(state: JourneyActivityAttributes.ContentState, isStale: Bool, now: Date) -> Int`.
`progressFraction(state: JourneyActivityAttributes.ContentState, isStale: Bool, now: Date) -> Double?`.

같은 렌더에서 now를 한 번만 채취한다. sampledTimeText와 별도 접근성 timeContent 인자는 없다.
paused는 stale보다 우선한다. 시간 fixed M:SS·진행 fixed 값.
stale running/arrived/missing-end running은 arrived·fixed 도착했어요·progress hidden으로 정규화한다. 기존 timeContent/displayStatus도 같은 규칙을 사용해 문구/심볼/낭독이 다르지 않게 한다.
정상 running 시간은 안전 범위 min(now,end)...end. 유효 total이면 progress timer=(end-total)...end, 아니면 hidden.
잔여 초는 running max(0,Int(ceil(end-now))), paused max(0,pausedRemaining??0). 유효 total의 비율은 clamp(1-Double(remaining)/Double(total),0…1). 수치 함수는 단위 검사·정적 paused 렌더에 쓰며 running 화면/접근성의 고정 퍼센트로 쓰지 않는다.

### 4. 실제 표면

running 시간은 모든 표면에서 Text(timerInterval:countsDown:true,showsHours:false). compact의56pt를 절대 계약으로 두지 않고 가변 폭·고정폭 숫자·제한된 축소로 M:SS를 보존한다. 360:00 가독성과 잘림은 실제 화면 검사 대상이다.
확장 leading 노선, trailing 시간, bottom 눈금·목적지·상태, 카메라 영역 비우기.
running 진행은 ProgressView(timerInterval:countsDown:false)의 기본.linear, paused는 ProgressView(value:)의 fixed 채움. 눈금은 정적 장식으로 정렬하고 custom ProgressViewStyle은 쓰지 않는다.
버스는 트랙 바깥 leading의 고정 여정 심볼. 현재 위치/퍼센트를 암시하는 overlay 없음. 상태별 bus/pause/checkmark는 한 번만 제공하며 SF Symbol 지원은 빌드/미리보기에서 확인한다.
lock은 상세 정보만·눈금 없음. compact는 상태 심볼과 M:SS, minimal은 시각적으로 상태 심볼만. stale는 도착 상태·문구로 바꾸고 진행 막대를 제거한다.
차콜·오프화이트·반복 앱 아이콘/장식 곡선 없음. custom 이동 애니메이션을 추가하지 않아 Reduce Motion 전후 정보가 같다.

### 5. 접근성

`accessibilitySummary(attributes: JourneyActivityAttributes, presentation: JourneyActivityPresentation) -> String`.
summary는 전체 노선·종류·목적지·상태만 담고 어느 상태에서도 잔여 숫자를 합성하지 않는다. 시간 renderer와 접근성 시간 renderer가 같은 presentation.time을 사용한다.
expanded/lock/compact: summary 한 요소·시간 한 요소. running은 native timer Text 자체를 노출하며 고정 accessibilityValue로 덮지 않는다. paused는 fixed M:SS 한 번. arrived는 summary의 도착만 읽고 안내 시간 요소는 숨긴다.
minimal: Image에 summary를 label, 같은 native timer Text를 accessibilityValue(Text)로 제공하는 후보를 검증한다. paused는 fixed time, arrived는 잔여 없음.
이 API의 timer가 실제 Live Activity에서 동적으로 낭독되는지는 SDK 빌드와 실제 VoiceOver 게이트다. 실패하면 정적 시간으로 대체하지 않는다. 별도 native timer 접근성 요소를 노출하면서 시각 심볼만 유지하는 조정 경로를 확인한다. 구현/장치 근거 없이 접근성 완료를 주장하지 않는다.
눈금·진행 막대는 접근성에서 숨기고 시간으로 진행 맥락을 전달한다. 표본 퍼센트와 실시간 시간을 동시에 읽지 않는다.

## 의존성·영향

새 라이브러리 없음. iOS17 API 경로를 사용하고 매초 ActivityKit update를 추가하지 않는다. 시스템 렌더 빈도·실제 VoiceOver 갱신은 자동 단위 검사와 구분한다. legacy JSON·재사용·cleanup·즉시 종료 회귀를 검증한다.

## 구현 순서 / 격리 RED 계약

0. PRD·설계 변경 사용자 승인 완료.
1. T1 (AC1~3 데이터 전달): ContentState·Policy·Sync 및 해당 XCTest. 총 시간·JSON 호환·pause/resume·추가 갱신 없음·기존 종료 계약.
2. T2 (AC1~5 표시): Display·Widget·신규 PresentationTests·DEBUG 미리보기. native/fixed/hidden·전체 이름·네 표면·접근성. 시각 및 실제 VoiceOver 증거는 별도 기록.

두 태스크는 순차 실행하며 생산/테스트 파일을 겹치지 않는다. 기존 DisplayTests는 T2만 소유한다. 같은 컴포넌트의 AC는 묶는다. 각 태스크는 RED→IMPLEMENT→검증→조건부 리뷰를 수행한다.
고정 now=Date(timeIntervalSince1970:1791882000), total1800,end=now+1122또는135. 기댓값 literal progress0.3766667/0.925, 60초 후1062·0.41; pause300초 뒤 동일.
running progress 범위=(end-1800)...end, 시간 end 불변·경과만으로 Sync 추가 요청0. resume는 새 now+1122 end. nil/0/-1 total→hidden, 잔여1900/-5→0/1. legacy literal JSON 누락/null 복원.
missing-end/stale/arrived→같은 arrived·도착·hidden. compact 별도 포맷 함수 없음. paused5/599/5999/7200/21600초→0:05/9:59/99:59/120:00/360:00. summary에는 전체 이름/상태, 잔여 없음; 시간 소유자는 presentation.time 한 곳.
Sync Rig에 minutes 인자를 추가해30분 fixture, 수동 clock·recording gateway만 사용. 명령 python3 scripts/check-ios.py test {files}. 한 번에 빌드/테스트 하나. 스타일 속성 assert 대신 미리보기/캡처 비교, 실제 Island·lock·VoiceOver는 별도 기록.

## 공식 규격 근거

- https://developer.apple.com/documentation/swiftui/progressview/init(timerinterval:countsdown:)
- https://developer.apple.com/documentation/swiftui/progressviewstyleconfiguration/fractioncompleted
- https://developer.apple.com/documentation/swiftui/text/init(timerinterval:pausetime:countsdown:showshours:)
- https://developer.apple.com/documentation/widgetkit/animating-data-updates-in-widgets-and-live-activities

## 확인이 필요한 사항

2026-10-16 사용자 “ㄱㄱ” 승인 기록. 나머지 저장·진행·완료·범위는 보존한다.

## Testability 평가 (test-architect)

### 컴포넌트별 테스트 전략

| 컴포넌트 | 레이어·러너·격리 전략 | AC |
|---|---|---|
| ContentState | 동작·XCTest. 실제 Codable 누락/null/정상 값과 외부 JSON 계약. 외부모의·앱 저장 migration 없음 | AC3 |
| Policy·Sync | 동작·XCTest. 고정Date·ManualJourneyClock·FakeProgressSaver·RecordingLiveActivityGateway로 payload·호출수 관찰 | AC1~3 |
| Presentation/remaining/progress | 동작·XCTest. 주입 now·독립 literal 기대값, countdown/fixed 및 timer/fixed/hidden, missing-end/stale/paused 정규화 | AC1~4 |
| AccessibilitySummary | 동작·XCTest. 전체 이름·상태 보존, 잔여 숫자 중복 없음. 단일 presentation.time 사용 | AC4~5 |
| 표면 렌더 분기 | 동작 경로는 빌드/미리보기/실제 렌더링. native/fixed/arrived 시간 요소 연결을 확인 | AC1~5 |
| 색·눈금 간격·glyph·폰트 | 표현 — 단위 assert 대상 아님. 승인 시안과 실제 캡처를 대조 | 시각 검증 |

### 격리 RED 데이터

total1800, remaining1122/135→0.3766667/0.925; 시간 범위min(now,end)...end·진행 범위(end-1800)...end; 60초 후1062·0.41·추가gateway요청0; pause300초후불변·resume새종료시각; nil/0/-1total hidden;1900/-5remaining0/1; 소수초ceil; legacy누락/null; missing-end/stale/arrived; stale paused; fixed5/599/5999/7200/21600→0:05/9:59/99:59/120:00/360:00.
생산 포맷으로 expected 생성·sleep 금지. 새 계약 승인 후 HhMM 전용 테스트는 만들지 않는다. native 타이머의 실제 장시간 표시는 범위 단위 테스트와 렌더 검증을 나눈다.

### 런타임 검증 게이트

- compact120:00/360:00의 실제 가독성·잘림.
- native 진행 채움의 실제 갱신·정지·재개.
- minimal Image.accessibilityValue(nativeTimerText)의 SDK 수용·시간 경과 후 재낭독. 실패 시 별도 native 시간 요소를 검증하며 정적 잔여로 대체하지 않는다.
- 모든 표면 running/paused/arrived의 실제 이름·상태·시간 단일 낭독.
- Reduce Motion 전후 실제 정보 보존. 입력 없는 pure함수 두 번 비교로 설정 검증을 대체하지 않는다.

### Testability Score: 8/10

조건부 TESTABILITY PASS. 테스트 가능성은 충족하며 PRD 변경 승인 조건은 해소되었다. 실제 SDK·렌더·VoiceOver 통과는 아직 주장하지 않는다. 이번 평가에서 테스트·빌드·파일 수정을 하지 않았다.
