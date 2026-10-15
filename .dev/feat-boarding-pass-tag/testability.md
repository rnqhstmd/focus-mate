## Testability 평가

평가 근거로 읽은 파일은 설계서, PRD 수용 기준(AC-1~28), 코드 맵, frontend-testing.md(§2 레이어 분류, §4 셀렉터 규약)입니다. 실제 코드도 대조했습니다: `CardIssuanceController.swift`, `CardIssuanceTestDoubles.swift`, `UITestBootstrap.swift`, `UITestLaunchSupport.swift`, `LocalSnapshotStore.swift:104`.

러너 상태: XCTest 단위 테스트(`ios/FocusMateTests`)와 XCUITest(`ios/FocusMateUITests`)가 이미 있습니다. 실행 명령은 `python3 scripts/check-ios.py test <파일경로>`입니다. 동작 레이어 가운데 러너가 없는 곳은 없습니다.

결론: 7.5점으로 PASS이며, 아래 조건 6개를 붙입니다. 이 중 2건은 설계서가 제시한 검증 방법이 그대로는 성립하지 않는 결함입니다.
- AC-8: 손을 뗀 뒤에 위치를 읽는 방식이라, 그 시점이면 카드가 이미 원위치로 돌아가 있습니다.
- AC-21: 설계서가 고른 시드(진행 여정 보유)로는 승차 태그 화면까지 갈 수 없습니다.

---

### 컴포넌트별 테스트 전략

#### C1. JourneySnapshot / JourneySection / AppSnapshot.validate / SnapshotCodec (T1)
- **레이어**: 동작(상태·데이터 로직). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - JourneySnapshotTests: `boarding(details:cardID:id:boardedAt:)`가 위치·방향·시간·진도 0·할 일·태그·소리를 담고 phase가 `awaitingDeparture`인지 확인. `confirmingDeparture()`는 phase만 바꾸고 진도는 0 그대로인지 확인.
  - `ActiveJourneyValidationIssue`의 경우별 위반 테스트 10개.
  - `ActiveJourneyFactory`에 고정 `makeID`·`now`를 주입하고 초 단위 내림을 확인.
- **통합 테스트**
  - JourneySnapshotStorageTests: 실제 `LocalSnapshotStore`에 임시 파일 URL을 써서 다음을 확인.
    - 왕복 저장·읽기
    - v3 active 객체 읽기
    - v2는 null만 허용(`LegacyJourneySectionV2`)
    - `{}`·`"x"` 손상
    - 검증 위반 후보는 `invalidState`로 거절되고 파일 바이트가 변하지 않음
    - active가 null인 기존 파일은 다시 저장해도 바이트가 같음
- **모의 대상**: 없음(파일 시스템은 임시 디렉터리). 시계와 ID는 팩토리 주입.
- **격리 전략**: 값 타입과 순수 검증 함수라 완전히 격리됩니다.
- **AC 매핑**: AC-11(저장 내용), AC-19·BR-5(저장 단에서 awaiting이면 진도 0), AC-24(재실행 읽기의 근거), BR-8(필드가 단일 값)

#### C2. BoardingGeometry / BoardingTiming / BoardingClock (T2, 순수)
- **레이어**: 동작(순수 유틸). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - `overlapRatio`: 경계값 29.9%, 30%, 30.1%
  - `clampedOffset`: x=±100은 ±26으로, y가 태그 위쪽을 넘으면 `tagArea.minY - cardRest.minY`로, y=+100은 +20으로 잘리는지
  - `isTap`: 7.9와 8.0
  - `activationOffset`: 결과 위치에서 `isContact == true`이고 카드 위쪽이 태그 영역 아래쪽 가장자리 안에 있는지
  - `BoardingTiming.contact/fade(reduceMotion: true) == .zero`, hold는 1400 유지
  - `BoardingClock.text`: 고정 Date와 TimeZone(UTC, Asia/Seoul)으로 "HH:mm" 24시간 표기
- **통합 테스트**: 불필요
- **모의 대상**: 없음
- **격리 전략**: 입력이 CGRect·CGSize 값뿐입니다.
- **AC 매핑**: AC-5(HH:mm 포맷), AC-6·AC-7·AC-9 판정 계산, **AC-8 범위 제한의 주 검증 지점**, AC-10(활성 위치), AC-22(타이밍 0), BR-7

#### C3. BoardingPassContent (T2, 순수)
- **레이어**: 동작(포맷터). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - 출발·도착 이름, "12개", 거리 문자열, "지금", 날짜 `yyyy/MM/dd`(고정 now와 TimeZone)
  - 글꼴 크기 4/6/9자 경계(28/24/20/17)
  - `routeAccessibilityLabel`에 버스 번호와 분이 들어 있는지
  - 버스 번호·분이 화면용 필드(`stopsText`, `distanceText` 등)에는 들어 있지 않은지
- **통합 테스트**: 불필요
- **모의 대상**: 없음(`RouteStops`·`BusLine` 실제 카탈로그 사용)
- **격리 전략**: 순수 init입니다.
- **AC 매핑**: AC-3(값과 낭독 전용 정보). 글꼴 크기는 표현 쪽 경계이지만 규칙이 결정적이라 단위 테스트로 둬도 무방합니다.

#### C4. AppModel 확장: Destination 가드, AppModel+Boarding (T3)
- **레이어**: 동작(라우팅·가드와 상태 로직). 적합도 높음
- **러너**: XCTest
- **단위 테스트(BoardingModelTests)**
  - 진입과 가드
    - `showBoardingPass` 연타 시 path에 `.board`가 1회만 쌓임
    - 미완성이면 false, path 불변
    - `open(.board/.boarding)`은 `confirmedPreparation == nil`이면 무시, `open(.journey)`는 active가 nil이면 무시
    - `openBoarding`은 쓰기 0회
  - 승차 저장
    - `boardJourney`가 기존 active A를 B로 교체해 1건 유지
    - 저장 성공 후 `persist`가 path를 비우지 않음(launchRoute는 `.main` 유지)
    - 실패 시 snapshot 불변이고 `saveFailure`가 남음
  - 전환과 출발 확인
    - `finishBoardingTransition`은 `path == [.journey]`
    - `path.last != .boarding`이면 무시
    - `confirmDeparture`는 멱등이고 이미 `departed`면 쓰기 0
  - 메인에서 새 여행
    - `startTripFromMain`: active가 없으면 쓰기 0, 있으면 폐기 후 `.time`, 폐기 실패면 path 불변
  - records는 모든 경로에서 불변
- **통합 테스트**: 실제 `LocalSnapshotStore`(임시 파일)에 쓰기 횟수를 세는 `writeData` 클로저를 주입. 실패 시나리오는 `writeData`가 throw하도록 만듭니다(`LocalSnapshotStore`가 이미 클로저 주입을 지원하므로 새 모의 계층이 필요 없음).
- **모의 대상**: 파일 쓰기(`writeData` 클로저), `ActiveJourneyFactory`(고정 ID와 시계)
- **격리 전략**: `journeyFactory`를 기본값이 있는 init 인자로 받아 기존 호출부에 영향이 없습니다. 프로토콜 `JourneyBoarding`·`DepartureConfirming` 덕분에 컨트롤러 테스트가 AppModel 없이 돌아갑니다.
- **AC 매핑**: AC-1, AC-2(모델 단 "어떤 경로로도"), AC-4, AC-11(1건), AC-13(경로), AC-20(모델), AC-21(기존 active 불변. **이 AC의 "기존 진행 여정 포함 불변"은 여기서만 검증 가능**, 아래 지적 3 참고), AC-25, AC-26(경로), AC-27, BR-9

#### C5. BoardingTagController (T4) — 핵심 비동기 상태 기계
- **레이어**: 동작(상태 기계). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - 대역: `SuspendingSleep`(contact·fade용 1개, `holdSleep`용 1개를 따로 두어 단계를 구분), `FakeIssuanceHaptics`, `RecordingAnnouncer`, 신규 `FakeJourneyBoarder(results: [Bool], calls)`
  - **AC-6 놓기 전 인식**
    - `dragChanged`만 호출해도(`dragEnded` 없음) phase가 contacting, 햅틱 1, cardOffset이 clamp된 값
    - **불변식 테스트를 추가할 것**: `dragChanged(작은 이동)` 뒤 `dragEnded(임계를 넘는 이동)`를 보내면 인식하지 않고 원위치. 이 테스트가 있어야 UI 테스트의 "햅틱 1"이 "손 떼기 전 경로(dragChanged)로 인식됐다"는 증거가 됩니다(아래 AC-6 항목).
  - **AC-11 300ms 뒤 1회 저장**: 인식 → contact 수면 확인(`requested == [300ms]`) → `resume()` → `boarder.calls == 1`이고 phase는 held, hold 수면에서 멈춤, `onFinished` 미호출.
  - **AC-12 중복 무시**: held에서 `dragChanged`·`activate`·`dragEnded`를 보내도 calls, 햅틱, 낭독이 그대로.
  - **AC-13 전환**: hold `resume` → fading → fade `resume` → finished이고 `onFinished` 1회.
  - **세대 token 테스트(AC-14·15·16)**
    1. contacting 중 `cancelPendingTransition()` → 동기 저장으로 calls 1, phase abandoned → 남은 contact 수면 `resume` → **calls 여전히 1**(늦은 commit은 token이 달라 무효)
    2. held 중 취소 → hold `resume` → fading으로 가지 않고 `onFinished` 0
    3. fading 중 취소 → fade `resume` → `onFinished` 0
    4. dragging 중 취소 → offset `.zero`, ready, calls 0, 예약 Task 없음
    5. abandoned에서 `activate`·`drag`는 무시
  - **AC-21 저장 실패**: `results [false, true]`이면 첫 시도는 failed, `showsSaveFailure`, offset `.zero`, 실패 낭독. 다시 `activate`하면 성공해 held.
  - **AC-22 동작 줄이기**: 햅틱 0, `requested`에 300·450 없음, hold 1400은 요청됨, 낭독은 즉시.
  - **AC-9 터치**: tapSlop 미만의 `dragEnded` → `tapBounceCount` 1, `showsTapHint`, calls 0.
  - **AC-10 활성화**: `activate` → offset이 `activationOffset`이고 낭독 "집중동행카드 인식됨, 승차했습니다"가 1회.
- **통합 테스트**: 화면에서 `DragGesture` 연결은 C9 UI 테스트로.
- **모의 대상**: sleep(SuspendingSleep), 햅틱, 낭독, `JourneyBoarding`
- **격리 전략**: 생성자 주입으로 완전히 분리됩니다. 시간은 수면 주입으로 결정적입니다.
- **[필수 보완 1] 내부 Task 대기 수단이 없음**
  - 상황: 설계는 컨트롤러가 내부에서 `Task {}`를 시작합니다. token이 달라 Task가 다음 수면 없이 끝나는 경우, 테스트는 그 Task가 끝났는지 결정적으로 알 수 없습니다. `untilSuspended()`는 다음 수면이 있을 때만 쓸 수 있습니다. 그래서 위 1~3번 같은 "늦은 전환이 일어나지 않음"은 `Task.yield()`를 몇 번 돌리는 식의 비결정적 테스트가 됩니다.
  - 권고: `@ObservationIgnored private(set) var pendingTransition: Task<Void, Never>?`를 두고, 테스트가 `@testable`로 `await controller.pendingTransition?.value`를 기다리게 합니다. 이 형태를 설계 시그니처에 명시해야 합니다.
- **AC 매핑**: AC-6, 7, 8(cardOffset clamp 연결), 9, 10, 11, 12, 13, 14, 15, 16, 21, 22

#### C6. DepartureBriefingController (T5)
- **레이어**: 동작(상태 기계). 적합도 높음
- **러너**: XCTest
- **단위 테스트**
  - `begin(reduceMotion: false)`를 `Task`로 시작: index 0 → 수면(1700) → `resume` → 1 → `resume` → 2이고 `showsStart`, `focusTarget == .startButton`. 각 시점에 `showsStart == false`, `focusTarget == nil` 확인.
  - `begin(reduceMotion: true)`: 수면 요청 0, `showsAll`, `showsStart`.
  - `reset()` 뒤 index 0, `showsStart` false. 이전 begin의 수면을 `resume`해도 index가 바뀌지 않음(token).
  - `confirm()`: `showsStart` 전에는 false이고 confirmer 호출 0. 실패하면 `showsSaveFailure`이고 `showsStart` 유지, 재시도 성공.
  - AC-19: 시작을 누르지 않고 마지막 단계까지 진행해도 confirmer 호출 0. 저장 진도 불변은 C1·C4가 담당.
- **[보완 2] SuspendingSleep 대기 슬롯이 1개뿐**
  - 상황: reset 뒤 다시 begin하는 시나리오에서는 수면 두 개가 동시에 걸립니다. 현재 `SuspendingSleep`은 continuation을 한 칸에만 담아 이전 것을 덮어쓰고, 덮인 continuation은 누수 경고를 냅니다.
  - 권고: `BoardingTestDoubles.swift`에 대기열형 `QueuedSleep`(대기 목록과 `resume(at:)`)을 두거나, 이 시나리오 테스트에서만 begin마다 sleep 인스턴스를 분리합니다.
- **모의 대상**: sleep, `DepartureConfirming`(FakeDepartureConfirmer)
- **격리 전략**: 생성자 주입입니다. 일시정지 조작과 남은 시간이 화면에 없다는 점은 구조로 보장됩니다.
- **AC 매핑**: AC-17(순서·시작·포커스 값), AC-18, AC-19(호출 없음), AC-20(confirm 경로)

#### C7. JourneyServices / FocusMateApp 조립 / UITestBootstrap 확장 (T6·T7)
- **레이어**: 동작(조립과 테스트 하네스). 단위 테스트 대상이 아니라 UI 테스트의 전제 조건입니다.
- **러너**: XCUITest(간접)
- **단위 테스트**: `UITestBootstrap` 인자 파싱(`--fm-ui-boarding-hold manual`, `--fm-ui-reduce-motion on`, 잘못된 값이면 `invalidArguments`)은 기존 관례가 있으면 확장합니다(선택).
- **통합 테스트**: 모든 UI 테스트가 이 조립을 통과합니다.
- **모의 대상**: `UITestFeedbackRecorder`(햅틱·낭독), `UITestIssuanceGate`(hold), `UITestWriteCounter`, `forcedReduceMotion`
- **격리 전략**: DEBUG 인자로만 켜집니다.
- **[필수 보완 3] AC-21 UI 시나리오의 전제가 성립하지 않음**
  - 상황: 설계는 "`--fm-ui-save fail`과 `activeJourney` 시드면 기존 저장 불변을 확인할 수 있다"고 적었습니다. 하지만 active 여정이 있는 메인에서 '여행 준비'를 누르면 `startTripFromMain`이 폐기 쓰기를 하고, 이 쓰기가 실패하면 이동하지 않습니다(설계 6번). 따라서 이 조합으로는 승차 태그 화면에 도달할 수 없습니다. 게다가 전체 실패 설정이라 AC-21의 "다시 태그할 수 있다(성공)"도 보일 수 없습니다.
  - 권고: 다음 중 하나로 정합니다.
    - (a) `--fm-ui-save fail-once-boarding` 신설. `UITestCardSaveFailure`처럼 승차 저장 직전에만 arm됩니다. 시드는 `ready`. 1회차는 실패(화면 유지, 안내, `persistedBytes` 불변), 2회차는 성공해 writeCount 1.
    - (b) UI는 시드 `ready`와 전체 실패로 "전환 없음·안내·바이트 불변"만 보고, "기존 active 불변"과 "재시도 성공"은 C4·C5 단위 테스트에 맡긴다고 설계서에 명시합니다.
    - (a)를 권장합니다.
- **AC 매핑**: AC-10(`test.activateBoardingCard`), AC-12(`test.writeCount`), AC-15·AC-22(hold 게이트, 동작 줄이기 강제), AC-24 시드

#### C8. BoardingPassView / JourneyView / RootView 메인 안내 / PreparationView 연결 / DestinationScreen (T6)
- **레이어**: 화면 조립(동작 부분만 대상). 지도 배경, TicketDots, 그라데이션, 버스 아이콘, 진입 연출, 점선 깜빡임, 접촉 이동·페이드 애니메이션, 정류장 글꼴 적용, "같은 자리" 배치는 **표현이라 범위 밖**(리뷰나 시안 대조).
- **러너**: XCUITest
- **단위 테스트**: 없음(로직은 C3·C4·C6로 이동됨)
- **통합 테스트**: 아래 UI 배분 참고
- **모의 대상**: 시드, 실패 저장소, 게이트, 기록기
- **격리 전략**: 데이터 출처가 `model.confirmedPreparation` 하나라 화면 쪽 분기가 적습니다.
- **셀렉터 규약(§4)**
  - 대체로 준수합니다. 설계가 `screen.*`, `board.*`, `boarding.*`, `journey.*`, `main.activeJourney` 식별자를 쓰고, 버튼은 라벨이나 식별자로 찾습니다. 프로젝트 관례(식별자 우선)와 일치합니다.
  - "보이지 않음" 단언은 `exists == false`가 아니라 다음처럼 둡니다.
    - 낭독 전용 요소는 hittable이 아니거나 화면에 보이는 텍스트 노드가 없음
    - 버스 번호·분은 `staticTexts` 라벨 전체에서 해당 문자열이 0건이고, `board.route` 라벨에는 포함됨
  - 색이나 크기를 단언하지 않습니다.
- **AC 매핑**: AC-1~5, 9, 17, 18, 20, 23, 24, 26~28 화면 동작

#### C9. BoardingTagView (T6) — 제스처·생명주기 연결
- **레이어**: 컴포넌트 동작(연결). 연출은 표현
- **러너**: XCUITest
- **통합 테스트**: 아래 "주요 AC의 XCUITest 결정적 검증 방법" 참고
- **AC 매핑**: AC-5~10, 12~16, 21, 22

---

### 주요 AC의 XCUITest 결정적 검증 방법

- **AC-6(놓기 전 인식)**
  - XCUITest는 손을 대고 있는 도중에 단언할 수 없습니다(`press(forDuration:thenDragTo:)`는 동기 호출이라 끝난 뒤에야 검사 가능).
  - 설계대로 "놓기 전"은 C5 단위 테스트가 보장합니다. 여기에 C5의 **불변식 "dragEnded는 절대 인식하지 않음"** 단위 테스트를 더하면, UI에서 끌고 놓은 뒤 햅틱 1과 LCD '집중동행카드'가 관찰되는 것만으로 화면이 `dragChanged` 경로로 연결됐다는 결정적 증거가 됩니다. onEnded에만 연결했다면 인식이 일어날 수 없기 때문입니다.
  - "카드는 그 자리에 머문다"는 놓은 뒤 `test.boarding.offsetY < 0`(원위치 아님)으로 단언합니다.
- **AC-8(범위)** — **[필수 보완 4] 설계서 방식이 성립하지 않음**
  - 상황: 설계는 "과도하게 끈 뒤 `test.boarding` offset으로 단언"한다고 적었습니다. 하지만 미인식 상태에서 손을 떼면 C5 규칙상 offset이 `.zero`로 돌아갑니다(AC-7). 놓은 뒤에는 clamp 흔적이 없습니다. 위쪽으로 넘치게 끌면 그 전에 30%에서 인식되므로 위쪽 한계도 UI에서 관찰할 수 없습니다.
  - 권고
    - 주 검증은 C2(`clampedOffset`)와 C5(`dragChanged` 순서 → `cardOffset`) 단위 테스트로 지정합니다.
    - UI가 필요하면 `test.boarding`에 `peakX`·`peakDown`(이번 끌기 중 관찰한 |x| 최댓값과 아래쪽 최댓값, 새 끌기에서 초기화)을 추가합니다. 좌우 100 끌기 → `peakX ≤ 26`, 아래 100 끌기 → `peakDown ≤ 20`. 위쪽 한계는 단위 테스트에만 둡니다.
- **AC-15(앱 숨김)**
  - 순서: `--fm-ui-boarding-hold manual`로 실행 → 끌어서 인식 → `test.writeCount == 1`이고 held 확인 → `XCUIDevice.shared.press(.home)` → `app.activate()` → `test.releaseBoardingHold` 탭.
  - 판정: 시간 경과에 기대는 부정 단언 대신 **양성 상태 `test.boarding.phase == "abandoned"`**를 기다려 단언합니다. 이어서 `screen.boarding`이 있고, `screen.journey`는 짧은 대기 뒤에도 없으며, writeCount 1입니다.
  - 이 저장소에는 아직 `press(.home)`을 쓰는 UI 테스트가 없습니다(검색 0건). 첫 도입이므로 시뮬레이터에서 scenePhase가 background로 넘어가는지 T8 초기에 한 번 확인해야 합니다.
  - contacting 중(300ms 창) 숨김은 UI로 다루지 않고 C5 단위 테스트로만 검증합니다.
- **AC-17(포커스)**
  - XCUITest는 VoiceOver 포커스를 읽을 수 없습니다. `test.briefing.focus == "start"`는 컨트롤러의 `focusTarget` 값일 뿐이고, `@AccessibilityFocusState` 연결 자체는 검증되지 않습니다.
  - 남는 위험을 명시합니다: 연결은 코드 리뷰와 W14 실기기 VoiceOver 확인으로 처리합니다(신뢰 기록에 남김).
  - 문장 순서는 C6 단위 테스트가 주 검증입니다. UI는 실제 1.7초 간격에서 첫 문장을 놓칠 수 있으므로(경쟁 상태) 최종 상태만 단언합니다: `briefingSentence` 값이 '버스 출발합니다', `journey.start`가 hittable, 노선·버스·정류장 문자열 0건, 일시정지 요소 0건.
  - 순서까지 UI로 보려면 `--fm-ui-briefing-step manual` 게이트(`UITestIssuanceGate` 재사용)를 선택적으로 둡니다. 비용 대비 효과가 낮아 필수는 아닙니다.
- **AC-22(동작 줄이기)**
  - 순서: `--fm-ui-reduce-motion on`과 hold 게이트로 실행 → 인식 → `test.hapticCount == 0`, LCD '집중동행카드', `screen.journey` 없음(게이트가 hold를 붙잡고 있어 유지 시간이 보존됨을 양성으로 확인) → 해제 → `screen.journey` 등장.
  - "접촉 이동·페이드 생략"은 C5에서 sleep 요청 목록으로 검증합니다.
  - "진입 연출·점선 깜빡임 없음"은 표현이라 범위 밖(리뷰)입니다.
- **AC-23(큰 글자)**
  - 기존 관례 인자 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`을 씁니다.
  - 테스트 1개로 연결합니다. activeJourney 시드 메인에서 `open.preparation`이 hittable이고 frame이 창 안에 있음 → 탭(폐기) → 시간 선택 → 준비 → `board.boardBus` hittable → 승차 태그 → `test.activateBoardingCard` → 출발 안내 `journey.start` hittable.
  - 동작 줄이기 강제를 함께 켜서 시간을 줄입니다.

### 비동기 sleep 주입과 세대 token의 단위 테스트 방법(요약)
1. contact·fade용 `SuspendingSleep`과 `holdSleep`용 `SuspendingSleep`을 따로 주입해 단계를 구분합니다.
2. 각 단계는 `await sleep.untilSuspended()`로 정지점에 도달했는지 확인한 뒤 상태를 단언하고 `resume()`합니다.
3. 취소 시나리오는 `cancelPendingTransition()` → `resume()` → **`await controller.pendingTransition?.value`**(필수 보완 1) → `boarder.calls`와 `onFinished` 호출 횟수를 단언합니다.
4. token 경쟁(contacting 중 취소 → 동기 commit → 늦은 commit 무효)은 calls가 정확히 1인지로 고정합니다.
5. 출발 안내의 reset·begin 재시작은 대기열형 sleep 대역(보완 2)으로 검증합니다.

### 단위/UI 배분(UI 테스트 과다 방지)
AC마다 UI 테스트를 하나씩 만들면 25개가 넘고, 대부분이 시간 선택 → 준비 흐름을 반복 통과합니다. 단위 테스트가 판정을 맡고 UI는 연결과 흐름만 맡는다는 원칙으로 **UI 테스트 11개**를 권장합니다.

| # | 파일 | 묶는 AC |
|---|---|---|
| U1 | BoardingFlowUITests | AC-1, 3, 4, 5, 26 (확정 → 승차권 항목 → 탑승 → 태그 화면 요소 → 뒤로 → 뒤로 → 준비, writeCount 0) |
| U2 | BoardingFlowUITests | AC-2 (기존 비활성 단언에 "승차권 보기 탭 후 `screen.board` 없음" 추가, 기존 테스트 확장으로 대체 가능) |
| U3 | BoardingFlowUITests | AC-14, 25, 28 (A 인식·hold 중 뒤로 → abandoned·1건 → 준비 수정 → B 인식 → `persistedBytes` 내용이 B → 메인까지 뒤로 → `main.activeJourney`) |
| U4 | BoardingTagUITests | AC-6, 11, 12, 13 → 이어서 AC-17, 19, 20 (끌기 인식 → hold 중 writeCount 1·태그 화면 → 재끌기·활성화로 불변 → 해제 → 여행 → 최종 안내 → 시작 → departed·진도 0, 뒤로가기는 메인) |
| U5 | BoardingTagUITests | AC-7, 9, 16, (8 peak 진단을 쓸 경우) (짧은 끌기 → 원위치 → 터치 → 안내 → 숨김·복귀 → writeCount 0·전환 없음) |
| U6 | BoardingTagUITests | AC-10 (`test.activateBoardingCard` → 낭독 1회·writeCount 1) |
| U7 | BoardingTagUITests | AC-15 |
| U8 | BoardingTagUITests | AC-21 (보완 3 방식) |
| U9 | BoardingTagUITests | AC-22 → 이어서 AC-18 |
| U10 | ActiveJourneyMainUITests | AC-24, 27 (시드 → relaunch → 안내·자동 이동 없음 → 여행 준비 → active 0·시간 선택·records 0) + 폐기 실패(save fail) 1건 |
| U11 | LargeText 계열 | AC-23 |

- **[권고 5] 비용 절감용 진입 인자**: 승차 태그 화면 진입 UI 테스트가 7개 이상이고 각각 준비 흐름을 통과하므로, DEBUG 인자 `--fm-ui-route boarding`을 검토합니다. 부트스트랩이 `journeyPlan`과 준비 초안을 채우고 `confirmPreparation`을 호출한 뒤 `[.time, .preparation, .board, .boarding]`를 쌓습니다. U1·U3은 실제 흐름을 유지하고 나머지만 이 인자를 씁니다. 필수는 아닙니다.
- **[권고 6] 기존 진단과 세는 기준 통일**: `test.writeCount`는 `modelStore.writeData` 성공만 셉니다. 시드 쓰기는 별도 store라 포함되지 않습니다. AC 단언은 "증가량 0 또는 1"로 쓰도록 테스트 명명 규칙에 남깁니다.

---

### Testability Score: 7.5/10 (동작 컴포넌트 기준)

- **강점**
  - 모든 동작 로직이 순수 규칙(C2·C3), 프로토콜 주입 컨트롤러(C5·C6), 기본값 있는 팩토리 주입 모델(C4)로 떨어져 있습니다.
  - 시간은 전부 주입 가능합니다.
  - 저장 실패는 기존 `writeData` 클로저로 격리됩니다.
  - 기존 대역(`SuspendingSleep`, `FakeIssuanceHaptics`, `RecordingAnnouncer`)과 UI 하네스(게이트, 기록기, `persistedBytes`, `relaunch`)를 그대로 재사용합니다.
- **감점**
  - 내부 Task를 기다릴 수단이 없음(필수 보완 1)
  - AC-8 UI 검증 방식이 성립하지 않음(필수 보완 4)
  - AC-21 UI 전제가 도달 불가(필수 보완 3)
  - AC-17 포커스 연결과 AC-10 실제 VoiceOver는 원리상 자동 검증 불가(남는 위험)
  - 출발 안내 재시작 대역의 슬롯 한계(보완 2)

### 판정: PASS (조건부)

- 7점 이상이므로 재설계는 필요 없습니다. 다만 red-green-refactor에 들어가기 전에, architect가 아래 4건을 설계서에 반영하는 경미한 수정을 권고합니다.
  1. `BoardingTagController`에 `pendingTransition: Task<Void, Never>?`(테스트에서 await 가능)를 명시
  2. C5 불변식 테스트 "dragEnded는 인식하지 않음"을 T4 목록에 추가하고, AC-6 UI 근거를 이 불변식으로 기술
  3. AC-21 UI 시나리오를 `fail-once-boarding` 인자(권장)나 "UI는 ready 시드 + 단위 테스트 분담"으로 수정하고, "activeJourney 시드면 불변 확인 가능" 문장 삭제
  4. AC-8의 주 검증을 C2·C5 단위 테스트로 지정하고, UI는 `peakX`·`peakDown` 진단을 쓰거나 생략
- 나머지(보완 2, 권고 5·6, AC-15·AC-22를 양성 상태 `abandoned`·게이트로 판정하는 방식)는 T4·T7·T8 구현 지침으로 넘기면 됩니다.
- 남는 위험(신뢰 기록 대상): AC-17의 실제 접근성 포커스 이동, AC-10의 실제 VoiceOver·Full Keyboard Access 활성화. 둘 다 W14 실기기에서 확인합니다.

---

### 탐색 추가 항목
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMateTests/CardIssuanceTestDoubles.swift:60-91`: `SuspendingSleep`은 continuation을 한 칸에만 담습니다(보완 2의 근거).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMate/UITestBootstrap.swift:125-127`: `writeData`에서 실패를 주입하는 지점. `:139-145`의 `applySaveScenario`는 메인에서 정류장 저장 실패를 1회 일으킵니다(AC-21 시드 설계 시 고려). `:216-232`: `UITestIssuanceGate`의 `releasedEarly` 처리(hold 게이트 재사용 시 해제 순서 경쟁이 없음). `:234-245`: `UITestCardSaveFailure`의 arm/consume 패턴(보완 3의 fail-once 원형).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMateUITests/UITestLaunchSupport.swift:13-37`: `launch`(hold 인자는 `--fm-ui-issue-hold` 고정이라 `boardingHold`·`reduceMotion` 인자 추가 필요), `relaunch`(시드 없이 같은 testID로 재실행, AC-24에 그대로 사용 가능).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMate/LocalSnapshotStore.swift:104-109`: save 시 validate 뒤 load 재확인. 단위 테스트에서 `writeData` 클로저로 실패와 횟수를 주입할 수 있습니다.
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMate/CardIssuanceController.swift:51-69`: 기존 컨트롤러는 async 메서드라 테스트가 Task 핸들을 쥘 수 있었습니다. 신규 승차 태그 컨트롤러는 내부 Task라서 이 이점이 사라집니다(필수 보완 1의 근거).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMateUITests/LargeTextUITests.swift:77`, `CardIssuanceFlowTests.swift:9`: XXXL 실행 인자 관례(AC-23).
- `/Users/bonseung/Documents/ChatGPT/new-w04/ios/FocusMateUITests/` 전체: `XCUIDevice.shared.press(.home)`·`app.activate()` 사용 예가 0건이라, AC-15·AC-16은 이 저장소에서 처음 도입하는 방식입니다.