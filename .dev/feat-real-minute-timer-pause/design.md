# 설계서 (개정 2판): W05 실제 분 타이머·일시정지 (journey FR-5 / AC-6)

설계 규모는 **대형**이다. v4 저장 형식, 카탈로그 검증, 주입형 단조 시계, 새 상태 기계, 여행 화면 교체, 내비게이션 차단, 재승차 차단, UI 테스트용 시계 제어를 모두 다룬다.

요구사항은 `.dev/feat-real-minute-timer-pause/prd.md`를 따른다(FR-1~12, BR-1~11, AC-1~32, 끝의 "사용자 결정").

진도 규칙은 사용자 결정(2026-10-15)에 따라 다음과 같다.
- 앱 프로세스가 살아 있으면 포그라운드·비활성·백그라운드에서 모두 시간이 흐른다. 시간은 ContinuousClock 단조 시간으로 잰다.
- 앱이 종료되면 여정이 끊긴 것으로 본다. 재실행하면 메인으로 가고, 여정은 마지막 저장 진도에서 일시정지 상태로 복원한다.
- 타이머 화면에서는 메인으로 갈 수 없다. 도착한 뒤에는 다시 시작할 수 없다.

## 변경 범위

### 신규 파일
pbxproj는 PBXFileSystemSynchronizedRootGroup이므로 등록할 필요가 없다.

| 파일 | 책임 |
|---|---|
| `ios/FocusMate/JourneyClock.swift` | `JourneyClock`·`JourneyTicker` 프로토콜, `ContinuousJourneyClock`, `TaskJourneyTicker`, `#if DEBUG ManualJourneyClock` |
| `ios/FocusMate/JourneyTimerDisplay.swift` | 올림 분 계산, "N min" 문자열, 낭독 라벨·값, 문구 상수(순수 함수) |
| `ios/FocusMate/JourneyTimerController.swift` | `JourneyProgressSaving` 프로토콜과 상태 기계 |
| `ios/FocusMate/JourneyTimerView.swift` | 타이머 UI와 DEBUG 진단 `test.timer` |
| `ios/FocusMate/NavigationPopBlocker.swift` | 스와이프 뒤로가기를 막는 UIKit 브리지 |
| `ios/FocusMate/AppModel+JourneyTimer.swift` | `saveJourneyProgress`, `hasDepartedJourney` |
| FocusMateTests | `JourneyClockTests`, `JourneyTimerDisplayTests`, `JourneyTimerControllerTests`, `JourneyTimerModelTests`, `JourneySnapshotV4StorageTests`, `JourneyTimerTestDoubles` |
| FocusMateUITests | `JourneyTimerUITests`, `JourneyTimerLifecycleUITests`, `JourneyTimerAccessibilityUITests` |

### 수정 파일 (앱)
- `JourneySnapshot.swift`: `paused` 추가, :4·:58 주석 교체, 검증 강화, v3 디코드 분기, 진도 갱신 메서드.
- `SnapshotCodec.swift`: currentVersion을 4로 올리고 v3 읽기 분기를 넣는다.
- `AppModel.swift`: `loadSnapshot`(:180-193)에 `restingForLaunch`를 적용하고, `open`(:261-267)과 `goBack`(:268-271)에 departed 가드를 넣는다.
- `AppModel+Boarding.swift`: `showBoardingPass`·`openBoarding`·`boardJourney`에 가드를 넣는다. `confirmDeparture`가 성공하면 `discardConfirmedPreparation()`을 호출한다.
- `JourneyServices.swift`: `clock`, `makeTicker`, `beforeForeground`를 추가한다. DEBUG 빌드에는 `testClock`·`failNextSave`를 추가한다. `AppModel: JourneyProgressSaving`을 채택한다.
- `JourneyView.swift`: placeholder를 타이머로 바꾼다. 뒤로가기 버튼과 스와이프를 막고, scenePhase 처리를 한 곳으로 모은다.
- `UITestBootstrap.swift`: `--fm-ui-clock manual`, `UITestNextSaveFailure`, 시드, `--fm-ui-route journey`를 추가하고 `seededJourney`(:238-242)에 `paused`를 넣는다.

### 수정 파일 (기존 테스트)

| 파일:라인 | 변경 |
|---|---|
| `BoardingTestDoubles.swift:24-42` | `destinationStopID` 기본값을 `"seongsu-dest"`에서 `"seongdongSportsCenter"`로 바꾸고 `paused: Bool = false`를 추가한다. **카탈로그 검증과 같은 T1에서** 처리한다. |
| `JourneySnapshotTests.swift:62, :212-220` | `withDestination`에 `paused`를 전달한다. |
| `JourneySnapshotTests.swift:76-83` | "카탈로그 밖 id는 통과" 테스트를 뒤집는다. 출발·도착 id는 `unknownStop`, 버스 id는 `unknownBus`를 기대한다. |
| `JourneySnapshotTests.swift:122-126` | 361분은 `invalidMinutes(361)`, 360분은 통과하는 케이스를 추가한다. |
| `JourneySnapshotTests.swift:155`, `JourneySnapshotStorageTests.swift:171` | **`invalidProgress`를 유지한다.** awaiting 상태에서 elapsed≠0이면 invalidProgress다. |
| `JourneySnapshotStorageTests.swift:41-57` | version을 4로 바꾸고 `active["paused"] == false`를 단언한다. |
| `JourneySnapshotStorageTests.swift:145, :220` | v3 바이트는 그대로 둔다. v3 분기로 읽히며, departed 여정은 paused=true가 된다. |
| `SnapshotCodecTests.swift:37, :46, :69-70` | version 4, `currentVersion == 4` |
| `StorageV2Tests.swift:66, :89` | version 4 |
| `CardSupplementTests.swift:33`, `CardStorageTests.swift:39`, `CardCustomizationAppModelTests.swift:456`, `CardStyleStorageTests.swift:135`, `RecordStorageTests.swift:97` | `root["version"] == 4`. `CardStyleStorageTests:24, :89`의 v3 입력은 유지한다. |
| `BoardingModelTests.swift` | AC-18 재승차 거부 케이스를 추가한다. `confirmDeparture`가 성공하면 확정값을 정리한다. departed를 로드하면 메모리상 paused=true가 된다는 전제를 반영한다. |
| `DepartureBriefingUITests.swift:40-79` | :70은 `journey.timer.remaining`을 기다린다. :76-78의 뒤로가기→메인 단계는 지우고 `navigationBars.buttons.count == 0`과 `screen.journey` 유지를 단언한다. 테스트 이름에서 "뒤로 메인"을 뺀다. |
| `UITestLaunchSupport.swift:33-37` | `relaunch(extraArguments: [String] = [])` |

### 문서
- `docs/FLOWS.md`: :16의 "백그라운드 정지"를 "백그라운드 진행·진입 시 체크포인트"로 바꾼다. :78의 "앱 밖 시간 미가산"은 iOS 계약(프로세스 생존 시간)으로 바꾼다.
- `docs/CURRENT-STATE.md`
- `context/journey/architecture.md:15-17`
- `.dev/plan.md`: W05 행 갱신, W07 메모(재진입·나가기·`NavigationPopBlocker` 해제 조건), W15 확장점 메모.

## 적용 컨벤션
- 컨트롤러는 `@MainActor @Observable final class`로 만든다. 의존성은 `@ObservationIgnored private let`, 상태는 `private(set) var`로 둔다.
- 저장자는 `@MainActor protocol …: AnyObject` 형태이고 Bool을 반환한다.
- 저장은 `snapshot.updating(journey:)` 후 `save`를 호출한다. 실패하면 snapshot은 그대로 두고 `saveFailure`를 남긴다.
- DEBUG 진단은 JSON을 `accessibilityValue`에 넣는다(font 1, `.clear`).
- 테스트 더블은 결과 배열을 순서대로 소비하고 `calls`를 기록한다.
- 테스트 이름은 `testAC<n>_한국어`이고, 실패 이유는 `// 깨짐:` 주석으로 남긴다.

## 상세 설계

### A. 저장 형식 v4

**A1. `JourneySnapshot.swift`**
- `let paused: Bool`을 추가한다. 이 필드 때문에 멤버와이즈 생성자를 쓰는 `boarding`, `confirmingDeparture`, `UITestBootstrap.seededJourney`, `BoardingFixtures.journey`를 T1에서 함께 고친다.
- 생성 시 값:
  - `boarding`은 paused=false로 만든다.
  - `confirmingDeparture()`는 `.departed`, paused=false로 바꾸고 진도는 유지한다.
- 신규 멤버:
  - `totalSeconds = minutes*60`
  - `isArrived = phase == .departed && elapsed == totalSeconds`
  - `updatingProgress(elapsedSeconds:paused:)`
  - `restingForLaunch()`: departed이고 `!paused`일 때만 paused 사본을 만든다. 그 밖에는 self를 반환한다.
- 검증 순서: 빈 필드 → 카드 → 방향 → 분 → **카탈로그** → 할 일 → 태그 → 진도 → paused.
  - 분이 1...360 밖이면 `invalidMinutes(m)`.
  - `originStopID`·`destinationStopID`가 `RouteStops.all`의 id가 아니면 `unknownStop(id)`.
  - `busID`가 `BusLine.all`의 id가 아니면 `unknownBus(id)`.
  - elapsed가 0 ≤ elapsed ≤ total을 벗어나면 `invalidProgress`. awaiting에서 elapsed≠0인 경우도 `invalidProgress`다.
  - awaiting에서 paused == true면 `invalidPausedState`.
- `ActiveJourneyValidationIssue`에 `unknownStop(String)`, `unknownBus(String)`, `invalidPausedState`를 추가한다.
- :4 주석: "id는 RouteStops/BusLine 카탈로그 값이어야 한다(BR-3). 카탈로그가 바뀌면 그 여정은 읽을 때 버려진다."
- :58 주석: "구조와 카탈로그를 본다. 손상 여정은 SnapshotCodec.dropInvalidActiveJourney가 여정만 버린다."
- 디코드:
  - `decoder.userInfo[.journeyFormat] as? Format == .v3`이면 paused 키를 읽지 않고 `phase == .departed`로 채운다.
  - v4에서는 paused가 필수다. 키가 없으면 throw하고, `JourneySection`의 `try?`가 여정만 버린다.
- 인코드에 paused를 포함한다.
- `enum Format { case v3, v4 }`와 `extension CodingUserInfoKey { static let journeyFormat }`를 둔다. userInfo는 중첩 디코더까지 전달되므로 DTO를 복제하지 않는다.

**A2. `SnapshotCodec.swift`**
- `currentVersion = 4`.
- `case 3`: userInfo에 `.journeyFormat = .v3`를 넣은 디코더로 Envelope를 읽는다.
- `case 4`: 기본 디코더로 읽는다.
- 두 경우 모두 이어서 `dropInvalidActiveJourney`를 적용한다. 강화된 검증이 v3 데이터에도 적용된다(AC-26).
- encode는 항상 v4로 한다.

**A3. `AppModel.loadSnapshot`**
- 복원된 active에 `restingForLaunch()`를 적용하되 메모리에만 반영하고 파일은 쓰지 않는다.
- 그래서 재실행 뒤 paused는 UI 테스트에서 **`test.snapshot`(메모리)**으로 단언한다. `test.persistedBytes`는 명시적 전환 뒤에만 단언한다.

### B. 모델

**B1. `AppModel+JourneyTimer.swift`**
- `saveJourneyProgress(journeyID:elapsedSeconds:paused:) -> Bool`
  - 다음 중 하나라도 어긋나면 false를 반환하고 쓰지 않는다: `.ready(.main)`, active 존재, id 일치, departed.
  - 조건을 통과하면 `save(snapshot.updating(journey: JourneySection(active: active.updatingProgress(...))))`를 호출한다.
  - 범위를 벗어난 값은 validate가 거부하므로 false가 반환된다.
  - 값이 같아도 쓰기를 **생략하지 않는다**. 중복 방어는 컨트롤러가 맡는다.
- `var hasDepartedJourney: Bool { activeJourney?.phase == .departed }`
- records는 건드리지 않는다.

**B2. 재승차 차단**
- 가드 4곳:
  - `showBoardingPass`: `confirmPreparation()` 앞에서 `guard !hasDepartedJourney else { return false }`.
  - `openBoarding`, `boardJourney`: 같은 가드.
  - `AppModel.open`: departed면 `.board`·`.boarding`으로 가지 않고 return한다.
- `goBack`: `path.last == .journey && hasDepartedJourney`면 return한다(방어용).
- 근본 원인 처리: `confirmDeparture`가 성공하면 `discardConfirmedPreparation()`을 호출한다.
  - `boardJourney`가 성공한 시점에는 정리하지 않는다. AC-19의 awaiting 덮어쓰기와 `BoardingTagView.swift:98`의 제목이 확정값을 쓰기 때문이다.
- awaiting 상태의 교체는 기존처럼 허용한다(AC-19).

### C. 시계·틱 (`JourneyClock.swift`)
- 프로토콜:
  - `@MainActor protocol JourneyClock: AnyObject { var now: Duration { get } }`: 단조 시계이며 Date를 쓰지 않는다.
  - `@MainActor protocol JourneyTicker: AnyObject { func start(_ onTick: @escaping @MainActor () -> Void); func stop(); var isTicking: Bool { get } }`
- `ContinuousJourneyClock`: init 시점의 `ContinuousClock().now`를 origin으로 잡고 `origin.duration(to: .now)`를 반환한다. 잠자기 시간을 포함하고 벽시계 변경에 영향받지 않는다.
- `TaskJourneyTicker(interval: Duration = .seconds(1), sleep: @escaping (Duration) async -> Void = { try? await Task.sleep(for: $0) })`
  - `start`는 기존 Task를 cancel한 뒤 새 루프를 만든다: `Task { @MainActor in while !Task.isCancelled { await sleep(interval); guard !Task.isCancelled else { return }; onTick() } }`.
  - `stop`과 `deinit`은 Task를 cancel한다.
  - 테스트를 위해 `loop` 핸들을 노출한다.
- `#if DEBUG final class ManualJourneyClock: JourneyClock, JourneyTicker`
  - `advance(by:notify: Bool = true)`: now를 증가시킨다. ticking이고 notify가 true면 onTick을 1회 호출한다.
  - `armForegroundAdvance(by:)`와 `applyArmedForegroundAdvance()`: 백그라운드에 있는 동안 흐른 시간을 재현한다.
- **수명은 weak 캡처로 관리한다.** 컨트롤러는 `ticker.start { [weak self] in self?.tick() }`로 시작한다.
  - 참조 방향은 controller → ticker(strong) → Task → closure → controller(weak)라서 순환이 없다. 컨트롤러가 해제되면 ticker deinit이 Task를 cancel한다.
  - `.task` 방식을 쓰지 않은 이유: 동기 단위 테스트로 검증할 수 있는 형태를 유지하기 위해서다.
- 원칙: 진도는 항상 `clock.now`의 차이로 계산한다. 틱은 화면 갱신과 체크포인트 판정을 일으키는 계기일 뿐이다.

### D. 표시 규칙 (`JourneyTimerDisplay`, enum, 순수 함수)
- `remainingMinutes(totalSeconds:elapsedSeconds:) = max(0, (total - elapsed + 59) / 60)`
  - **입력은 내림한 정수 elapsed로 고정한다.** 예: 1499.5초는 elapsed 1499이므로 "1 min"이고 arrived가 아니다.
- `text(minutes:)`는 "\(m) min", `accessibilityValue(minutes:)`는 "남은 시간 \(m)분"을 반환한다.
- 라벨 상수: `accessibilityLabel = "타이머"`, `pauseLabel = "일시정지"`, `resumeLabel = "재개"`.
- 낭독 상수: `pausedAnnouncement = "일시정지됨"`, `resumedAnnouncement = "재개됨"`.
- 안내 문구 상수:
  - `transitionFailureText = "저장하지 못했어요. 다시 눌러주세요."`
  - `checkpointWarningText = "진도를 저장하지 못해 멈췄어요. 재개를 눌러주세요."`
  - `arrivalWarningText = "도착을 저장하지 못했어요."`(임시 문구)

### E. 타이머 컨트롤러 (`JourneyTimerController.swift`)
- `@MainActor protocol JourneyProgressSaving: AnyObject { func saveJourneyProgress(journeyID: String, elapsedSeconds: Int, paused: Bool) -> Bool }`
- `@MainActor @Observable final class JourneyTimerController`
  - `enum Status: Equatable { case running, paused, arrived }`
  - 노출 상태(`private(set)`): `status`, `elapsedSeconds`(내림), `remainingMinutes`, `remainingSeconds`, `showsTransitionFailure`, `showsSaveWarning`
  - 내부 상태(`@ObservationIgnored`): `journeyID`, `totalSeconds`, `baseElapsed: Duration`, `runAnchor: Duration?`, `lastSavedElapsed`, `arrivalPersisted`
  - `init(journey:autoStart:saver:clock:ticker:announcer: AccessibilityAnnouncing, checkpointInterval: Int = 10)`
  - 메서드: `appear()`, `pause()`, `resume()`, `tick()`, `enterBackground()`, `returnToForeground()`, `leave()`
  - 1차안의 `pendingPauseRetry`, `FocusTarget`, `makeProgressSaver`는 제거했다.

**초기 상태 규칙 (MUST-ADDRESS A 해소)**
1. `journey.isArrived`면 arrived이고 `arrivalPersisted = true`다.
2. 그렇지 않고 `autoStart && !journey.paused`면 running이고 `runAnchor = clock.now`다.
3. 나머지는 모두 paused다.

`autoStart`는 같은 JourneyView가 '시작' 전이를 직접 본 경우(`briefing.isConfirmed`)에만 true다. 즉 **저장된 paused=false만으로는 절대 자동 시작하지 않는다.**

모델과 컨트롤러의 역할:
- `AppModel.snapshot`은 마지막으로 성공한 저장값이고, 컨트롤러가 런타임 상태의 기준이다.
- 저장이 실패했을 때 남는 paused=false는 재실행 시 `restingForLaunch`가, 컨트롤러 재생성 시 `autoStart=false`가 각각 paused로 만든다.

불변식:
- `running ⇔ runAnchor != nil`
- `running && appeared ⇔ ticker.isTicking`
- `elapsed ≤ total`

**공통 계산**
- `current = min(.seconds(total), baseElapsed + (runAnchor.map { clock.now - $0 } ?? .zero))`
- `elapsedInt = Int(current.components.seconds)`
- 도착은 `current >= .seconds(total)`로 판정한다.
- `fold()`: `baseElapsed = current; runAnchor = nil`
- `refresh()`: 노출 상태를 갱신한다.

**상태 기계**

| 이벤트 | running | paused | arrived |
|---|---|---|---|
| `appear()` (멱등, MUST-B) | 앵커를 **건드리지 않는다**. ticking이 아니면 start(weak). refresh | refresh | `!arrivalPersisted`면 도착 저장 재시도 |
| `tick()` | ① | 무시 | 무시 |
| `pause()` | ② | 무시 | 무시 |
| `resume()` | 무시 | ③ | 무시(재시작 수단 없음) |
| `enterBackground()` | ④ | 쓰기 0 | `!arrivalPersisted`면 재시도 |
| `returnToForeground()` | `tick()` 1회 | 무시(자동 재개 없음) | 무시 |
| inactive | 무시 | 무시 | 무시 |
| `leave()` (방어용) | ⑤ | ticker.stop | `!arrivalPersisted`면 재시도 |

① tick
- total에 도달했으면 arrive.
- 아니면 `elapsedInt - lastSavedElapsed ≥ interval`일 때 (elapsedInt, false)를 1회 저장한다. 시간이 크게 뛰어도 저장은 1회다.
- 저장이 실패하면 `fold()`, `stop()`, paused로 바꾸고 `showsSaveWarning`을 켠 뒤 경고를 1회 낭독한다.

② pause
- total에 도달했으면 arrive.
- 아니면 (elapsedInt, true)를 저장한다.
  - 성공: `fold()`, `stop()`, paused, 실패 표시 해제, "일시정지됨" 낭독.
  - 실패: 상태와 앵커를 유지해 시간이 계속 흐르게 하고 `showsTransitionFailure`를 켠다.

③ resume
- (elapsedInt, false)를 저장한다.
  - 성공: running, `runAnchor = now`, `start()`, 경고·실패 표시 해제, "재개됨" 낭독.
  - 실패: paused를 유지한다. 경고가 이미 떠 있으면 경고만 유지하고, 아니면 `showsTransitionFailure`를 켠다.

④ enterBackground (상태 전환 없음)
- total에 도달했으면 arrive.
- 아니면 주기와 상관없이 (elapsedInt, false)를 즉시 저장한다. ticker는 유지한다.
- 저장이 실패하면 ①의 실패 처리와 같게 한다(메모리상 일시정지와 경고).

⑤ leave
- `fold()`, `stop()`, paused로 바꾸고 (elapsedInt, true)를 저장한다. 낭독하지 않는다.
- 정상 경로에서는 호출되지 않는다.

arrive
- 이미 arrived면 return한다.
- `fold()`(= total), `stop()`, arrived, refresh 후 (total, true)를 저장한다.
  - 성공: `arrivalPersisted = true`.
  - 실패: `showsSaveWarning`을 켠다.
- 재시도는 `enterBackground`와 `appear`에서만 한다.

**`lastSavedElapsed` 갱신**
- 초기값은 `journey.progress.elapsedSeconds`다.
- checkpoint·background·pause·resume·arrival·leave 중 **어떤 저장이든 성공하면** 저장한 값으로 갱신한다. 실패하면 갱신하지 않는다.

**낭독**
- 전환에 성공했을 때만 "일시정지됨"/"재개됨"을 낭독한다.
- 체크포인트·백그라운드 실패 경고는 1회 낭독한다.
- 남은 시간 값이 바뀔 때는 낭독하지 않는다.

**Live Activity 확장점 (W15, 이번에는 구현하지 않음)**
- `status`와 `remainingSeconds`를 노출해 둔다.
- W15에서 관찰자 프로토콜을 `JourneyServices`로 주입하고, `Date.now + remainingSeconds`로 종료 시각을 계산해 넘기면 된다.

### F. 화면

**F1. `JourneyView.swift`**
- `JourneyView`에 `@State timer: JourneyTimerController?`를 둔다.
- `ensureTimer()`: `timer == nil && activeJourney?.phase == .departed`일 때 다음 인자로 생성한다.
  - `autoStart: briefing?.isConfirmed == true`
  - `saver: model`
  - `clock: services.clock`
  - `ticker: services.makeTicker()`
  - `announcer: services.announcer`
- `ensureTimer()`는 `.onChange(of: model.activeJourney?.phase, initial: true)`와 `.onChange(of: briefing?.isConfirmed)`에서 호출한다.
- `JourneyView.onDisappear { timer?.leave() }`는 방어용이다. 이 사실을 주석으로 남긴다.
- `JourneyScreen` 본문: awaiting이면 안내, timer가 있으면 `JourneyTimerView`, 그 밖에는 `Color.clear`.
- **뒤로가기 차단**은 화면의 모든 단계에 적용한다.
  1. `.navigationBarBackButtonHidden(true)`와 `.toolbar(.hidden, for: .navigationBar)`
  2. `.background(NavigationPopBlocker())`: `UIViewControllerRepresentable`로 만든다.
     - `viewDidAppear`에서 `navigationController?.interactivePopGestureRecognizer?.isEnabled = false`로 막는다. iOS 26에서는 `interactiveContentPopGestureRecognizer`도 막는다.
     - `viewWillDisappear`와 `dismantleUIViewController`에서 원래 값으로 되돌린다. 내비게이션 컨트롤러를 다른 화면과 공유하므로 복원이 필수다.
  3. 모델의 `goBack` 가드
  4. V8 UI 테스트로 검증한다.
- **scenePhase는 `JourneyScreen`의 `.onChange(of: scenePhase)` 한 곳에서** 처리한다.
  - awaiting: 기존 briefing 처리를 그대로 둔다.
  - 타이머: `.background`면 `timer.enterBackground()`, `.active`면 `services.beforeForeground()` 후 `timer.returnToForeground()`. `.inactive`는 무시한다.
- DEBUG 시계 버튼은 `JourneyScreen`의 `#if DEBUG .safeAreaInset(edge: .top)`에 44pt 높이 한 줄로 둔다. `services.testClock != nil`일 때만 보인다. 레이아웃이 자리를 예약하므로 큰 글씨에서도 타이머 버튼과 겹치지 않는다.
  - 버튼: `test.clock.advance1/advance10/advance60/advance600`, `test.clock.armForeground600`, `test.failNextSave`

**F2. `JourneyTimerView.swift`**
- `journey.timer.remaining`
  - `Text("N min")`, `.accessibilityLabel("타이머")`, `.accessibilityValue("남은 시간 N분")`.
  - onAppear에서 `@AccessibilityFocusState`를 1회 지정한다. 값이 바뀌어도 post하지 않는다.
- `journey.timer.pause`와 `journey.timer.resume`은 상태에 따라 하나만 보인다. arrived에서는 둘 다 숨긴다. 라벨은 "일시정지"/"재개"이고 크기는 44×44 이상이다.
- `journey.timer.saveFailure`: `showsTransitionFailure`일 때 보인다.
- `journey.timer.saveWarning`: arrived면 `arrivalWarningText`, 그 밖에는 `checkpointWarningText`를 보인다.
- `journey.arrived`: 임시 도착 문구.
- 숫자는 64 bold, lineLimit 1, minimumScaleFactor 0.5로 둔다. 버튼 글자 크기 상한은 `...accessibility3`, 경고는 `fixedSize(vertical)`이다. 레이아웃은 VStack + Spacer로 하고 스크롤은 없다.
- 동작 줄이기가 꺼져 있을 때만 `.contentTransition(.numericText())`를 쓴다.
- `.onAppear { controller.appear() }`
- DEBUG `test.timer` JSON: `{status, elapsed, remainingMinutes, text, showsSaveWarning, showsSaveFailure, focus, path}`. `allowsHitTesting(false)`로 둔다.

**F3. `JourneyServices.swift`**
- `var clock: JourneyClock`, `var makeTicker: @MainActor () -> JourneyTicker`, `var beforeForeground: @MainActor () -> Void`
- `#if DEBUG var testClock: ManualJourneyClock?`, `var failNextSave: UITestNextSaveFailure?`
- `live()` = `ContinuousJourneyClock()`, `{ TaskJourneyTicker() }`, `{}`
  - ticker를 팩토리로 둔 이유: RootView의 `.live()` 기본값이 다시 평가될 수 있기 때문이다.
- `extension AppModel: JourneyBoarding, DepartureConfirming, JourneyProgressSaving {}`

### G. UI 테스트 지원 (`UITestBootstrap.swift`)
- `--fm-ui-clock manual`
  - `ManualJourneyClock` 하나가 clock과 ticker를 함께 맡는다(`makeTicker = { clock }`).
  - `beforeForeground = { clock.applyArmedForegroundAdvance() }`, `testClock = clock`.
  - `manual`이 아닌 값은 `invalidArguments`다.
- `UITestNextSaveFailure`
  - `pending: Int`. `arm()`은 +1, `consume()`은 pending > 0이면 -1 하고 true를 반환한다.
  - `writeData`(:178)의 실패 조건에 `|| nextFailure.consume()`를 붙인다.
  - manual 모드에는 자율 쓰기가 없다. 그래서 "arm 직후 곧바로 대상 조작"을 지키면 실패 시점이 결정적이다. 헬퍼 `failNextSave(then:)`가 이 순서를 강제한다.
- 시드: v4, 25분, `seoulForest` 출발, 카탈로그에 있는 도착지, 버스 `2014`.
  - `timerPaused90`: departed, 90초, paused
  - `timerNearArrival`: 1440초, paused
  - `timerArrived`: 1500초, paused
- v3 파생 시드: v4를 `SnapshotCodec.encode`한 뒤 JSONSerialization으로 version을 3으로 바꾸고 `active.paused`를 지운다.
  - `v3Awaiting`
  - `v3Departed`(0초)
  - `v3InvalidMinutes`(361분)
  - `v3UnknownStop`(`"gone-stop"`)
- `seededJourney`에 `paused: false`를 넣는다.
- `--fm-ui-route journey`
  - 허용 조건: `route == "boarding" && seed == "ready"` 또는 `route == "journey"`.
  - `applyRoute`는 active가 없으면 `invalidSaveState`를 throw하고, 있으면 `model.open(.journey)`를 호출한다. relaunch에서도 쓸 수 있다.

## 기존 구조와의 차이
- 카탈로그 대조 검증을 넣는다(W04의 "구조만" 계약을 뒤집음).
- v3 분기를 userInfo로 처리한다.
- 실행 경계에서 메모리만 paused로 정규화한다.
- 웹의 "백그라운드 정지"를 "백그라운드 진행 + 체크포인트"로 바꾼다. 진도는 ContinuousClock 단조 시간으로 잰다.
- running 초기값은 '시작'을 직접 본 경우에만 준다.
- 쓰기 생략 규칙을 두지 않는다.
- 시계·틱 서비스(팩토리, weak)를 새로 둔다.
- 여행 화면에서 메인으로 돌아가는 길을 없앤다. 막는 장치는 세 겹이다: 버튼 숨김, `NavigationPopBlocker`, `goBack` 가드.
- scenePhase 처리를 한 곳으로 모은다.
- '시작'에 성공하면 확정값을 정리한다.
- DEBUG 시계 버튼은 상단 safe-area inset에 둔다.

## 의존성 및 영향도
- 새 라이브러리는 없다. iOS 17 대상이다.
- v3 데이터는 읽을 수 있다. W04 앱은 v4 데이터를 `unsupportedVersion`으로 처리하며, 다운그레이드는 지원하지 않는다.
- W07으로 넘기는 일: 재실행 후 타이머로 돌아오는 진입점과 나가기, `NavigationPopBlocker`·`goBack` 가드 조건 재정의. 이때 컨트롤러는 autoStart=false로 만든다.

## 구현 순서

| # | 태스크 | AC | 파일 | 의존 |
|---|---|---|---|---|
| T1 | 저장 v4·검증·v3 읽기·픽스처 | 20, 21, 22, 23, 24, 26, 25(저장) | JourneySnapshot, SnapshotCodec, UITestBootstrap(seededJourney paused), BoardingTestDoubles + 기존 테스트 표 / JourneySnapshotV4StorageTests | - |
| T2 | 단조 시계·틱 | 32 기반, BR-1 | JourneyClock / JourneyClockTests | - |
| T3 | 표시 규칙 | 2, 27, 28 문자열 | JourneyTimerDisplay / Tests | - |
| T4 | 모델 저장·정규화·재승차·확정값 정리 | 1(저장), 11, 13(복원), 18, 19, 31 | AppModel+JourneyTimer, AppModel, AppModel+Boarding, JourneyServices(채택) / JourneyTimerModelTests, BoardingModelTests | T1 |
| T5 | 타이머 컨트롤러 | 3, 4, 5, 6, 7, 8, 10, 12, 13, 14, 15, 16, 28, 32 | JourneyTimerController / JourneyTimerControllerTests, JourneyTimerTestDoubles | T1, T2, T3 |
| T6 | 화면·연결·뒤로가기 차단 | 1, 9, 17, 25, 27, 29, 30 | JourneyTimerView, JourneyView, NavigationPopBlocker, JourneyServices(필드) | T4, T5 |
| T7 | UI 테스트 부트스트랩 | 전제 | UITestBootstrap, UITestLaunchSupport | T1, T6 |
| T8 | UI 테스트 | V1~V8 | JourneyTimer*UITests, DepartureBriefingUITests | T6, T7 |
| T9 | 문서 | - | FLOWS, CURRENT-STATE, architecture, plan | T8 |

### T5 단위 테스트 (ManualJourneyClock + FakeProgressSaver(results, writes) + 기록 announcer)

| AC | 시나리오 | 기대 |
|---|---|---|
| 3 | 360분, running, advance 21600 | arrived, [(21600,true)] 저장. 이후 어떤 조작에도 쓰기 수 불변 |
| 4 | running 90, pause, advance 300 | 저장 (90,true), 24 min, paused, ticker 정지 |
| 5 | 이어서 resume, advance 60 | 저장 (90,false), 이어서 체크포인트 (150,false). 23 min |
| 6 | pause×2, resume×2, 그 사이 advance 5 | 쓰기 2회. 진도는 running 구간만 증가 |
| 7 | running 100, background, advance(600, notify:false), foreground | 저장 (100,false), 이어서 (700,false). running, 14 min, ticker 유지 |
| 8 | running 1400, background, advance 600, foreground | 저장 (1400,false), 이어서 (1500,true) 1회. arrived |
| 8 | paused 상태에서 background, foreground | 쓰기 0, 상태 불변 |
| 10 | running 0, advance 1 ×9 | 쓰기 0. 1초 더 지나면 (10,false) |
| lastSaved | paused 90, resume, advance 1 ×9 | 쓰기는 resume의 (90,false)뿐. 1초 더 지나면 (100,false) |
| 12 | running 1440, advance 60 | (1500,true) 1회, 0 min, arrived |
| 13 | init(isArrived) | arrived, ticker 미시작, appear 후에도 쓰기 0 |
| 14 | running, 1499.5까지 진행(advance 500ms, notify:false), 이어서 600ms(notify:false), background, tick, foreground | 도착 저장 1회, 1500 |
| 14 경계 | elapsed 1499.5 | "1 min", running |
| 14 | arrived 상태에서 resume, pause | 무시, 쓰기 0 |
| 15 | 결과 [false, true], pause ×2 | 1회차: running 유지, transitionFailure, 시간 계속 흐름. 2회차: paused, 실패 표시 해제 |
| 16 | 결과 [false, true], running 0, advance 10 | paused, saveWarning, 경고 낭독 1회. advance 60 후에도 25 min. resume하면 (10,false), 경고 해제, running |
| 16 | 결과 [false, false] | resume 실패 후 paused와 경고 유지, transitionFailure는 켜지지 않음 |
| bg 실패 | 결과 [false], running 50, background | paused, 경고. resume이 재시도 |
| 도착 실패 | 결과 [false, true], 1440에서 advance 60 | arrived, 경고. appear 또는 background에서 (1500,true) 재시도 1회, 이후 쓰기 0 |
| MUST-A | departed, paused=false, autoStart=false | paused, 앵커 nil, ticker 미시작 |
| MUST-A | autoStart=true | running |
| MUST-B | running, appear ×3, 사이마다 advance 5 | 진도 15, ticker start 1회 |
| 28 | pause, resume, advance 60 | 낭독 == ["일시정지됨", "재개됨"] |
| 32 | advance 60 | +60. 프로토콜에 Date 없음 |
| leave | running 30, leave | (30,true), paused, stop |
| 수명 | 컨트롤러 해제 | weak 참조가 nil, ticker 정지 |

그 밖의 단위 테스트:
- **T2**
  - TaskJourneyTicker에 QueuedSleep을 주입해 start → tick 3회, stop 후 0회를 확인한다. 다시 start하면 이전 루프가 cancel되는지 확인한다.
  - ManualJourneyClock: notify:false면 틱이 없는지, arm 적용이 되는지 확인한다.
  - ContinuousJourneyClock이 단조인지 확인한다.
- **T3**: 0·1·60·61·1499·1500 → 25·25·24·24·1·0. 1499.5 → 1. 라벨과 값.
- **T4 JourneyTimerModelTests**
  - 가드 4종: false를 반환하고 쓰기 0.
  - 범위 밖 값 거부.
  - `loadSnapshot`은 메모리만 paused로 바꾸고 파일 바이트는 그대로 둔다(AC-11).
  - AC-13, AC-31.
- **T4 BoardingModelTests**
  - AC-18: 4개 경로 모두 거부, id·경과·paused 불변.
  - `confirmDeparture`가 성공하면 `confirmedPreparation == nil`.
  - AC-19 회귀.
- **T1 JourneySnapshotV4StorageTests**
  - AC-20·21·22: 쓰기 거부, 읽을 때 여정만 버리고 카드·기록은 유지.
  - AC-23: 왕복.
  - AC-24·26: v3 읽기.
  - v4에 paused 키가 없으면 여정만 버림.
  - awaiting + paused → `invalidPausedState`.

### T8 UI 테스트 (모두 `--fm-ui-clock manual`)

| # | 파일 | AC | 시드·조작 | 확인 |
|---|---|---|---|---|
| V1 | JourneyTimerUITests | 1, 2, 17 | ready + route boarding → 태그 → 시작 / failNextSave → 시작 | `test.timer.text == "60 min"`. snapshot은 departed·false·0. 실패 시 `journey.saveFailure`, awaiting·0 |
| V2 | JourneyTimerUITests | 4, 5, 6, 10 | timerPaused90 + route journey → resume → advance1 ×9/×1 → pause ×2 → resume ×2 | `test.snapshot` 값, 버튼 노출, 쓰기 횟수 |
| V3 | JourneyTimerUITests | 12, 13, 14, 31 | timerNearArrival → resume → advance60 → relaunch(route journey) | "0 min", `journey.arrived`, pause·resume 없음, 기록 0. 재실행 후에도 arrived |
| V4 | JourneyTimerLifecycleUITests | 15, 16 | timerPaused90 → resume → failNextSave → pause / failNextSave → advance10 → resume | 전환 실패 표시. 경고·resume 노출, 남은 시간 고정, 재개 후 경고 해제 |
| V5 | JourneyTimerLifecycleUITests | 7, 8, 11 | (a) timerPaused90 → resume → advance10 → armForeground600 → home → activate (b) timerNearArrival → resume → arm600 → home → activate (c) resume → advance10 ×3 → advance1 ×5 → relaunch() | (a) 진입 시 저장 (100,false), 복귀 후 running·700·14 min (b) arrived·1500 (c) `main.activeJourney`, snapshot 120·paused true |
| V6 | JourneyTimerLifecycleUITests | 24, 25, 26 | v3Departed + route journey → resume / v3Awaiting + route journey / v3InvalidMinutes·v3UnknownStop | paused·0, 재개 후 version 4 / `journey.start` / `main.activeJourney` 없음, 카드 유지 |
| V7 | JourneyTimerAccessibilityUITests | 27, 28, 29, 30 | timerPaused90 / 전환 2회 + advance60 / accessibility5 / reduce-motion on | 값 "남은 시간 24분", 라벨 "타이머", text "24 min", 0초면 "0분" / 낭독 / isHittable·44pt·스크롤 없음 / reduce-motion 결과 동일 |
| V8 | JourneyTimerUITests | 9 | paused·running·arrived 각각 route journey → 가장자리 드래그 + 중앙 드래그 | `navigationBars.buttons.count == 0`, `screen.journey` 유지, `screen.main` 없음, `test.timer.path == ["journey"]` |

- AC-3, AC-14 경계, AC-32는 T5에서, AC-18은 T4 단위 테스트에서만 검증한다.
- QE-1 실제 낭독과 iOS 26 콘텐츠 스와이프는 W14 실기기에서 확인한다.

## Testability 평가 (test-architect)
- 1차 평가: **9/10, TESTABILITY PASS.** 2판은 구조가 같고(시계·틱·saver·announcer 주입, 동기 전환, 순수 표시 규칙, writeData 주입 모델) 1차 평가의 권고 8개를 모두 반영했다.
  - resume 등 모든 성공 저장에서 `lastSaved` 갱신
  - 도착 실패 시나리오
  - Duration→Int 입력 고정
  - onDisappear 오발화 대응(이탈 경로 제거, 방어용으로 축소)
  - 초기 상태 진단
  - AC-32 체크리스트
  - 실패 스위치 순서
  - 픽스처와 카탈로그를 같은 태스크에서 처리
- 컴포넌트별 전략:
  - **JourneySnapshot·SnapshotCodec (동작, XCTest)**: 경계값 표, 디코드 분기, 바이트 fixture 통합 테스트. 모킹 없음.
  - **JourneyClock·Ticker (동작, XCTest)**: 주입한 sleep과 QueuedSleep으로 루프·취소를 검증한다.
  - **JourneyTimerDisplay (동작, XCTest)**: 순수 함수 표 테스트.
  - **AppModel+JourneyTimer·가드 (동작, XCTest)**: 메모리 readData/writeData 클로저(`Probe.writes`)를 쓴다.
  - **JourneyTimerController (동작, XCTest)**: ManualJourneyClock, FakeProgressSaver, RecordingAnnouncer를 쓴다. 공개 상태, 쓰기 로그, 낭독 로그, isTicking만 단언한다.
  - **JourneyView·JourneyTimerView·NavigationPopBlocker**
    - 조건부 노출·scenePhase·차단은 동작으로 보고 XCUITest(V1~V8)로 검증한다.
    - 폰트·색·전환 효과는 표현이라 범위 밖이다.
  - **UITestBootstrap**: 인프라라 점수 대상이 아니다.
- 남는 감점 요인: scenePhase와 `NavigationPopBlocker`의 SwiftUI/UIKit 연결은 XCUITest로만 검증할 수 있다.
