## 설계 초안 (개정 2판, 최종): W07 포기·이어가기·생명주기 (journey FR-13 / AC-15, NFR-2 Simulator 부분 / AC-8)

### 설계 규모
대형입니다. 메인 화면, 타이머 화면, 현재 정류장 저장(이번에 처음 바뀜), 재실행 복원에 걸칩니다. 확인 대화상자 2개와 여정을 바꾸거나 지우는 저장 경로 3개(포기·새 여정·이어가기)가 새로 생깁니다.

### 배경 및 목적
- 지금 상태:
  - 메인 '여행 시작하기'가 진행 여정을 확인 없이, 기록 없이 지웁니다(`ios/FocusMate/AppModel+Boarding.swift:50-61`).
  - 출발 후 타이머 화면에는 나가는 길이 없습니다.
  - 재실행하면 일시정지로 남지만 이어갈 방법이 없습니다(임시 안내 `ios/FocusMate/RootView.swift:175-182`).
- 목표:
  - 여정은 사용자가 확인했을 때만 사라집니다.
  - 포기하면 도달한 정류장에서 다음 여행을 시작합니다. 완료 기록은 남기지 않습니다.
  - 재실행 뒤 메인에서 이어갈지, 새로 시작할지 사용자가 고릅니다.
- 성공 지표: 한 번의 탭으로 여정이 사라지는 경로 0개, 저장 실패를 성공으로 안내하는 경로 0개, 중복 여정·기록 증가 0.

### 요구사항 및 수용 기준
`.dev/feat-abandon-resume-lifecycle/prd.md`(확정본)를 그대로 따릅니다.
- [Must] FR-1~FR-11, BR-1~BR-9, BR-11
- [Should] FR-12, BR-10, QE-1~3
- [Could] FR-13은 이번 범위가 아닙니다.
- 수용 기준은 AC-1~AC-35 전부입니다.

이번 판에 반영한 사용자 결정(2026-10-15):
- AC-18(나)는 "성수대교 북단 정방향, 2014번, 경과 **900초** → 성수역(방향 1)"으로 PRD가 수정됐습니다.
- 두 대화상자는 **아이폰 기본 확인 창**(`.alert`, 안전 버튼은 `role: .cancel`)으로 합니다. 창이 열릴 때 VoiceOver가 처음 가는 위치(AC-6·14·27·32의 해당 부분)는 W14 실기기 점검으로 넘기고 trust-ledger에 기록합니다.

### 변경 범위

**신규 파일 (앱)**
pbxproj는 PBXFileSystemSynchronizedRootGroup이라 따로 등록하지 않아도 됩니다.

| 파일 | 책임 |
|---|---|
| `ios/FocusMate/JourneyReach.swift` | BR-1 도달 정류장 순수 규칙, `JourneySnapshot.reachedStation`, `AppSnapshot.endingActiveJourney(at:)` |
| `ios/FocusMate/JourneyLifecycleText.swift` | W07 문구·낭독 상수 |
| `ios/FocusMate/ActiveJourneyCardContent.swift` | 메인 카드 값(순수 값 타입, 이어가기 가능/도착 변형) |
| `ios/FocusMate/AppModel+JourneyLifecycle.swift` | `LifecycleActionResult`, 이어가기·새 여정 확정·포기, 시작 버튼 문구, 이어가기 진입 신호 소비, `AppModel: JourneyAbandoning` |
| `ios/FocusMate/JourneyAbandonController.swift` | `JourneyAbandoning` 프로토콜, 포기 확인 흐름 상태(확인 중, 실패, 완료, 포커스 목표) |
| `ios/FocusMate/JourneyAbandonBar.swift` | 타이머 화면 하단 '포기하기' 버튼·포기 alert·실패 문구, DEBUG `test.abandon` |
| `ios/FocusMate/MainActiveJourneyView.swift` | 메인 이어가기 카드 뷰, 포기 안내 뷰(항상 존재), 새 여정 alert 수식어 |

**신규 파일 (테스트)**
- FocusMateTests:
  - `JourneyReachTests`
  - `ActiveJourneyCardContentTests`
  - `JourneyAbandonControllerTests`
  - `JourneyLifecycleModelTests`
  - `JourneyLifecycleTestDoubles`(`FakeJourneyAbandoner`, attempts/writes 분리 `LifecycleProbe`)
  - `LifecycleSeedTests`
- FocusMateUITests:
  - `JourneyResumeUITests`
  - `NewJourneyUITests`
  - `JourneyAbandonUITests`
  - `JourneyLifecycleSafetyUITests`

**수정 파일 (앱)**

| 파일 | 지점 |
|---|---|
| `AppModel.swift` | 저장 프로퍼티 2개(`abandonNotice`, `resumeEntryJourneyID`)를 추가합니다. `saveHandlingFailure(_:)`를 추가합니다. `open`(:263-269)과 `beginCardCustomization`(:280)에서 포기 안내를 지웁니다. `goBack` 주석(:272)을 바꿉니다. |
| `AppModel+Boarding.swift:50-61` | 진행 여정이 있으면 `startTripFromMain`이 거부합니다. |
| `RootView.swift` | :175-182 카드·안내 교체, :187-188 버튼 문구·동작, 메인 실패 `@State`, alert 수식어 1줄, DEBUG `test.main.failNextSave`·`test.writeAttempts` |
| `JourneyView.swift` | `ensureTimer`(:27-32)에 2줄, `JourneyScreen` 수식어 체인에 `.safeAreaInset(edge: .bottom)` 1줄, 주석(:4, :23) |
| `UITestBootstrap.swift` | 이름 붙은 `lifecycleSeeds`, `UITestWriteCounter`, `route journey` 주석(:214) |

**조건부 수정 (W06 충돌을 피하는 것이 목표이지 절대 조건은 아님)**
- `JourneyTimerView.swift:19`: 기본안은 **수정하지 않습니다**. T6에서 기존 V7 AC29가 실패할 때만 `VStack(spacing: 32)`를 큰 글씨에서 줄어드는 간격으로 바꾸는 **1줄**만 허용합니다. 자세한 내용은 상세 설계 9를 봅니다.

**수정하지 않는 파일**
`JourneyTimerController.swift`, `JourneyServices.swift`, `NavigationPopBlocker.swift`, `JourneySnapshot.swift`, `AppSnapshot.swift`

**수정 파일 (기존 테스트)**
- `BoardingModelTests.swift:304-332`: AC27 두 건
- `ActiveJourneyMainUITests.swift:19-58`: 세 건 재작성
- `BoardingLargeTextUITests.swift:56-69`: U11에 alert 확정 단계 추가
- `UITestLaunchSupport.swift`: 도우미 추가
- 회귀 대상(수정 없이 다시 실행): `JourneyTimerAccessibilityUITests.swift:60-82`(V7 AC29). 이 테스트는 T6 완료 조건입니다.

**문서**
`docs/FLOWS.md`, `docs/CURRENT-STATE.md`, `context/journey/status.md`, `context/journey/architecture.md`, `context/journey/glossary.md`, `.dev/plan.md`

### 적용 컨벤션
- 프로젝트 CLAUDE.md는 없습니다. W05 설계서 "적용 컨벤션"(`.dev/feat-real-minute-timer-pause/design.md:61-67`)을 따릅니다.
- 컨트롤러: `@MainActor @Observable final class`. 의존성은 `@ObservationIgnored private let`, 상태는 `private(set) var`, 포커스 의도는 컨트롤러의 `focusTarget`(`DepartureBriefingController.swift:13, 21` 방식)으로 둡니다.
- 경계 프로토콜: `@MainActor protocol …: AnyObject`. 거부와 저장 실패를 구분해야 하는 W07 동작은 Bool 대신 enum을 반환합니다.
- 저장: 최신 `snapshot`에서 `updating…`으로 후보를 만들어 한 번만 저장합니다. 성공하면 snapshot이 바뀌고, 실패하면 그대로입니다(`AppModel.swift:198-219`). `persist`는 경로(route)가 바뀔 때만 path를 비우므로(:214) 메인→메인 저장 뒤의 이동은 직접 지정합니다.
- 화면 이동은 `open(_:)`을 통합니다. 메인 동작은 path가 빈 상태에서만 받습니다.
- 대화상자: `.alert` + `role: .cancel` 안전 버튼 + `accessibilityIdentifier`(`CardCustomizationView.swift:108-111`)
- 문구는 enum 상수(`JourneyTimerDisplay.swift`), 화면 값은 순수 Content 구조체(`BoardingPassContent.swift`)로 둡니다.
- DEBUG 진단은 `accessibilityValue`에 넣습니다(font 1, `.clear`, `allowsHitTesting(false)`). 테스트 버튼은 불투명 44pt로 만듭니다(`JourneyView.swift:162-170`).
- 테스트 이름은 `testAC<n>_한국어`, 실패 이유는 `// 깨짐:`으로 적습니다. 더블은 결과 배열을 순서대로 소비하고 호출을 기록합니다.

### 상세 설계

#### A. 도달 정류장 규칙 (BR-1, BR-2)

**1. `ios/FocusMate/JourneyReach.swift` (신규)**
- 현재:
  - 도착지는 승차할 때 `wrap(origin.index + direction * stops)`로 계산해 `destinationStopID`로 저장합니다(`JourneySnapshot.swift:40-46`).
  - stops는 `minutes / minutesPerStop`입니다(`JourneyPlanner.swift:27-29`).
  - 간격은 `BusLine.minutesPerStop`(`RouteData.swift:77-88`), 순환 정류장은 `RouteStops`(`RouteData.swift:10-25`)에 있습니다.
  - `validate`는 도착지가 이 식과 맞는지 검사하지 않습니다(`JourneySnapshot.swift:78-97`). 기존 `timerJourney` 시드(`UITestBootstrap.swift:274-281`)는 식으로 계산한 값(seongsuIntersection)과 저장값(seongdongSportsCenter)이 다릅니다.
- 변경 (기준값을 하나로 정합니다):
  - **도착(`isArrived`)**: 저장된 `destinationStopID`와 그 카탈로그 이름을 씁니다. 카드에 보인 "{도착지}까지"와 확정 후 현재 정류장이 항상 같습니다(FR-9).
  - **그 밖(출발 대기 포함)**: 칸 수 = `min(elapsed / (minutesPerStop*60), minutes / minutesPerStop)`, 정류장 = `RouteStops.all[wrap(originIndex + direction * 칸 수)]`입니다. 출발 대기는 진도가 0이라 출발 정류장이 됩니다(FR-8).
  - 이름은 카탈로그 이름(예: "뚝섬역"), 방향은 여정의 `direction` 그대로입니다(BR-2).
  - 현재 정류장 변경과 여정 삭제는 한 후보로 만듭니다. 원자적 쓰기 1회입니다(BR-4). records는 건드리지 않습니다(BR-3).
- 시그니처:
  - `enum JourneyReach { static func reachedStops(elapsedSeconds: Int, minutes: Int, minutesPerStop: Int) -> Int; static func station(originStopID: String, direction: Int, stops: Int) -> StationSnapshot? }`
  - `extension JourneySnapshot { var reachedStation: StationSnapshot? }`: 카탈로그 밖이면 nil입니다.
  - `extension AppSnapshot { func endingActiveJourney(at station: StationSnapshot) -> AppSnapshot }`: `updatingStage(cardIssued:initialStation:currentStation: station).updating(journey: .empty)`입니다(`AppSnapshot.swift:39-50` 재사용, initialStation 유지).

#### B. 문구·카드 값

**2. `ios/FocusMate/JourneyLifecycleText.swift` (신규)**
PRD 원문 그대로 둡니다.
- 카드
  - `resumableTitle = "잠시 멈춘 여정이 있어요."`, `arrivedTitle = "도착한 여정이 있어요"`
  - `remaining(minutes:)` → "N min 남음"(`JourneyTimerDisplay.text(minutes:)` 재사용)
  - `route(tag:destination:)` → "{태그} · {도착지}까지"
  - `resumeButton = "이전 여정 이어가기 →"`, `resumeButtonLabel = "이전 여정 이어가기"`
  - `newJourneyButton = "새 여정 시작"`
- 대화상자
  - 새 여정: 제목, 본문, `keepJourney = "이전 여정 유지하기"`
  - 포기: 제목, 본문, `continueTrip = "계속 여행"`, `quitTrip = "그만두기"`, `abandonButton = "포기하기"`
- 안내·낭독
  - `abandonNotice(stationName:)` → "{정류장}에서 여행을 마쳤어요. 완료 기록은 남기지 않았어요."
  - `resumeAnnouncement = "이전 여정을 남은 시간부터 이어갑니다."`
  - `saveFailure = JourneyTimerDisplay.transitionFailureText`

**3. `ios/FocusMate/ActiveJourneyCardContent.swift` (신규)**
- 현재: 메인 안내는 하드코딩된 2줄입니다(`RootView.swift:177-180`).
- 변경:
  - `isArrived`면 `.arrived`, 그 밖은 `.resumable`입니다.
  - 남은 시간은 `JourneyTimerDisplay.remainingMinutes`(올림, `JourneyTimerDisplay.swift:6-8`)로 계산합니다. 출발 대기는 전체 분이 됩니다.
  - 버스는 "지선 2014" 형식입니다.
  - 도착 카드는 남은 시간 없이 제목·할 일·버스·경로만 보입니다(가정).
- 시그니처: `struct ActiveJourneyCardContent: Equatable { enum Kind { case resumable, arrived }; let kind: Kind; let title, task, busText, routeText: String; let remainingText: String?; var showsResume: Bool; var accessibilityLabel: String; init?(journey: JourneySnapshot) }`

#### C. 모델

**4. `ios/FocusMate/AppModel.swift` (수정)**
- 현재:
  - `open`(:263-269)은 `.journey`를 active가 있을 때만 엽니다.
  - `goBack`(:270-275)은 출발한 여정이면 메인으로 가지 않습니다(유지, FR-10).
  - `loadSnapshot`(:180-195)의 `restingForLaunch`(:184)는 메모리에서만 일시정지로 바꿉니다(유지).
  - `save`(:198-202)는 실패하면 `saveFailure`를 남기고, RootView(:30-33)가 일반 문구 "저장에 실패했어요. 변경 내용의 재실행 복원을 보장할 수 없어요."를 보입니다.
- 변경:
  - `var abandonNotice: String?`: 메모리 전용(BR-10)입니다. 설정은 lifecycle 확장에서만 한다고 주석을 답니다. 다른 파일의 확장에서 쓰므로 `path`처럼 internal setter입니다.
  - `@ObservationIgnored var resumeEntryJourneyID: String?`
  - `func saveHandlingFailure(_ candidate: AppSnapshot) -> Bool`: 실패를 호출자가 직접 안내하는 저장입니다(W07 전용). `persist`를 부르고, 성공하면 `saveFailure = nil`, **실패해도 `saveFailure`를 남기지 않습니다**. W07 동작은 실패해도 아무것도 바뀌지 않으므로 "재실행 복원을 보장할 수 없어요"가 사실이 아니기 때문입니다. 이렇게 하면 다른 화면을 다녀온 뒤 일반 문구가 다시 나타나는 문제도 없어집니다. `!isRecovering` 가드는 `save`와 같습니다.
  - `open`의 가드 뒤에 `abandonNotice = nil`을 넣습니다.
  - `beginCardCustomization()`(:280)의 성공 경로에 `abandonNotice = nil`을 넣습니다. fullScreenCover는 `open`을 거치지 않아 생기던 빈틈을 막습니다.
  - :272 주석: "출발한 여행 화면에서 메인으로 가는 길은 포기뿐이다(W07, FR-10)."

**5. `ios/FocusMate/AppModel+JourneyLifecycle.swift` (신규)**
- 시그니처:
  - `enum LifecycleActionResult: Equatable { case done, rejected, saveFailed }`
    - `rejected`: 가드 거부(연타, 상태 불일치). 화면에 아무 안내도 하지 않습니다.
    - `saveFailed`: 저장 실패만 해당합니다(BR-7 안내).
  - `extension AppModel: JourneyAbandoning`
    - `var activeJourneyCard: ActiveJourneyCardContent?`
    - `var mainStartTitle: String`: active가 있으면 "새 여정 시작", 없으면 `Destination.preparation.mainMenuTitle`
    - `@discardableResult func resumeJourney() -> LifecycleActionResult`
    - `func consumeResumeEntry(journeyID: String) -> Bool`
    - `@discardableResult func confirmNewJourney() -> LifecycleActionResult`
    - `@discardableResult func abandonJourney(timerPaused: Bool) -> LifecycleActionResult`
- **resumeJourney** (FR-2, FR-8, BR-8, BR-11)
  - 가드: `.ready(.main)`, `path.isEmpty`, active 존재, `!isArrived`. 어긋나면 `.rejected`입니다.
  - path 가드가 연타를 막습니다. 첫 탭이 path를 동기적으로 `[.journey]`로 바꾸기 때문입니다(AC-5). 시간 기반 디바운스는 쓰지 않습니다. W05에서 컨트롤러 디바운스가 테스트와 충돌한 전례가 있어서입니다.
  - 출발 대기: 저장 없이 `open(.journey)`하고 `.done`입니다. JourneyView가 새 `DepartureBriefingController`로 안내를 처음부터 보여 줍니다(`DepartureBriefingController.swift:38-57`, AC-23).
  - 출발 후: `saveHandlingFailure(snapshot.updating(journey: JourneySection(active: active.updatingProgress(elapsedSeconds: active.progress.elapsedSeconds, paused: false))))`로 1회 저장합니다.
    - 성공: `resumeEntryJourneyID = active.id`, `open(.journey)`, `.done`
    - 실패: `.saveFailed`, 이동하지 않고 상태도 그대로입니다(BR-7, AC-35).
    - `saveJourneyProgress`를 재사용하지 않는 이유: 그 함수는 일반 `save`를 거쳐 `saveFailure`를 남깁니다.
- **consumeResumeEntry**: id가 일치할 때 한 번만 true를 반환하고 값을 지웁니다.
- **confirmNewJourney** (FR-4, FR-8, FR-9, BR-4, BR-8)
  - 가드: `.ready(.main)`, `path.isEmpty`, active 존재, `reachedStation` 존재. 어긋나면 `.rejected`입니다.
  - `saveHandlingFailure(snapshot.endingActiveJourney(at: station))`를 1회 부릅니다.
    - 성공: `discardConfirmedPreparation()`(기존 :57-58과 같은 이유), `open(.time)`, `.done`
    - 실패: `.saveFailed`
  - 두 번째 확정은 active가 nil이고 path가 비어 있지 않아 `.rejected`가 됩니다(AC-11).
- **abandonJourney(timerPaused:)** (FR-6, BR-1~4, **BR-6을 모델에서 강제**)
  - 가드: `timerPaused == true`, `.ready(.main)`, `path.last == .journey`, active가 `.departed`이고 `!isArrived`, `reachedStation` 존재. 어긋나면 `.rejected`입니다.
  - 일시정지 여부를 인자로 받는 이유: 런타임 진도의 주인은 타이머 컨트롤러입니다(W05). 체크포인트 저장에 실패해 멈춘 경우 메모리의 `snapshot.paused`가 false로 남을 수 있으므로, snapshot 값 대신 호출자가 컨트롤러 상태를 넘기는 것을 계약으로 드러냅니다. W06 지도 도구 같은 다른 호출 경로도 이 인자를 넘겨야 합니다.
  - 도달 정류장은 **마지막으로 저장된 경과**로 계산합니다(BR-1의 "저장된 경과 초").
  - 성공: `path = []`, `abandonNotice = station.name`, `.done`
  - 실패: `.saveFailed`. 경로와 상태는 그대로입니다.
- **포기 후 컨트롤러 정리**
  - `JourneyView.onDisappear { timer?.leave() }`(`JourneyView.swift:24`)에서 paused면 `ticker.stop()`만 하고 저장하지 않습니다(`JourneyTimerController.swift:131`).
  - 저장을 시도하더라도 `saveJourneyProgress` 가드(active 없음·id 불일치, `AppModel+JourneyTimer.swift:15-16`)가 쓰지 않습니다. 그래서 컨트롤러는 수정하지 않습니다.

**6. `ios/FocusMate/AppModel+Boarding.swift:50-61` (수정)**
`guard snapshot?.journey.active == nil else { return false }`를 넣습니다. 여정 정리는 확인을 거친 `confirmNewJourney`만 합니다. active가 없을 때의 동작(확정값 정리, `open(.time)`, 쓰기 0)은 그대로입니다(AC-12).

#### D. 포기 흐름

**7. `ios/FocusMate/JourneyAbandonController.swift` (신규)**
- 시그니처:
  - `@MainActor protocol JourneyAbandoning: AnyObject { func abandonJourney(timerPaused: Bool) -> LifecycleActionResult }`
  - `@MainActor @Observable final class JourneyAbandonController`
    - 상태: `enum FocusTarget: Equatable { case abandonButton }`, `private(set) var isConfirming`, `showsFailure`, `hasFinished`, `focusTarget: FocusTarget?`
    - `init(abandoner: JourneyAbandoning)`
    - `func request(isPaused: Bool)`: `isPaused && !hasFinished`일 때만 엽니다. 이미 열려 있으면 무시합니다. `showsFailure`와 `focusTarget`을 지웁니다.
    - `func cancel()`: `isConfirming = false`. `!hasFinished`면 `focusTarget = .abandonButton`입니다(AC-15).
    - `@discardableResult func confirm(isPaused: Bool) -> LifecycleActionResult`: `!hasFinished`일 때만 동작합니다. 먼저 `isConfirming = false`로 두고 `abandoner.abandonJourney(timerPaused: isPaused)`를 부릅니다.
      - `.done`: `hasFinished = true`, `focusTarget = nil`
      - `.saveFailed`: `showsFailure = true`, `focusTarget = .abandonButton`
      - `.rejected`: 아무 표시도 하지 않습니다.
    - `func clearFailure()`
- 순서 독립성: 확정은 `isConfirming`에 의존하지 않습니다. alert 바인딩의 set(false)과 버튼 액션 중 어느 쪽이 먼저 불려도 결과가 같습니다.
  - confirm→cancel: `hasFinished`라 cancel이 포커스를 잡지 않습니다.
  - cancel→confirm: cancel이 잡은 포커스를 confirm 성공이 지웁니다.
  - 두 순서 모두 단위 테스트로 고정합니다(R2).

**8. `ios/FocusMate/JourneyAbandonBar.swift` (신규)**
- 구성:
  - `struct JourneyAbandonBar: View { init(abandoner: JourneyAbandoning, timer: JourneyTimerController) }`
  - `@State private var flow`는 initialValue로 만듭니다.
  - `@AccessibilityFocusState private var abandonFocused`
- 컨테이너(VStack)는 **항상 존재**하고 버튼만 조건부로 그립니다. 상태가 바뀌어도 @State와 alert가 유지됩니다.
- 노출: `timer.status == .paused`일 때만 보입니다(AC-13).
  - 진행 중(이어가기 직후 포함), 도착, 출발 안내 단계에서는 bar의 높이가 0입니다. 출발 안내 단계에는 `timer`가 nil이라 bar 자체가 없습니다.
- 버튼:
  - id `journey.abandon`, 라벨 "포기하기"
  - `Text(...).font(.headline)`, `frame(minWidth: 160, minHeight: 44)`, `.padding(.vertical, 8)`, 외곽선 Capsule
  - `.dynamicTypeSize(...DynamicTypeSize.accessibility3)`: 재개 버튼(`JourneyTimerView.swift:76`)과 같은 상한입니다.
- 실패 문구:
  - `flow.showsFailure && !timer.showsTransitionFailure`일 때 `Text(saveFailure)`를 id `journey.timer.saveFailure`로 보입니다(AC-20). 같은 id가 두 번 나오지 않게 하는 조건입니다.
  - `.font(.subheadline)`, 같은 상한, `fixedSize(vertical)`
  - `.onChange(of: timer.status) { flow.clearFailure() }`
- 배치: `.padding(.horizontal, 24).padding(.bottom, 8)`. ScrollView는 쓰지 않습니다(V7 AC29의 `scrollViews.count == 0` 유지).
- alert:
  - `.alert(제목, isPresented: Binding(get: { flow.isConfirming }, set: { if !$0 { flow.cancel() } })) { Button("계속 여행", role: .cancel){}.id("journey.abandon.cancel"); Button("그만두기", role: .destructive){ flow.confirm(isPaused: timer.status == .paused) }.id("journey.abandon.confirm") } message: { 본문 }`
  - 버튼 탭: `flow.request(isPaused: timer.status == .paused)`
- 포커스 복귀:
  - **`.onChange(of: flow.isConfirming) { _, open in if !open { abandonFocused = flow.focusTarget == .abandonButton } }`**로만 판정합니다. 바인딩 set 안에서 판정하지 않습니다.
- DEBUG `test.abandon`: `{"visible","confirming","showsFailure","focus": flow.focusTarget == .abandonButton ? "abandon" : "none"}`. FocusState 원값이 아니라 **컨트롤러 상태**를 보고합니다(R3).

#### E. 화면 연결

**9. `ios/FocusMate/JourneyView.swift` (수정 3곳) / 큰 글씨 배치**
- (a) `ensureTimer`
  - `let resumed = model.consumeResumeEntry(journeyID: journey.id)`
  - `autoStart: briefing?.isConfirmed == true || resumed`
  - `if resumed { services.announcer.announce(JourneyLifecycleText.resumeAnnouncement) }`. 화면 문구로는 넣지 않습니다(FR-2).
  - 컨트롤러는 `autoStart && !journey.paused`일 때만 running이고(`JourneyTimerController.swift:47-49`), 기준 시각은 화면이 열린 시점입니다. 그래서 메인에 머문 시간과 종료 중 시간은 더해지지 않습니다.
  - 재실행 뒤에는 `restingForLaunch`로 paused이고 신호도 없습니다. `--fm-ui-route journey`도 신호가 없어 W05 테스트는 그대로 통과합니다.
- (b) `JourneyScreen` 수식어 체인(:62-66 부근):
  - `.safeAreaInset(edge: .bottom, spacing: 0) { if let timer { JourneyAbandonBar(abandoner: model, timer: timer) } }`
  - inset이 자리를 예약하므로 타이머 본문과 겹치지 않습니다.
- (c) 주석 :4, :23을 "메인으로 가는 길은 포기뿐"으로 바꿉니다.
- 유지:
  - 뒤로가기 숨김, `NavigationPopBlocker`(:63-65), `goBack` 가드(FR-10·AC-26)
  - 포기 뒤 이동은 모델이 `path = []`로 직접 하므로 차단과 충돌하지 않고, 사라질 때 `restore()`됩니다.
  - scenePhase(:68-81)는 그대로입니다. paused에서 `enterBackground`는 쓰기 0이므로 대화상자 중 백그라운드 왕복은 저장값을 바꾸지 않습니다(AC-27).
- **V7 AC29 회귀 대응 (MUST-ADDRESS 1)**
  - 테스트: `JourneyTimerAccessibilityUITests.swift:60-82`. 일시정지 + XXXL에서 remaining·resume의 isHittable·44pt를 보고, 재개 뒤 pause와 `scrollViews.count == 0`을 봅니다.
  - 높이 추정(XXXL, 버튼은 accessibility3로 제한):
    - bar 약 70pt(headline 상한 + 세로 패딩 16 + 아래 8)
    - DEBUG 상단 줄 44pt(`JourneyView.swift:158`)
    - 타이머 본문은 64pt 고정 글자(약 77) + 간격 32 + 버튼 약 60 + 패딩 48로 약 220pt이고 Spacer로 줄어듭니다.
    - 약 852pt 기기에서 안전 영역을 빼고도 여유가 있으므로 **JourneyTimerView를 수정하지 않는 것이 기본안**입니다.
    - 재개 뒤 진행 중에는 bar 높이가 0이라 pause 단언에는 영향이 없습니다.
  - T6 완료 조건: V7 AC29가 수정 없이 통과하고, 신규 AC-33(일시정지 XXXL에서 `journey.abandon`·`journey.timer.resume`·`journey.timer.remaining` 모두 isHittable·44pt 이상·scrollViews 0)이 통과해야 합니다.
  - 실패 시 대안 순서:
    1. bar 상한을 `...accessibility2`로 낮추고 세로 패딩을 4로 줄입니다.
    2. 그래도 실패하면 `JourneyTimerView.swift:19`의 `VStack(spacing: 32)`를 `@Environment(\.dynamicTypeSize)`가 accessibility일 때 16으로 바꾸는 **1줄**을 허용합니다. 이 경우 W06 세션에 알립니다.

**10. `ios/FocusMate/MainActiveJourneyView.swift` (신규)**
- `ActiveJourneyCardView(content:onResume:)`
  - 정보 묶음은 한 요소입니다: `.accessibilityElement(children: .combine)`, id `main.activeJourney`
  - 버튼은 형제 요소입니다: id `main.resumeJourney`. 보이는 문구는 "이전 여정 이어가기 →", 낭독 라벨은 "이전 여정 이어가기", 44pt. `showsResume`일 때만 보입니다(AC-24·32).
  - 컨테이너 id는 두지 않습니다. ScrollView에 흡수되는 문제를 피하기 위해서입니다(`JourneyView.swift:117` 주석과 같은 이유).
- `MainAbandonNoticeView(stationName: String?, announcer: AccessibilityAnnouncing)`
  - **mainContent에 조건 없이 항상 배치**합니다. 안의 Text만 조건부로 그립니다.
  - `.onChange(of: stationName)`에서 nil이 아닌 값으로 바뀌면 `@AccessibilityFocusState`를 지정하고 1회 낭독합니다. id는 `main.abandonNotice`입니다(AC-16·32).
- `extension View { func newJourneyConfirmation(isPresented: Binding<Bool>, onConfirm: @escaping () -> Void) -> some View }`
  - alert 제목·본문
  - `Button("이전 여정 유지하기", role: .cancel)`: id `main.newJourney.keep`
  - `Button("새 여정 시작", role: .destructive)`: id `main.newJourney.confirm`

**11. `ios/FocusMate/RootView.swift` (수정)**
- :175-182를 교체합니다.
  - `MainAbandonNoticeView(stationName: model.abandonNotice, announcer: services.announcer)`
  - `if mainActionFailed { Text(saveFailure).id("main.saveFailure") }`
  - `if let card = model.activeJourneyCard { ActiveJourneyCardView(content: card) { apply(model.resumeJourney()) } }`
- 메인 실패는 **뷰 `@State private var mainActionFailed`**에 둡니다.
  - `apply(_:)` 규칙: `.saveFailed`면 true, `.done`이면 false, `.rejected`면 그대로입니다.
  - `.onChange(of: model.path)`가 되면 false로 바꿉니다(다른 화면으로 가면 사라짐).
  - 모델에 `.saveFailed` 상태는 두지 않습니다.
- :187-188 버튼
  - 문구: `destination == .preparation ? model.mainStartTitle : destination.mainMenuTitle`
  - 동작: active가 있으면 `confirmsNewJourney = true`, 없으면 `model.startTripFromMain()`
  - id `open.preparation`은 유지합니다.
- `@State private var confirmsNewJourney`, `.newJourneyConfirmation(isPresented: $confirmsNewJourney) { apply(model.confirmNewJourney()) }`
- :30 일반 문구 조건은 그대로 둡니다. W07 저장은 `saveHandlingFailure`라 `saveFailure`를 남기지 않습니다.
- DEBUG
  - 트레일링 오버레이(:89-107)에 `if model.path.isEmpty, let failure = services.failNextSave`일 때 id `test.main.failNextSave` 버튼을 둡니다. 여행 화면의 `test.failNextSave`와 동시에 있으면 여러 개가 일치하므로 id와 노출 조건을 분리했습니다.
  - `testDiagnostics`(:239-256)에 `test.writeAttempts`(값 `testBootstrap.writeCounter.attempts`)를 추가합니다.

#### F. UI 테스트 인프라

**12. `ios/FocusMate/UITestBootstrap.swift` (수정)**
- **이름 붙은 시드 딕셔너리**를 씁니다(`timerSeeds` 방식, :271). 파라미터 파서는 두지 않습니다.
  - `private struct LifecycleSeed { busID, minutes, originStopID, direction, elapsed: Int? }`. elapsed가 nil이면 출발 대기입니다.
  - `static let lifecycleSeeds: [String: LifecycleSeed]`
  - `static func lifecycleSnapshot(_ name: String) -> AppSnapshot?`: internal로 두어 단위 테스트가 쓸 수 있게 합니다.
- 시드 목록:

| 이름 | 버스·분·출발·방향 | 진도 | 주 사용 AC |
|---|---|---|---|
| `lifePaused90` | 2014·25·seongsu·1 | 90 | 1, 3, 4, 5, 6, 7, 27, 28, 29, 30, 32~35 |
| `lifePaused600` | 2014·25·seongsu·1 | 600 | 8, 9, 10, 11, 14, 15, 16, 20, 21, 22 |
| `lifePaused0` | 2014·25·seongsu·1 | 0 | 2(25), 19 |
| `lifePaused299` / `lifePaused300` | 2014·25·seongsu·1 | 299 / 300 | 17 경계 |
| `lifePaused1499` | 2014·25·seongsu·1 | 1499 | 2(1 min), 13(도착 전이), 17 |
| `lifeReverse300` | 2014·25·seongsu·−1 | 300 | 18(가) |
| `lifeWrap900` | 2014·25·seongsuBridgeNorth·1 | 900 | 18(나) |
| `lifeArrived` | 2014·25·seongsu·1 | 1500 | 24 |
| `lifeAwaiting` | 2014·25·seongsu·1 | 출발 대기 | 23 |

- 공통 값:
  - departed·paused=true. 재실행된 상태와 같습니다.
  - 도착지는 `JourneyReach.station(..., stops: minutes/minutesPerStop)`로 **식과 일치**시킵니다.
  - initialStation·currentStation은 출발 정류장입니다(카탈로그 이름, 같은 방향).
  - **완료 기록 1건**(`RecordSnapshot`, id `seed-record-1`, 25분)을 넣어 AC-31이 의미를 갖게 합니다.
  - 카드는 `fixedCard`입니다.
- `seeds`(:147)에 `lifecycleSeeds.keys`를 합칩니다. 없는 이름은 기존처럼 `invalidArguments` → `test.setupError`입니다(:49). 이름 시드라 R5의 잘못된 파라미터 입력 경로는 **해당 없습니다**. 대신 `LifecycleSeedTests`가 모든 시드의 validate 통과, 도착지=식, 현재 정류장=출발지, 기록 1건을 검증합니다.
- **W07 단언 규칙**: 현재 정류장·도달 정류장·카드 내용을 단언하는 W07 테스트는 `life*` 시드만 씁니다. 기존 `activeJourney`·`timer*` 시드는 출발지와 현재 정류장이 다르거나 도착지가 식과 다르므로, 존재·흐름·회귀 확인에만 씁니다. 예외는 AC-25의 손상 시드(`v3InvalidMinutes`)입니다. 여정이 버려지는 것만 봅니다.
- `@Observable final class UITestWriteCounter { private(set) var attempts = 0; func record() }`
  - `let writeCounter = UITestWriteCounter()`
  - `modelStore.writeData`(:189-191)의 첫 줄에서 `record()`를 부릅니다. 실패 주입보다 먼저 세므로 실패한 시도도 셉니다.
  - 시드 `prepare()`는 별도 store라 세지 않습니다. 프로세스마다 0부터 시작하므로 재실행을 넘어서 비교하지 않습니다.
- `UITestNextSaveFailure.arm`은 누적형입니다(:387-390). 그대로 두고 아래 규칙을 지킵니다.
  - **반드시 쓰기가 일어나는 동작 직전에만** arm합니다. `.rejected`가 예상되는 동작(연타의 두 번째, 도착 여정 이어가기 등)에는 arm하지 않습니다.
  - arm한 동작 뒤에는 `writeAttempts` 증가가 정확히 1인지 단언해 예약이 소비됐음을 증명합니다. 남은 예약이 다음 쓰기로 새는 것을 테스트가 바로 잡아냅니다.
  - 대화상자는 arm 버튼을 가리므로 순서는 **arm → 대화상자 열기 → 확정**입니다. 메인과 일시정지 화면에는 자율 쓰기가 없어 결정적입니다.
- :214 주석: "진단용 진입(autoStart 없음). 실제 이어가기는 `resumeJourney`."

**13. `ios/FocusMateUITests/UITestLaunchSupport.swift` (수정)**
- 추가:
  - `static func launchLifecycle(seed: String, extraArguments: [String] = [])`: 수동 시계 포함
  - `func writeAttempts() throws -> Int`
  - `func failNextMainSave(then:)`: `test.main.failNextSave`
  - `func alert(titled:) -> XCUIElement`, `func alertButton(_ id: String, label: String) -> XCUIElement`: `CardCustomizationFlowTests.swift:521-554`와 같은 방식
  - `func abandonDiagnostic() throws -> [String: Any]`
- 관측 규칙:
  - **alert가 열린 동안의 불변(AC-6·14·27·28)**은 열기 전 값과 **안전 버튼으로 닫은 직후** 값의 차이(`writeAttempts`, `persistedBytes`, `test.snapshot`)로 봅니다(R6). 열린 상태에서 진단을 읽는 것은 보강 단언으로만 씁니다.
  - 재실행은 `relaunch(extraArguments: manualClockArguments)`로 합니다. AC-28의 "3600초 뒤"는 재실행 때 시계가 초기화되므로 (24 min, 90, paused=true) 단언으로 대체합니다.
  - AC-29의 "5초 진행"은 `advance(1, times: 5)`로 매핑합니다(R7, advance5 버튼은 없음).
  - alert 버튼의 진짜 두 번 탭은 재현할 수 없습니다(첫 탭에 닫힘). AC-11·21은 `doubleTap()` + 쓰기 증가 1 + path로 최대한 재현하고, 1차 보장은 단위 테스트(모델 `.rejected`, `hasFinished`, R2)라고 테스트 주석에 적습니다.
  - 낭독은 `test.announcements`의 항목 증가분으로 봅니다. 포기 안내와 이어가기 낭독은 정확히 +1이고, 재실행 뒤 포기 안내는 0입니다(R4).

### 의존성 및 영향도
- 새 라이브러리는 없고 저장 형식도 바뀌지 않습니다(v4).
- 현재 정류장이 처음으로 바뀝니다. 메인 표시(`RootView.swift:170-174`), 시간 선택 출발지(`AppModel+JourneyStart.swift:5-7`), 다음 승차권에 반영됩니다. `RouteStops.position(of:)`는 id로 찾으므로 카탈로그 이름이 들어와도 문제없습니다.
- 기존 테스트:
  - `BoardingModelTests.swift:306-317`: active가 있을 때 `startTripFromMain`이 false·쓰기 0이라는 안전 테스트로 바꿉니다. 원래 단언(쓰기 1, active nil, 기록 0)은 `confirmNewJourney`로 옮깁니다.
  - `BoardingModelTests.swift:321-332`: `confirmNewJourney`가 `.saveFailed`일 때 path `[]`·active 불변이고 **`saveFailure == nil`**(일반 문구 없음)인지로 바꿉니다.
  - `BoardingModelTests.swift:336-344`, `:364-374`: 변화 없습니다.
  - `ActiveJourneyMainUITests.swift:19-58`: 카드 제목, alert 확정 → `screen.time`, 저장 실패 시 `main.saveFailure`로 다시 씁니다. `activeJourney` 시드는 흐름 확인에만 씁니다.
  - `BoardingLargeTextUITests.swift:65-69`: `main.newJourney.confirm` 단계를 넣습니다. `:32`는 id가 같아 그대로 통과합니다.
  - `JourneyTimerAccessibilityUITests.swift:60-82`: 수정 없이 통과해야 합니다(T6 완료 조건).
  - `BoardingFlowUITests.swift:13-17, 186`, `JourneyTimerLifecycleUITests.swift:123, 166`: id·문구가 유지되므로 영향 없습니다.
- W09 인계: FR-9는 임시입니다. W09는 하차 저장에서 `endingActiveJourney(at:)`와 `reachedStation`(도착이면 저장된 도착지)을 재사용하고, `ActiveJourneyCardContent.Kind.arrived`를 하차 진입으로 바꿉니다.
- W06 인계(머지 뒤 필수 재실행): **AC-3**(이어가기 바로 흐름, 1회용 신호가 뷰 재생성으로 사라지지 않는지), **V7 AC29·AC-33**(하단 배치), AC-13·26. W06이 하단에 지도 도구를 두면 inset 순서를 조정합니다(위치는 디자인 스펙을 따름).

#### 기존 구조와의 차이
- 대화상자 표시 상태는 뷰 `@State`에 둡니다. 기존 저장 정리 확인은 모델에 둡니다(`AppModel.swift:84, 142-172`). 확정의 안전성은 모델의 상태 기반 가드와 `LifecycleActionResult.rejected`가 맡고, alert 바인딩의 호출 순서에 의존하지 않습니다.
- W07 저장은 `saveHandlingFailure`를 씁니다. 실패를 호출자가 구체적으로 안내하고 상태가 바뀌지 않으므로 일반 `saveFailure` 문구를 남기지 않습니다. 기존 저장은 그대로입니다.
- W07 동작은 Bool 대신 `LifecycleActionResult`(done/rejected/saveFailed)를 반환합니다. 거부를 실패로 안내하지 않습니다.
- BR-6은 모델 계약 `abandonJourney(timerPaused:)`로 드러냅니다. 판단 근거는 런타임 진도의 주인인 컨트롤러 상태입니다.
- 도착 여정의 정류장은 저장된 `destinationStopID`를 씁니다. 진행 중이면 식으로 계산합니다.
- autoStart 규칙을 넓힙니다. "'시작'을 직접 본 경우" 외에 "이번 실행에서 이어가기 저장에 성공한 같은 여정(1회용 메모리 신호)"도 포함합니다. 저장된 paused=false만으로는 여전히 자동 시작하지 않습니다.
- 메인 실패 안내는 뷰 @State, 포기 안내는 모델 메모리에 둡니다(화면을 건너 전달해야 하므로).
- UI 테스트에 쓰기 시도 수 진단 `test.writeAttempts`, 메인 전용 실패 주입 `test.main.failNextSave`, 기록 1건을 포함한 이름 붙은 `life*` 시드를 새로 둡니다.

### 구현 순서

| # | 태스크 | AC | 파일 | focused 테스트 | 의존 |
|---|---|---|---|---|---|
| T1 | [Must] 도달 정류장 규칙·여정 종료 후보 | 17, 18(가·나=900초), 19, 8·16·24의 정류장, BR-1~4 | JourneyReach | FocusMateTests/JourneyReachTests | 없음 |
| T2 | [Must] 문구·카드 값 | 1(필드), 2(0/1/60/61/1499), 23(25 min), 24(kind), 32(카드 라벨) | JourneyLifecycleText, ActiveJourneyCardContent | FocusMateTests/ActiveJourneyCardContentTests | 없음 |
| T3 | [Must] 포기 흐름 컨트롤러 | 15(포커스 의도), 20(실패·재시도), 21, BR-6 | JourneyAbandonController(+`LifecycleActionResult`는 T4 파일. T3은 enum 선언을 이 파일에 둘 수 있으며 이때 T4가 참조) | FocusMateTests/JourneyAbandonControllerTests, JourneyLifecycleTestDoubles | 없음 |
| T4 | [Must] 모델 동작 | 4, 5, 7, 8, 10, 11, 12, 16, 19, 20(모델 불변), 23, 24, 31, 35, BR-6·10 | AppModel, AppModel+JourneyLifecycle, AppModel+Boarding | FocusMateTests/JourneyLifecycleModelTests, BoardingModelTests | T1, T2, T3 |
| T5 | [Must] 메인 화면 | 1, 6, 7, 10, 12, 24, 25, 35의 화면, 32(카드·포기 안내) | MainActiveJourneyView, RootView(비 DEBUG) | ActiveJourneyMainUITests, BoardingLargeTextUITests, BoardingFlowUITests | T2, T4 |
| T6 | [Must] 타이머 화면 연결 | 3, 13, 14, 15, 20, 26, 32(포기하기 라벨·이어가기 낭독), 33(타이머 쪽) | JourneyAbandonBar, JourneyView, (조건부) JourneyTimerView:19 | JourneyTimerAccessibilityUITests(**V7 AC29 통과가 완료 조건**), JourneyTimerUITests(V8 스와이프), DepartureBriefingUITests | T3, T4 |
| T7 | [Must] UI 테스트 인프라 | 전제 | UITestBootstrap, RootView(DEBUG), UITestLaunchSupport | FocusMateTests/LifecycleSeedTests | T1, T5 |
| T8 | [Must] 기능 UI 테스트 | 1~26, 29, 30, 31, 35 | 신규 UI 테스트 3개 | JourneyResumeUITests, NewJourneyUITests, JourneyAbandonUITests | T5, T6, T7 |
| T9 | [Should] 생명주기·접근성 UI 테스트 | 27, 28, 32, 33, 34 | 신규 UI 테스트 1개 | JourneyLifecycleSafetyUITests | T5, T6, T7 |
| T10 | [Must] 문서 | - | FLOWS, CURRENT-STATE, status, architecture, glossary, plan | - | T8, T9 |

- 병렬로 진행할 수 있는 묶음: T1·T2·T3, T5와 T6, T8과 T9.
- T5와 T7은 같은 RootView를 고치므로 순차입니다.
- `LifecycleActionResult`는 T3 파일(`JourneyAbandonController.swift`)에 선언합니다. 그러면 T3이 T4에 의존하지 않습니다.
- 전체 테스트는 돌리지 않고, 각 태스크의 focused 테스트가 통과하면 다음 단계로 갑니다.

**단위 테스트 요지**
- **T1**:
  - 2014/25 정방향 성수역: 0·299 → seongsu, 300 → seongsuDong, 600 → ttukseom, 1499 → seoulForest
  - 도착(1500)은 저장 `destinationStopID`를 씁니다. 식과 다른 도착지를 가진 픽스처도 저장값을 따르는지 봅니다.
  - 302/30·360, 421/40·480 → seongsuDong
  - 역방향 300 → seongsuIntersection(−1), seongsuBridgeNorth 900 → seongsu(1), 출발 대기 → 출발지
  - 분 상한, 카탈로그 밖이면 nil
  - `endingActiveJourney`는 records·cards·initialStation을 보존합니다.
- **T2**:
  - 0/1/60/61/1499 → 25/25/24/24/1 "min 남음"(시·초 없음)
  - "지선 2014", "독서 · 서울숲 입구까지", arrived에는 이어가기 없음, 출발 대기는 전체 분
- **T3** (`FakeJourneyAbandoner(results:)`, calls):
  - request 2회 → 하나
  - cancel → calls 0, focusTarget이 abandonButton
  - confirm 2회 → calls 1
  - `.rejected` → 실패 표시 없음
  - `.saveFailed` → showsFailure·포커스, 재시도하면 성공
  - **confirm→cancel**·**cancel→confirm** 두 순서 모두 calls 1, 최종 focusTarget nil(R2)
  - 성공 뒤 request 무시
- **T4** (`LifecycleProbe`: `attempts`는 실패 포함, `writes`는 성공 바이트, `shouldFail`, R1):
  - resume: 출발 후는 attempts·writes 1, (90, false), path `[.journey]`, `consumeResumeEntry`가 true 다음 false
  - resume 연타: 두 번째는 `.rejected`, attempts 1
  - resume 출발 대기: attempts 0. 도착: `.rejected`, 0
  - resume 실패: `.saveFailed`, path `[]`, 신호 없음, `saveFailure == nil`
  - confirmNewJourney:
    - AC-8: ttukseom(1), writes 1, `[.time]`, records 1건 유지
    - AC-10: 실패하면 attempts 1·writes 0·불변, 재시도하면 AC-8 결과
    - AC-11: 연타는 `.rejected`
    - AC-23·24: 출발지, seoulForestGate
  - abandon:
    - AC-16: path `[]`, notice "뚝섬역"
    - AC-19
    - `timerPaused: false` → `.rejected`·attempts 0(BR-6)
    - path에 journey 없음·출발 대기·도착 → `.rejected`
    - AC-20: 실패하면 불변
  - `open`·`beginCardCustomization`이 notice를 지웁니다(BR-10).
  - active가 있을 때 `startTripFromMain`은 false·0
  - 모든 경로에서 records 수가 불변입니다(AC-31).
- **T7 LifecycleSeedTests**: 모든 `life*` 시드가 `launchRoute() == .main`, 도착지=식, currentStation=출발지, 기록 1건, 출발 후면 paused=true인지 봅니다.

### 위험
1. 시스템 alert가 열릴 때 VoiceOver 첫 위치는 시뮬레이터에서 관측할 수 없습니다(사용자 결정에 따라 W14 실기기, trust-ledger). 대체 관측은 `role: .cancel` 코드 리뷰와 버튼 문구·존재 UI 테스트입니다.
2. 이어가기 낭독(push 직후)과 **포기 안내 낭독·포커스(pop 전환과 alert 닫힘 도중)**가 시스템 화면 전환 알림에 묻힐 수 있습니다. 1회 호출은 `test.announcements`로 확인하고, 실제 청취는 W14에서 봅니다.
3. 이어가기 신호는 1회용입니다. W06 머지로 JourneyView의 @State가 다시 만들어지면 새 타이머가 일시정지로 열려 FR-2가 조용히 깨질 수 있습니다. 이전 타이머의 `leave`가 paused=true를 저장하므로 데이터 손상은 없습니다. W06 머지 뒤 AC-3을 반드시 다시 돌립니다.
4. 하단 bar와 큰 글씨: V7 AC29·AC-33을 T6 완료 조건으로 두고, 실패하면 상세 설계 9의 대안 순서를 따릅니다. W06 하단 도구와 겹치는지는 머지 때 조정합니다.
5. 체크포인트 저장에 실패해 멈춘 상태에서 포기하면 도달 정류장은 **마지막 저장 경과**로 계산됩니다. 저장 경과는 화면 경과보다 작거나 같으므로 화면보다 **한 칸 뒤**일 수 있습니다. BR-1 문언대로 수용합니다.
6. `UITestNextSaveFailure`는 누적형이라 실패 예약이 다음 쓰기로 샐 수 있습니다. 쓰기가 확실한 동작에만 arm하고 증가 1을 단언하는 규칙으로 막습니다.
7. 기존 테스트 4개 파일을 갱신하고 V7 AC29를 회귀로 돌려야 합니다. 하나라도 빠뜨리면 회귀처럼 보입니다.
8. 문서 충돌: `docs/FLOWS.md:66`("이어가기는 안내 없이 바로 여행 화면")은 출발 대기 여정의 FR-8과 다릅니다. PRD 기준으로 고칩니다.

### 문서 갱신 대상 (T10)
- `docs/FLOWS.md`
  - :9 메인 행: 카드 변형, 새 여정 확인
  - :17 멈춤·포기 행: 일시정지 중에만, 도달 정류장, 방향 유지
  - :66: 출발 대기 이어가기는 출발 안내부터
  - :88, :98, :99를 확정 계약으로 바꿉니다.
  - 새 절 "iOS 포기·이어가기·생명주기 — W07": 문구, 저장 1회, 실패 안내 위치(메인 `main.saveFailure`, 타이머 `journey.timer.saveFailure`), 연타, 대화상자 중 백그라운드·종료, 도착 여정 임시 처리
  - **출발 대기 여정을 이어간 뒤 그만두려면 '시작' → 일시정지 → 포기의 3단계가 필요합니다**(FR-8에 포기가 없고 뒤로가기는 막혀 있음). PRD 결정 범위라 결함이 아님을 적어 둡니다.
- `docs/CURRENT-STATE.md:75`: "나가기·이어가기는 W07"을 지우고 W07 단락을 추가합니다.
- `context/journey/status.md:38`: FR-13 / AC-15, NFR-2(Simulator) 구현 근거와 W14로 넘긴 항목(alert 첫 포커스, 실제 낭독)
- `context/journey/architecture.md:17`: `JourneyReach`, `AppModel+JourneyLifecycle`, `JourneyAbandonController`, autoStart 확장, `saveHandlingFailure`
- `context/journey/glossary.md`: 도달 정류장, 이어가기, 포기
- `.dev/plan.md`
  - :12 W07 상태
  - :64, :66 인계: W09(도착 여정 처리는 임시, `endingActiveJourney` 재사용), W06(머지 뒤 AC-3·V7 AC29·AC-33 재실행, 하단 영역 조정, `abandonJourney(timerPaused:)` 계약), 카드 교체 불변식은 여전히 범위 밖

### 탐색 추가 항목
- `ios/FocusMate/AppModel.swift:84, 142-172` → 모델 주도 확인 패턴. 대화상자 상태 배치를 비교한 근거입니다.
- `ios/FocusMate/AppModel.swift:198-219, 280` → `save`/`persist`(:214 경로가 바뀔 때만 path 초기화), `beginCardCustomization`(포기 안내를 지우는 지점)
- `ios/FocusMate/RootView.swift:30-33, 51` → 일반 저장 실패 문구, `open`을 거치지 않는 fullScreenCover
- `ios/FocusMate/AppModel+JourneyTimer.swift:14-19` → id·departed 가드. 포기 뒤 `leave` 저장을 거부합니다.
- `ios/FocusMate/JourneyTimerController.swift:47-49, 124-134, 155-160` → autoStart 초기 상태, paused의 `leave`는 쓰지 않음, 체크포인트 실패 시 halt
- `ios/FocusMate/JourneySnapshot.swift:40-46, 74-97` → 도착지 생성식, validate가 식과의 일치를 검사하지 않음
- `ios/FocusMate/JourneyPlanner.swift:25-32`, `ios/FocusMate/RouteData.swift:10-37, 77-88` → 정류장 수, 순환, 간격
- `ios/FocusMate/RecordSection.swift:3-16` → 시드 기록 1건에 쓰는 `RecordSnapshot` 멤버와이즈 생성자
- `ios/FocusMate/CardCustomizationView.swift:108-111`, `ios/FocusMateUITests/CardCustomizationFlowTests.swift:521-554` → alert 관례와 UI 테스트 접근 패턴
- `ios/FocusMate/DepartureBriefingController.swift:13, 21`, `ios/FocusMateUITests/DepartureBriefingUITests.swift:53` → 포커스를 컨트롤러 상태로 진단하는 패턴(R3)
- `ios/FocusMate/JourneyView.swift:146-159` → 수동 시계 버튼은 1/10/60/600/armForeground600뿐입니다(R7).
- `ios/FocusMate/UITestBootstrap.swift:147-200, 264-286, 317-319, 387-390` → 시드·쓰기 주입 지점, 기존 시드의 불일치, 누적형 실패 예약
- `ios/FocusMateUITests/JourneyTimerAccessibilityUITests.swift:60-82` → 하단 bar의 직접 회귀 대상(T6 완료 조건)
- `ios/FocusMateTests/JourneyTimerModelTests.swift:10-28` → 성공 쓰기만 세는 Probe(R1 분리 근거)
- `ios/FocusMateTests/BoardingModelTests.swift:304-374`, `ios/FocusMateUITests/ActiveJourneyMainUITests.swift:19-58`, `ios/FocusMateUITests/BoardingLargeTextUITests.swift:56-69` → 기대가 바뀌는 기존 테스트
- `docs/FLOWS.md:9, 17, 66, 88, 98-99`, `.dev/plan.md:12, 64, 66` → 문서 갱신 지점

---

## 확인이 필요한 사항

추가 확인 사항 없음. 설계가 완료되었습니다.

## Testability 평가 (test-architect)

## Testability 평가: W07 포기·이어가기·생명주기

결론은 **8/10, TESTABILITY PASS**입니다. 재설계는 필요 없고, 아래 권고 R1~R7만 설계서에 반영하면 됩니다.

설계서는 `/Users/bonseung/Documents/ChatGPT/new-w07/.dev/feat-abandon-resume-lifecycle/design.md`입니다. 규칙(JourneyReach), 화면 값(ActiveJourneyCardContent), 모델 동작, 포기 흐름 컨트롤러는 모두 주입된 저장소와 Fake로 단위 테스트할 수 있습니다. 대부분의 UI AC는 수동 시계와 `test.*` 진단으로 결정적으로 자동화됩니다. 자동화할 수 없는 것은 대화상자가 열릴 때 VoiceOver가 처음 읽는 위치 하나뿐이고, 이것은 W14 실기기 점검과 trust-ledger로 넘깁니다.

### 러너
- `python3 scripts/check-ios.py test <files>`로 돌립니다(focused).
- 단위 테스트는 FocusMateTests(XCTest), UI 테스트는 FocusMateUITests(XCUITest, 시뮬레이터)입니다.
- 하네스는 이미 있습니다: `ios/FocusMateUITests/UITestLaunchSupport.swift`의 FocusMateUIHarness, 수동 시계, `test.failNextSave`, `test.snapshot`, `test.persistedBytes`, `test.announcements`.

### 컴포넌트별 테스트 전략

#### JourneyReach (도달 정류장 규칙, BR-1·2)
- **레이어**: 동작(순수 규칙). 러너는 XCTest.
- **단위**:
  - 표 기반으로 `reachedStops`의 경계를 봅니다: 0, 299, 300, 1499, 1500, 분 상한, 간격 5/6/8.
  - `station`은 정방향·역방향과 순환(끝에서 처음)을 봅니다.
  - `reachedStation`은 출발 대기면 출발지, 도착이면 도착지, 카탈로그 밖이면 nil입니다.
  - `endingActiveJourney`는 records·cards·initialStation을 보존하고 journey를 비우는지 봅니다.
- **통합**: 없음.
- **모의 대상**: 없음. 실제 `RouteStops`와 `BusLine` 카탈로그를 씁니다.
- **격리**: 다른 코드에 의존하지 않는 enum과 extension입니다.
- **AC 매핑**: AC-17(전체), AC-18(가), AC-18(나), AC-19, AC-24의 정류장, AC-8·16의 정류장. AC-18(나)는 질문 1의 답이 와야 기대값이 정해지고, 그 전에는 RED를 쓸 수 없습니다.

#### JourneyLifecycleText / ActiveJourneyCardContent
- **레이어**: 동작(순수 포맷터와 값 타입). 문구 상수 자체는 표현입니다.
- **러너**: XCTest.
- **단위**:
  - 남은 시간 올림: 0/1/60/61/1499초 → 25/25/24/24/1입니다.
  - 버스 문자열 "지선 2014", 경로 문자열 "{태그} · {도착지}까지"를 봅니다.
  - Kind가 resumable과 arrived로 갈리는지, 출발 대기는 전체 분인지 봅니다.
  - `showsResume`, `accessibilityLabel` 조합을 봅니다.
- **모의 대상**: 없음.
- **격리**: `init?(journey:)` 하나만 입력으로 받습니다.
- **AC 매핑**: AC-1(필드), AC-2, AC-23의 "25 min", AC-24의 kind, AC-32의 카드 라벨.

#### AppModel+JourneyLifecycle (resume, confirmNewJourney, abandon, consumeResumeEntry, mainStartTitle, startTripFromMain 가드, open의 notice 초기화)
- **레이어**: 동작(상태·가드·라우팅). 러너는 XCTest.
- **단위**:
  - 기존 `JourneyTimerModelTests.swift:10-28`의 패턴을 씁니다. 메모리 readData와 writeData(Probe)를 주입하고, `AppModel(store:journeyFactory:)` 뒤에 `loadIfNeeded`를 부릅니다.
  - path, snapshot, mainLifecycleNotice, 쓰기 수, 저장된 바이트의 디코드 값을 단언합니다.
  - 연타는 두 번 호출해서 봅니다. 가드가 상태(path, active) 기반이라 시간 의존이 없고 결정적입니다.
- **통합**: `saveJourneyProgress`(실제 코드 재사용)와 SnapshotCodec 왕복을 실제로 통과시킵니다.
- **모의 대상**: 파일 I/O만 대체합니다(writeData 클로저와 shouldFail 스위치).
- **격리**: 확장 파일과 저장 프로퍼티 2개뿐이고, 외부 의존은 store 하나입니다.
- **AC 매핑**: AC-4, AC-5, AC-7, AC-8, AC-10, AC-11, AC-12, AC-16, AC-19, AC-20(모델 불변), AC-23, AC-24, AC-31(모든 경로에서 records 불변), AC-35, BR-10(open이 notice를 지움).
- **권고 R1**: Probe를 `attempts`(실패한 시도 포함)와 `writes`(성공한 바이트)로 나눕니다. 지금 패턴은 성공한 쓰기만 셉니다. AC-10·35의 "실패 시 시도 1회, 재시도 1회"를 단언하려면 시도 수가 필요하고, UI의 `test.writeAttempts`(실패도 셈)와 의미도 맞춰야 합니다.

#### JourneyAbandonController (+ FakeJourneyAbandoner)
- **레이어**: 동작(상태 기계). 러너는 XCTest.
- **단위**:
  - 이미 설계에 있는 경우: request를 두 번 불러도 confirming은 하나, cancel 후 호출 0, confirm을 두 번 불러도 호출 1, `isPaused == false`면 무시, 실패하면 showsFailure이고 재시도하면 성공, 성공 뒤 request는 무시.
  - **권고 R2**: alert 바인딩의 set(false)와 버튼 액션의 호출 순서가 보장되지 않으므로 두 순서를 모두 단위 테스트로 고정합니다.
    - `confirm` → `cancel`: 호출 1, 성공 상태 유지.
    - `cancel` → `confirm`: 호출 1. 확정이 isConfirming에 의존하지 않음을 증명합니다.
  - **권고 R3**: 포커스 복귀 의도를 컨트롤러 상태로 올립니다. 예: `private(set) var focusTarget: FocusTarget?`(`.abandonButton`). cancel이나 실패 후 닫힐 때 설정됩니다. 뷰는 이 값을 `@AccessibilityFocusState`에 옮기기만 하고, DEBUG `test.abandon.focus`는 이 값을 보고합니다.
    - 근거: 출발 안내는 이미 `briefing.focusTarget`을 진단하고 있고(`JourneyView.swift:82, 175`), 이것은 UI 테스트에서 단언됩니다(`DepartureBriefingUITests.swift:53`).
    - 반면 `@AccessibilityFocusState` 값을 그대로 노출하는 `test.timer.focus`(`JourneyTimerView.swift:101`)를 단언하는 UI 테스트는 하나도 없습니다. VoiceOver가 꺼진 시뮬레이터에서 이 값이 유지된다는 근거가 저장소에 없습니다.
- **모의 대상**: `JourneyAbandoning`. Fake는 결과 배열을 순서대로 소비하고 calls를 기록합니다.
- **격리**: 프로토콜 주입이라 AppModel 없이 테스트합니다.
- **AC 매핑**: AC-15(포커스 의도), AC-20(showsFailure·재시도), AC-21, BR-6.

#### JourneyAbandonBar / JourneyView 연결 (autoStart||resumed, 낭독, safeAreaInset)
- **레이어**: 동작(조건부 노출, alert, 자동 시작, 낭독). 외곽선 스타일과 배치는 표현이라 범위 밖입니다.
- **러너**: XCUITest.
- **단위**: 일부만 가능합니다. 판단 로직은 컨트롤러와 모델에 있습니다(`consumeResumeEntry` 1회용은 모델 단위 테스트). `autoStart` 합성식과 `announce` 호출은 뷰 안에 있어서 UI 테스트로만 검증됩니다. W05와 같은 수준의 남는 감점입니다.
- **통합(XCUITest)**:
  - 노출 조건: `journey.abandon`의 존재·부재. 일시정지는 `journey.timer.pause`로, 도착은 수동 시계 advance로 만듭니다.
  - alert는 `app.alerts.matching(label == 제목)`으로 찾고, 버튼은 `.buttons.matching(identifier:)`에 label을 더해 찾습니다. 이 방식은 `CardCustomizationFlowTests.swift:521-554`와 `CardCustomizationView.swift:108-111`에서 이미 쓰고 있어 동작이 확인된 패턴입니다. 본문은 `alert.staticTexts`의 label로 단언합니다.
  - 실패 주입은 `test.failNextSave`를 arm한 뒤 abandon을 누르고 confirm합니다.
  - 낭독은 `test.announcements`에서 정확히 1회 나오는지 보고, 같은 label의 staticText가 화면에 없는지도 봅니다.
- **모의 대상**: ManualJourneyClock, UITestFeedbackRecorder(announcer), UITestNextSaveFailure. 모두 기존 것입니다.
- **AC 매핑**: AC-3, AC-4(후반), AC-13, AC-14(문구·불변), AC-15(닫힘·resume 노출·쓰기 0·focus 진단), AC-20, AC-21, AC-26, AC-32(포기하기 라벨, 이어가기 낭독), AC-33.

#### MainActiveJourneyView / RootView 연결 (카드, 안내, 새 여정 alert, 버튼 문구, DEBUG)
- **레이어**: 동작(조건부 카드, 안내, alert, 라우팅). 카드 스타일은 표현입니다.
- **러너**: XCUITest.
- **통합**:
  - 카드는 `main.activeJourney`(combine 한 요소, label 단언)와 형제 버튼 `main.resumeJourney`를 봅니다.
  - 새 여정 alert 버튼은 `main.newJourney.keep`과 `main.newJourney.confirm`입니다.
  - 안내는 `main.abandonNotice`와 `main.saveFailure`입니다.
  - 메인 실패 주입은 `test.main.failNextSave`입니다. 식별자를 분리한 것은 적절합니다. 진단 오버레이는 path가 비었을 때만 보이므로 여러 개가 일치하는 문제를 피합니다.
- **권고 R4**: 포기 안내 낭독은 `.onChange(of: notice)`에 의존합니다. NavigationStack 루트 뷰가 살아 있어야만 발화하므로 다음 두 가지를 UI 테스트에 명시합니다.
  - 포기 직후 `test.announcements`의 항목 수 증가분이 정확히 1이어야 합니다.
  - 재실행 뒤 같은 문구가 낭독 기록에 없어야 합니다(AC-22, BR-10).
- **AC 매핑**: AC-1, AC-6, AC-7, AC-8, AC-9, AC-10, AC-11, AC-12, AC-16의 안내, AC-22, AC-23, AC-24, AC-25, AC-32(카드 한 요소와 별도 버튼, 포기 안내 1회 낭독), AC-35.

#### UITestBootstrap (lifecycle 시드, `--fm-ui-journey`, UITestWriteCounter)
- **레이어**: 테스트 인프라라 점수 대상이 아닙니다.
- **확인 사항**:
  - `modelStore.writeData`(`UITestBootstrap.swift:189-191`)의 첫 줄에서 세면 실패 주입보다 먼저 세므로 실패한 시도도 셉니다.
  - 시드 `prepare()`는 별도 `LocalSnapshotStore`라 세지 않습니다.
  - `applySaveScenario`가 실행 시 하는 쓰기는 카운터에 들어가지만, 차이(diff)로 단언하므로 무해합니다.
  - 카운터는 프로세스마다 0부터 시작하므로, 재실행을 넘어서 비교하면 안 됩니다.
- **권고 R5**: 파라미터 시드의 잘못된 입력(방향 0, 분 361, 경과가 total보다 큼, 카탈로그 밖 ID)이 `test.setupError`를 내는지 UI 테스트 1건으로 확인합니다. 시드가 조용히 통과하면 모든 매핑 테스트가 거짓 양성이 됩니다.

### 특히 평가할 항목

1. **alert 버튼 접근**: 가능합니다. 이미 동작이 확인된 패턴(`.accessibilityIdentifier`를 붙인 alert 버튼, 제목 label로 alert 찾기)이 있습니다. 설계의 `alertButton(_:)` 도우미는 identifier와 label을 같이 매칭하도록 만듭니다.
   - 연타 한계: alert 버튼은 첫 탭에 사라지므로 XCUITest에서 진짜로 "두 번 탭"할 수는 없습니다.
   - AC-11과 AC-21의 '그만두기' 2회는 `doubleTap()`으로 최대한 재현하고 쓰기 diff 1과 path를 단언합니다. 실제 보장은 단위 테스트(모델 가드, `hasFinished`, R2)가 맡는다고 테스트 주석에 적습니다.
   - `journey.abandon`과 `main.resumeJourney`의 연타는 `doubleTap()`으로 실제 재현할 수 있습니다.
2. **test.writeAttempts**: 관측할 수 있습니다. RootView `testDiagnostics` 오버레이는 모든 화면에 있습니다.
   - **권고 R6**: alert가 떠 있는 동안 뒤쪽 진단 요소를 XCUITest가 읽을 수 있다는 근거가 저장소에 없습니다. 기존 테스트는 모두 alert를 닫은 뒤에 읽습니다(`CardCustomizationFlowTests.swift:65-77`).
   - AC-6, AC-14, AC-27의 "열린 동안 저장값 불변·쓰기 0"은 열기 전 값과 안전 버튼으로 닫은 직후 값의 차이로 단언하는 것을 기본 경로로 정합니다. 안전 버튼 자체의 쓰기 0은 AC-7·15와 단위 테스트가 따로 증명합니다.
   - 열린 상태에서 읽기가 되면 보강 단언으로만 둡니다.
3. **수동 시계와 재실행**: 결정적입니다.
   - 재실행하면 수동 시계가 0으로 돌아가므로, AC-28의 "3600초 뒤"는 "종료 중 시간이 더해지지 않음"과 같은 단언(24 min, 90, paused=true)으로 대체합니다. 설계 F-13 그대로이고 타당합니다.
   - **권고 R7**: AC-29의 "5초 진행"용 `test.clock.advance5` 버튼은 없습니다. 있는 것은 1, 10, 60, 600, armForeground600입니다(`JourneyView.swift:148-152`). `h.advance(1, times: 5)`로 쓴다고 매핑을 고칩니다.
   - AC-30은 armForeground600을 누르고 `goBackground()`를 한 뒤 relaunch(manual)하면 되고, 기존 W05 패턴입니다.
4. **VoiceOver 포커스·낭독**:
   - 낭독(AC-32의 이어가기 1회, 포기 안내 1회)은 `test.announcements`로 자동화됩니다.
   - 포커스 복귀(AC-15)는 R3을 적용하면 컨트롤러 상태로 단위 테스트와 UI 테스트 양쪽에서 결정적이 됩니다.
   - 대화상자가 열릴 때 처음 포커스가 가는 위치(AC-6, AC-14, AC-27 후반, AC-32 일부)는 시스템 alert라 XCUITest로 관측할 수 없습니다.
     - 대체 관측: 안전 버튼이 `role: .cancel`인지는 코드 리뷰로 확인하고, 버튼 문구와 존재는 UI 테스트로 봅니다.
     - 실제 첫 위치는 W14 실기기 점검으로 넘기고 trust-ledger에 기록합니다. 질문 2에서 (a)를 고르는 경우입니다. (b) 앱 전용 창을 고르면 포커스 의도를 R3과 같은 컨트롤러 상태로 둘 수 있어 자동화가 가능해집니다.
5. **대화상자 중 백그라운드(AC-27)**: 자동화할 수 있습니다.
   - `goBackground()`(home 후 activate, `UITestLaunchSupport.swift:155-159`)를 하고 alert가 남아 있는지 `waitForExistence`로 봅니다.
   - 저장값과 쓰기 0은 R6의 방식(안전 버튼으로 닫은 뒤 diff)으로 봅니다.
   - 포기 대화상자는 일시정지 상태라 `enterBackground`가 쓰지 않으므로 결정적입니다.
   - 포커스 부분은 4번과 같이 자동화할 수 없습니다.

### 자동 테스트로 확인할 수 없는 항목과 대체 관측
| AC | 불가 부분 | 대체 |
|---|---|---|
| AC-6, 14, 27, 32 | alert가 열릴 때 VoiceOver 첫 포커스 | `role: .cancel` 코드 리뷰, 버튼 문구·존재 UI 테스트, W14 실기기 점검(trust-ledger) |
| AC-32 | 실제 청취(전환 알림에 묻히는지) | `test.announcements` 1회, W14 |
| AC-28 | 실제 3600초 경과 | 재실행 시 시계 리셋 + (90, paused, 24 min) 동치 단언 |
| AC-11, 21 | alert 버튼 진짜 2회 탭 | `doubleTap` 최대 재현 + 단위 가드 테스트가 1차 보장 |
| AC-18(나) | 기대값 미확정 | 질문 1의 답 필요(테스트 차단 요인) |
| AC-33 | 44pt "가려지지 않음"의 시각 판단 | `isHittable`, frame 높이 44 이상 단언, 레이아웃 붕괴는 범위 밖 |

### Testability Score: 8/10 (동작 컴포넌트 대상)
- **가점**:
  - 순수 규칙과 값 타입을 분리했습니다.
  - 프로토콜(`JourneyAbandoning`)을 주입하고 Fake 패턴을 씁니다.
  - 모델은 store 주입만으로 테스트됩니다.
  - 연타 방지가 시간 기반이 아니라 상태 기반입니다.
  - 이어가기 신호가 1회용이라 검증할 수 있습니다.
  - UI 쪽은 쓰기 수, 저장값, 낭독 진단과 실패 주입 순서를 명시했습니다.
- **감점**:
  - (−1) 시스템 alert의 첫 포커스는 관측할 수 없습니다(구조적 한계, 대체 관측 있음).
  - (−1) 뷰 접착부(autoStart 합성식, 포기 안내 onChange 낭독, alert 바인딩 순서)는 XCUITest로만 검증됩니다. 포커스 진단이 FocusState 원값에 의존하는 문제는 R3으로 해소할 수 있습니다.

### 판정
TESTABILITY PASS입니다. 설계를 확정하고 red-green-refactor로 들어갈 수 있습니다. 진입 전에 아래를 반영해 주세요(구조 변경이 아니라 테스트 계약 보강입니다).
- **R1**: Probe를 `attempts`와 `writes`로 나눕니다.
- **R2**: 컨트롤러에서 confirm과 cancel의 두 순서를 단위 테스트로 고정합니다.
- **R3**: `JourneyAbandonController.focusTarget`을 두고, `test.abandon.focus`는 그 값을 보고합니다(DepartureBriefing 패턴).
- **R4**: 포기 안내 낭독은 증가분 정확히 1회, 재실행 뒤 0회를 단언합니다.
- **R5**: 파라미터 시드의 잘못된 입력이 `test.setupError`를 내는지 1건 확인합니다.
- **R6**: alert가 열린 동안의 불변은 안전 버튼으로 닫은 뒤 diff로 보는 것을 기본 경로로 둡니다.
- **R7**: AC-29는 `advance(1, times: 5)`로 매핑합니다.
- 차단 요인: AC-18(나)의 기대값(질문 1)이 정해져야 해당 RED를 쓸 수 있습니다.

### 탐색 추가 항목
- `ios/FocusMateUITests/CardCustomizationFlowTests.swift:521-554`: alert를 제목 label로 찾고, 버튼을 identifier와 label로 찾는 동작 확인된 패턴입니다. 진단은 닫은 뒤에 읽습니다.
- `ios/FocusMate/JourneyView.swift:82, 172-180`, `ios/FocusMateUITests/DepartureBriefingUITests.swift:53`: 포커스를 컨트롤러 상태로 진단하는 패턴입니다(R3 근거).
- `ios/FocusMate/JourneyTimerView.swift:101`: FocusState 원값 진단인데, 이를 단언하는 UI 테스트가 없습니다(R3 근거).
- `ios/FocusMate/JourneyView.swift:146-159`: 수동 시계 버튼은 1/10/60/600/armForeground600뿐이고, `test.failNextSave`는 여행 화면에만 있습니다(R7, 메인 전용 arm이 필요한 근거).
- `ios/FocusMate/UITestBootstrap.swift:173-200, 229-246`: writeData 주입 지점, announcer=recorder, failNextSave 서비스 연결입니다.
- `ios/FocusMate/RootView.swift:239-256`: `testDiagnostics` 오버레이(`test.announcements`, 그리고 `test.writeAttempts`를 추가할 위치)입니다.
- `ios/FocusMateUITests/UITestLaunchSupport.swift:33-37, 134-159`: relaunch는 인자를 초기화하므로 수동 시계를 다시 넘겨야 합니다. failNextSave 순서와 goBackground도 여기 있습니다.
- `ios/FocusMateTests/JourneyTimerModelTests.swift:10-28`: Probe는 성공한 쓰기만 기록합니다(R1 근거).

### 설계 2차 반영 메모
- R1~R7 반영됨(설계 개정 2판). R5는 이름 시드 채택으로 해당 없음 → LifecycleSeedTests로 대체. AC-18(나) 900초 확정.
