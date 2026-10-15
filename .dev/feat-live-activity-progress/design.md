# 설계 확정본: W15 다이나믹 아일랜드·잠금 화면 진행 표시 (Live Activity)

### 설계 규모
대형입니다. 이 프로젝트의 첫 앱 확장 타깃과 첫 두 타깃 공유 소스 폴더가 들어갑니다. 함께 들어가는 것은 시스템 API(ActivityKit) 게이트웨이, 순수 정책, 동기화 객체, 타이머 컨트롤러 훅, 앱 시작 정리, pbxproj 편집입니다. AC는 33건입니다(AC-1~26, 28~34. AC-27은 삭제).

### 배경 및 목적
- 지금은 여행의 남은 시간이 앱 안에서만 보입니다. 잠금 화면이나 다른 앱을 쓰는 중에는 확인할 수 없습니다.
- 목표
  - 잠금 화면과 다이나믹 아일랜드에 버스, 도착지, 남은 시간(시스템 분:초 카운트다운), 상태를 보여줍니다. 진행 막대는 PRD 개정 1에 따라 넣지 않습니다.
  - 일시정지, 재개, 도착, 화면 이탈, 앱 재실행을 빠짐없이 반영합니다.
  - 기능이 꺼져 있거나 실패해도 여행 진행, 저장, 화면에는 영향이 없습니다.

### 요구사항 및 수용 기준
원문은 `.dev/feat-live-activity-progress/prd.md`이고, **"개정 1"(51-68행)이 본문보다 우선합니다.**
- [Must] FR-1~12, FR-14, BR-1·3~7은 "진행 정도"를 뺀 상태로 적용합니다. BR-2는 개정 1로 무효입니다.
- [Must] 개정 1의 앱 시작 정리(FR-6 앱 시작 절 대체)와 AC-32·33·34.
- [Should] FR-13(AC-20), QE-1·QE-2(M-3, M-8).
- 알려진 한계 M-13(사용자가 카드를 닫으면 같은 세션에서 다시 띄우지 않음)과 M-14(백그라운드에서 시작하면 거부될 수 있음)는 감수합니다.
- 확정 문구(FR-10)는 PRD 123-137행을 그대로 씁니다.

---

### 사용자 결정 반영 요약

| 확인 사항 | 결정 | 설계 반영 |
|---|---|---|
| 1. 진행 막대 | 없앰 | 필드 7개. `progress`, `Policy.progress`, 위젯 `ProgressView`를 모두 삭제 |
| 2. 재실행 시 같은 여행의 운행 중 카드 | 앱 시작 시 "일시정지"로 갱신 | `launchPlan`이 `pausedUpdate`를 돌려줌(AC-32·33) |
| 3. 앱 시작 시 다른 여행 id 카드 | 바로 종료 | `launchPlan.endIDs`에 포함(AC-32) |
| 4. 상태 전달 방식 | 컨트롤러 옵저버 훅 | 상세 설계 5 |

**design-critic CONSIDER 처리**

| 항목 | 처리 |
|---|---|
| MUST-ADDRESS: 재실행 뒤 운행 중 카드가 실제 상태와 어긋남 | `JourneyLiveActivityPolicy.launchPlan` 추가로 해결. AC-10·11과 일관됨 |
| `request`는 포그라운드에서만 성공, 사용자가 닫으면 `.dismissed` | 한계로 기록(M-13·14). `activeActivities`는 `.active`/`.stale`만 걸러냄 |
| R-3 update/end 순서 | "순서 비보장, 확률 낮음, 감수"로 정정 |
| T8 완료 조건 | 기존 UI 테스트 1건 실행 성공을 추가(위젯 타깃 태스크 T9) |
| 단위 테스트 호스트에서 실제 게이트웨이 `atLaunch`가 실행됨 | 가정으로 명시 |
| 시작 정리 호출 위치 | DEBUG 시나리오 적용 **뒤**에 둠. 기록기 `existing` 시드 런치 인자는 **만들지 않음**(과함) |
| SIMPLIFY: 기록기의 `failsUpdates` | 제거 |
| SIMPLIFY: SentKey | `status` + `pausedRemainingSeconds`로 단순화 |
| SIMPLIFY: UI 하네스 | 축소. `JourneyServices.wallNow`와 `liveActivityRecorder` 프로퍼티는 제거. UI 테스트는 2건에서 1건으로. RootView 진단은 캐스팅 1블록만 |

---

### 변경 범위

**신규: 공유 폴더 `ios/Shared/`** (앱과 위젯 두 타깃이 함께 컴파일)

| 파일 | 책임 | import |
|---|---|---|
| `ios/Shared/JourneyActivityAttributes.swift` | `ActivityAttributes` 데이터 모델. 필드 정확히 7개(AC-30), 상태 enum 포함 | ActivityKit |
| `ios/Shared/JourneyActivityDisplay.swift` | 확정 문구, "M:SS" 포맷, 접근성 설명(AC-26), 위젯용 시간 표시 선택과 접근성 라벨 선택 순수 함수 | Foundation |

**신규: 앱 `ios/FocusMate/`**

| 파일 | 책임 | import |
|---|---|---|
| `JourneyLiveActivityPolicy.swift` | 순수 정책: 속성 생성, 요청 내용(endDate/staleDate), 화면 진입 정리 계획, 앱 시작 정리 계획 | Foundation |
| `LiveActivityGateway.swift` | 게이트웨이 프로토콜, 실제 `ActivityKitLiveActivityGateway`, DEBUG `RecordingLiveActivityGateway` | ActivityKit, Observation |
| `JourneyLiveActivitySync.swift` | 화면 세션 하나의 동기화 객체(`JourneyTimerObserving` 채택) | Foundation |
| `JourneyLiveActivityCleanup.swift` | 앱 시작 정리 실행(`launchPlan`을 게이트웨이에 적용). Sync와 파일을 나눠 태스크를 병렬로 할 수 있게 함 | Foundation |

**신규: 위젯 확장 `ios/FocusMateWidgets/`** (새 타깃 `FocusMateWidgets`)

| 파일 | 책임 |
|---|---|
| `FocusMateWidgetsBundle.swift` | `@main WidgetBundle` |
| `JourneyLiveActivityWidget.swift` | `ActivityConfiguration`, 잠금 화면 뷰, `DynamicIsland`(expanded/compact/minimal). 진행 막대 없음 |
| `Info.plist` | `NSExtension` 아래 `NSExtensionPointIdentifier = com.apple.widgetkit-extension`만 둠 |

**신규: 테스트**
- `ios/FocusMateTests/`
  - `JourneyActivityDisplayTests`: AC-26, AC-30, 위젯 선택 함수
  - `JourneyLiveActivityPolicyTests`
  - `JourneyLiveActivitySyncTests`
  - `JourneyLiveActivityCleanupTests`
  - `JourneyTimerObserverParityTests`
  - `AppInfoLiveActivityTests`
- `ios/FocusMateUITests/JourneyLiveActivityUITests.swift`: 배선 스모크 1건

**수정**

| 파일 | 변경 | 규모 |
|---|---|---|
| `ios/FocusMate/JourneyTimerController.swift` | init 끝에 옵셔널 `observer`, `appear`/`halt`/`resume`/`arrive` 끝에 알림 1줄씩. 진도 계산은 그대로 | +8줄 |
| `ios/FocusMate/JourneyView.swift` | `ensureTimer()`(34-43행)에서 Sync를 만들어 `observer:`로 전달 | +2줄 |
| `ios/FocusMate/JourneyServices.swift` | 기본값 있는 프로퍼티 `liveActivities` 1개. `live()`(25-30행)는 그대로 | +2줄 |
| `ios/FocusMate/FocusMateApp.swift` | `start()`(92-107행) 끝에 시작 정리 호출, 게이트웨이를 고르는 private 프로퍼티 | +8줄 |
| `ios/FocusMate/UITestBootstrap.swift` | `makeJourneyServices`(229-247행)에 기록기 주입 1줄 | +1줄 |
| `ios/FocusMate/RootView.swift` | DEBUG `testDiagnostics`(239-256행)에 `test.liveActivity` 1블록 | +3줄 |
| `ios/FocusMate.xcodeproj/project.pbxproj` | 위젯 타깃, Shared 동기화 그룹, 임베드, 의존성, Info 키, 버전 키 | 아래 상세 |
| `context/journey/architecture.md` | W15 반영 | 문서 |

수정하지 않는 파일은 `AppModel*`, `JourneyTimerView.swift`, `JourneySnapshot.swift`, 스킴 파일입니다.

### 적용 컨벤션
- 컨벤션 전용 파일은 없습니다. W05/W06 코드 패턴과 `.dev/feat-mapkit-virtual-course/design.md`의 "적용 컨벤션"을 따릅니다.
- **네이밍**
  - 타입 접두어는 `Journey*`입니다. 문구는 `enum XxxDisplay`의 static으로 둡니다(`JourneyTimerDisplay.swift:4-22`).
  - 진단 식별자는 `test.<영역>` 형식입니다(`test.liveActivity`).
  - 테스트 메서드는 `testV15_AC<n>_<한국어>`이고, 위에 `// 깨짐:` 주석을 둡니다.
- **구조**
  - 외부 시스템은 `@MainActor protocol` 뒤에 둡니다(`AccessibilityAnnouncing`, `IssuanceHaptics`, `JourneyClock` 방식).
  - 테스트 더블은 앱의 `#if DEBUG`에 둡니다(`ManualJourneyClock`, `JourneyClock.swift:60-86`).
  - 순수 규칙은 `enum`의 static 함수, 의존성은 생성자 주입입니다.
- **진단**: `JSONSerialization` + `.sortedKeys` 결과를 1pt 투명 `Text`의 `accessibilityValue`로 노출합니다(`RootView.swift:239-256`).
- **테스트 실행**: focused 테스트는 `python3 scripts/check-ios.py test ios/FocusMateTests/<File>.swift`로 돌립니다. 파일 단위 `-only-testing`이고 `scripts/check-ios.py:35-39`에 있습니다.

---

### 상세 설계

#### 1. `ios/Shared/JourneyActivityAttributes.swift`: 데이터 모델 (FR-9, AC-30)
- **현재**: 없음.
- **변경**
  - 정적 속성 4개 + 동적 상태 3개 = 7필드입니다. 진행 비율은 두지 않습니다.
  - 카드 id, 카드 이름, 할 일, 태그, 소리, 출발지 필드는 없습니다.
  - 상태 enum은 `JourneyTimerController.Status`와 1:1이지만 공유 폴더에 따로 정의합니다. 위젯 타깃이 컨트롤러를 모르기 때문입니다.
- **시그니처**
  ```swift
  enum JourneyActivityStatus: String, Codable, Hashable { case running, paused, arrived }
  struct JourneyActivityAttributes: ActivityAttributes {
      struct ContentState: Codable, Hashable {
          var status: JourneyActivityStatus
          var endDate: Date?                 // running만
          var pausedRemainingSeconds: Int?   // paused만
      }
      let journeyID: String
      let busNumber: String
      let busKind: String
      let destinationName: String
  }
  ```
- **AC-30 판정**: `Mirror(reflecting:)`로 속성 label 4개와 상태 label 3개를 구해, 기대 집합 7개와 정확히 같은지 비교합니다. 소유 테스트는 `JourneyActivityDisplayTests` 한 곳(T1)입니다.

#### 2. `ios/Shared/JourneyActivityDisplay.swift`: 확정 문구와 위젯 선택 함수 (FR-10, BR-7, AC-26)
- **문구 시그니처**
  ```swift
  enum JourneyActivityDisplay {
      static func statusName(_ status: JourneyActivityStatus) -> String   // 운행 중 / 일시정지 / 도착
      static let expiredText: String                                      // "도착했어요"
      static func pausedTime(seconds: Int) -> String                      // "M:SS", 음수는 0
      static func accessibilityDescription(busNumber: String, busKind: String, destination: String,
                                           status: JourneyActivityStatus, pausedRemainingSeconds: Int?) -> String
  }
  ```
  - 일시정지 접근성 설명의 "{M}분 {S}초"에서 초는 0을 채우지 않습니다(65초 → "1분 5초"). 표기용 "M:SS"에서는 초를 2자리로 채웁니다.
- **위젯 선택 함수**(test-architect 권장 반영. 위젯 뷰의 분기를 순수 함수로 빼서 크래시를 막는 데 집중)
  ```swift
  enum JourneyActivityTimeContent: Equatable {
      case countdown(ClosedRange<Date>)   // Text(timerInterval:countsDown:)용
      case fixed(String)                  // 정적 문자열(일시정지 "M:SS" 또는 만료 문구)
  }
  extension JourneyActivityDisplay {
      static func timeContent(state: JourneyActivityAttributes.ContentState, isStale: Bool, now: Date) -> JourneyActivityTimeContent
      static func accessibilityLabel(attributes: JourneyActivityAttributes,
                                     state: JourneyActivityAttributes.ContentState, isStale: Bool) -> String
  }
  ```
- **`timeContent`의 우선순위**
  1. `paused`이면 `.fixed(pausedTime(pausedRemainingSeconds ?? 0))`입니다. 일시정지는 stale이어도 일시정지로 남습니다(M-5).
  2. `isStale`이거나 `arrived`이면 `.fixed(expiredText)`입니다.
  3. `running`이고 `endDate`가 있으면 `.countdown(min(now, endDate)...endDate)`입니다. 하한을 `min`으로 맞추는 것은 필수입니다. 하한이 상한보다 크면 `ClosedRange`가 트랩합니다.
  4. `running`인데 `endDate`가 nil이면(계약 위반 방어) `.fixed(expiredText)`입니다.
- **`accessibilityLabel`**
  - paused는 일시정지 설명입니다.
  - stale이거나 arrived이면 도착 설명입니다.
  - running은 운행 중 설명입니다. 남은 시간은 카운트다운 요소를 시스템이 읽습니다.

#### 3. `ios/FocusMate/JourneyLiveActivityPolicy.swift`: 순수 정책 (BR-1·3·5, FR-6, 개정 1, AC-31)
- **값 타입**: 게이트웨이 입력이자 기록기의 기록 단위입니다.
  ```swift
  struct JourneyActivityRequest: Equatable {
      let state: JourneyActivityAttributes.ContentState
      let staleDate: Date?
  }
  struct LiveActivityHandle: Equatable { let id: String; let journeyID: String }
  struct JourneyLaunchPlan: Equatable {
      struct PausedUpdate: Equatable { let id: String; let request: JourneyActivityRequest }
      let endIDs: [String]
      let pausedUpdate: PausedUpdate?
  }
  ```
  - critic이 제안한 튜플 `(endIDs, pausedUpdate: (id, request)?)`와 의미는 같습니다. 테스트에서 `XCTAssertEqual`을 쓸 수 있게 struct로 둡니다.
- **시그니처**
  ```swift
  enum JourneyLiveActivityPolicy {
      static func attributes(for journey: JourneySnapshot) -> JourneyActivityAttributes?
      static func request(status: JourneyTimerController.Status, remainingSeconds: Int, now: Date) -> JourneyActivityRequest?
      static func pausedRequest(remainingSeconds: Int) -> JourneyActivityRequest
      static func appearPlan(existing: [LiveActivityHandle], journeyID: String) -> (reuseID: String?, endIDs: [String])
      static func launchPlan(existing: [LiveActivityHandle], journey: JourneySnapshot?) -> JourneyLaunchPlan
  }
  ```
- **`attributes(for:)`**
  - 버스는 `journey.bus`(`JourneySnapshot.swift:75`)의 `number`와 `kind`를 씁니다.
  - 도착지는 `journey.destinationName`(74행)입니다. 저장된 `destinationStopID`의 카탈로그 이름이고, `CourseJourney`의 계산값이 아닙니다(AC-31).
  - 둘 중 하나라도 nil이면 nil을 돌려주고, 이때는 표시하지 않습니다.
- **`request`**
  - running: `endDate = now + remaining`, `staleDate = endDate`, `pausedRemainingSeconds = nil` (BR-1, BR-5).
  - paused: `pausedRequest(remaining)`입니다. `endDate = nil`, `staleDate = nil`, `pausedRemainingSeconds = max(0, remaining)`.
  - arrived: nil입니다(종료 대상).
- **`appearPlan`**: journeyID가 같은 첫 handle을 재사용합니다. 같은 id의 나머지와 다른 id는 모두 `endIDs`에 넣습니다(AC-14·15).
- **`launchPlan`**(개정 1)
  - `journey == nil`이거나, `journey.phase != .departed`이거나, `journey.isArrived`이면 `endIDs = existing 전부`, `pausedUpdate = nil`입니다(AC-10·11).
  - 출발했고 미도착이면 다음과 같습니다.
    - 다른 id 전부와 같은 id 중 첫 번째를 뺀 나머지를 `endIDs`에 넣습니다(AC-32·33).
    - 같은 id의 첫 handle이 있으면 `pausedUpdate = (id, pausedRequest(journey.totalSeconds - journey.progress.elapsedSeconds))`입니다(AC-32: 3600 − 600 = 3000).
    - 같은 id가 없으면 `pausedUpdate = nil`이고 시작하지 않습니다(AC-34).
  - `journey.paused` 값은 보지 않습니다. 로드 시 `restingForLaunch`(`JourneySnapshot.swift:63-65`, `AppModel.swift:184`)로 이미 true입니다. 정책은 "출발·미도착 = 일시정지"를 그대로 따릅니다.

#### 4. `ios/FocusMate/LiveActivityGateway.swift`: 게이트웨이 (FR-7)
- **비동기 처리**
  - `start`는 **동기**입니다. `Activity.request`가 동기 throws라 결과(id 또는 실패)를 바로 알 수 있습니다.
  - `update`/`end`는 **`Task`를 발사하고 결과를 무시**합니다. iOS 16.2+의 `update(_:)`와 `end(_:dismissalPolicy:)`는 async non-throwing입니다.
  - 그래서 프로토콜의 `update`/`end`는 반환값이 없습니다. FR-7("재시도하지 않음")과 맞습니다.
- **시그니처**
  ```swift
  @MainActor protocol LiveActivityGateway: AnyObject {
      var activeActivities: [LiveActivityHandle] { get }
      /// 사용 불가·거부·실패면 nil. 실패도 시도로 본다.
      func start(attributes: JourneyActivityAttributes, request: JourneyActivityRequest) -> String?
      func update(id: String, request: JourneyActivityRequest)
      func end(id: String)
  }
  final class ActivityKitLiveActivityGateway: LiveActivityGateway { init() }
  ```
- **실제 구현**은 상태가 없습니다. 그래서 `.live()`가 다시 평가돼도 안전합니다(`JourneyServices.swift:16` 주석과 같은 이유).
  - `activeActivities`: `Activity<JourneyActivityAttributes>.activities` 중 `activityState`가 `.active`나 `.stale`인 것만 `(id, attributes.journeyID)`로 바꿉니다. `.dismissed`와 `.ended`는 빠지므로, 사용자가 닫은 카드는 다음 세션에서 "없음"으로 보입니다(M-13).
  - `start`
    - `ActivityAuthorizationInfo().areActivitiesEnabled == false`이면 nil입니다.
    - 그 밖에는 `try? Activity.request(attributes:content: ActivityContent(state:staleDate:), pushType: nil).id`입니다. 백그라운드에서 거부되면 nil입니다(M-14).
  - `update`: id로 activity를 찾아 `Task { await activity.update(ActivityContent(state:staleDate:)) }`를 실행합니다. 찾지 못하면 무시합니다.
  - `end`: `Task { await activity.end(nil, dismissalPolicy: .immediate) }`입니다.
- **DEBUG 기록기**(단위 테스트와 UI 테스트 공용. `failsUpdates`는 제거)
  ```swift
  #if DEBUG
  @MainActor @Observable final class RecordingLiveActivityGateway: LiveActivityGateway {
      struct Entry: Equatable {
          enum Op: String { case start, update, end }
          let op: Op; let activityID: String?; let journeyID: String?; let request: JourneyActivityRequest?
      }
      var failsStart = false          // AC-16·17: nil을 돌려주고 시도만 기록
      private(set) var entries: [Entry]
      private(set) var activeActivities: [LiveActivityHandle]
      init(existing: [LiveActivityHandle] = [])
      func count(_ op: Entry.Op) -> Int
      var diagnosticJSON: String { get }   // test.liveActivity
  }
  #endif
  ```
  - id는 "activity-1"부터 순서대로 만듭니다.
  - `end`는 `activeActivities`에서 제거합니다. AC-14·15·33의 "최종 활성 표시"는 이 목록으로 판정합니다.
  - `Entry`는 attributes 전체 대신 `journeyID`만 저장합니다. AC-1·31의 속성 값은 Sync 테스트에서 `Policy.attributes` 결과를 기록기의 마지막 start 인자로 비교합니다. 이를 위해 `lastStartAttributes: JourneyActivityAttributes?`를 하나 둡니다. `ActivityAttributes`의 Equatable 합성 문제는 이렇게 피합니다.

#### 5. `ios/FocusMate/JourneyTimerController.swift`: 옵저버 훅 (결정 4, AC-28)
- **현재**: 상태가 바뀌거나 처음 노출되는 곳은 `appear`(62-69), `halt`(147-153. pause·leave·저장 실패 정지가 공유), `resume`(93-106), `arrive`(162-172)뿐입니다.
- **변경**
  - init(33-34행)에 마지막 매개변수 `observer: JourneyTimerObserving? = nil`을 추가하고 `@ObservationIgnored private let observer`에 보관합니다.
  - `private func notifyObserver()`는 `observer?.timerDidChange(status: status, remainingSeconds: remainingSeconds)`만 호출합니다.
  - 호출 위치는 네 곳입니다.
    - `appear()` 끝(68행 `refresh()` 뒤)
    - `halt()` 끝(152행 뒤)
    - `resume()` 끝(105행 뒤)
    - `arrive()` 끝(171행 뒤)
  - 알림이 없는 경로: `tick` 체크포인트, `enterBackground` 성공 저장, 일시정지 상태의 `returnToForeground`, paused·arrived 상태의 `leave`(131-132행)는 위 네 곳을 거치지 않습니다(AC-3·19·21·25).
- **시그니처**
  ```swift
  @MainActor protocol JourneyTimerObserving: AnyObject {
      func timerDidChange(status: JourneyTimerController.Status, remainingSeconds: Int)
  }
  init(journey:autoStart:saver:clock:ticker:announcer:checkpointInterval: Int = 10, observer: JourneyTimerObserving? = nil)
  ```
  - 진행 비율이 없어졌으므로 `elapsedSeconds`는 넘기지 않습니다.
- **고려사항**
  - 기존 호출부(`JourneyView.swift:36-37`)와 기존 테스트(`JourneyTimerControllerTests.swift:32-35`)는 observer를 넘기지 않으므로 수정 없이 통과합니다(AC-28).
  - observer는 컨트롤러를 참조하거나 다시 호출하지 않습니다. 재진입이 없습니다.
  - `pause`/`resume`은 저장 실패 시 guard에서 돌아가므로(84-87, 95-98행) 알림이 없습니다(AC-5).
  - `leave`의 running 분기(126-130행)는 `halt()` 뒤에 저장합니다. 그래서 알림은 저장 결과와 상관없이 나갑니다. 컨트롤러가 일시정지로 바뀐 것은 사실이므로 AC-24와 일관됩니다.

#### 6. `ios/FocusMate/JourneyLiveActivitySync.swift`: 동기화 객체 (FR-1~8·13·14)
- **저장자도 타이머도 참조하지 않습니다**(W06 `JourneyMapController`와 같은 원칙). 표시가 진도나 저장을 바꿀 경로가 구조적으로 없습니다(BR-6).
- **시그니처**
  ```swift
  @MainActor final class JourneyLiveActivitySync: JourneyTimerObserving {
      init?(journey: JourneySnapshot, gateway: LiveActivityGateway, now: @escaping @MainActor () -> Date = { Date() })
      func timerDidChange(status: JourneyTimerController.Status, remainingSeconds: Int)
  }
  ```
- **내부 상태**: `attributes`, `activityID: String?`, `didReconcile`, `startFailed`, `lastSent: SentKey?`. 초안의 `finished`는 뺐습니다. arrived 뒤에는 running/paused로 돌아갈 수 없어서 필요 없습니다.
- **`SentKey`**: `struct SentKey: Equatable { let status: JourneyActivityStatus; let pausedRemainingSeconds: Int? }`
  - running의 `endDate`는 호출 시각에 따라 달라지는 파생값이라 키에서 뺍니다.
- **알고리즘**
  1. 첫 호출에서 한 번만 정리합니다. `appearPlan(gateway.activeActivities, journeyID)`의 `endIDs`를 순서대로 `end`하고, `reuseID`를 `activityID`로 둡니다. `lastSent`는 nil이므로 재사용 시 반드시 update가 나갑니다(AC-11 화면, 12·13·14·15).
  2. `startFailed`이면 아무것도 하지 않습니다(AC-17).
  3. arrived이면 `activityID`가 있을 때만 `end`하고 nil로 비웁니다. 시작은 하지 않습니다(AC-6·7·11·23).
  4. running/paused이면 `Policy.request(status:remainingSeconds:now: now())`로 요청 내용을 만듭니다.
     - `activityID`가 있으면 `SentKey`가 같을 때 건너뛰고, 다르면 `update`합니다.
     - `activityID`가 없으면 `start`합니다. 결과가 nil이면 `startFailed = true`입니다.
     - start/update를 시도할 때 `lastSent`를 갱신합니다. update 실패는 알 수 없고 재시도하지 않습니다(FR-7).
- **세션 범위**: Sync는 `ensureTimer()`가 만드는 컨트롤러 하나와 수명이 같습니다. 화면을 다시 만들면 새 세션이므로 `startFailed`도 새로 시작합니다(FR-7 "그 화면 세션").
- **M-13**: 사용자가 카드를 닫아도 Sync의 `activityID`는 그대로입니다. 이후 update는 시스템이 무시하고, 같은 세션에서 다시 start하지 않습니다.

#### 7. `ios/FocusMate/JourneyLiveActivityCleanup.swift`: 앱 시작 정리 (개정 1, AC-10·11·32·33·34)
- **시그니처**
  ```swift
  @MainActor enum JourneyLiveActivityCleanup {
      static func atLaunch(gateway: LiveActivityGateway, journey: JourneySnapshot?)
  }
  ```
- **동작**: `launchPlan(existing: gateway.activeActivities, journey:)`를 구한 뒤 `endIDs`를 순서대로 `end`하고, `pausedUpdate`가 있으면 `update(id:request:)`를 부릅니다. start는 하지 않습니다.
- 순서는 end가 먼저, update가 나중입니다. AC-33의 최종 활성 표시 1개는 기록기의 `activeActivities`로 확인합니다.

#### 8. `ios/FocusMate/JourneyServices.swift`: 주입 지점
- **현재**: 생성자 주입 묶음이고 `live()`(25-30행)가 memberwise init을 호출합니다.
- **변경**: 기본값 있는 프로퍼티 1개만 추가합니다. memberwise init 매개변수에 기본값이 붙으므로 `live()`와 기존 호출부는 바뀌지 않습니다.
  ```swift
  /// 앱 밖 표시 요청 창구. UI 테스트는 기록기로 바꾼다.
  var liveActivities: LiveActivityGateway = ActivityKitLiveActivityGateway()
  ```
- 초안의 `wallNow`와 `liveActivityRecorder`는 SIMPLIFY에 따라 제거했습니다. 벽시계는 Sync의 기본 인자(`Date()`)이고, 진단은 RootView에서 캐스팅해 꺼냅니다.

#### 9. `ios/FocusMate/JourneyView.swift`: 연결 (FR-1·5·14)
- **현재**: `ensureTimer()`(34-43행)가 컨트롤러를 만들고, `onDisappear`(27-30행)가 `timer?.leave()`를 부릅니다.
- **변경**: 36행 앞에 다음을 두고 생성자에 `observer: live`를 추가합니다.
  ```swift
  let live = JourneyLiveActivitySync(journey: journey, gateway: services.liveActivities)
  ```
  - 컨트롤러가 강하게 참조하므로 `@State`는 따로 두지 않습니다.
  - `onDisappear`는 바꾸지 않습니다. `leave()`가 `halt()`를 거쳐 알림을 보내기 때문입니다(AC-24).

#### 10. `ios/FocusMate/FocusMateApp.swift`: 앱 시작 정리 호출
- **현재**: `start()`(92-107행)가 `model.start()`로 로드한 뒤, DEBUG에서 `applySaveScenario`와 `applyRoute`를 적용합니다.
- **변경**
  - DEBUG 블록 **뒤**(106행 `#endif` 다음)에 `cleanUpLiveActivities()`를 호출합니다.
  - 근거: 테스트 시나리오가 적용된 최종 모델 상태를 기준으로 정리합니다. `applyRoute("journey")`의 `model.open(.journey)`는 경로만 쌓고, JourneyView의 `onAppear`는 다음 렌더에서 실행됩니다. 따라서 시작 정리가 화면 정리보다 항상 먼저입니다.
  ```swift
  private func cleanUpLiveActivities() {
      guard case .ready = model.launchState else { return }   // .failed는 "여행 없음"이 아니다
      JourneyLiveActivityCleanup.atLaunch(gateway: liveActivityGateway, journey: model.activeJourney)
  }
  private var liveActivityGateway: LiveActivityGateway  // DEBUG: journeyServices.liveActivities / Release: ActivityKitLiveActivityGateway()
  ```
  - `model.activeJourney`(`AppModel+Boarding.swift:6`)는 `restingForLaunch`가 적용된 값입니다.
- AppModel을 바꾸지 않으므로 W07과 충돌하지 않습니다.

#### 11. `ios/FocusMate/UITestBootstrap.swift`·`RootView.swift`: DEBUG 하네스 (축소)
- **`makeJourneyServices`(229-247행)**: 238행 뒤에 `services.liveActivities = RecordingLiveActivityGateway()` 1줄을 추가합니다.
  - UI 테스트 모드에서는 항상 기록기를 씁니다. 기존 182개 UI 테스트가 시뮬레이터에 실제 카드를 띄우지 않게 하는 AC-29 보호 장치입니다.
  - 새 런치 인자는 만들지 않습니다.
- **`RootView.testDiagnostics`(250-253행 뒤)**
  ```swift
  if let gateway = services.liveActivities as? RecordingLiveActivityGateway {
      Text("표시 진단").accessibilityValue(gateway.diagnosticJSON).accessibilityIdentifier("test.liveActivity")
  }
  ```
  - `journeyServices`(`FocusMateApp.swift:85`)는 `testServices`(stored let)를 돌려주므로 같은 기록기 인스턴스입니다.
  - 기록기가 `@Observable`이라 RootView가 갱신을 관찰합니다.
- **`test.liveActivity` 스키마**: endDate와 staleDate는 epoch 초(Double) 또는 null입니다.
  ```json
  {"active":[{"id":"activity-1","journeyID":"seed-timer"}],
   "requests":[{"op":"start","id":"activity-1","status":"paused","endDate":null,"staleDate":null,"pausedRemaining":1410}]}
  ```

#### 12. 위젯 UI: `ios/FocusMateWidgets/JourneyLiveActivityWidget.swift` (표현 레이어, M-1~12)
- `ActivityConfiguration(for: JourneyActivityAttributes.self) { lockScreen } dynamicIsland: { ... }`
- **시간 표시**: 하위 뷰 `JourneyActivityTimeText(content:)` 하나를 씁니다. `JourneyActivityDisplay.timeContent(state:isStale: context.isStale, now: .now)` 결과로 분기합니다.
  - `.countdown(range)`이면 `Text(timerInterval: range, countsDown: true, showsHours: false)`입니다.
  - `.fixed(text)`이면 `Text(text)`입니다.
  - `Text(endDate, style: .timer)`는 0을 지나면 다시 올라가므로 쓰지 않습니다.
- **잠금 화면**
  - 표시 요소는 "번호 종류" 버스, 도착지, 상태 이름, 시간입니다. 진행 막대는 없습니다.
  - 컨테이너 라벨은 `JourneyActivityDisplay.accessibilityLabel(attributes:state:isStale:)`입니다. running에서는 카운트다운 요소를 따로 남겨 시스템이 읽게 합니다.
- **Dynamic Island**
  - expanded: leading 버스 번호, trailing 시간, bottom 도착지와 상태 이름
  - compact: leading 버스 번호, trailing 시간
  - minimal: 시간
- 문구와 포맷은 모두 `JourneyActivityDisplay`에서 가져옵니다. 위젯 안에 리터럴을 두지 않습니다.

---

### 상태와 요청 흐름

```
[앱 시작] FocusMateApp.start → model.start(restingForLaunch) → (DEBUG 시나리오) → (ready) Cleanup.atLaunch
   journey 없음 / 미출발 / isArrived  → existing 전부 end                                           (AC-10, 11)
   출발·미도착 → 다른 id·여분 end → 같은 id 1개 update(paused, total−elapsed, nil/nil)               (AC-32, 33)
               같은 id 없음 → 요청 0                                                                  (AC-34)

[화면] JourneyView.ensureTimer → Sync(journey, gateway) → JourneyTimerController(observer: Sync)
JourneyTimerView.onAppear → controller.appear() → notify
   Sync 첫 호출: reconcile → 다른 id·여분 end, 같은 id → activityID 재사용
     running: activityID? update(endDate=now+rem, stale=endDate) : start(...)                       (AC-1, 12, 14, 15)
     paused : activityID? update(paused rem, nil/nil)            : start(...)                       (AC-8, 13)
     arrived: activityID? end : 요청 없음                                                            (AC-7, 11)
사용자 pause ─저장 성공→ halt → notify(paused) → update                                               (AC-2)
사용자 resume ─저장 성공→ resume → notify(running) → update(endDate = now + rem)                      (AC-4, 9)
              ─저장 실패→ 알림 없음                                                                   (AC-5)
tick/checkpoint/returnToForeground/enterBackground(성공) → 알림 없음 / appear 반복 → SentKey 동일 → 생략 (AC-3, 18, 19, 21)
checkpoint·background 저장 실패 → stopForSaveFailure → halt → notify(paused) → update                (AC-20)
reachedTotal(틱·복귀·백그라운드) → arrive → notify(arrived) → end 1회                                (AC-6, 23)
JourneyView.onDisappear → leave: running → halt → notify(paused) → update / paused·arrived → 없음       (AC-24, 25)
```

**실패 처리 요약 (FR-7)**

| 상황 | 처리 |
|---|---|
| start가 nil(꺼짐, 거부, 백그라운드, 예외) | 세션 동안 `startFailed` 고정. 이후 update/end 0회. 사용자에게 아무것도 보여주지 않음 |
| update/end 실패 | 알 수 없으므로 무시. `lastSent`는 갱신. 다음 상태 변화 때 정상 요청 |
| 사용자가 카드를 닫음(.dismissed) | 같은 세션에서는 다시 띄우지 않음(M-13). 다음 세션에서는 "없음"으로 보고 start |
| 속성 생성 불가(카탈로그 밖 버스·정류장) | `Sync.init?`가 nil. observer 없이 동작 |

---

### pbxproj 변경 상세 (`ios/FocusMate.xcodeproj/project.pbxproj`)
기존 ID 규칙(타입별 접두어 + 순번)을 이어서 씁니다.

| 객체 | ID | 내용 |
|---|---|---|
| PBXFileReference | `A20000000000000000000014` | `explicitFileType = "wrapper.app-extension"; includeInIndex = 0; path = FocusMateWidgets.appex; sourceTree = BUILT_PRODUCTS_DIR;` |
| PBXBuildFile | `A10000000000000000000001` | `fileRef = A2…14; settings = {ATTRIBUTES = (RemoveHeadersOnCopy, ); };` |
| PBXFileSystemSynchronizedRootGroup | `A40000000000000000000006` | `path = FocusMateWidgets; exceptions = (A8…01);` |
| PBXFileSystemSynchronizedRootGroup | `A40000000000000000000007` | `path = Shared;` |
| PBXFileSystemSynchronizedBuildFileExceptionSet | `A80000000000000000000001` | `membershipExceptions = (Info.plist, ); target = A5…04;`. Info.plist가 리소스로 복사돼 "Multiple commands produce"가 나는 것을 막음 |
| PBXGroup(main, 28행) | 기존 | children에 `A4…06`, `A4…07` 추가 |
| PBXGroup(Products, 29행) | 기존 | children에 `A2…14` 추가 |
| PBXSourcesBuildPhase / Frameworks / Resources | `A6…04` / `A6…14` / `A6…24` | 위젯용 빈 단계 3개 |
| PBXCopyFilesBuildPhase | `A60000000000000000000031` | `name = "Embed Foundation Extensions"; dstPath = ""; dstSubfolderSpec = 13; files = (A1…01); buildActionMask = 2147483647; runOnlyForDeploymentPostprocessing = 0;` |
| PBXNativeTarget | `A50000000000000000000004` | `name = FocusMateWidgets; productType = "com.apple.product-type.app-extension"; buildPhases = (A6…04, A6…14, A6…24); fileSystemSynchronizedGroups = (A4…06, A4…07); dependencies = (); productReference = A2…14; buildConfigurationList = AA…04;` |
| PBXNativeTarget FocusMate(32행) | 기존 | T1에서 `fileSystemSynchronizedGroups = (A4…02, A4…07)`. T9에서 `buildPhases`에 `A6…31`(Resources 뒤) 추가, `dependencies = (A7…03)` |
| PBXContainerItemProxy | `A30000000000000000000003` | `containerPortal = A9…01; proxyType = 1; remoteGlobalIDString = A5…04; remoteInfo = FocusMateWidgets;` |
| PBXTargetDependency | `A70000000000000000000003` | `target = A5…04; targetProxy = A3…03;` |
| PBXProject(37행) | 기존 | `targets`에 `A5…04` 추가. `TargetAttributes`에 `A5…04 = {CreatedOnToolsVersion = 27.0; };` |
| XCConfigurationList | `AA0000000000000000000004` | `(AB…40 Debug, AB…41 Release)`, `defaultConfigurationName = Release` |

**빌드 설정**
- **위젯** `AB…40`/`AB…41`
  ```
  CODE_SIGN_STYLE = Automatic; DEVELOPMENT_TEAM = ""; GENERATE_INFOPLIST_FILE = YES;
  INFOPLIST_FILE = FocusMateWidgets/Info.plist; INFOPLIST_KEY_CFBundleDisplayName = FocusMate;
  PRODUCT_BUNDLE_IDENTIFIER = app.focusmate.prototype.widgets; PRODUCT_NAME = "$(TARGET_NAME)";
  SKIP_INSTALL = YES; APPLICATION_EXTENSION_API_ONLY = YES;
  LD_RUNPATH_SEARCH_PATHS = ("$(inherited)", "@executable_path/Frameworks", "@executable_path/../../Frameworks");
  SUPPORTED_PLATFORMS = "iphoneos iphonesimulator";
  ```
  - Debug에만 `SWIFT_OPTIMIZATION_LEVEL = "-Onone"`을 둡니다.
  - deployment 17.0, Swift 5, `STRICT_CONCURRENCY = minimal`, `TARGETED_DEVICE_FAMILY = 1`은 프로젝트 수준(54-55행)에서 상속합니다.
- **앱** `AB…10`/`AB…11`(56-57행): `INFOPLIST_KEY_NSSupportsLiveActivities = YES;`를 추가합니다.
- **프로젝트** `AB…00`/`AB…01`(54-55행): `MARKETING_VERSION = 1.0; CURRENT_PROJECT_VERSION = 1;`을 추가합니다. 앱과 확장이 같은 값을 상속해 임베드 검증 경고를 피합니다.
- **위젯 `Info.plist`**: `NSExtension` 딕셔너리 하나에 `NSExtensionPointIdentifier = com.apple.widgetkit-extension`만 둡니다.

**스킴**(`xcshareddata/xcschemes/FocusMate.xcscheme`)은 바꾸지 않습니다. 3행이 `buildImplicitDependencies="YES"`라서 앱을 빌드하면 위젯도 함께 빌드되고 임베드됩니다.

**`CODE_SIGNING_ALLOWED=NO` 시뮬레이터**: 위젯 확장에는 Live Activity용 entitlement가 필요 없습니다. 서명 없이 임베드한 앱이 실제로 설치되는지는 T9 완료 조건(기존 UI 테스트 1건 실행)으로 확인합니다. 실기기(W14)는 팀 서명이 필요합니다.

**단위 테스트 접근**: `ios/Shared`는 앱 타깃에도 속합니다. 그래서 `JourneyActivityAttributes`와 `JourneyActivityDisplay`는 FocusMate 모듈의 internal 타입이 되고 `@testable import FocusMate`로 접근합니다.

---

### AC 매핑 (AC마다 소유 테스트 1개)
진행 비율 판정은 AC-1·2·4·8·9·20에서 모두 뺐습니다.

| AC | 소유 테스트 | 판정 |
|---|---|---|
| 1, 2, 4, 5, 6, 7, 8, 9 | `JourneyLiveActivitySyncTests`(T4) | 실제 컨트롤러 + `ManualJourneyClock` + `FakeProgressSaver` + 기록기. AC-1은 `lastStartAttributes`로 "343"·"간선"·저장 도착지 이름까지 확인 |
| 11(화면), 12, 13, 14, 15 | `JourneyLiveActivitySyncTests`(T5) | 기록기 `existing` 시드 |
| 3, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25 | `JourneyLiveActivitySyncTests`(T6) | AC-22는 AC-1·4·12와 AC-2·8·13·20 시나리오 기록 전체에서 status별 staleDate 규칙을 일괄 검사 |
| 10, 11(시작), 32, 33, 34 | `JourneyLiveActivityCleanupTests`(T7) | `atLaunch` + 기록기. AC-32: end 1(다른 id), update 1(paused 3000, nil/nil), start 0. AC-33: end 1, update 1, active 1개. AC-34: 0/0/0 |
| 26, 30 | `JourneyActivityDisplayTests`(T1) | 문자열 정확 일치, Mirror로 정확히 7 label |
| 31 | `JourneyLiveActivityPolicyTests`(T3) | 저장 도착지 이름(계산 도착지와 다른 픽스처) |
| 28 | `JourneyTimerObserverParityTests`(T2) + 기존 `JourneyTimerControllerTests` 무수정 | observer 유무 두 컨트롤러의 status, elapsed, remaining, writes를 매 단계 비교 |
| 29 | `AppInfoLiveActivityTests`(T9) + 전체 `check-ios.py build/test`(T12) | 절별로 소유 |
| 위젯 선택 함수(보조) | `JourneyActivityDisplayTests`(T8) | paused 우선, stale 또는 arrived는 만료 문구, running의 하한 `min`(endDate < now에서 트랩 없음), endDate nil 방어 |
| 배선(보조) | `JourneyLiveActivityUITests`(T11) 1건 | 아래 참고 |

- **AC-27은 삭제**됐습니다(개정 1).
- **배선 UI 테스트 1건**: `launchJourney(seed: "timerPaused90")`로 시작합니다.
  1. requests가 `[start paused 1410 null/null]` 1건이어야 합니다. 이것으로 시작 정리 요청이 0건(AC-34 배선)이고 화면 start 경로가 배선됐음을 확인합니다.
  2. `journey.timer.resume`을 누르면 `update running`이고, endDate는 non-null이며 staleDate == endDate입니다.
  3. `test.clock.advance60`을 누르면 추가 요청이 없습니다.
  4. `journey.timer.pause`를 누르면 `update paused 1350`입니다.
  - 초안의 `timerArrived` 케이스는 AC-7 단위 테스트와 겹쳐 뺐습니다.
- **픽스처 주의점**(test-architect)
  - 버스는 `BoardingFixtures.journey(minutes: 60, busID: "421", phase: .departed, ...)`입니다. 기본값 busID "2014"(`BoardingTestDoubles.swift:30`)가 아니라 "421"(343 간선, `RouteData.swift:86`)을 써야 합니다.
  - `ManualJourneyClock`은 tick 구독을 하나만 받습니다(`JourneyClock.swift:69`). parity 테스트는 시계와 저장자를 컨트롤러마다 따로 만듭니다.
  - `now = base.addingTimeInterval(TimeInterval(clock.now.components.seconds))`는 정수 초입니다. AC-4·9·12의 endDate는 정확히 일치로 비교합니다.
  - AC-31: 카탈로그(`RouteData.swift:11`)에 "서울역"이 없습니다. 계산 도착지와 다른 저장 `destinationStopID`를 쓰고, 그 정류장의 카탈로그 이름과 정확히 같은지 판정합니다. AC-26은 문구 함수에 "서울역"을 직접 넣습니다.

---

### 의존성 및 영향도
- **새 의존성**: ActivityKit, WidgetKit(시스템 프레임워크). 외부 라이브러리는 없습니다.
- **기존 코드 영향**
  - 컨트롤러 init에는 기본값 매개변수만 추가되므로 호출부 수정이 없습니다.
  - `JourneyServices`의 memberwise init도 기본값 덕분에 호출부 수정이 없습니다.
- **하위 호환**: 저장 형식 v4, `JourneySnapshot`, `AppModel`은 바뀌지 않습니다.
- **기존 UI 테스트**: 부트스트랩 모드에서는 항상 기록기를 쓰므로 실제 표시 요청이 0건입니다. 화면 요소와 식별자는 그대로이고 `test.liveActivity`만 추가됩니다.
- **단위 테스트 호스트(가정)**: 호스트 앱은 부트스트랩 없이 실행되므로 실제 게이트웨이로 `atLaunch`가 돕니다. 시뮬레이터 호스트에는 남은 activity가 없다고 가정하므로 요청은 0건입니다. 남아 있더라도 end/update만 일어나고, 단위 테스트는 각자의 기록기를 쓰므로 판정에 영향이 없습니다.

#### 기존 구조와의 차이 (`context/journey/architecture.md`)
1. **첫 앱 확장 타깃과 첫 공유 소스 폴더**(`ios/Shared`)입니다. 지금까지는 단일 앱 모듈이었습니다.
2. **타이머 동기화 경로가 W06과 다릅니다.**
   - 지도는 `JourneyTimerView`의 `onChange(MapSync)`(56-58행)로 맞춥니다.
   - 표시는 컨트롤러 옵저버 훅으로 맞춥니다. 화면 이탈(`onDisappear` → `leave`)과 백그라운드 저장 실패 정지는 뷰 `onChange`로는 반영을 보장할 수 없기 때문입니다.
   - 진도 계산과 저장 경로는 바뀌지 않습니다.
3. **벽시계(`Date`)가 처음 여행 런타임에 들어옵니다.** 진도는 계속 단조 시계(`JourneyClock`)만 쓰고, `Date`는 Sync의 종료 시각 계산에만 씁니다.
4. **앱 시작 지점(`FocusMateApp.start`)에 저장 이외의 부수 효과**가 생깁니다. 남은 표시를 종료하거나 일시정지로 갱신합니다.
5. 문서 규칙("새 계층·파일·API를 이미 구현된 것으로 표시하지 않는다")에 따라 구현 완료 후에만 반영합니다.

#### W07 충돌 최소화

| 파일 | 변경 hunk | W07 예상 수정과의 관계 |
|---|---|---|
| `AppModel*`, `JourneyTimerView.swift` | 없음 | — |
| `JourneyView.swift` | `ensureTimer()` 안 2줄 | W07은 이탈과 나가기 UI. hunk가 다름 |
| `RootView.swift` | DEBUG 진단 블록 3줄 | W07이 고칠 `mainContent`와 다른 hunk |
| `JourneyServices.swift` | 프로퍼티 1개 | `live()`는 그대로 |
| `UITestBootstrap.swift` | `makeJourneyServices` 1줄 | — |
| `FocusMateApp.swift` | `start()` 끝 1줄 + private 헬퍼 | — |

- W07의 "나가기·포기 시 표시 종료"는 `services.liveActivities.activeActivities` 전부를 `end`하면 됩니다. 별도 API를 미리 만들지 않습니다.

---

### 테스트 가능성
- **게이트웨이 프로토콜**: 단위·UI 테스트는 동기 기록기로 검증합니다. 실제 ActivityKit은 얇은 어댑터에만 있고 M 항목으로 확인합니다.
- **시각 주입**: Sync의 `now`를 `ManualJourneyClock`에서 파생합니다. 종료 시각을 정확히 비교할 수 있습니다.
- **순수 정책과 선택 함수**: enum static이라 픽스처 없이 표 기반 테스트가 가능합니다. `launchPlan`의 경계(nil, 미출발, 도착, 출발·미도착 × existing 0/1/2/다른 id)를 Policy 테스트에서 표로 덮고, Cleanup 테스트는 게이트웨이 적용 결과(AC-10·11·32~34)만 봅니다.
- **동기화 객체**: 저장자와 타이머 의존이 없습니다. 실제 컨트롤러에 observer로 꽂아 사용자 조작 순서 그대로 검증하므로 뷰 배선을 흉내 낼 필요가 없습니다.
- **위젯**: 뷰 자체는 빌드만 자동 판정합니다. 크래시 위험이 있는 분기(ClosedRange 하한)는 Shared 순수 함수로 단위 테스트합니다.

---

### 구현 순서
태스크 하나가 RGR 1사이클입니다. 작업 중에는 focused 테스트만 돌리고, 전체 테스트는 T12에서 한 번만 돌립니다. 빌드와 테스트 실행은 순차로 합니다(동시 빌드 금지).

1. [Must] **T1 공유 모델·문구** (의존: 없음)
   - `ios/Shared/JourneyActivityAttributes.swift`, `JourneyActivityDisplay.swift`(문구만)
   - pbxproj에 Shared 동기화 그룹을 **앱 타깃에만** 연결
   - AC-26, AC-30
   - focused: `ios/FocusMateTests/JourneyActivityDisplayTests.swift`
2. [Must] **T2 컨트롤러 옵저버 훅** (의존: 없음)
   - `JourneyTimerController.swift`, AC-28
   - focused: `ios/FocusMateTests/JourneyTimerObserverParityTests.swift`, `ios/FocusMateTests/JourneyTimerControllerTests.swift`
3. [Must] **T3 순수 정책** (의존: 1)
   - `JourneyLiveActivityPolicy.swift`
   - `attributes`, `request`/`pausedRequest`(BR-1·5), `appearPlan`, `launchPlan` 표 테스트, AC-31
   - focused: `ios/FocusMateTests/JourneyLiveActivityPolicyTests.swift`
4. [Must] **T4 게이트웨이·기록기 + 동기화 시작·전이** (의존: 2, 3)
   - 초안의 T4와 T5a를 합쳤습니다.
   - `LiveActivityGateway.swift`, `JourneyLiveActivitySync.swift`
   - AC-1, 2, 4, 5, 6, 7, 8, 9
   - focused: `ios/FocusMateTests/JourneyLiveActivitySyncTests.swift`
5. [Must] **T5 동기화: 정리·재사용** (의존: 4. Sync 파일 공유)
   - reconcile, AC-11(화면), 12, 13, 14, 15
   - focused: `JourneyLiveActivitySyncTests.swift`
6. [Must] **T6 동기화: 억제·실패·이탈·자동 정지** (의존: 5. Sync 파일 공유)
   - SentKey, startFailed, AC-3, 16, 17, 18, 19, 21, 22, 23, 24, 25
   - [Should] AC-20도 여기에 넣습니다. 훅 구조상 별도 구현이 없어 RED가 없는 단독 태스크가 되기 때문입니다.
   - focused: `JourneyLiveActivitySyncTests.swift`
7. [Must] **T7 앱 시작 정리 함수** (의존: 3, 4)
   - `JourneyLiveActivityCleanup.swift`, AC-10, 11(시작), 32, 33, 34
   - focused: `ios/FocusMateTests/JourneyLiveActivityCleanupTests.swift`
8. [Must] **T8 위젯 표시 선택 함수** (의존: 1. Display 파일 공유)
   - `JourneyActivityDisplay.timeContent`, `accessibilityLabel`
   - focused: `JourneyActivityDisplayTests.swift`
9. [Must] **T9 위젯 타깃·프로젝트 구성** (의존: 1. pbxproj 공유)
   - pbxproj: 위젯 타깃, 임베드, 의존성, 버전 키, `NSSupportsLiveActivities`, Shared를 위젯에도 연결
   - 최소 `FocusMateWidgetsBundle` + 빈 `ActivityConfiguration`, `Info.plist`
   - **완료 조건**
     - `check-ios.py build` 성공
     - `AppInfoLiveActivityTests` 통과
     - 기존 UI 테스트 1건 실행 성공: `python3 scripts/check-ios.py test ios/FocusMateUITests/HarnessUITests.swift`(1건). 서명 없이 확장을 임베드한 앱이 설치되는지 확인합니다.
   - focused: `ios/FocusMateTests/AppInfoLiveActivityTests.swift`, `ios/FocusMateUITests/HarnessUITests.swift`
10. [Must] **T10 위젯 UI** (의존: 8, 9)
    - `JourneyLiveActivityWidget.swift`(잠금 화면, Dynamic Island, 접근성)
    - 자동 판정은 `check-ios.py build`뿐입니다. M-1~12는 W14에서 확인합니다.
11. [Must] **T11 앱 배선 + 배선 UI 테스트** (의존: 4, 7)
    - 초안의 T7과 T10을 한 사이클로 합쳤고, 위젯 타깃 의존은 뗐습니다.
    - `JourneyServices`, `JourneyView.ensureTimer`, `FocusMateApp.start`, `UITestBootstrap.makeJourneyServices`, `RootView` 진단
    - focused: `ios/FocusMateUITests/JourneyLiveActivityUITests.swift`(1건)
12. [Must] **T12 문서와 전체 검증** (의존: 6, 10, 11)
    - `context/journey/architecture.md` 갱신
    - 전체 `check-ios.py build` + `test` 1회로 AC-29(회귀 0건) 확인

**병렬 가능**
- 1과 2는 서로 독립입니다.
- 4 이후 5→6(같은 파일 체인)과 7은 독립입니다.
- 8과 9는 1 이후 서로 독립입니다(파일이 겹치지 않음).
- 위젯 쪽(8·9·10)과 앱 쪽(4~7·11)은 파일이 겹치지 않습니다. 단, 실행은 순차로 합니다.

---

### 위험과 대안
- **R-1 동기화 그룹 하나를 두 타깃에 연결**
  - objectVersion 77에서 지원되는 구성이지만 이 프로젝트에서는 처음입니다. T1(앱만)과 T9(위젯 추가)에서 단계적으로 확인합니다.
  - 대안: `ios/Shared`를 일반 `PBXGroup` + `PBXFileReference` 2개 + 두 Sources 단계의 `PBXBuildFile`로 바꿉니다.
- **R-2 위젯 Info.plist 처리**: 예외 세트로 리소스 복사를 막습니다. 그래도 충돌하면 Info.plist를 동기화 폴더 밖(`ios/FocusMateWidgets-Info.plist`)으로 옮기고 `INFOPLIST_FILE`만 바꿉니다.
- **R-3 update/end 순서 비보장 (정정)**
  - 각 요청이 독립 `Task`라 실행 순서가 보장되지 않습니다.
  - 연속 요청은 일시정지 update 직후 도착 end 정도라 확률이 낮습니다. 역전돼도 끝난 activity에 대한 update는 반영되지 않으므로 **감수**합니다.
  - 대안(채택 안 함): 게이트웨이 인스턴스에 직전 Task를 이어 붙이는 직렬 체인. 상태 없는 게이트웨이 원칙을 깨므로 쓰지 않습니다.
- **R-4 실제 `activities` 반영 지연**: 앱 시작 정리 직후 같은 실행에서 화면 정리가 이미 끝난 표시에 end를 한 번 더 보낼 수 있습니다. 무해하고, 기록기 기반 AC에는 영향이 없습니다.
- **R-5 시스템 수명 제한**: 최대 여정 360분(`JourneySnapshot.swift:9`)은 활성 표시 8시간 한도 안입니다. 그보다 오래 방치된 일시정지 카드는 시스템이 정리하며, 이는 감수합니다.
- **R-6 컨트롤러 수정(AC-28)**
  - 훅은 알림 1줄씩이고 상태와 진도 변수를 건드리지 않습니다. parity 테스트와 기존 테스트 무수정으로 보장합니다.
  - 대안 A(W06처럼 뷰 `onChange` + 명시 호출)는 사용자 결정 4에 따라 채택하지 않았습니다.
- **R-7 M-13/14 한계**: 사용자가 닫은 카드나 백그라운드 시작 거부는 같은 세션에서 복구하지 않습니다(PRD 개정 1 감수). `activeActivities`가 `.active`/`.stale`만 걸러내므로 다음 세션에서 자연스럽게 새로 시작됩니다.

### 설계 가정
- 앱 밖 표시의 "시계 현재 시각"은 요청 시점의 `Date()`입니다. 단조 시계와의 1초 미만 차이와 정수 초 내림 오차는 QE-1(1분) 범위 안입니다.
- `end`는 최종 내용 없이(`nil`) `.immediate`로 보냅니다. `JourneyActivityStatus.arrived`는 문구와 접근성(AC-26) 그리고 위젯 방어 분기에만 씁니다.
- 출발 대기(`awaitingDeparture`) 여정에는 표시가 생기지 않습니다(`JourneyView.swift:35`). 앱 시작 정리는 미출발 여정을 "여행 없음"과 똑같이 보고 남은 표시를 모두 종료합니다. PRD 개정 1은 "출발·미도착"만 규정하므로, 정당한 카드가 있을 수 없는 경우를 정리 쪽으로 해석했습니다.
- 저장소 읽기 실패(`launchState == .failed`)에서는 시작 정리를 하지 않습니다. "저장된 여행 없음"과 다르기 때문입니다.
- 단위 테스트 호스트에서 실제 게이트웨이 `atLaunch`가 돌아도 요청은 0건입니다(위 영향도 참고).
- UI 테스트에서 기록기에 `existing`을 시드해 시작 정리 배선을 검증하는 런치 인자는 만들지 않습니다. 배선 UI 테스트의 "첫 요청이 화면 start"라는 판정과 Cleanup 단위 테스트로 충분하다고 봅니다.

### 탐색 추가 항목
- `ios/FocusMate/JourneyTimerController.swift:62-69, 93-106, 124-134, 147-153, 162-172` → 훅 위치 4곳과 `leave` 분기(halt 뒤 저장)
- `ios/FocusMate/JourneySnapshot.swift:55-56, 63-65, 74-75` → `totalSeconds`, `isArrived`, `restingForLaunch`, `destinationName`, `bus`
- `ios/FocusMate/AppModel.swift:180-195` → 로드 시 `restingForLaunch` 적용, `launchState` `.ready`/`.failed`
- `ios/FocusMate/FocusMateApp.swift:12, 85, 92-107` → `testServices`(stored), `journeyServices`, `start()`의 DEBUG 시나리오 순서
- `ios/FocusMate/JourneyServices.swift:14-30` → 주입 묶음, `.live()` 재평가 주석
- `ios/FocusMate/JourneyView.swift:27-30, 34-43` → 이탈 처리, 컨트롤러 생성부
- `ios/FocusMate/UITestBootstrap.swift:212-218, 229-247, 271, 274-282` → `route journey`, 서비스 주입, 타이머 시드(25분, 2014 지선, `seed-timer`)
- `ios/FocusMate/RootView.swift:7, 239-256` → `services` 기본값, 전역 DEBUG 진단
- `ios/FocusMate/JourneyTimerView.swift:90-92, 264` → `journey.timer.pause`/`resume`, `test.timer`
- `ios/FocusMate/JourneyClock.swift:62-85` → `ManualJourneyClock` 단일 tick 구독
- `ios/FocusMateTests/BoardingTestDoubles.swift:24-36` → `BoardingFixtures.journey` 기본값(busID "2014")
- `ios/FocusMateTests/JourneyTimerControllerTests.swift:12-43` → Rig 패턴
- `ios/FocusMateUITests/UITestLaunchSupport.swift:60-77` → `launchJourney`, 진단 JSON 읽기
- `ios/FocusMateUITests/HarnessUITests.swift` → 1건짜리 기존 UI 테스트(T9 설치 확인용)
- `scripts/check-ios.py:29-39` → 스킴, `CODE_SIGNING_ALLOWED=NO`, 파일 단위 `-only-testing`
- `ios/FocusMate.xcodeproj/project.pbxproj:9-67` → 객체 ID 규칙, 동기화 그룹, 빌드 설정
- `ios/FocusMate.xcodeproj/xcshareddata/xcschemes/FocusMate.xcscheme:3` → `buildImplicitDependencies="YES"`

---

## Testability 평가 (test-architect)

> 주: 아래 평가는 설계 초안 기준(8/10 PASS). 확정본은 그 보정 권고(AC-30 일원화, T4→T5a 병합, T7+T10 병합, 위젯 선택 함수 Shared 추출)와 사용자 결정(진행 막대 제거 → progress 관련 항목 무효)을 반영했다.


설계서 `/Users/bonseung/projects/focus-mate/next-step-w15/.dev/feat-live-activity-progress/design-draft.md`를 기준으로 평가했습니다. 근거로 확인한 코드는 `JourneyTimerController.swift`, `JourneyClock.swift`(ManualJourneyClock), `JourneyTimerTestDoubles.swift`, `BoardingTestDoubles.swift`, `UITestBootstrap.swift:229-282`, `JourneyView.swift:23-43`, `JourneySnapshot.swift:55-75`, `RouteData.swift:86`입니다.

### 레이어 분류 (frontend-testing.md §2 기준)

| 컴포넌트 | 레이어 | 점수 대상 |
|---|---|---|
| JourneyActivityDisplay (Shared) | 순수 포맷터 | O |
| JourneyActivityAttributes (Shared) | 데이터 모델 | O (AC-30) |
| JourneyLiveActivityPolicy | 순수 규칙 | O |
| JourneyLiveActivitySync | 상태·데이터 로직 | O |
| JourneyLiveActivityCleanup | 순수 분기 | O |
| JourneyTimerController 옵저버 훅 | 상태 로직 | O |
| RecordingLiveActivityGateway | 테스트 더블(DEBUG) | 대상 아님 |
| ActivityKitLiveActivityGateway | 시스템 어댑터 | O (얇은 어댑터, 수동 확인) |
| 앱 배선 (Services/JourneyView/FocusMateApp/Bootstrap/RootView) | 화면 조립 | O (UI 스모크) |
| JourneyLiveActivityWidget, Bundle | 순수 표현 | 대상 아님 (빌드로만 판정, M-1~10) |
| pbxproj / Info 키 | 구성 | AC-29 |

### 컴포넌트별 테스트 전략

#### JourneyActivityDisplay (`ios/Shared`)
- 레이어: 순수 포맷터 / 러너: FocusMateTests. Shared는 앱 타깃에도 속하므로 `@testable import FocusMate`로 접근할 수 있습니다.
- 단위 테스트: 문자열 정확 일치 표를 씁니다. 상태 이름 3개, expiredText, pausedTime(3000/65/0/3600, 음수→0), 접근성 설명 4종을 확인합니다.
- 통합 테스트: 없음
- 모의 대상: 없음
- 격리 전략: enum static이라 픽스처가 필요 없습니다.
- AC 매핑: AC-26

#### JourneyActivityAttributes (`ios/Shared`)
- 레이어: 데이터 모델 / 러너: FocusMateTests
- 단위 테스트: Attributes와 ContentState 인스턴스를 만들고 `Mirror(reflecting:)`로 label을 구한 뒤 Set을 비교합니다. 기대값은 정확히 8개입니다. Optional 필드는 nil이어도 label이 나옵니다.
- 모의 대상: 없음
- AC 매핑: AC-30
- 주의: 설계서 안에서 AC-30의 담당이 어긋납니다. T1에는 "DisplayTests에서 AC-30(Mirror)"이라 적혀 있고, AC 매핑 표에는 "27·30·31 → PolicyTests"로 되어 있습니다. T1 시점에는 PolicyTests 파일이 없으므로 AC-30은 **JourneyActivityDisplayTests 한 곳**에 두도록 표를 고쳐야 합니다.

#### JourneyLiveActivityPolicy
- 레이어: 순수 규칙 / 러너: FocusMateTests
- 단위 테스트
  - progress: 0/1800/3600/4000/-1과 total≤0 경우를 확인합니다.
  - request: running이면 endDate=now+rem이고 stale=endDate입니다. paused이면 둘 다 nil이고 pausedRemaining=rem입니다. arrived이면 nil입니다.
  - appearPlan: 같은 id 1개면 재사용, 같은 id 2개면 재사용 1개와 end 1개, 다른 id면 end입니다.
  - launchEndIDs: nil·arrived면 전부 종료, 진행 중이면 빈 목록입니다.
  - attributes(for:): bus 또는 도착지가 nil이면 nil입니다.
- 모의 대상: 없음. `now: Date`는 인자로 받습니다.
- 격리 전략: enum static으로 된 표 기반 테스트입니다.
- AC 매핑: AC-27, AC-31, 그리고 AC-22 규칙의 단위 수준 보강

#### JourneyTimerController 옵저버 훅
- 레이어: 상태 로직 / 러너: FocusMateTests
- 단위 테스트: 기존 `JourneyTimerControllerTests`를 고치지 않고 그대로 돌립니다(회귀 확인).
- 통합 테스트: `JourneyTimerObserverParityTests`
  - observer가 있는 rig와 없는 rig 두 개를 같은 조작 순서로 진행합니다.
  - 매 단계 status, elapsed, remaining, `saver.writes`를 비교합니다.
- 모의 대상: 시계·티커(ManualJourneyClock), 저장(FakeProgressSaver), 낭독(RecordingAnnouncer), observer(호출만 기록하는 테스트 전용 더블. 설계서의 Recording 기록기와 Sync를 써도 됨)
- 격리 전략: init 기본값 매개변수로 주입합니다. observer는 컨트롤러로 재진입하지 않습니다.
- AC 매핑: AC-28

#### JourneyLiveActivitySync
- 레이어: 상태·데이터 로직 / 러너: FocusMateTests
- 통합 테스트(주된 검증): 실제 컨트롤러에 observer로 꽂고, ManualJourneyClock, FakeProgressSaver, RecordingLiveActivityGateway, `now = base + clock.now`를 붙입니다. 사용자 조작 순서 그대로 실행한 뒤 `recorder.entries`와 `count(_:)`를 판정합니다. 뷰 배선을 흉내 낼 필요는 없습니다.
- 단위 테스트(선택): 컨트롤러 없이 `timerDidChange`를 직접 호출해 SentKey 억제와 startFailed 고정을 확인합니다.
- 모의 대상: 게이트웨이(기록기), 벽시계(클로저), 저장(FakeProgressSaver)
- 격리 전략: Sync는 저장자와 타이머를 참조하지 않습니다. 게이트웨이와 now만 생성자로 주입하므로 BR-6이 구조적으로 보장됩니다.
- AC 매핑: AC-1~9, 11(화면 진입 절), 12~25

#### JourneyLiveActivityCleanup
- 레이어: 순수 분기 / 러너: FocusMateTests
- 단위 테스트: `RecordingLiveActivityGateway(existing:)`에 handle을 미리 넣고 `atLaunch(journey: nil / arrived / 진행 중)` 각각의 요청 횟수를 확인합니다.
- 모의 대상: 게이트웨이(기록기)
- AC 매핑: AC-10, AC-11(앱 시작 절)

#### ActivityKitLiveActivityGateway
- 레이어: 시스템 어댑터 / 러너: 없음(빌드만)
- 단위 테스트: 하지 않습니다. 시뮬레이터 권한과 시스템 상태에 의존해 결정적인 결과를 얻을 수 없습니다.
- 격리 전략: 프로토콜 뒤에 둔 얇은 어댑터입니다. 로직은 Policy와 Sync로 빼 두었습니다.
- 검증: M 항목(W14)
- 이 부분이 점수 1점 감점의 일부입니다. 다만 분기가 거의 없으므로 허용합니다.

#### 앱 배선 (JourneyServices / JourneyView.ensureTimer / FocusMateApp.start / UITestBootstrap / RootView)
- 레이어: 화면 조립 / 러너: FocusMateUITests
- 통합(E2E) 테스트: `JourneyLiveActivityUITests` 2건. 셀렉터는 프로젝트 규약인 accessibilityIdentifier `test.liveActivity`이고, 그 accessibilityValue JSON을 읽습니다. §4의 data-testid에 해당합니다.
- 모의 대상: 부트스트랩 모드에서는 항상 기록기를 쓰고, 수동 시계를 쓰면 wallNow를 고정합니다.
- 공백: `FocusMateApp.start`가 `.ready`일 때만 `atLaunch`를 부르는지(배선)는 자동으로 검증되지 않습니다. UI ②는 기록기가 비어 있어서 "호출 안 함"과 "호출했지만 대상 0"을 구분하지 못합니다. 함수 자체는 T6에서 보장되므로 잔여 위험(낮음)으로 기록합니다. 필요하면 부트스트랩이 기존 handle을 미리 넣는 시드를 하나 추가하는 방법이 있습니다(선택).
- AC 매핑: 보조 배선, AC-29 보호(실제 카드 0건)

#### JourneyLiveActivityWidget / FocusMateWidgetsBundle
- 레이어: 순수 표현 / 러너: 빌드만(FocusMateTests에서 위젯 모듈에 접근할 수 없음)
- 테스트하지 않습니다(§2 "대상 아님"). M-1~10으로 확인합니다.
- **권고(차단 아님)**: `JourneyActivityTimeText`에는 동작 분기가 들어 있습니다(stale → expiredText, running → `min(now,endDate)...endDate`, paused → 정적 문자열). 특히 `min` 하한 처리를 빠뜨리면 ClosedRange 트랩으로 **크래시**가 납니다.
  - 이 선택 로직을 `ios/Shared`의 순수 함수로 빼는 것을 권합니다. 예: `JourneyActivityDisplay.timeContent(status:endDate:pausedRemaining:isStale:now:) -> enum { expired, countdown(ClosedRange<Date>), paused(String) }`. 접근성 라벨 선택(stale이면 arrived 설명)도 같은 방식으로 뺄 수 있습니다.
  - 그러면 FocusMateTests에서 단위 테스트를 할 수 있고, 위젯은 순수 표현만 남습니다. AC가 없으므로 T9에 테스트 1~2건을 더하는 수준입니다.

#### pbxproj / Info 키
- 러너: FocusMateTests의 `AppInfoLiveActivityTests`(`AppInfoLocationTests.swift` 패턴, `Bundle.main.object(forInfoDictionaryKey: "NSSupportsLiveActivities") as? Bool == true`)와 `check-ios.py build`
- AC 매핑: AC-29

### Testability Score: 8/10

- 감점 1: 실제 ActivityKit 어댑터와 위젯의 시간 선택 로직이 자동 테스트 밖에 있습니다. 시간 선택 로직은 크래시 위험이 있는 분기입니다.
- 감점 1: 앱 시작 정리의 배선이 자동으로 검증되지 않습니다. 태스크 T4와 T7에 RED 수단이 없습니다(아래 참고).
- 가점 요인: 모든 외부 시스템이 `@MainActor protocol` 뒤에 있습니다. 시계와 벽시계가 주입되고, 동기 기록기를 쓰며, 비동기가 없습니다. Sync는 저장과 타이머에서 분리돼 있고, 실제 컨트롤러로 조작 순서 그대로 검증할 수 있습니다.

### 판정: PASS (설계 확정, red-green-refactor 진입 가능)

다음 보정은 재설계가 아니고 설계서 문서만 고치면 됩니다.
1. **AC-30 담당 일원화**: JourneyActivityDisplayTests 한 곳으로 정하고 AC 매핑 표를 고칩니다.
2. **T4는 RED가 없는 태스크**입니다. 기록기와 프로토콜은 T5a의 RED를 통과시키는 GREEN에 포함되므로 T4를 T5a에 합치는 것을 권합니다. 따로 두려면 기록기 자체 테스트(id 순번, end 시 active 제거, failsStart)를 소량 둡니다.
3. **T7(배선)도 단위 RED가 없습니다.** T10의 UI 테스트 ①이 T7의 RED입니다. UI ①②에는 위젯 타깃이 필요 없으므로, T10의 의존을 T8에서 떼어 **T7과 T10을 한 사이클로 합치는 것**을 권합니다. 이렇게 하면 위젯 pbxproj 위험(R-1, R-2)과 배선 검증이 분리됩니다.
4. (선택) 위젯 시간 선택 로직을 Shared 순수 함수로 빼고 T9에 단위 테스트를 둡니다.

---

### red-writer가 알아야 할 픽스처 주의점

**시계와 벽시계**
- `now` 파생: `let base = Date(timeIntervalSince1970: 1_791_882_000)`, `now: { base.addingTimeInterval(Double(clock.now.components.seconds)) }`
  - 시계는 **정수 초로만** 진행합니다. 그래야 Double 연산이 정확해 endDate를 `XCTAssertEqual`로 바로 비교할 수 있습니다.
  - 기대값은 같은 방식으로 계산합니다. 예: `base + t2 + 3000`
- **ManualJourneyClock의 tick 구독자는 하나뿐**입니다(`start`가 구독을 교체). AC-28 parity의 두 컨트롤러에는 **시계와 저장자를 각각 따로** 주고, 같은 순서로 나란히 진행합니다.
- `advance(by:notify: true)`는 tick을 일으킵니다. 실행 중이면 체크포인트 저장이나 도착이 함께 일어날 수 있습니다. 시간만 흘려야 하면 `notify: false`를 씁니다. 백그라운드 경과는 `notify: false` + `returnToForeground()`나 `armForegroundAdvance` + `applyArmedForegroundAdvance()`로 재현합니다(AC-23).
- AC-12 "시계 현재 T4": `appear` 전에 `advance(notify: false)`로 T4≠base를 만듭니다. 기대 endDate는 `appear` 뒤에 읽은 `now + controller.remainingSeconds`입니다.

**알림 시점 (컨트롤러 코드에서 확인)**
- 알림은 `appear`, `halt`, `resume`, `arrive`에서만 나갑니다. **`controller.appear()`를 부르기 전에는 Sync가 아무것도 받지 않습니다.** 기존 Rig의 `running()`/`pausedRig()`처럼 appear 뒤에 횟수를 셉니다.
- `leave()`가 running일 때는 `halt()`(알림)가 **save보다 먼저** 일어납니다. AC-24에서 update가 나가는지는 저장 결과와 상관이 없습니다.
- `pause`와 `resume`은 저장 guard를 먼저 거칩니다. 실패하면 알림이 없습니다(AC-5).
- FakeProgressSaver의 `results`는 **체크포인트를 포함한 모든 save 호출 순서대로** 소비됩니다.
  - AC-20: `results: [false]` 상태에서 `advance(by: .seconds(120))`를 1회 하면 첫 체크포인트 저장이 실패하고 정지합니다. 기대값은 remaining 3480, progress 120/3600입니다.
  - 중간 단계를 나누면 소비 순서를 다시 계산해야 합니다.
- AC-16 "모든 요청 실패": `failsStart = true`이면 이후 update/end가 나가지 않아 사실상 AC-17과 같은 경로가 됩니다. update 경로도 확인하려면 `failsStart = false, failsUpdates = true` 변형을 하나 더 둡니다. 비교 대상인 "성공 시" rig는 별도로 만듭니다.

**기록기 위치와 더블**
- `RecordingLiveActivityGateway`는 **앱 타깃 `#if DEBUG`**에 있습니다. FocusMateTests에 같은 이름의 더블을 만들지 말고(이름 충돌) `@testable import FocusMate`로 씁니다.
- 기존 handle id는 `"old-1"`처럼 **"activity-N"과 겹치지 않게** 정합니다. 기록기 start는 "activity-1"부터 번호를 매깁니다.
- AC-14·15의 "최종 활성 1개"는 `recorder.activeActivities`로 판정합니다. 기록기는 end할 때 제거하고 start할 때 추가해야 합니다.
- `JourneyActivityAttributes`는 Equatable이 아닐 수 있습니다. Entry의 attributes는 **필드별로 assert**합니다(busNumber, busKind, destinationName, journeyID).
- Sync는 `init?`이므로 `try XCTUnwrap`을 씁니다. 컨트롤러만 Sync를 강하게 잡으므로 rig에는 **컨트롤러를 보관**합니다.

**여정 픽스처**
- `BoardingFixtures.journey(minutes: 60, busID: "421", phase: .departed, elapsedSeconds:, paused:)`를 씁니다. 기본 busID "2014"를 쓰면 AC의 "343 간선"이 나오지 않으므로 **busID "421"이 필수**입니다.
- AC-31: 계산 도착지와 다른 `destinationStopID`를 넣습니다. `CourseJourney(journey:) == nil`을 먼저 확인하고, `attributes.destinationName == journey.destinationName`(카탈로그 이름)을 판정합니다. 카탈로그에 "서울역"은 없습니다.
- AC-26만 문구 함수에 "서울역"을 직접 넣습니다.

**비동기와 격리**
- 비동기는 없습니다. 테스트 클래스는 `@MainActor final class ... : XCTestCase`이고, `expectation`이나 `await`가 필요 없습니다. 실제 게이트웨이의 `Task`는 테스트 경로에 없습니다.
- 단위 테스트 호스트 앱이 실행되면서 실제 게이트웨이로 `atLaunch`가 돌지만 무해합니다. 테스트가 `Activity.activities`에 의존하지 않게 합니다.

**규약**
- 메서드 이름은 `testV15_AC<n>_<한국어>` 형식이고, 위에 `// 깨짐:` 주석을 둡니다.
- UI 테스트는 `test.liveActivity`의 accessibilityValue JSON만 판정합니다. 위젯 외형은 assert하지 않습니다(§3).
- UI ① 기대값: 시드 `timerPaused90`은 25분(1500초)에 경과 90초입니다. start paused rem 1410 → resume update running endDate=epoch+1410 → advance60 후 추가 요청 0 → pause update paused rem 1350.

### 태스크별 focused 테스트 파일

러너는 `python3 scripts/check-ios.py test <파일>`입니다.

| 태스크 | focused 파일 |
|---|---|
| T1 공유 모델·문구 | `ios/FocusMateTests/JourneyActivityDisplayTests.swift` (AC-26, AC-30) |
| T2 옵저버 훅 | `ios/FocusMateTests/JourneyTimerObserverParityTests.swift` + `ios/FocusMateTests/JourneyTimerControllerTests.swift`(무수정 회귀) |
| T3 정책 | `ios/FocusMateTests/JourneyLiveActivityPolicyTests.swift` |
| T4 게이트웨이·기록기 | T5a에 합치는 것을 권고. 따로 두면 자체 소량 테스트 필요 |
| T5a~T5d 동기화 | `ios/FocusMateTests/JourneyLiveActivitySyncTests.swift` |
| T6 시작 정리 | `ios/FocusMateTests/JourneyLiveActivityCleanupTests.swift` |
| T7 앱 배선 | `ios/FocusMateUITests/JourneyLiveActivityUITests.swift` (T10과 합치는 것을 권고) |
| T8 위젯 타깃·구성 | `ios/FocusMateTests/AppInfoLiveActivityTests.swift` + `check-ios.py build` |
| T9 위젯 UI | `check-ios.py build` (Shared 추출 시 `JourneyActivityDisplayTests.swift`에 추가) |
| T10 배선 UI | `ios/FocusMateUITests/JourneyLiveActivityUITests.swift` |
| T11 전체 | `check-ios.py test` 1회 |

### 탐색 추가 항목
- `ios/FocusMate/JourneyClock.swift:62-85`: ManualJourneyClock의 단일 tick 구독, `advance(notify:)`, 백그라운드 경과 재현 API
- `ios/FocusMate/JourneyTimerController.swift:124-134`: running에서 leave하면 halt(알림)가 save보다 먼저
- `ios/FocusMateTests/BoardingTestDoubles.swift:24-43`: `BoardingFixtures.journey` 매개변수(busID 기본값 "2014")
- `ios/FocusMateTests/JourneyTimerControllerTests.swift:12-57`: Rig, `running()`/`pausedRig()`, `assertWrites` 패턴
- `ios/FocusMate/JourneySnapshot.swift:55-56, 74-75`: totalSeconds, isArrived, destinationName(카탈로그), bus
- `ios/FocusMate/RouteData.swift:86`: `BusLine(id: "421", number: "343", kind: "간선")`
- `ios/FocusMate/UITestBootstrap.swift:229-247, 271-282`: 수동 시계 주입, timerSeeds(25분, seed-timer)
- `ios/FocusMate/JourneyView.swift:34-43`: `guard timer == nil`이므로 Sync는 화면 세션당 1회 생성
- `ios/FocusMateTests/AppInfoLocationTests.swift`: Info 키 테스트 패턴