## 설계 초안: W06 MapKit 가상 코스 (여행 화면 지도)

### 설계 규모
대형. 신규 순수 로직 3개(코스 데이터, 진도→위치, 지도 상태 머신)와 MapKit 뷰를 새로 만들고, W05 타이머 화면 배치를 바꾸고, AC 40건(단위·UI·수동)을 다룹니다.

### 배경 및 목적
- 지금 여행 화면은 검은 배경 위에 남은 시간("N min")과 일시정지/재개만 있습니다(`ios/FocusMate/JourneyTimerView.swift:18-37`). 정류장은 id와 이름만 있고 좌표가 없습니다(`ios/FocusMate/RouteData.swift:10-21`).
- 목표:
  - 배경을 Apple 지도로 바꿉니다.
  - 가상 순환 코스 위에서 버스가 W05 진도에 맞춰 움직이게 합니다.
  - 따라가기/자유 탐색, 지도 테마 시트, 하단 정보 3종(남은 시간·정류장·거리)을 넣습니다.
  - 지도 조작이 진도와 저장에 영향을 주지 않게 합니다.

### 요구사항 및 수용 기준
PRD 원문은 `.dev/feat-mapkit-virtual-course/prd.md`에 있습니다(FR-1~17, BR-1~8, QE-1~3, AC-1~40, M-1~7).
- [Must] FR-1~15, BR-1~8
- [Should] FR-16 / AC-40, QE-1~3
- [Could] FR-17(따라가기 중 진행 방향이 위로 오도록 회전)

---

### 변경 범위

**영향 모듈**: 여행 화면(`JourneyView`/`JourneyTimerView`), 경로 데이터(`RouteData`), DEBUG UI 테스트 장치(`UITestBootstrap`, `JourneyServices`, `UITestLaunchSupport`). 저장 계층(`AppModel`, `SnapshotCodec`)은 바꾸지 않습니다.

**신규 파일 (앱)**

| 파일 | 책임 | import |
|---|---|---|
| `ios/FocusMate/JourneyCourse.swift` | 9개 정류장 좌표(`CoursePoint`), 닫힌 코스 선 | Foundation |
| `ios/FocusMate/JourneyCourseProgress.swift` | 진도 → 버스 위치, heading, 다음 정류장, 남은 정류장, 남은 거리 (BR-2, BR-7) | Foundation |
| `ios/FocusMate/JourneyMapState.swift` | 지도 상태 머신(값 타입), 카메라 정책(`JourneyCameraPolicy`), 렌더 모델(`JourneyMapRenderModel`) | Foundation |
| `ios/FocusMate/JourneyMapController.swift` | `@Observable` 연결부. 타이머 상태와 경과를 받아 상태·위치·카메라 목표를 갱신 | Foundation, Observation |
| `ios/FocusMate/JourneyMapDisplay.swift` | 지도·하단 정보 문구와 접근성 값(BR-8) | Foundation |
| `ios/FocusMate/JourneyMapView.swift` | SwiftUI `Map`, 코스 선·정류장·버스·도착 표시, 사용자 제스처 감지 | SwiftUI, MapKit |
| `ios/FocusMate/JourneyMapThemeSheet.swift` | 지도 테마 시트(어두운 지도/위성/정류장 표시) | SwiftUI |

**신규 파일 (테스트)**

| 파일 | 대상 |
|---|---|
| `ios/FocusMateTests/JourneyCourseTests.swift` | AC-5 |
| `ios/FocusMateTests/JourneyCourseProgressTests.swift` | AC-6~9, AC-39 계산 |
| `ios/FocusMateTests/JourneyMapStateTests.swift` | AC-13~25 전이, AC-30~32 |
| `ios/FocusMateTests/JourneyMapControllerTests.swift` | AC-10~12, AC-22·24 연동, AC-27·28 구조 |
| `ios/FocusMateTests/AppInfoLocationTests.swift` | AC-29 |
| `ios/FocusMateUITests/JourneyMapUITests.swift` | AC-1·2·4, 13~28, 38 보조, 40 |
| `ios/FocusMateUITests/JourneyMapAccessibilityUITests.swift` | AC-3, 30~37 |

**수정 파일**

| 파일 | 변경 |
|---|---|
| `ios/FocusMate/JourneyTimerView.swift` | 배경을 지도로, 배치 변경, 하단 정보 3종, 도구 버튼과 시트, `test.map` 진단 |
| `ios/FocusMate/JourneyView.swift` | `JourneyMapController` 생성·전달, 이탈 시 `leave()`, DEBUG 테스트 버튼 추가 |
| `ios/FocusMate/JourneyServices.swift` | DEBUG `blankMap` 플래그(FR-16 대체 검증용) |
| `ios/FocusMate/UITestBootstrap.swift` | `--fm-ui-map blank` 인자 파싱, 서비스 주입 |
| `ios/FocusMateUITests/UITestLaunchSupport.swift` | `mapDiagnostic()`, `dragMap()`, `frame(_:)` 도우미 |

Xcode 프로젝트는 동기화 폴더라 pbxproj는 수정하지 않습니다. MapKit은 `import MapKit`의 자동 링크로 연결됩니다(`project.pbxproj:54`에 `CLANG_ENABLE_MODULES = YES`). Info.plist는 `GENERATE_INFOPLIST_FILE = YES`이고 위치 키가 없으며(`project.pbxproj:56-57`), 이 상태를 유지합니다.

### 적용 컨벤션
- 프로젝트 루트에 CLAUDE.md/컨벤션 파일은 없습니다(`.claude/config.json`만 있음). 기존 코드에서 학습한 규칙을 따릅니다.
- **네이밍**
  - 타입은 `Journey*` 접두어(`JourneyTimerController`, `JourneyTimerDisplay`)를 씁니다.
  - 문구·표기 규칙은 `enum XxxDisplay`의 static 멤버로 둡니다(`JourneyTimerDisplay.swift:4-22`).
  - 접근성 식별자는 `journey.<영역>.<요소>`, DEBUG 진단은 `test.<영역>`입니다.
- **구조**
  - `@MainActor @Observable final class` 컨트롤러가 `private(set)` 상태를 가집니다. 외부 의존성은 생성자 주입이고, 저장하지 않을 상태는 `@ObservationIgnored`로 둡니다(`JourneyTimerController.swift:7-31`).
  - View는 얇게 둡니다(컨트롤러 메서드 호출과 표시만).
  - 순수 규칙은 `enum` 네임스페이스의 static 함수입니다(`JourneyPlanner`, `RouteStops`).
- **DEBUG 진단**: `JSONSerialization` + `.sortedKeys`로 만든 문자열을 1pt 투명 `Text`의 `accessibilityValue`에 넣습니다(`JourneyTimerView.swift:95-108`).
- **테스트**
  - XCTest 클래스 이름과 파일 stem이 같습니다.
  - 메서드 이름은 `test<번호>_AC<n>_<한국어 설명>` 형식이고, 위에 `// 깨짐:` 주석을 둡니다(`JourneyTimerUITests.swift:31-46`).
  - UI 테스트는 `FocusMateUIHarness.launchJourney(seed:)`와 수동 시계를 씁니다.

---

### 상세 설계

#### 1. `ios/FocusMate/JourneyCourse.swift` — 가상 코스 데이터 (신규, AC-5, BR-1)
- **현재**: `RouteStops.all`에 `(id, name)` 9개만 있고 좌표가 없습니다(`RouteData.swift:11-21`).
- **변경**
  - `RouteStops`는 건드리지 않습니다. 좌표는 별도 테이블에 **id 기준**으로 둡니다.
  - `JourneyCourse.stops`는 `RouteStops.all`을 순서대로 돌면서 id로 좌표를 찾아 만듭니다. 순서와 id가 `RouteStops`와 같다는 것이 구조로 보장됩니다.
  - 좌표 표에 없는 id는 `preconditionFailure`로 막습니다. 단위 테스트가 항상 이 경로를 실행합니다.
  - CoreLocation 타입을 쓰지 않고 자체 `CoursePoint`를 둡니다. 순수 로직과 테스트가 MapKit·CoreLocation 없이 돌아가게 하기 위해서입니다. `CLLocationCoordinate2D` 변환은 뷰 파일의 extension에서만 합니다.
- **시그니처**
  ```swift
  struct CoursePoint: Equatable, Hashable { let latitude: Double; let longitude: Double }
  struct CourseStop: Equatable { let index: Int; let id: String; let name: String; let point: CoursePoint }
  enum JourneyCourse {
      static let stops: [CourseStop]                    // 9개, RouteStops.all 순서
      static func point(at index: Int) -> CoursePoint   // RouteStops.wrap 적용
      static var closedPath: [CoursePoint]              // stops + stops[0] (10개 점, 9개 선분)
      static func index(ofStopID id: String) -> Int?
  }
  ```
- **좌표 초안**: 확정값은 "확인이 필요한 사항" 1번에서 정합니다. 테스트는 범위와 서로 다름만 판정합니다.

  | # | id | 이름 | lat | lon | 비고 |
  |---|---|---|---|---|---|
  | 0 | seongsu | 성수역 | 37.5446 | 127.0559 | 실제 위치 근처 |
  | 1 | seongsuDong | 성수동 | 37.5470 | 127.0520 | 생활권 중심 근사 |
  | 2 | ttukseom | 뚝섬역 | 37.5474 | 127.0474 | 실제 위치 근처 |
  | 3 | seongdongSportsCenter | 성동구민체육센터 | 37.5495 | 127.0425 | 실제 위치 미확인 |
  | 4 | seoulForest | 서울숲역 | 37.5437 | 127.0447 | 실제 위치 근처 |
  | 5 | seoulForestGate | 서울숲 입구 | 37.5430 | 127.0380 | 실제 위치 근처 |
  | 6 | seongsuBridgeNorth | 성수대교 북단 | 37.5395 | 127.0345 | 실제 위치 근처 |
  | 7 | ttukseomHangangPark | 뚝섬한강공원 | 37.5335 | 127.0520 | **실제(경도 약 127.067)가 범위 밖이라 범위 안으로 당긴 점** |
  | 8 | seongsuIntersection | 성수사거리 | 37.5400 | 127.0565 | 근사 |
- **고려사항**: 정류장 간격은 지리적으로 고르지 않습니다. 따라서 구간마다 화면상 버스 속도가 다릅니다(BR-2의 "구간별 일정 비율 보간"은 따릅니다). 남은 거리는 기하 거리가 아니라 `0.55km × 정류장 수`입니다(BR-7).

#### 2. `ios/FocusMate/JourneyCourseProgress.swift` — 진도 → 버스 위치 (신규, BR-2, BR-7, AC-6~11, 39)
- **현재**
  - 도착지는 `RouteStops.wrap(origin.index + origin.direction * stops)`으로 계산합니다(`JourneyPlanner.swift:28-30`, `JourneySnapshot.swift:42`).
  - 진도는 `JourneyTimerController.elapsedSeconds`(정수 초, `JourneyTimerController.swift:12, 187`)입니다.
- **변경**
  - `CourseJourney`는 `JourneySnapshot`에서 originStopID, direction, minutes, bus를 뽑은 순수 입력입니다. 카탈로그에 없는 값이면 `nil`입니다(`validate`가 이미 보장하지만 방어합니다).
  - **정수 산술로 정확도를 지킵니다.**
    - `secondsPerStop = minutesPerStop × 60`
    - `k = elapsed / secondsPerStop`, `r = elapsed % secondsPerStop`, `fraction = Double(r) / Double(secondsPerStop)`
    - 예: 12분 30초(750초) ÷ 300초 → k=2, fraction=0.5가 정확히 나옵니다.
  - **도착 판정**: `elapsed`를 `[0, totalSeconds]`로 자르고, `k >= totalStops`이면 도착 정류장에 고정합니다(AC-8, AC-11).
  - **보간**: `from = wrap(origin + dir·k)`, `to = wrap(origin + dir·(k+1))`이고 위경도를 선형 보간합니다.
  - **heading**
    - 국지 평면 근사입니다: `dx = Δlon·cos(평균 위도)`, `dy = Δlat`, `atan2(dx, dy)`를 도 단위 `[0, 360)`로 바꿉니다.
    - 같은 선분을 반대로 가면 정확히 180° 차이가 납니다(AC-7을 판정할 수 있음). 대권 초기 방위각은 두 방향이 정확히 반대가 아니라서 쓰지 않습니다.
    - 경과 0이면 첫 구간, 정류장 경계에서는 다음 구간, 도착이면 마지막 구간의 heading을 씁니다.
  - **다음 정류장**: `wrap(origin + dir·min(total, k+1))`입니다(웹 `draw()` 783행의 nextIndex와 같음). 도착이면 도착 정류장입니다.
  - **남은 정류장**: `totalStops − min(totalStops, k)`(BR-7)입니다.
  - **남은 거리**
    - 0.01km 정수(`JourneyPlanner.hundredthsKmPerStop = 55`와 같은 단위)로 계산합니다: `numerator = totalStops × 55 × (totalSeconds − elapsed)`.
    - 소수 첫째 자리는 정수 반올림(half-up)으로 구합니다: `tenths = (2·numerator + 10·total) / (20·total)`. 웹 `toFixed(1)`과 같은 결과를 냅니다.
- **시그니처**
  ```swift
  struct CourseJourney: Equatable {
      let originIndex: Int; let direction: Int; let minutesPerStop: Int; let totalMinutes: Int
      var totalStops: Int { get }          // totalMinutes / minutesPerStop
      var totalSeconds: Int { get }
      var destinationIndex: Int { get }    // RouteStops.wrap(originIndex + direction * totalStops)
      init(originIndex: Int, direction: Int, minutesPerStop: Int, totalMinutes: Int)
      init?(journey: JourneySnapshot)
  }
  struct CourseBusPosition: Equatable {
      let point: CoursePoint; let headingDegrees: Double
      let segmentFrom: Int; let segmentTo: Int; let fraction: Double   // 정류장 위면 fraction == 0
      let travelledStops: Double; let isArrived: Bool
  }
  enum JourneyCourseProgress {
      static func position(of journey: CourseJourney, elapsedSeconds: Int) -> CourseBusPosition
      static func nextStopIndex(of journey: CourseJourney, elapsedSeconds: Int) -> Int
      static func remainingStops(of journey: CourseJourney, elapsedSeconds: Int) -> Int
      static func remainingDistanceTenthsKm(of journey: CourseJourney, elapsedSeconds: Int) -> Int
  }
  ```
- **고려사항**
  - `minutes`가 `minutesPerStop`으로 나누어떨어지지 않는 손상 데이터라면 `totalStops`를 내림합니다. 도착 위치는 `destinationIndex`(계산값)입니다. 정상 데이터에서는 `JourneySnapshot.destinationStopID`와 같습니다(`JourneySnapshot.swift:42`).
  - 일시정지 중에는 `elapsedSeconds`가 바뀌지 않으므로 위치도 바뀌지 않습니다. 순수 함수라 따로 처리할 것이 없습니다(AC-10).

#### 3. `ios/FocusMate/JourneyMapState.swift` — 지도 상태 머신·카메라 정책·렌더 모델 (신규, BR-3~5, FR-8·9·11, AC-13~25, 30~32)
- **현재**: 해당 상태가 없습니다. 웹은 전역 변수(`following`, `mapMode`, `mapStops`, 816행)와 토글(`followMap.onclick`, 844행)로 처리합니다.
- **변경 — `JourneyMapState`(값 타입, `Equatable`)**
  - 초기값은 `follow`, `dark`, 정류장 표시 켜짐, 시트 닫힘입니다. `toolsEnabled`는 `status != .paused`에서 파생합니다(BR-4).
  - `userMovedCamera()`: 상태와 관계없이 `explore`가 됩니다. 일시정지 중 조작도 허용합니다(BR-3).
  - `followTapped()`: 도구가 비활성이면 무시합니다. 아니면 `follow`가 됩니다. 이미 `follow`여도 `follow`를 유지합니다(AC-16). 반환값 `Bool`은 "카메라를 다시 맞춰야 함" 신호입니다.
  - `openThemeSheet()`: 도구가 비활성이면 무시합니다(AC-25).
  - `dismissThemeSheet()`, `select(theme:)`, `setShowsStops(_:)`는 상태만 바꿉니다.
  - `timerStatusChanged(_:)`
    - `.paused` 또는 `.arrived`로 바뀌면 시트를 닫습니다(BR-5).
    - 카메라 모드는 바꾸지 않습니다(BR-3, AC-18).
  - `leave()`: 시트를 닫습니다(AC-23).
  - 동작 줄이기는 이 상태에 들어가지 않습니다. 그래서 상태 전이 결과가 동작 줄이기와 무관하다는 것(AC-32)이 구조로 보장됩니다.
- **변경 — `JourneyCameraPolicy`(순수)**
  - 입력은 버스 위치, 동작 줄이기, 회전 허용 여부입니다. 출력은 `JourneyCameraTarget`입니다.
  - pitch는 0보다 큰 고정값(초안 55°, 디자인 스펙에서 조정)입니다. 거리는 고정값(초안 1200m)입니다.
  - heading은 동작 줄이기면 0, 아니면 `rotatesWithBus` 여부에 따라 버스 heading 또는 0입니다. FR-17(Could) 전까지 `rotatesWithBus = false`입니다.
  - `animated = !reduceMotion`입니다(AC-30, 31).
- **변경 — `JourneyMapRenderModel`(순수)**
  - 뷰가 그리는 것과 진단이 보고하는 것을 한 곳에서 만듭니다.
  - 구성: 코스 선 점 10개, 정류장 표시(켜짐이면 9개, 꺼짐이면 0개), 버스(항상), 도착 표시(항상, 도착 정류장 좌표).
  - 이것으로 AC-12와 AC-21의 "코스 선·버스·도착 표시는 존재"를 진단으로 판정할 수 있습니다. 실제 픽셀은 M-7입니다.
- **시그니처**
  ```swift
  enum JourneyCameraMode: String { case follow, explore }
  enum JourneyMapTheme: String { case dark, satellite }
  struct JourneyMapState: Equatable {
      private(set) var camera: JourneyCameraMode = .follow
      private(set) var theme: JourneyMapTheme = .dark
      private(set) var showsStops = true
      private(set) var isThemeSheetPresented = false
      private(set) var status: JourneyTimerController.Status
      var toolsEnabled: Bool { get }
      init(status: JourneyTimerController.Status)
      mutating func userMovedCamera()
      @discardableResult mutating func followTapped() -> Bool
      mutating func openThemeSheet()
      mutating func dismissThemeSheet()
      mutating func select(theme: JourneyMapTheme)
      mutating func setShowsStops(_ on: Bool)
      mutating func timerStatusChanged(_ status: JourneyTimerController.Status)
      mutating func leave()
  }
  struct JourneyCameraTarget: Equatable {
      let center: CoursePoint; let headingDegrees: Double; let pitchDegrees: Double
      let distanceMeters: Double; let animated: Bool; let revision: Int
  }
  enum JourneyCameraPolicy {
      static let pitchDegrees: Double; static let distanceMeters: Double
      static func target(for bus: CourseBusPosition, reduceMotion: Bool, rotatesWithBus: Bool, revision: Int) -> JourneyCameraTarget
  }
  struct JourneyMapRenderModel: Equatable {
      let route: [CoursePoint]; let stopMarkers: [CourseStop]; let bus: CourseBusPosition; let destination: CourseStop
      init(journey: CourseJourney, bus: CourseBusPosition, showsStops: Bool)
  }
  ```

#### 4. `ios/FocusMate/JourneyMapController.swift` — `@Observable` 연결부 (신규)
- **현재**: 해당 없음. 비슷한 구조는 `DepartureBriefingController`와 `JourneyTimerController`입니다.
- **변경**
  - 상태 머신, 위치 계산, 카메라 정책을 묶습니다. 뷰는 이 컨트롤러만 봅니다.
  - **저장자나 타이머 의존성을 갖지 않습니다.** 생성자에 `JourneyProgressSaving`이 없으므로 지도 때문에 저장이 일어날 경로가 아예 없습니다(BR-6, AC-28 구조 보장).
  - `sync(status:elapsedSeconds:)`
    - 뷰가 타이머 값이 바뀔 때마다 부릅니다.
    - 위치와 렌더 모델을 다시 계산하고 `state.timerStatusChanged`를 반영합니다.
    - `follow`일 때만 `cameraTarget`을 새로 만듭니다(`revision` +1). `explore`면 `cameraTarget`을 그대로 둡니다(AC-17).
  - `followTapped()`가 `true`를 돌려주면 즉시 새 `cameraTarget`을 만듭니다. 중심은 현재 버스 위치입니다(AC-15).
  - `setReduceMotion(_:)`: 이후 카메라 목표의 `animated`와 heading에 반영합니다. `follow`이면 즉시 다시 냅니다.
  - 테스트 가능성: 순수 값만 받으므로 단위 테스트에 더블이 필요 없습니다. 실제 `JourneyTimerController`와 묶은 연동 테스트는 기존 `FakeProgressSaver`, `ManualJourneyClock`(`JourneyTimerTestDoubles.swift:7-19`, `JourneyClock.swift:62-85`)으로 할 수 있습니다.
- **시그니처**
  ```swift
  @MainActor @Observable
  final class JourneyMapController {
      private(set) var state: JourneyMapState
      private(set) var bus: CourseBusPosition
      private(set) var render: JourneyMapRenderModel
      private(set) var cameraTarget: JourneyCameraTarget
      private(set) var nextStopIndex: Int
      private(set) var remainingStops: Int
      private(set) var remainingDistanceTenthsKm: Int
      @ObservationIgnored let journey: CourseJourney
      init(journey: CourseJourney, status: JourneyTimerController.Status, elapsedSeconds: Int, reduceMotion: Bool)
      convenience init?(snapshot: JourneySnapshot, status: JourneyTimerController.Status, elapsedSeconds: Int, reduceMotion: Bool)
      func sync(status: JourneyTimerController.Status, elapsedSeconds: Int)
      func setReduceMotion(_ on: Bool)
      func userMovedCamera()
      func followTapped()
      func openThemeSheet()
      func dismissThemeSheet()
      func select(theme: JourneyMapTheme)
      func setShowsStops(_ on: Bool)
      func leave()
  }
  ```

#### 5. `ios/FocusMate/JourneyMapDisplay.swift` — 문구 (신규, BR-8, FR-12·15)
- **시그니처**
  ```swift
  enum JourneyMapDisplay {
      static let mapLabel = "가상 코스 지도"
      static func mapValue(next: String, destination: String) -> String   // "다음 정류장 X, 도착 정류장 Y"
      static let followLabel = "버스 따라가기"
      static func followValue(_ mode: JourneyCameraMode) -> String        // "따라가는 중" / "자유 탐색 중"
      static let themeLabel = "지도 테마"
      static let darkLabel = "어두운 지도"; static let satelliteLabel = "위성"; static let stopsLabel = "정류장 표시"
      static func selectedValue(_ on: Bool) -> String                     // "선택됨" / "선택 안 됨"
      static func switchValue(_ on: Bool) -> String                       // "켜짐" / "꺼짐"
      static let remainingStopsLabel = "남은 정류장"; static let remainingDistanceLabel = "남은 거리"
      static func stopsText(_ n: Int) -> String                           // "N"
      static func stopsAccessibilityValue(_ n: Int) -> String             // "N개"
      static func distanceText(tenthsKm: Int) -> String                   // "2.8" (도착 "0.0")
      static func distanceAccessibilityValue(tenthsKm: Int) -> String     // "2.8km"
  }
  ```
- 남은 시간의 라벨 "타이머"와 값 "남은 시간 N분"은 `JourneyTimerDisplay`를 그대로 씁니다(W05 테스트 `JourneyTimerAccessibilityUITests.swift:20-21` 유지).
- 지도 조작에는 낭독(announce)을 넣지 않습니다. W05의 "일시정지됨/재개됨 1회" 단언(`JourneyTimerAccessibilityUITests.swift:47, 55`)이 흔들리지 않게 하려는 것입니다. 상태는 접근성 값으로 전달합니다.

#### 6. `ios/FocusMate/JourneyMapView.swift` — SwiftUI MapKit 뷰 (신규, FR-1~4·8·11·14·17)
- **변경 (iOS 17 API)**
  - **지도와 상호작용**
    - `Map(position: $position, interactionModes: [.pan, .zoom, .rotate]) { … }`. `.pitch`를 빼서 사용자가 2D로 바꿀 입력 경로를 없앱니다(FR-8, AC-13). 회전은 FR-4에 따라 허용합니다.
    - `position`은 뷰의 `@State var position: MapCameraPosition`입니다. 초기값은 `.camera(MapCamera(centerCoordinate:distance:heading:pitch:))`로 컨트롤러의 `cameraTarget`에서 만듭니다. 처음 진입할 때 날아드는 애니메이션은 없습니다.
  - **카메라 목표 적용**
    - `.onChange(of: map.cameraTarget)`에서 `target.animated`면 `withAnimation(.easeInOut(duration:)) { position = .camera(...) }`, 아니면 그냥 대입합니다.
    - 앱이 대입한 position은 `positionedByUser == false`입니다.
  - **사용자 제스처 감지**
    - `.onChange(of: position) { _, new in if new.positionedByUser { map.userMovedCamera() } }`.
    - `MapCameraPosition.positionedByUser`는 iOS 17 공식 API입니다(사용자가 지도를 움직이면 바인딩이 `positionedByUser == true`인 값으로 바뀜). 그래서 앱이 따라가며 옮기는 갱신은 `explore`를 만들지 않습니다(AC-14 후반).
    - **불확실한 점**: `MapCameraPosition`이 `Equatable`인지는 구현 첫 컴파일에서 확인해야 합니다. 안 되면 `.onMapCameraChange` 대신 `Binding(get:set:)`의 setter에서 `positionedByUser`를 검사하는 방식으로 바꿉니다. 이 방식은 Equatable이 필요 없습니다.
    - `.onMapCameraChange(frequency:)`의 `MapCameraUpdateContext`에는 사용자/프로그램 구분 필드가 **없으므로** 감지 수단으로 쓰지 않습니다.
  - **지도 내용**
    - `MapPolyline(coordinates: render.route.map(\.coordinate)).stroke(…, lineWidth: …)`.
    - 정류장은 `ForEach(render.stopMarkers) { Annotation("", coordinate:) { Circle() } }`이고 `.annotationTitles(.hidden)`을 씁니다.
    - 도착 표시와 버스는 `Annotation`입니다. 버스 아이콘 회전 = `bus.headingDegrees − renderedHeading`입니다. `renderedHeading`은 `.onMapCameraChange(frequency: .continuous) { ctx in ctx.camera.heading }`로 뷰 로컬 `@State`에 둡니다.
  - **스타일**
    - 어두운 지도는 `.mapStyle(.standard(elevation: .realistic))`에 지도에만 `.environment(\.colorScheme, .dark)`를 줍니다. 위성은 `.mapStyle(.imagery(elevation: .realistic))`입니다(위성 라벨 여부는 "확인이 필요한 사항" 2번).
    - 실제로 어둡게 보이는지는 M-5에서 확인합니다.
  - **컨트롤 숨김**
    - `.mapControls { MapCompass().mapControlVisibility(.hidden); MapPitchToggle().mapControlVisibility(.hidden); MapScaleView().mapControlVisibility(.hidden) }`. `MapUserLocationButton`은 넣지 않습니다(AC-4, FR-14).
    - 빈 `.mapControls {}`만으로 기본 나침반이 사라지는지는 문서가 분명하지 않습니다. 그래서 명시적으로 `.hidden`을 지정합니다.
  - **위치 권한·사용자 위치**: `UserAnnotation`, `CLLocationManager`를 쓰지 않습니다(AC-29).
  - **접근성**
    - 지도 전체를 `.accessibilityElement(children: .ignore)`로 묶습니다. 라벨은 `JourneyMapDisplay.mapLabel`, 값은 `mapValue(...)`, 식별자는 `"journey.map"`입니다. 개별 표시는 노출되지 않습니다(AC-33).
    - 부작용: MapKit 법적 표기도 접근성 트리에서 빠질 수 있습니다. 이 경우 AC-3은 M-1로 대체합니다(PRD 허용).
  - **FR-16 대체 렌더(DEBUG)**: `services.blankMap == true`이면 `Map` 대신 단색 배경에 같은 식별자와 같은 렌더 모델 진단을 둡니다. 타이머, 도구, 하단 정보가 지도 로딩과 무관하다는 것을 UI 테스트로 확인하기 위해서입니다.
- **시그니처**
  ```swift
  @MainActor struct JourneyMapView: View {
      let map: JourneyMapController
      let blank: Bool          // DEBUG에서만 true 가능
      var body: some View
  }
  extension CoursePoint { var coordinate: CLLocationCoordinate2D { get } }   // 이 파일 private
  ```

#### 7. `ios/FocusMate/JourneyMapThemeSheet.swift` — 지도 테마 시트 (신규, FR-6·12, AC-19~21, 35, 36)
- **변경**
  - **구성**: `ScrollView` 안의 `VStack`에 다음을 둡니다.
    - 버튼 2개(`journey.map.theme.dark`, `journey.map.theme.satellite`): `.accessibilityAddTraits(selected ? .isSelected : [])`, `accessibilityValue(selectedValue)`.
    - `Toggle`(`journey.map.stops`): `.accessibilityValue(switchValue)`.
    - 닫기 버튼(`journey.map.themeSheet.close`).
  - **컨트롤 크기**: 모두 `minHeight: 44` 이상입니다.
  - **시트 식별자**: 루트 컨테이너에 `.accessibilityElement(children: .contain).accessibilityIdentifier("journey.map.themeSheet")`를 붙입니다.
  - **표시 방식**
    - `.presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.medium])`. 큰 글자에서는 large와 스크롤로 잘림을 막습니다(AC-36).
    - **`.presentationBackgroundInteraction(.enabled(upThrough: .medium))`**: 시트가 열린 채 왼쪽 위 일시정지와 DEBUG 시계 버튼을 누를 수 있어야 합니다(AC-22, AC-24). 기본 시트는 배경 입력을 막기 때문에 이 설정이 필수입니다.
  - **Toggle 값 주의**: XCUITest에서 SwiftUI `Toggle`의 `value`는 기본적으로 `"1"/"0"`입니다. `.accessibilityValue`로 덮어쓴 값이 XCUITest에 그대로 보이는지 구현 시 확인합니다. 안 되면 `Button` + `.accessibilityAddTraits(.isToggle)`(iOS 17)로 바꿉니다.
- **시그니처**
  ```swift
  @MainActor struct JourneyMapThemeSheet: View { let map: JourneyMapController; var body: some View }
  ```

#### 8. `ios/FocusMate/JourneyTimerView.swift` — 배치 변경 (수정, FR-1·5·10·15, AC-1·2·36·37·38)
- **현재**: `VStack`으로 남은 시간, 버튼, 안내를 중앙에 두고 배경은 `Color.black`입니다(18-37행). 버튼은 텍스트 캡슐(minWidth 160, 63-79행)이고 DEBUG `test.timer`가 있습니다(95-108행).
- **변경**
  - **프로퍼티**: `let map: JourneyMapController?`와 `let blankMap: Bool`을 추가합니다. 지도가 `nil`이면(손상 방어) 기존 검은 배경으로 대체합니다.
  - **화면 구성**
    - 바닥은 `JourneyMapView(...).ignoresSafeArea()`입니다.
    - 그 위에 `.safeAreaInset(edge: .bottom) { bottomInfo }`를 둡니다. WWDC23 Meet MapKit for SwiftUI의 패턴으로, 지도 법적 표기가 하단 정보 **위 왼쪽**으로 밀려 올라갑니다(FR-10, AC-3).
    - 위쪽은 `.overlay(alignment: .top) { topBar }`입니다. `topBar`는 `HStack { control(왼쪽); Spacer; VStack { follow; theme }(오른쪽) }` 아래에 `notices`를 둡니다.
  - **`bottomInfo`**: `ViewThatFits(in: .horizontal) { HStack(3열 균등); VStack(세로 쌓기) }`. 기본 크기에서는 HStack이라 AC-2의 midX 조건을 만족하고, 큰 글자에서는 세로로 쌓여 겹치지 않습니다(AC-36). 각 열은 라벨이 위, 숫자가 아래입니다(FR-15). 배경은 반투명 material입니다.
    - **남은 시간**: 열 전체를 `.accessibilityElement(children: .ignore)`로 묶고, 라벨 "타이머", 값 "남은 시간 N분", 식별자 `journey.timer.remaining`, `.accessibilityFocused($remainingFocused)`를 **이 요소로 옮깁니다**. 보이는 숫자 텍스트는 `minutesText`("N min") 그대로입니다(AC-37, AC-38).
    - **남은 정류장**: 식별자 `journey.timer.stops`, 라벨 "남은 정류장", 값 "N개"입니다.
    - **남은 거리**: 식별자 `journey.timer.distance`, 라벨 "남은 거리", 값 "2.8km"입니다.
  - **`control`(왼쪽 위)**
    - 일시정지/재개는 아이콘 원형 버튼(44pt 이상)으로 바꿉니다. `accessibilityLabel`("일시정지"/"재개")과 식별자, `tapGuard`(12-14행)는 유지합니다.
    - 도착이면 같은 자리에 `"도착했어요"`(`journey.arrived`)를 둡니다.
  - **도구 버튼**
    - `journey.map.follow`: 라벨 "버스 따라가기", 값 따라가는 중/자유 탐색 중.
    - `journey.map.theme`: 라벨 "지도 테마".
    - 둘 다 `.disabled(!map.state.toolsEnabled)`, 원형 48pt, `.dynamicTypeSize(...accessibility3)`입니다. 기존 `controlButton`의 상한(76행)과 맞춥니다.
  - **notices**: 상단 바 아래 왼쪽 정렬 배너입니다. 식별자 `journey.timer.saveFailure`, `saveWarning`은 유지합니다.
  - **시트**: `.sheet(isPresented: Binding(get: { map.state.isThemeSheetPresented }, set: { if !$0 { map.dismissThemeSheet() } })) { JourneyMapThemeSheet(map:) }`.
  - **동기화**
    - `.onChange(of: MapSync(status: controller.status, elapsed: controller.elapsedSeconds), initial: true) { map.sync(...) }`.
    - `.onChange(of: reduceMotion) { map.setReduceMotion($1) }`.
  - **DEBUG `test.map`**: 기존 `diagnostics`와 같은 패턴으로 하나 더 둡니다. 스키마는 아래 "UI 테스트 검증 수단"에 있습니다.
- **고려사항**: `.onAppear`의 `controller.appear()`와 `remainingFocused = true`(30-33행)는 유지합니다.

#### 9. `ios/FocusMate/JourneyView.swift` — 생성·이탈 연결 (수정)
- **현재**: `@State timer`를 `ensureTimer()`에서 한 번 만들고(28-32행), `.onDisappear { timer?.leave() }`를 둡니다(24행). `JourneyScreen`이 `JourneyTimerView`를 만들고(52-57행), DEBUG `testControls`가 있습니다(145-160행).
- **변경**
  - `@State private var map: JourneyMapController?`를 추가하고, `ensureTimer()`에서 timer를 만든 직후 `JourneyMapController(snapshot: journey, status: timer.status, elapsedSeconds: timer.elapsedSeconds, reduceMotion: …)`를 만듭니다.
    - reduceMotion 초기값은 `JourneyScreen`에서 받습니다. 아니면 `JourneyServices.forcedReduceMotion`과 시스템 값을 `JourneyScreen`의 `onAppear`에서 `setReduceMotion`으로 반영합니다.
  - `.onDisappear { timer?.leave(); map?.leave() }`로 이탈 규칙(BR-5, AC-23)을 연결합니다. W07이 나가기를 만들면 이 경로를 그대로 탑니다.
  - 컨트롤러가 `JourneyView`의 `@State`라서 화면을 떠났다가 들어오면 새로 만들어집니다. 따라서 기본값으로 시작합니다(AC-27). 지도 상태는 어디에도 저장되지 않습니다(AC-26).
  - DEBUG `testControls`에 `test.map.userPan` 버튼을 추가합니다. `map.userMovedCamera()`를 직접 부르는 대체 수단입니다(아래 "자유 탐색 전환을 일으키는 방법" 참고).

#### 10. `ios/FocusMate/JourneyServices.swift`, `ios/FocusMate/UITestBootstrap.swift` — DEBUG 장치 (수정)
- `JourneyServices`의 `#if DEBUG` 블록(20-23행)에 `var blankMap = false`를 추가합니다.
- `UITestBootstrap.init`에서 `--fm-ui-map`을 파싱합니다(`nil` 또는 `"blank"`만 허용, 다른 값은 `SetupIssue.invalidArguments`, 57-64행 패턴). `makeJourneyServices`(229-247행)에서 주입합니다.
- 시드는 새로 추가하지 않습니다. 기존 `timerPaused90`(서울숲역 index 4, 역방향, 25분, 2014, 경과 90초, `UITestBootstrap.swift:271-281`)로 충분합니다.
  - 경과 90초: k=0, fraction 0.3, 다음 정류장 = 성동구민체육센터… 가 아니라 index 3이 첫 다음 정류장입니다.
  - 도착 = `seongdongSportsCenter`(4 − 5 = −1 → 8?)인지 확인이 필요해 계산합니다: 25/5 = 5정류장, 4 + (−1)(5) = −1 → wrap 8 = 성수사거리. 그런데 시드의 `destinationStopID`는 `seongdongSportsCenter`(index 3)입니다. **시드 불일치**이므로 위험 R-6을 참고하십시오.

#### 11. `ios/FocusMateUITests/UITestLaunchSupport.swift` — 도우미 (수정)
- `mapDiagnostic() throws -> [String: Any]`: `test.map` JSON을 읽습니다(`timerDiagnostic`, 72-77행과 같은 형태).
- `dragMap()`: `journey.map` 프레임 중앙에서 오른쪽 아래로 `press(forDuration: 0.1, thenDragTo:)`합니다(기존 V8 패턴, `JourneyTimerUITests.swift:163-166`).
- `waitForMap(_ key: String, equals: Any, timeout:)`: `waitForTimerText`(145-152행)와 같은 폴링입니다.

---

### 데이터 흐름

```
JourneySnapshot ──(JourneyView.ensureTimer)──▶ JourneyTimerController (진도·저장 소유, 기존)
       │                                              │ status, elapsedSeconds (@Observable)
       └─▶ CourseJourney(init?) ─▶ JourneyMapController ◀── JourneyTimerView.onChange(MapSync) ── sync(...)
                                       │  ├─ JourneyCourseProgress.position/next/remaining (순수)
                                       │  ├─ JourneyMapState.timerStatusChanged / 사용자 이벤트 (순수)
                                       │  ├─ JourneyMapRenderModel (순수)
                                       │  └─ JourneyCameraPolicy.target (순수) → cameraTarget(revision++)
                                       ▼
                       JourneyMapView: onChange(cameraTarget) → position(.camera) [animated?]
                                       onChange(position).positionedByUser → map.userMovedCamera()
                       JourneyTimerView: 도구 버튼 → followTapped/openThemeSheet
                                         시트 바인딩 → dismissThemeSheet/select/setShowsStops
                       JourneyView.onDisappear → timer.leave(); map.leave()
```

지도에서 저장으로 가는 화살표는 없습니다. 지도 쪽 데이터는 타이머에서 지도로 한 방향으로만 흐릅니다.

---

### UI 테스트 검증 수단

**`test.map` 진단 JSON (DEBUG, `.sortedKeys`)**
```json
{
  "status": "running|paused|arrived",
  "mode": "follow|explore", "theme": "dark|satellite", "stops": "on|off",
  "sheet": false, "toolsEnabled": true, "reduceMotion": false, "blank": false,
  "bus": {"lat": 0, "lon": 0, "from": 4, "to": 3, "fraction": 0.3, "travelled": 0.3, "heading": 0, "arrived": false},
  "next": {"index": 3, "name": "성동구민체육센터"},
  "destination": {"index": 8, "name": "…", "lat": 0, "lon": 0},
  "remainingStops": 5, "remainingDistance": "2.6",
  "render": {"route": 10, "stopMarkers": 9, "bus": true, "destination": true},
  "camera": {"lat": 0, "lon": 0, "heading": 0, "pitch": 55, "distance": 1200, "animated": true, "revision": 3},
  "course": [[37.5446, 127.0559], …]
}
```
- `course`가 들어 있으므로 UI 테스트도 "정류장 좌표와 일치"로 판정할 수 있습니다(AC-11, 12, 15).
- `camera`는 **마지막으로 낸 목표**입니다. 렌더된 실제 카메라는 타일이나 애니메이션 시점에 따라 흔들리므로 단언에 쓰지 않습니다.

**자유 탐색 전환을 일으키는 방법**
- **주 경로**: 실제 드래그 `h.dragMap()`입니다. XCUITest의 `press(thenDragTo:)`는 시뮬레이터의 `MKMapView` 패닝에서 대체로 동작합니다. 이 경로가 `positionedByUser` 감지(AC-14의 핵심)를 실제로 검증합니다. 드래그 시작점은 오버레이가 없는 화면 중앙(지도)입니다.
- **보조 경로**: `test.map.userPan` DEBUG 버튼입니다(수동 시계일 때만 보임). AC-15~18·32처럼 전환 자체가 아니라 전환 **이후**를 보는 테스트에서 드래그 불안정성을 없애는 데 씁니다.
  - AC-14 자체는 반드시 실제 드래그로 검증합니다.
  - 드래그가 CI에서 불안정하면 AC-14 UI 테스트를 재시도 1회로 감싸고, 판정은 `waitForMap("mode", "explore")` 폴링으로 합니다.

---

### AC 매핑

| AC | 검증 컴포넌트 | 테스트 | 방식 |
|---|---|---|---|
| 1 | JourneyTimerView 식별자 | JourneyMapUITests | 7개 식별자 존재 |
| 2 | JourneyTimerView 배치 | JourneyMapUITests | frame 비교식(PRD 그대로) |
| 3 | safeAreaInset + MapKit 법적 표기 | JourneyMapAccessibilityUITests | `app.links`/`buttons`/`staticTexts`에서 "Legal"·"법적" 라벨 탐색. 찾으면 frame 단언, 못 찾으면 `XCTContext` 기록 후 M-1 |
| 4 | mapControls 숨김, interactionModes | JourneyMapUITests | 전체 요소 식별자·라벨에 compass/pitch/overview/나침반/2D/3D/전체 노선 없음 |
| 5 | JourneyCourse | JourneyCourseTests (단위) | 9개, id 순서, 좌표 서로 다름, 범위, closedPath 끝 = 시작 |
| 6 | JourneyCourseProgress | JourneyCourseProgressTests | 0/300/750/1500초 → i, i+1, mid(i+2, i+3), i+5 |
| 7 | JourneyCourseProgress | 〃 | 역방향 300/1500초. 같은 선분을 반대로 가면 heading 차이 180°(±1e-9) |
| 8 | JourneyCourseProgress | 〃 | 360분: 2700초 → i, 21600초 → 도착, 30000초 → 도착 고정 |
| 9 | JourneyCourseProgress | 〃 | 버스 3종을 1초씩 전 구간 스윕. 한 번의 이동 거리 ≤ 최대 선분 길이. 정류장 좌표와 일치하는 것은 `elapsed % sps == 0`일 때만 |
| 10 | JourneyMapController + 실제 JourneyTimerController | JourneyMapControllerTests | ManualJourneyClock으로 진행 → pause → advance → 위치 불변 → resume → 이어짐 |
| 11 | Progress, Controller | Progress·ControllerTests (+UI `timerArrived` 시드 보조) | 도착 시 bus.point == destination.point |
| 12 | JourneyMapRenderModel | ControllerTests (+UI 진단) | showsStops on/off 모두 destination 존재·좌표 일치 |
| 13 | JourneyMapState, CameraPolicy | StateTests + JourneyMapUITests | 초기 follow, pitch > 0. `interactionModes`에 pitch 없음은 코드 리뷰(M-3 보조) |
| 14 | JourneyMapView `positionedByUser` | JourneyMapUITests (실제 드래그) + StateTests | 드래그 → explore. `sync`를 반복해도 follow 유지(단위) |
| 15 | Controller.followTapped | ControllerTests + UITests | explore → 탭 → follow, camera.center == bus |
| 16 | JourneyMapState | StateTests + UITests | follow 탭 → follow |
| 17 | Controller.sync | ControllerTests + UITests | explore에서 advance → bus 변화, camera.revision과 center 불변 |
| 18 | JourneyMapState | StateTests + UITests | explore → pause → resume → explore |
| 19 | ThemeSheet, State | UITests + StateTests | 시트 식별자, 3개 컨트롤, dark 선택됨, stops 켜짐 |
| 20 | State.select | UITests (+단위) | 위성 → satellite·isSelected, 다시 dark |
| 21 | State.setShowsStops, RenderModel | UITests (+단위) | off → render.stopMarkers 0, route·bus·destination 존재 |
| 22 | State.timerStatusChanged, backgroundInteraction | UITests + ControllerTests | 시트 열림 → pause 탭 → 시트 없음, 도구 isEnabled false → resume → true |
| 23 | State.leave, JourneyView.onDisappear | StateTests, ControllerTests (단위) | 시트 열림 → leave → 닫힘. W06에는 이탈 경로가 없어 UI는 W07에서 추가(위험 R-5) |
| 24 | State.timerStatusChanged(.arrived) | UITests (`timerNearArrival` → resume → 시트 열기 → advance60) + 단위 | 시트 닫힘, 도구 활성 |
| 25 | State.openThemeSheet 가드 | UITests + StateTests | paused에서 theme `isEnabled == false`, 탭해도 시트 없음 |
| 26 | 저장 무관(구조) | UITests | 위성·정류장 끔·explore 뒤 `persistedJourney()`: version 4, 바이트에 `theme`/`mapMode`/`camera`/`pitch`/`showsStops` 키 없음 |
| 27 | Controller 수명(@State) | UITests (relaunch + `--fm-ui-route journey`) + ControllerTests(init 기본값) | follow / dark / on |
| 28 | Controller에 저장자 없음 | UITests + ControllerTests | 수동 시계 실행 중 드래그·테마 변경 전후 `persistedBytes` 동일. `FakeProgressSaver.writes` 수가 늘지 않음, 경과·status 동일 |
| 29 | Info.plist, 코드 | AppInfoLocationTests (단위) + UITests | `Bundle.main`에 NSLocation*UsageDescription 4종 nil. 여행 화면에서 `app.alerts.count == 0`, springboard 알림 없음 |
| 30 | CameraPolicy | StateTests + AccessibilityUITests(`--fm-ui-reduce-motion on`) | animated false, heading 0 |
| 31 | CameraPolicy | 〃(off) | animated true |
| 32 | State(동작 줄이기와 무관) | StateTests + AccessibilityUITests | 같은 이벤트 열에서 on/off 결과 `JourneyMapState` 동일. UI는 mode/theme/stops/sheet 비교 |
| 33 | JourneyMapView 접근성 | AccessibilityUITests | `journey.map` label "가상 코스 지도", value에 next·destination 이름. 정류장 이름 요소가 없음 |
| 34 | 도구 버튼 접근성 | AccessibilityUITests | label·value, paused에서 isEnabled false |
| 35 | ThemeSheet 접근성 | AccessibilityUITests | dark/satellite value 선택됨/선택 안 됨, stops 켜짐/꺼짐 |
| 36 | ViewThatFits, detents | AccessibilityUITests (AccessibilityXXXL) | hittable, 44×44 이상, 시트 3개 컨트롤 hittable, 하단 3개·pause frame 교차 없음 |
| 37 | remainingFocused 유지 | AccessibilityUITests | `test.timer.focus == "remaining"`, 낭독 1회(W05 V7 재사용) |
| 38 | W05 회귀 | 기존 JourneyTimerUITests / Lifecycle / Accessibility 전부 | 수정 없이 통과(또는 아래 영향 분석 반영) |
| 39 | Progress, Display | ProgressTests + UITests | 공식 비교. 0 → total, 도착 → 0 / "0.0". 화면 `journey.timer.stops`·`distance` value가 진단과 같음 |
| 40 | blankMap 대체 렌더 | JourneyMapUITests (`--fm-ui-map blank`) + M-6 | pause/resume 정상, render route·bus true, 도구 존재 |

---

### 의존성 및 영향도

**새 의존성**: MapKit(시스템 프레임워크, `import MapKit`만, 뷰 파일 1개). 외부 라이브러리는 없습니다.

**W05 기존 UI 테스트 영향 분석**
- **중앙 배치를 전제한 frame 단언은 없습니다**(검색 결과 frame과 coordinate 사용은 아래 2곳뿐).
- **`JourneyTimerAccessibilityUITests.testV7_AC29`**
  - 영향 1: `XCTAssertEqual(h.app.scrollViews.count, 0)`(81행). `MKMapView`는 `UIScrollView`가 아니지만, SwiftUI `Map` 내부 구현이 스크롤 뷰로 노출될 가능성은 실행으로 확인해야 합니다. 지도를 `children: .ignore`로 묶으면 내부가 숨겨지므로 0이 유지될 것으로 예상합니다. 하단 정보에는 ScrollView를 쓰지 않습니다.
  - 영향 2: 일시정지/재개가 아이콘 원형으로 바뀌어도 44×44 이상이고 hittable이면 통과합니다.
- **`JourneyTimerUITests.assertStaysOnJourneyAfterSwipes`**(159-172행): 화면 중앙 드래그가 이제 지도를 패닝해 explore로 바뀝니다. 단언(화면 유지, path)에는 영향이 없습니다. 오히려 "지도 제스처가 내비게이션 이탈을 일으키지 않는다"는 보강 효과가 있습니다.
- **`testV7_AC27`·`AC28`**: 남은 시간의 라벨과 값을 같은 식별자 요소로 옮기므로 그대로 통과합니다. 지도는 낭독하지 않으므로 낭독 횟수도 바뀌지 않습니다.
- **나머지(V1~V6)**: 식별자 존재와 진단 값만 봅니다. 일시정지가 아이콘이어도 `label == "재개"`(39행)는 `accessibilityLabel`로 유지됩니다.

**하위 호환성**: 저장 형식 v4는 변경하지 않습니다. `JourneySnapshot`, `AppModel`, `SnapshotCodec`도 수정하지 않습니다.

#### 기존 구조와의 차이 (`context/journey/architecture.md` 기준)
1. 아키텍처 문서는 "별도 도메인 서비스 레이어 없음, 순수 규칙 `RouteData`·`JourneyPlanner`"입니다. 이번에 순수 규칙 `JourneyCourse`·`JourneyCourseProgress`·`JourneyMapState`와 `@Observable` `JourneyMapController`가 생깁니다. 서비스 계층이 아니라 W05의 "컨트롤러 + 순수 규칙" 패턴의 확장입니다. 구현 후 architecture.md 17행 "MapKit … 예정(W06)"을 구현됨으로 갱신해야 합니다(문서 작업).
2. 웹(`updateCamera`, 841행)은 SVG 경로 길이를 9등분해 **길이 비례**로 위치를 정합니다. iOS는 BR-2에 따라 **정류장 구간별 비율**로 보간합니다. 구간마다 지리 길이가 달라 화면 속도가 다릅니다.
3. 웹 `followMap`은 토글(844행)이지만 iOS는 항상 "버스로 복귀"입니다(BR-3, AC-16).
4. 웹은 동작 줄이기에서 정류장 단위로 점프합니다(783행 `$('reduce').checked?completedStops:travel`). iOS는 버스를 연속 이동시키고 카메라 애니메이션만 끕니다(확정된 가정 3).
5. 웹은 테마 변경과 따라가기에서 낭독합니다(830, 844행). iOS는 W05 낭독 계약을 보호하려고 낭독 대신 접근성 값과 선택 특성을 씁니다.
6. 웹의 위성은 색 필터 시연이고, iOS는 실제 `.imagery`입니다(PRD 확정 가정 4).
7. 하단 남은 거리는 소수 1자리(BR-7)이고, 출발 전 화면의 `JourneyPlanner.distanceText`는 소수 2자리까지 표기합니다(`JourneyPlanner.swift:34-40`). 예를 들어 같은 5정류장이 "2.75km"와 "2.8"로 다르게 보입니다.

---

### 구현 순서
태스크는 AC 묶음 단위이며, 순서는 순수 로직 → 상태 머신 → 뷰 → UI 테스트입니다.

1. [Must] **T1 코스 데이터**: `JourneyCourse.swift` + `JourneyCourseTests` — AC-5 (의존: 없음)
2. [Must] **T2 진도 → 위치·남은 값**: `JourneyCourseProgress.swift`, `JourneyMapDisplay.swift` + `JourneyCourseProgressTests` — AC-6~9, 11, 39(계산) (의존: 1)
3. [Must] **T3 상태 머신·카메라 정책·렌더 모델**: `JourneyMapState.swift` + `JourneyMapStateTests` — AC-13·16·18~25·30~32(단위) (의존: 1, 2)
4. [Must] **T4 위치 권한 부재 검증**: `AppInfoLocationTests` — AC-29(단위) (의존: 없음)
5. [Must] **T5 컨트롤러**: `JourneyMapController.swift` + `JourneyMapControllerTests` — AC-10·11·12·15·17·22·24·27·28(단위) (의존: 2, 3)
6. [Must] **T6 지도 뷰·시트**: `JourneyMapView.swift`, `JourneyMapThemeSheet.swift` — FR-1~4·6·8·11·12·14 (의존: 5)
7. [Must] **T7 화면 통합**: `JourneyTimerView.swift` 배치·하단 정보·도구·`test.map`, `JourneyView.swift` 생성·leave·`test.map.userPan` — FR-5·7·10·15 (의존: 6)
8. [Must] **T8 UI 하네스**: `UITestLaunchSupport.swift`에 `mapDiagnostic`·`dragMap`·`waitForMap` (의존: 7. 진단 키 계약을 따름)
9. [Must] **T9 지도 UI 테스트**: `JourneyMapUITests` — AC-1·2·4·13~28 (의존: 7, 8)
10. [Must] **T10 접근성·동작 줄이기 UI 테스트**: `JourneyMapAccessibilityUITests` — AC-3·30~37 (의존: 7, 8)
11. [Must] **T11 W05 회귀**: 기존 3개 UI 테스트 클래스를 실행하고, 영향 분석에 따라 필요한 경우만 보정 — AC-38 (의존: 7)
12. [Should] **T12 지도 미로딩 대체 검증**: `JourneyServices.blankMap`, `UITestBootstrap --fm-ui-map blank`, `JourneyMapView` 분기 + `JourneyMapUITests`에 AC-40 추가 (의존: 7, 9. 9와 같은 테스트 파일이라 순차)
13. [Could] **T13 FR-17 진행 방향 회전**: `JourneyCameraPolicy.rotatesWithBus = true` 경로 + 버스 아이콘 상대 회전 + 단위 테스트(동작 줄이기면 0 유지) (의존: 3, 6)

병렬: 1과 4는 서로 독립입니다. 9와 10은 서로 다른 파일이라 병렬로 진행할 수 있습니다. 실행은 동시 빌드 금지 메모에 따라 순차로 합니다. 11은 9·10과 파일이 겹치지 않습니다.

---

### 위험

- **R-1 제스처 감지 API**: `positionedByUser`를 `onChange(of: position)`로 볼 때 `MapCameraPosition`의 Equatable 여부와 갱신 시점을 컴파일과 실행으로 확인해야 합니다. 대안(커스텀 Binding setter)은 상세 설계 6에 적었습니다.
- **R-2 XCUITest 드래그 신뢰성**: 시뮬레이터에서 `MKMapView` 패닝은 대체로 되지만 첫 프레임 로딩 중 드래그가 무시될 수 있습니다. 드래그 전에 `journey.map` hittable을 기다리고 `waitForMap` 폴링으로 판정합니다. 보조 DEBUG 훅이 있습니다.
- **R-3 법적 표기 접근성**: `children: .ignore`로 지도를 묶으면 표기를 트리에서 찾지 못할 가능성이 큽니다. 그 경우 AC-3은 M-1로 대체합니다(PRD 허용). 표기 위치는 `.safeAreaInset(edge: .bottom)` 동작에 의존하므로 M-1/M-4에서 눈으로 확인합니다.
- **R-4 AC-2 화면 높이 의존**: `check-ios.py`는 처음 사용 가능한 iPhone 시뮬레이터를 고릅니다(`scripts/check-ios.py:24`). 상단 DEBUG 시계 줄(44pt)이 있어서, SE급(667pt)에서는 `pause.midY < 0.2H`(133pt)가 빠듯합니다. 6.1인치 이상(852pt, 기준 약 140 < 170)에서는 여유가 있습니다.
- **R-5 AC-23 UI 검증 경로 없음**: W06에는 여행 화면에서 나가는 경로가 없습니다(`AppModel.goBack` 가드, `AppModel.swift:270-275`). 단위 테스트와 `onDisappear` 연결로 검증하고, UI 검증은 W07 나가기 구현 때 추가합니다.
- **R-6 `timerPaused90` 시드의 도착지 불일치**: 시드는 서울숲역(4), 역방향, 25분, 2014인데 `destinationStopID`가 `seongdongSportsCenter`(3)입니다(`UITestBootstrap.swift:276-277`). BR-2 계산값은 index 8(성수사거리)입니다. 지도는 계산값으로 버스를 움직이므로, 도착 표시를 스냅샷 값으로 두면 UI에서 둘이 다르게 보입니다.
  - 설계는 **계산값 하나로 통일**합니다(`CourseJourney.destinationIndex`).
  - 시드의 `destinationStopID`를 `seongsuIntersection`으로 고칠 것을 권합니다. W05 테스트는 도착지 이름을 단언하지 않으므로 영향이 없습니다.
- **R-7 Toggle 접근성 값**: XCUITest가 `"1"/"0"`을 보고할 수 있습니다. 대안은 `Button` + `.isToggle`입니다(상세 설계 7).
- **R-8 카메라 애니메이션과 1초 틱**: `withAnimation`이 1초마다 이어지면 끊겨 보일 수 있습니다. 곡선과 시간은 디자인 스펙 사항이고, QE-1은 W14 실기기에서 확인합니다.
- **R-9 어두운 지도 표현**: `.environment(\.colorScheme, .dark)`가 `Map` standard 스타일을 실제로 어둡게 하는지 M-5에서 확인합니다. 부족하면 `.standard(emphasis: .muted)`를 병행합니다.
- **R-10 일시정지 저장 실패 시 시트**: pause 저장이 실패하면 status가 running으로 남으므로 시트도 열린 채 남습니다(`JourneyTimerController.swift:84-87`). FR-7은 "일시정지 중"을 조건으로 하므로 규칙과 모순은 아닙니다.

### 설계 가정
- 일시정지/재개는 웹 `focusPause`처럼 아이콘 원형 버튼으로 바꾸고 접근성 라벨은 그대로 둡니다. 세부 치수는 디자인 스펙 사항입니다.
- 도착 시 하단 남은 거리는 "0.0"(웹 `toFixed(1)`과 같음), 남은 정류장은 "0"입니다.
- 지도 도구와 테마 변경은 낭독하지 않습니다(접근성 값으로 전달).

---

## 확인이 필요한 사항

1. 실제 위치가 허용 범위(위도 37.53~37.55, 경도 127.03~127.06) 밖인 정류장 좌표를 어떻게 정할까요?
   - 맥락: BR-1은 "각 정류장의 실제 위치 근처 점"이면서 AC-5는 이 범위를 강제합니다. 뚝섬한강공원의 실제 위치는 경도 약 127.067로 범위 밖입니다. 성동구민체육센터는 실제 위치를 확정하지 못했습니다. 초안 표에서는 두 점을 범위 안 근사치로 두었습니다.
   - 유형: 선택
   - 선택지:
     - (a) 범위 우선, 실제 위치에서 가장 가까운 범위 안 점 사용 (권장) — AC-5를 그대로 지키고 코스가 성수·서울숲 일대에 모여 보입니다. 대신 한강공원 점은 실제 공원 입구보다 서쪽에 찍힙니다.
     - (b) 범위를 경도 127.07까지 넓혀 실제 위치 사용 — 지명과 위치가 더 정확해집니다. 대신 PRD AC-5 수정이 필요하고 코스가 동쪽으로 길게 늘어납니다.
     - (c) 직접 입력 — 위 선택지 외 다른 방식을 직접 입력합니다
2. '위성' 모드에 도로·지명 라벨을 함께 보여 줄까요?
   - 맥락: MapKit은 라벨 없는 위성 영상(`.imagery`)과 라벨이 있는 위성(`.hybrid`)을 모두 제공합니다. PRD는 "실제 위성 영상"이라고만 정했습니다.
   - 유형: 선택
   - 선택지:
     - (a) 라벨 없는 위성 영상 (권장) — 실제 버스 노선과 정류장 라벨이 섞이지 않아 가상 코스와 헷갈릴 일이 적고(BR-1), 코스 선이 잘 보입니다. 대신 위치 감각(지명)은 약해집니다.
     - (b) 라벨이 있는 위성 — 지명으로 "어디쯤인지" 알기 쉽습니다. 대신 실제 교통 라벨이 가상 코스와 겹쳐 보일 수 있습니다.
     - (c) 직접 입력 — 위 선택지 외 다른 방식을 직접 입력합니다

## 탐색 추가 항목
- `ios/FocusMate/JourneyServices.swift:5-33` → 여행 화면 의존성 묶음. `forcedReduceMotion`, DEBUG `testClock`·`failNextSave`. `blankMap` 추가 위치
- `ios/FocusMate/JourneyTimerDisplay.swift:4-22` → 남은 시간 표기·접근성 문구. 하단 남은 시간 열에서 그대로 사용
- `ios/FocusMate/AppModel.swift:263-275` → `open`/`goBack`. 출발한 여행 화면에서는 이탈할 수 없음(AC-23 UI 검증 불가 근거)
- `ios/FocusMate/RootView.swift:238-256` → 전역 DEBUG 진단(`test.snapshot`, `test.persistedBytes`, `test.dynamicTypeSize`, `test.announcements`, `test.reduceMotion`)
- `ios/FocusMateUITests/JourneyTimerUITests.swift:159-172` → V8 스와이프 테스트. 이제 지도 패닝을 일으키지만 단언에는 영향 없음
- `ios/FocusMateUITests/JourneyTimerAccessibilityUITests.swift:60-82` → AX5 테스트. `scrollViews.count == 0` 단언이 지도 도입 후 재확인 대상
- `ios/FocusMateUITests/JourneyTimerLifecycleUITests.swift:17-22` → `runningFrom(seed)` 패턴. 지도 UI 테스트에서 재사용
- `ios/FocusMateTests/JourneyTimerControllerTests.swift:12-49` → Rig 패턴(ManualJourneyClock, FakeProgressSaver). `JourneyMapControllerTests` 연동 테스트에서 재사용
- `ios/FocusMateTests/BoardingTestDoubles.swift:24-32` → `BoardingFixtures.journey(...)`. 기본값 성수 정방향 60분 2014, 도착 seongdongSportsCenter(계산값과 일치)
- `ios/FocusMate/UITestBootstrap.swift:270-281` → `timerPaused90/NearArrival/Arrived` 시드. 도착지가 BR-2 계산값과 불일치(R-6)
- `ios/FocusMate.xcodeproj/project.pbxproj:54-61` → iOS 17, Swift 5, strict concurrency minimal, Info.plist 자동 생성, 위치 키 없음
- `scripts/check-ios.py:24-30` → 첫 번째 사용 가능한 iPhone 시뮬레이터 선택(R-4)
- `docs/FLOWS.md:16, 68-74` → 집중 화면 지도 도구와 하단 정보 계약
- `designs/final/animation-preview.html:811-848` → 웹 따라가기 토글, 카메라 정책, 테마 시트 동작(차이 비교 근거)