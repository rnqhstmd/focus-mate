# 설계: W06 MapKit 가상 코스 (여행 화면 지도) — 2회차 최종본

이번 회차에 반영한 결정은 다음과 같습니다.
- PRD 갱신: BR-1과 AC-5(서울 경계 상자, 정류장 id에 묶인 좌표), AC-7(비교 쌍), AC-40(M-6으로 대체), 확정 가정 4(위성은 `.hybrid`).
- design-critic의 M1·M2를 해소했습니다(아래 6·8번 항목과 T0 스파이크).
- test-architect 권고와 오케스트레이터 결정을 모두 반영했습니다.
  - DEBUG 훅(`blankMap`, `userPan`)과 FR-17을 범위에서 뺐습니다.
  - AC마다 소유 테스트를 하나만 둡니다.
  - 시드의 도착지를 정정합니다.

### 설계 규모
대형. 신규 순수 로직 3개, MapKit 뷰, W05 화면 배치 변경, AC 40건(단위·UI·수동)이 걸쳐 있습니다.

### 배경 및 목적
- 지금 여행 화면은 검은 배경에 남은 시간과 일시정지/재개만 있습니다(`ios/FocusMate/JourneyTimerView.swift:18-37`). 정류장은 id와 이름만 있습니다(`ios/FocusMate/RouteData.swift:10-21`).
- 목표:
  - 배경을 Apple 지도로 바꿉니다.
  - 가상 순환 코스에서 버스가 W05 진도대로 움직이게 합니다.
  - 따라가기/자유 탐색, 지도 테마 시트, 하단 정보 3종을 넣습니다.
  - 지도 조작이 진도와 저장을 바꾸지 않게 합니다.

### 요구사항 및 수용 기준
원문은 `.dev/feat-mapkit-virtual-course/prd.md`에 있습니다.
- [Must] FR-1~15, BR-1~8
- [Should] FR-16(AC-40은 M-6으로 대체), QE-1~3
- [Could] FR-17은 **이번 범위에서 제외합니다**. 카메라 heading은 0으로 고정하고, 버스 아이콘은 진행 방향만 표시합니다.

---

### 변경 범위

**신규 (앱)**

| 파일 | 책임 | import |
|---|---|---|
| `ios/FocusMate/JourneyCourse.swift` | 정류장 id별 좌표 데이터, 9개 코스, 닫힌 선 | Foundation |
| `ios/FocusMate/JourneyCourseProgress.swift` | `CourseJourney`, 진도 → 위치·heading·다음 정류장·남은 정류장·남은 거리 | Foundation |
| `ios/FocusMate/JourneyMapState.swift` | 지도 상태 머신(값 타입), 카메라 정책 | Foundation |
| `ios/FocusMate/JourneyMapController.swift` | 얇은 `@Observable` 연결부(상태, 위치, 카메라 목표, 렌더 계산 프로퍼티) | Foundation, Observation |
| `ios/FocusMate/JourneyMapDisplay.swift` | 지도·하단 정보 문구와 접근성 값 | Foundation |
| `ios/FocusMate/JourneyMapView.swift` | SwiftUI `Map`, 제스처 감지, 카메라와 버스 애니메이션 | SwiftUI, MapKit |
| `ios/FocusMate/JourneyMapThemeSheet.swift` | 지도 테마 시트 | SwiftUI |

**신규 (테스트)**: `ios/FocusMateTests/`의 `JourneyCourseTests`, `JourneyCourseProgressTests`, `JourneyMapStateTests`, `JourneyMapControllerTests`, `AppInfoLocationTests`. `ios/FocusMateUITests/`의 `JourneyMapUITests`, `JourneyMapAccessibilityUITests`. 스파이크용 `JourneyMapSpikeUITests`는 T0 이후 삭제합니다.

**수정**

| 파일 | 변경 |
|---|---|
| `ios/FocusMate/JourneyTimerView.swift` | 지도 배치와 W05 대체 배치 분기, 하단 정보, 도구 버튼, 시트, `test.map` |
| `ios/FocusMate/JourneyView.swift` | 지도 컨트롤러 생성(reduceMotion은 생성자로), 이탈 시 `leave()` |
| `ios/FocusMate/UITestBootstrap.swift` | `timerJourney`의 `destinationStopID`를 계산값으로 정정(276-277행. `v3Bytes` 290행이 파생하므로 v3 시드도 함께 정정됨) |
| `ios/FocusMateUITests/UITestLaunchSupport.swift` | `mapDiagnostic()`, `dragMap()`, `waitForValue(_:_:)` |
| `context/journey/architecture.md` | W06 구현 반영과 "저장 도착지 ≠ 계산 도착지면 지도 생략" 규칙 기록(W09가 같은 규칙을 씀) |

pbxproj, Info.plist, `JourneyServices.swift`는 바꾸지 않습니다. 동기화 폴더이고, MapKit은 `import`만으로 자동 링크되며, `GENERATE_INFOPLIST_FILE = YES`에 위치 키가 없습니다(`project.pbxproj:54-57`).

### 적용 컨벤션
- 컨벤션 파일은 없습니다. 기존 코드 패턴을 따릅니다.
- **네이밍**: 타입은 `Journey*` 접두어, 문구는 `enum XxxDisplay` static(`JourneyTimerDisplay.swift:4-22`), 식별자는 `journey.<영역>.<요소>`, 진단은 `test.<영역>`입니다.
- **구조**
  - `@MainActor @Observable final class`, `private(set)` 상태, 의존성은 생성자 주입입니다(`JourneyTimerController.swift:7-54`).
  - 순수 규칙은 `enum` static 함수입니다(`JourneyPlanner`, `RouteStops`).
  - View는 컨트롤러 호출만 합니다.
- **진단**: `JSONSerialization` + `.sortedKeys`를 1pt 투명 `Text`의 `accessibilityValue`로 노출합니다(`JourneyTimerView.swift:95-108`).
- **테스트**
  - 메서드 이름은 `testV<n>_AC<n>_<한국어>`이고 위에 `// 깨짐:` 주석을 둡니다.
  - UI 테스트는 `FocusMateUIHarness.launchJourney(seed:)`와 수동 시계를 씁니다(`UITestLaunchSupport.swift:59-70`).
  - **사용자가 관찰하는 값을 먼저 판정합니다.**
    - 모드: 따라가기 버튼의 접근성 값
    - 테마: 시트 버튼의 `isSelected`
    - 정류장 표시: 토글 값
    - 활성 여부: `isEnabled`
    - 시트: `journey.map.themeSheet` 존재
  - `test.map`은 화면에 없는 값(렌더 개수, 카메라 목표, 좌표)에만 씁니다.

---

### 상세 설계

#### 1. `JourneyCourse.swift` — 좌표 데이터 (AC-5, BR-1)
- **현재**: `RouteStops.all`은 `(id, name)`만 있습니다.
- **변경**
  - 좌표는 **정류장 id를 키로 하는 사전**입니다(`coordinates: [String: CoursePoint]`). `RouteStops`는 수정하지 않습니다. 카탈로그가 서울 전역으로 늘어도 사전 항목만 추가하면 됩니다(BR-1).
  - `stops`는 `RouteStops.all` 순서대로 id를 조회해 만듭니다. 좌표가 없는 id는 `preconditionFailure`이고, AC-5 테스트가 항상 이 경로를 실행합니다.
  - CoreLocation은 쓰지 않습니다(`CoursePoint` 자체 타입). 순수 로직과 단위 테스트가 MapKit 없이 돌아갑니다.
- **시그니처**
  ```swift
  struct CoursePoint: Equatable, Hashable { let latitude: Double; let longitude: Double }
  struct CourseStop: Equatable { let index: Int; let id: String; let name: String; let point: CoursePoint }
  enum JourneyCourse {
      static let seoulBounds: (latitude: ClosedRange<Double>, longitude: ClosedRange<Double>)  // 37.41...37.72, 126.76...127.19
      static let coordinates: [String: CoursePoint]
      static let stops: [CourseStop]
      static func point(at index: Int) -> CoursePoint      // RouteStops.wrap
      static var closedPath: [CoursePoint]                 // stops + stops[0]
  }
  ```
- **좌표**: 실제 위치의 근사값입니다. T1에서 Apple 지도로 각 점을 다시 확인하고 소수 4자리로 확정합니다. 테스트는 경계 상자와 서로 다름만 판정합니다.

  | id | 이름 | lat | lon | 근거 |
  |---|---|---|---|---|
  | seongsu | 성수역 | 37.5446 | 127.0559 | 2호선 성수역 |
  | seongsuDong | 성수동 | 37.5445 | 127.0507 | 성수동1가 생활권 중심 근사 |
  | ttukseom | 뚝섬역 | 37.5474 | 127.0474 | 2호선 뚝섬역 |
  | seongdongSportsCenter | 성동구민체육센터 | (T1 확인) | (T1 확인) | 실제 시설 주소 기준, 미검증 |
  | seoulForest | 서울숲역 | 37.5437 | 127.0447 | 수인분당선 서울숲역 |
  | seoulForestGate | 서울숲 입구 | 37.5432 | 127.0396 | 서울숲 정문 근사 |
  | seongsuBridgeNorth | 성수대교 북단 | 37.5403 | 127.0355 | 성수대교 북단 교차로 |
  | ttukseomHangangPark | 뚝섬한강공원 | 37.5296 | 127.0670 | 사용자 지정 |
  | seongsuIntersection | 성수사거리 | 37.5410 | 127.0573 | 근사, T1 확인 |

#### 2. `JourneyCourseProgress.swift` — 진도 → 위치 (BR-2, BR-7, AC-6~9, 39)
- **현재**: 도착지는 `RouteStops.wrap(origin.index + direction × stops)`로 계산합니다(`JourneyPlanner.swift:28-30`, `JourneySnapshot.swift:42`). 진도는 정수 초 `JourneyTimerController.elapsedSeconds`입니다.
- **`CourseJourney.init?(journey:)`**
  - 다음 경우 `nil`을 돌려줍니다.
    - 카탈로그에 없는 정류장이나 버스
    - `minutes % minutesPerStop != 0`
    - **저장된 `destinationStopID`가 계산값과 다를 때**
  - `nil`이면 여행 화면은 W05 대체 배치를 씁니다(8번).
- **계산(정수 산술)**
  - `sps = minutesPerStop × 60`, `e = clamp(elapsed, 0...totalSeconds)`, `k = e / sps`, `fraction = Double(e % sps) / Double(sps)`.
  - `k >= totalStops`이면 도착 정류장에 고정합니다.
  - 그 외에는 `from = wrap(o + d·k)`, `to = wrap(o + d·(k+1))` 사이를 선형 보간합니다.
- **heading**
  - 국지 평면 근사입니다: `atan2(Δlon·cos(평균 위도), Δlat)`를 도 단위 `[0, 360)`로 바꿉니다. 같은 선분을 반대로 가면 정확히 180° 차이가 납니다(AC-7).
  - 경과 0이면 첫 구간, 정류장 경계면 다음 구간, 도착이면 마지막 구간의 heading을 씁니다.
- **다음 정류장**: `wrap(o + d·min(total, k+1))`입니다.
- **남은 정류장**: `total − min(total, k)`입니다.
- **남은 거리**: 0.1km 정수로 반올림합니다(half-up): `n = total × 55 × (T − e)`, `tenths = (2n + 10T) / (20T)`. 단위는 `JourneyPlanner.hundredthsKmPerStop = 55`와 같습니다.
- **시그니처**
  ```swift
  struct CourseJourney: Equatable {
      let originIndex: Int; let direction: Int; let minutesPerStop: Int; let totalMinutes: Int
      var totalStops: Int { get }; var totalSeconds: Int { get }; var destinationIndex: Int { get }
      init(originIndex: Int, direction: Int, minutesPerStop: Int, totalMinutes: Int)
      init?(journey: JourneySnapshot)
  }
  struct CourseBusPosition: Equatable {
      let point: CoursePoint; let headingDegrees: Double
      let segmentFrom: Int; let segmentTo: Int; let fraction: Double; let isArrived: Bool
  }
  enum JourneyCourseProgress {
      static func position(of: CourseJourney, elapsedSeconds: Int) -> CourseBusPosition
      static func nextStopIndex(of: CourseJourney, elapsedSeconds: Int) -> Int
      static func remainingStops(of: CourseJourney, elapsedSeconds: Int) -> Int
      static func remainingDistanceTenthsKm(of: CourseJourney, elapsedSeconds: Int) -> Int
  }
  ```

#### 3. `JourneyMapState.swift` — 상태 머신과 카메라 정책 (BR-3~5)
- **`JourneyMapState`(값 타입)**
  - 필드: `camera`(follow/explore), `theme`(dark/satellite), `showsStops`, `isThemeSheetPresented`, `status`. `toolsEnabled = status != .paused`입니다.
  - `userMovedCamera()`: 항상 explore가 됩니다. 일시정지 중에도 그렇습니다.
  - `followTapped()`: 도구가 비활성이면 무시하고, 아니면 follow입니다. follow 상태에서 눌러도 follow를 유지합니다.
  - `openThemeSheet()`: 도구가 비활성이면 무시합니다.
  - `timerStatusChanged`: paused나 arrived가 되면 시트를 닫고, 카메라 모드는 건드리지 않습니다.
  - `leave()`: 시트를 닫습니다.
  - 동작 줄이기 값은 이 상태에 넣지 않습니다. 그래서 AC-32가 구조로 보장됩니다.
- **`JourneyCameraPolicy`**
  - pitch는 0보다 큰 고정값(초안 55°), 거리는 초안 1200m(값은 디자인 스펙)입니다.
  - **heading은 항상 0**입니다(FR-17 제외, AC-30).
  - `animated = !reduceMotion`입니다.
- **시그니처**
  ```swift
  enum JourneyCameraMode: String { case follow, explore }
  enum JourneyMapTheme: String { case dark, satellite }
  struct JourneyMapState: Equatable {
      private(set) var camera: JourneyCameraMode; private(set) var theme: JourneyMapTheme
      private(set) var showsStops: Bool; private(set) var isThemeSheetPresented: Bool
      private(set) var status: JourneyTimerController.Status
      var toolsEnabled: Bool { get }
      init(status: JourneyTimerController.Status)
      mutating func userMovedCamera(); @discardableResult mutating func followTapped() -> Bool
      mutating func openThemeSheet(); mutating func dismissThemeSheet()
      mutating func select(theme: JourneyMapTheme); mutating func setShowsStops(_ on: Bool)
      mutating func timerStatusChanged(_ status: JourneyTimerController.Status); mutating func leave()
  }
  struct JourneyCameraTarget: Equatable {
      let center: CoursePoint; let headingDegrees: Double; let pitchDegrees: Double
      let distanceMeters: Double; let animated: Bool; let revision: Int
  }
  enum JourneyCameraPolicy {
      static let pitchDegrees: Double; static let distanceMeters: Double
      static func target(center: CoursePoint, reduceMotion: Bool, revision: Int) -> JourneyCameraTarget
  }
  ```

#### 4. `JourneyMapController.swift` — 얇은 연결부
- **저장자와 타이머 의존성이 없습니다.** 지도 때문에 저장이 일어날 경로가 아예 없습니다(BR-6, AC-28, AC-40의 구조 보장).
- `sync(status:elapsedSeconds:)`
  - 위치, 다음 정류장, 남은 값을 다시 계산하고 `state.timerStatusChanged`를 반영합니다.
  - follow일 때만 `cameraTarget`을 새로 만듭니다(`revision` +1). explore면 그대로 둡니다.
- `followTapped()`: 상태 머신이 `true`를 돌려주면 현재 버스 위치로 새 목표를 만듭니다.
- `setReduceMotion`: 이후 목표의 `animated`에 반영합니다.
- 렌더 데이터는 별도 타입 없이 **계산 프로퍼티**로 둡니다: `routePoints`, `visibleStops`(showsStops가 아니면 빈 배열), `destinationStop`.
- **시그니처**
  ```swift
  @MainActor @Observable final class JourneyMapController {
      private(set) var state: JourneyMapState
      private(set) var bus: CourseBusPosition
      private(set) var cameraTarget: JourneyCameraTarget
      private(set) var nextStopIndex: Int; private(set) var remainingStops: Int; private(set) var remainingDistanceTenthsKm: Int
      @ObservationIgnored let journey: CourseJourney
      @ObservationIgnored private var reduceMotion: Bool
      var routePoints: [CoursePoint] { get }; var visibleStops: [CourseStop] { get }; var destinationStop: CourseStop { get }
      init(journey: CourseJourney, status: JourneyTimerController.Status, elapsedSeconds: Int, reduceMotion: Bool)
      func sync(status: JourneyTimerController.Status, elapsedSeconds: Int)
      func setReduceMotion(_ on: Bool)
      func userMovedCamera(); func followTapped(); func openThemeSheet(); func dismissThemeSheet()
      func select(theme: JourneyMapTheme); func setShowsStops(_ on: Bool); func leave()
  }
  ```

#### 5. `JourneyMapDisplay.swift` — 문구 (BR-8, FR-12, FR-15)
- 문구 목록:
  - 지도: `mapLabel` "가상 코스 지도", `mapValue(next:destination:)` "다음 정류장 X, 도착 정류장 Y"
  - 따라가기: `followLabel` "버스 따라가기", `followValue` "따라가는 중"/"자유 탐색 중"
  - 테마: `themeLabel` "지도 테마", `darkLabel` "어두운 지도", `satelliteLabel` "위성", `stopsLabel` "정류장 표시"
  - 상태 값: `selectedValue` "선택됨"/"선택 안 됨", `switchValue` "켜짐"/"꺼짐"
  - 하단 정보: "남은 정류장"/"N"/"N개", "남은 거리"/"2.6"/"2.6km"(도착 "0.0")
- 지도 조작에는 낭독을 넣지 않습니다. W05의 "1회 낭독" 단언(`JourneyTimerAccessibilityUITests.swift:47, 55`)을 지키기 위해서입니다.

#### 6. `JourneyMapView.swift` — MapKit 뷰 (FR-1~4·8·11·14, M1 해소)
- **입력**: `map: JourneyMapController`, `status`, `elapsedSeconds`.
- **카메라 바인딩**
  - `@State position: MapCameraPosition`의 초기값은 `.camera(MapCamera(centerCoordinate:distance:heading:pitch:))`이고 `map.cameraTarget`에서 만듭니다. 진입 애니메이션은 없습니다.
  - `Map(position: Binding(get: { position }, set: { new in position = new; if new.positionedByUser { map.userMovedCamera() } }), interactionModes: [.pan, .zoom, .rotate])`
    - **사용자 판정은 커스텀 바인딩의 setter에서 합니다.** 앱이 대입할 때는 `@State`에 직접 쓰므로 setter를 거치지 않습니다. 따라서 setter 호출은 MapKit(사용자 제스처)에서만 옵니다. 판정 조건은 iOS 17 API `positionedByUser`입니다. 이 방식은 `MapCameraPosition`의 Equatable 여부와 무관합니다.
    - `.pitch`를 빼서 2D로 바꿀 입력 경로를 없앱니다(AC-13).
- **애니메이션(1초 틱 동기)**
  - `.onChange(of: MapSync(status, elapsed))`에서 `withAnimation(map.cameraTarget.animated ? .linear(duration: 1) : nil) { map.sync(...) }`를 부릅니다. 버스 `Annotation` 좌표 이동이 이 트랜잭션으로 애니메이션됩니다.
  - `.onChange(of: map.cameraTarget)`에서 같은 곡선으로 `position = .camera(...)`를 대입합니다.
  - 동작 줄이기면 둘 다 애니메이션이 없습니다(`nil`).
- **내용**
  - `MapPolyline(coordinates:)`로 닫힌 선을 그립니다.
  - `visibleStops`, 도착 표시, 버스는 `Annotation`입니다. 모두 `.accessibilityHidden(true)`이고 `.annotationTitles(.hidden)`입니다.
  - 버스 아이콘 회전 = `bus.headingDegrees − renderedHeading`입니다. `renderedHeading`은 **`.onMapCameraChange(frequency: .onEnd)`**로만 갱신합니다(`.continuous`는 쓰지 않음).
- **스타일**: `.dark`는 `.mapStyle(.standard(elevation: .realistic))`에 지도에만 `.environment(\.colorScheme, .dark)`, `.satellite`는 `.mapStyle(.hybrid(elevation: .realistic))`입니다.
- **컨트롤**: `.mapControls { MapCompass().mapControlVisibility(.hidden); MapPitchToggle().mapControlVisibility(.hidden); MapScaleView().mapControlVisibility(.hidden) }`. `UserAnnotation`, `MapUserLocationButton`, `CLLocationManager`는 쓰지 않습니다.
- **안전 영역(M1)**
  - 지도에는 **`.ignoresSafeArea()`를 걸지 않습니다.** 지도는 ZStack 바닥 레이어로 화면을 채웁니다. MapKit은 지도 그림은 끝까지 그리고, 법적 표기와 컨트롤 배치에만 안전 영역을 씁니다.
  - 지도에 `.safeAreaPadding(.bottom, bottomInfoHeight)`와 `.safeAreaPadding(.top, topBarHeight)`(iOS 17)를 줍니다. 그러면 법적 표기가 하단 정보 위 왼쪽으로 올라갑니다.
  - 높이는 `GeometryReader` + `PreferenceKey`로 잽니다(iOS 17에는 `onGeometryChange`가 없음).
  - 하단 정보는 지도의 `safeAreaInset`이 아니라 **형제 overlay**입니다. 배경은 `.background(.ultraThinMaterial, ignoresSafeAreaEdges: .bottom)`이라 홈 인디케이터 영역까지 덮습니다.
  - 스파이크에서 지도가 위나 아래 안전 영역을 그리지 않는 것으로 나오면 `.ignoresSafeArea(.container, edges: .top)`만 추가합니다. **아래쪽은 절대 무시하지 않습니다.**
- **접근성(M2)**
  - 지도는 `.accessibilityElement(children: .ignore)`로 묶습니다. 라벨 "가상 코스 지도", 값 `mapValue`, 식별자 `journey.map`입니다(AC-33).
  - 이 설정의 결과로 MapKit 내부 요소가 숨겨지면, AC-4는 UI 단언에 의존하지 않습니다. 코드 리뷰 체크리스트와 M-3으로 검증합니다.
  - AC-3은 T0 결정 규칙을 따릅니다(아래 "검증 수단").

#### 7. `JourneyMapThemeSheet.swift` (FR-6, AC-19~21·35·36)
- `ScrollView` 안에 다음을 둡니다.
  - 버튼 `journey.map.theme.dark`, `journey.map.theme.satellite`: `.isSelected` 특성과 값 "선택됨"/"선택 안 됨".
  - 토글 `journey.map.stops`: 값 "켜짐"/"꺼짐".
  - 닫기 `journey.map.themeSheet.close`.
- 모든 컨트롤은 `minHeight: 44` 이상이고, 루트에 `.accessibilityElement(children: .contain).accessibilityIdentifier("journey.map.themeSheet")`를 붙입니다.
- `.presentationDetents([.medium, .large], selection: $detent)`. 초기 detent는 접근성 글자 크기면 `.large`, 아니면 `.medium`입니다.
- **`.presentationBackgroundInteraction(.enabled)`**(detent와 무관)를 둡니다. 큰 글자에서도 시트가 열린 채 일시정지와 DEBUG 시계 버튼을 누를 수 있어야 하기 때문입니다(AC-22·24).
- XCUITest가 Toggle의 `value`를 `"1"/"0"`으로 보고하면 `Button` + `.accessibilityAddTraits(.isToggle)`로 바꿉니다(T0에서 확인).

#### 8. `JourneyTimerView.swift` — 배치 (FR-5·7·10·15, AC-1·2·36~38)
- **현재**: 중앙 VStack에 검은 배경(18-37행), 텍스트 캡슐 버튼(63-79행), `test.timer`(95-108행)가 있습니다.
- **변경**
  - **입력**: `map: JourneyMapController?`를 추가합니다.
  - **분기**: `map == nil`이면 **기존 W05 본문 그대로**(`legacyBody`로 이동, 하단 정보 없음)입니다. 있으면 지도 배치입니다.
  - **지도 배치**: `ZStack { JourneyMapView; topBar(overlay .top); bottomInfo(overlay .bottom) }`
  - **`topBar`**
    - 왼쪽: 일시정지/재개 원형 아이콘 버튼(44pt 이상). 라벨 "일시정지"/"재개", 식별자, `tapGuard`(12-14행)는 유지합니다. 도착이면 같은 자리에 `"도착했어요"`(`journey.arrived`)입니다.
    - 오른쪽: 세로로 `journey.map.follow`(라벨 "버스 따라가기", 값 따라가는 중/자유 탐색 중), `journey.map.theme`(라벨 "지도 테마"). 둘 다 `.disabled(!toolsEnabled)`, `.dynamicTypeSize(...accessibility3)`입니다.
    - 그 아래: notices 배너(`journey.timer.saveFailure`, `saveWarning`)입니다.
  - **`bottomInfo`**: `ViewThatFits(in: .horizontal) { HStack(3열 균등); VStack }`. 라벨이 위, 숫자가 아래입니다.
    - 남은 시간 열은 `children: .ignore`로 묶고 라벨 "타이머", 값 "남은 시간 N분", 식별자 `journey.timer.remaining`, `.accessibilityFocused($remainingFocused)`를 이 열로 옮깁니다. 보이는 텍스트는 `"N min"`입니다.
    - 정류장: `journey.timer.stops`, 거리: `journey.timer.distance`입니다.
  - **시트**: `.sheet(isPresented: Binding(get: state.isThemeSheetPresented, set: { if !$0 { map.dismissThemeSheet() } }))`.
  - **동작 줄이기**: `.onChange(of: reduceMotion) { map.setReduceMotion($1) }`.
  - **DEBUG `test.map`**(스키마는 아래)를 둡니다.

#### 9. `JourneyView.swift` — 생성과 이탈
- `@Environment(\.accessibilityReduceMotion)`를 추가합니다.
- `ensureTimer()`에서 timer를 만든 직후 다음을 만듭니다.
  - `CourseJourney(journey:)`가 성공하면 `JourneyMapController(journey:, status: timer.status, elapsedSeconds: timer.elapsedSeconds, reduceMotion: services.reduceMotion(system: systemReduceMotion))`.
  - **reduceMotion 초기값은 생성자로 넘깁니다.** onAppear에서 반영하지 않습니다.
- `@State map`은 `JourneyScreen` → `JourneyTimerView`로 전달합니다.
- `.onDisappear { timer?.leave(); map?.leave() }`(24행)로 BR-5 이탈 규칙을 연결합니다. 화면을 다시 만들면 `@State`도 새로 만들어지므로 기본값으로 시작합니다(AC-27).

#### 10. `UITestBootstrap.swift` — 시드 정정 (필수, 구 R-6)
- `timerJourney`의 `destinationStopID: "seongdongSportsCenter"`(277행)를 `RouteStops.all[RouteStops.wrap(4 + (-1) * 5)].id`(= `seongsuIntersection`)로 바꿉니다. 리터럴이 아니라 계산식입니다.
- `v3Bytes`(289-300행)는 `timerJourney`에서 파생되므로 v3 시드도 함께 정정됩니다.
- 기존 UI 테스트 중 timer/v3 시드의 도착지 이름을 단언하는 것은 없습니다(검색 확인).

#### 11. `UITestLaunchSupport.swift`
- `mapDiagnostic()`: `test.map` JSON을 읽습니다.
- `dragMap()`: `journey.map` 중앙에서 `press(forDuration: 0.1, thenDragTo:)`합니다(V8 패턴, `JourneyTimerUITests.swift:163-166`).
- `waitForValue(_ id:, _ expected:, timeout:)`: 요소 `value` 폴링입니다(`waitForTimerText` 145-152행과 같은 형태).

---

### 데이터 흐름
```
JourneySnapshot ─ensureTimer─▶ JourneyTimerController (진도·저장 소유, 변경 없음)
     │                               │ status, elapsedSeconds
     └▶ CourseJourney.init? ─nil─▶ JourneyTimerView.legacyBody (W05 화면)
              │ ok
              ▼
      JourneyMapController ◀─ JourneyMapView.onChange(MapSync): withAnimation(linear 1s | nil) { sync }
        ├ JourneyCourseProgress (순수)   ├ JourneyMapState (순수)   └ JourneyCameraPolicy (순수)
              │ bus / cameraTarget(revision)
              ▼
      JourneyMapView: Annotation 이동, position = .camera(...)
      사용자 제스처 → Binding setter(positionedByUser) → userMovedCamera()
      도구·시트 → followTapped / openThemeSheet / select / setShowsStops / dismissThemeSheet
      JourneyView.onDisappear → timer.leave(); map.leave()
```
지도에서 저장으로 가는 경로는 없습니다.

### 검증 수단

**`test.map`(DEBUG)**: 화면에 없는 값만 담습니다.
```json
{"bus":{"lat":0,"lon":0,"from":4,"to":3,"fraction":0.3,"arrived":false},
 "destination":{"index":8,"lat":0,"lon":0},
 "course":[[lat,lon],…],
 "render":{"route":10,"stopMarkers":9,"bus":true,"destination":true},
 "camera":{"lat":0,"lon":0,"heading":0,"pitch":55,"animated":true,"revision":3}}
```

**T0 스파이크 결정 규칙**
- **AC-3**
  - 최종 구성(지도 `children: .ignore`)에서 법적 표기 요소가 트리에 보이면, 그 라벨로 frame 단언 테스트를 자동화합니다.
  - 보이지 않으면 테스트는 **2초 동안 1회 탐색**한 뒤 `XCTContext` 기록을 남기고 통과하며, M-1로 넘깁니다.
- **AC-4**: 항상 코드 리뷰 체크리스트로 검증합니다.
  - `.mapControls`에서 `MapCompass`, `MapPitchToggle`, `MapScaleView` 3종이 `.hidden`인지
  - `interactionModes`에 `.pitch`가 없는지
  - `MapUserLocationButton`이 없는지
  - 여기에 M-3을 더합니다.
- **`children: .ignore`가 Annotation을 숨기지 못하면**: 각 Annotation의 `.accessibilityHidden(true)`로 보강합니다(이미 설계에 포함).
- **W05 `scrollViews.count == 0`이 깨지면**: 단언 의도("스크롤 없이 닿음")를 유지하는 선에서 `journey.map` 하위를 제외하는 쿼리로 바꿉니다. 이 변경은 T11에서 기록합니다.
- **Annotation 좌표가 `withAnimation`으로 움직이지 않으면**: 버스 위치는 틱마다 점프하고 카메라만 애니메이션합니다(R-5).

**자유 탐색 전환**: 실제 드래그 UI 테스트 1개 흐름으로만 검증합니다. DEBUG 훅은 없습니다.

---

### AC 매핑 (AC마다 소유 테스트 1개)

| AC | 소유 | 판정 |
|---|---|---|
| 1 | JourneyMapUITests | 7개 식별자 존재(`timerPaused90` → resume) |
| 2 | JourneyMapUITests | PRD frame 비교식 |
| 3 | JourneyMapAccessibilityUITests | T0 규칙(자동 frame 단언, 또는 2초 탐색 후 기록·통과 + M-1) |
| 4 | 코드 리뷰 체크리스트 + M-3 | UI 단언 없음 |
| 5 | JourneyCourseTests | 9개, `RouteStops` 순서·id, 좌표 존재·서로 다름, 서울 경계 상자, closedPath 닫힘 |
| 6 | JourneyCourseProgressTests | 0/300/750/1500초 → i, i+1, mid(i+2, i+3), i+5 |
| 7 | JourneyCourseProgressTests | 역방향 300/1500초 → i−1, i−5. **출발 i 정방향 150초 vs 출발 i+1 역방향 150초**의 heading 차이 180°(±1e-9) |
| 8 | JourneyCourseProgressTests | 360분: 2700초 → i, 21600초 → 도착, 그 이상 → 도착 고정 |
| 9 | JourneyCourseProgressTests | 버스 3종 × 1초 스윕: 이동 거리 ≤ 최대 선분, 정류장 좌표와 일치하는 것은 `e % sps == 0`일 때만 |
| 10 | JourneyMapControllerTests | 실제 `JourneyTimerController` + `ManualJourneyClock` + `FakeProgressSaver`: pause 뒤 advance해도 위치 불변, resume 뒤 이어짐 |
| 11 | JourneyMapControllerTests | `sync(.arrived, total)`에서 bus.point == destinationStop.point |
| 12 | JourneyMapControllerTests | showsStops on/off 모두 destinationStop 좌표 일치, visibleStops는 9/0 |
| 13 | JourneyMapControllerTests | 초기 follow, `cameraTarget.pitch > 0`(진입 직후 목표로 판정). 입력 경로 없음은 AC-4 체크리스트 |
| 14 | JourneyMapUITests (흐름 A) | resume → advance10 ×3 → 시트 열고 닫기 → follow 값 "따라가는 중" 유지 → `dragMap()` → "자유 탐색 중" |
| 15 | JourneyMapUITests (흐름 A 이어서) | follow 탭 → "따라가는 중", `test.map` camera 중심 == bus |
| 16 | JourneyMapStateTests | follow에서 탭해도 follow |
| 17 | JourneyMapControllerTests | explore에서 sync → bus 바뀜, cameraTarget(revision·center) 그대로 |
| 18 | JourneyMapStateTests | explore → paused → running 뒤에도 explore |
| 19 | JourneyMapUITests | 시트 존재, 3개 컨트롤, dark isSelected, stops "켜짐" |
| 20 | JourneyMapUITests | 위성 isSelected, 다시 dark isSelected |
| 21 | JourneyMapUITests | 토글 "꺼짐" → render.stopMarkers 0, route·bus·destination true → 다시 "켜짐" |
| 22 | JourneyMapUITests | 시트 열림 → pause → 시트 없음, 두 버튼 `isEnabled == false` → resume → true |
| 23 | JourneyMapStateTests | 시트 열림 → leave → 닫힘. `onDisappear` 연결은 코드 리뷰. UI는 W07 |
| 24 | JourneyMapUITests | `timerNearArrival` → resume → 시트 열기 → advance60 → 시트 없음, `journey.arrived`, 두 버튼 활성 |
| 25 | JourneyMapUITests | paused에서 theme `isEnabled == false`, 탭해도 시트 없음 |
| 26 | JourneyMapUITests | 위성·정류장 끔·드래그 뒤 version 4, 저장 바이트에 theme/mapMode/camera/pitch/showsStops 키 없음 |
| 27 | JourneyMapUITests | 위 상태에서 relaunch(`--fm-ui-route journey`) → follow 값, dark 선택됨, stops 켜짐 |
| 28 | JourneyMapUITests | 수동 시계 running에서 드래그와 테마 변경 전후 `persistedBytes` 동일, `test.timer` elapsed·status 동일 |
| 29 | AppInfoLocationTests (키 4종 nil) + JourneyMapUITests의 AC-1 테스트(alert 0개) | 절별로 소유 |
| 30 | JourneyMapControllerTests | reduceMotion on: `cameraTarget.animated == false`, heading 0 |
| 31 | JourneyMapControllerTests | off: `animated == true` |
| 32 | JourneyMapControllerTests | 같은 이벤트 열을 on/off로 실행해 `state` 동일 |
| 33 | JourneyMapAccessibilityUITests | `journey.map` 라벨과 값(다음 정류장·도착 정류장 이름), 정류장 이름 요소 없음 |
| 34 | JourneyMapAccessibilityUITests | 두 버튼 라벨·값, paused에서 isEnabled false |
| 35 | JourneyMapAccessibilityUITests | 선택됨/선택 안 됨, 켜짐/꺼짐 |
| 36 | JourneyMapAccessibilityUITests (AccessibilityXXXL) | hittable, 44×44 이상, 시트 3개 컨트롤 hittable, 하단 3개와 pause frame 비교차 |
| 37 | JourneyMapAccessibilityUITests | `test.timer.focus == "remaining"`, 낭독 1회씩 |
| 38 | 기존 W05 UI 3개 클래스 + JourneyMapAccessibilityUITests의 **AX5 + 저장 경고** 조합 | 아래 T11 |
| 39 | 계산: JourneyCourseProgressTests / 화면: JourneyMapUITests | `timerPaused90`(5정류장, 90/1500초) → "5개", "2.6km". 도착 시드 → "0개", "0.0km" |
| 40 | M-6 | 구조 보장(4번) + AC-38 |

---

### 의존성 및 영향도
- **새 의존성**: MapKit(시스템). 외부 라이브러리는 없습니다.
- **W05 UI 테스트 영향**
  - 중앙 배치를 전제한 frame 단언은 없습니다.
  - `testV7_AC29`(`JourneyTimerAccessibilityUITests.swift:60-82`): `scrollViews.count == 0`은 T0 결과에 따라 처리합니다. pause와 resume은 44pt 원형이라 통과합니다.
  - V8 스와이프(`JourneyTimerUITests.swift:159-172`): 이제 지도가 패닝되어 explore가 되지만 단언에는 영향이 없습니다.
  - `testV7_AC27`·`AC28`: 라벨·값·식별자를 옮기므로 그대로 통과합니다. 지도는 낭독하지 않습니다.
  - 시드 정정은 도착지 이름 단언에 영향이 없습니다.
- **하위 호환**: 저장 형식 v4를 바꾸지 않고, `JourneySnapshot`·`AppModel`도 수정하지 않습니다.
- **단위 테스트 픽스처 주의**: `BoardingFixtures.journey` 기본값(성수, 60분, 2014, seongdongSportsCenter)은 일관됩니다. 하지만 `minutes`만 바꾸면 `CourseJourney.init?`가 nil이 됩니다. 지도 컨트롤러 테스트는 `CourseJourney`를 직접 만들거나 도착지를 맞춰야 합니다.

#### 기존 구조와의 차이 (`context/journey/architecture.md`)
1. 순수 규칙 `JourneyCourse`·`JourneyCourseProgress`·`JourneyMapState`와 `JourneyMapController`가 추가됩니다. 서비스 계층이 아니라 W05의 "컨트롤러 + 순수 규칙" 패턴의 확장입니다. architecture.md 17행 "MapKit … 예정(W06)"을 갱신합니다.
2. **새 규칙**: 저장된 도착지와 계산한 도착지가 다르면 지도를 생략하고 W05 화면으로 대체합니다. W09 도착 안내도 같은 규칙을 쓰도록 문서에 기록합니다.
3. 웹은 SVG 경로 길이를 9등분해 위치를 정합니다(`animation-preview.html:783`). iOS는 정류장 구간별 비율로 보간합니다(BR-2). 구간마다 화면 속도가 다릅니다.
4. 웹 따라가기는 토글(844행)이고 iOS는 항상 복귀입니다. 웹은 동작 줄이기에서 정류장 단위로 점프하고, iOS는 연속 이동입니다. 웹은 테마 변경을 낭독하고 iOS는 낭독하지 않습니다. 웹 위성은 필터 시연이고 iOS는 hybrid입니다. 웹은 따라가기 중 회전하고 iOS는 회전하지 않습니다(FR-17 제외).
5. 하단 남은 거리는 소수 1자리(BR-7)이고 출발 전 화면은 2자리(`JourneyPlanner.swift:34-40`)입니다. 같은 5정류장이 "2.75km"와 "2.8"로 보입니다.

### 설계 가정
- explore에서 축소할 때 MapKit이 pitch를 자동으로 제한하는 것은 허용합니다. AC-13은 진입 직후 목표 pitch로 판정합니다.
- 일시정지/재개는 아이콘 원형 버튼으로 하고 접근성 라벨은 유지합니다. 치수는 디자인 스펙입니다.
- 도착 시 하단 값은 "0"과 "0.0"입니다. 지도 조작은 낭독하지 않습니다.
- pause 저장이 실패하면 status가 running으로 남으므로 시트도 열린 채 남습니다(`JourneyTimerController.swift:84-87`). FR-7의 "일시정지 중" 조건과 모순되지 않습니다.

---

### 구현 순서
1. [Must] **T0 스파이크**: `JourneyMapView` 최소 골격(Map, `children: .ignore`, `safeAreaPadding`, Annotation 1개, mapControls)을 `JourneyTimerView`에 임시로 붙이고, 임시 `JourneyMapSpikeUITests`에서 `app.debugDescription`을 덤프합니다. 확인 항목은 다음과 같습니다.
   - 법적 표기 노출 여부와 라벨
   - 내부 컨트롤과 Annotation이 숨겨지는지
   - `scrollViews.count`
   - 법적 표기가 하단 패딩 위로 올라가는지
   - 지도가 위·아래 안전 영역까지 그려지는지
   - 드래그 시 setter의 `positionedByUser`
   - Annotation 애니메이션
   - Toggle 값

   결과는 `.dev/feat-mapkit-virtual-course/spike-map-a11y.md`에 기록하고, AC-3·Toggle·`scrollViews` 규칙을 확정합니다. 스파이크 테스트는 삭제합니다. (의존: 없음)
2. [Must] **T1 좌표 데이터**: `JourneyCourse.swift`(Apple 지도로 좌표 확인) + `JourneyCourseTests` — AC-5 (의존: 없음)
3. [Must] **T2 진도 → 위치**: `JourneyCourseProgress.swift`, `JourneyMapDisplay.swift` + `JourneyCourseProgressTests` — AC-6~9, 39(계산) (의존: 2)
4. [Must] **T3 상태 머신·카메라 정책**: `JourneyMapState.swift` + `JourneyMapStateTests` — AC-16·18·23 (의존: 2)
5. [Must] **T4 위치 권한 키**: `AppInfoLocationTests` — AC-29(키) (의존: 없음)
6. [Must] **T5 시드 정정**: `UITestBootstrap.swift` 276-277행 (의존: 없음)
7. [Must] **T6 컨트롤러**: `JourneyMapController.swift` + `JourneyMapControllerTests` — AC-10~13·17·30~32 (의존: 3, 4)
8. [Must] **T7 지도 뷰·시트**: `JourneyMapView.swift`(T0 골격 확장), `JourneyMapThemeSheet.swift` (의존: 1, 7)
9. [Must] **T8 화면 통합**: `JourneyTimerView.swift`(legacy 분기, 배치, 하단 정보, 도구, `test.map`), `JourneyView.swift` (의존: 8)
10. [Must] **T9 하네스**: `UITestLaunchSupport.swift` (의존: 9)
11. [Must] **T10 지도 UI 테스트**: `JourneyMapUITests` — AC-1·2·14·15·19~22·24~28·29(UI)·39(화면) (의존: 6, 9, 10)
12. [Must] **T11 접근성과 W05 회귀**: `JourneyMapAccessibilityUITests` — AC-3·33~37, AC-38의 **AX5 + 체크포인트 저장 경고 동시 조합**. 검증 내용은 다음과 같습니다.
    - 경고 배너가 존재하고 pause·도구·하단 3개와 겹치지 않음
    - resume이 hittable이고 44pt 이상

    그리고 기존 `JourneyTimerUITests`, `JourneyTimerLifecycleUITests`, `JourneyTimerAccessibilityUITests` 전체를 실행하고, T0 규칙에 따른 보정만 합니다. (의존: 6, 9, 10)
13. [Must] **T12 문서**: `context/journey/architecture.md`에 W06 반영과 도착지 불일치 규칙 기록 (의존: 9)

병렬 가능: 1·2·5·6은 서로 독립이고, 3과 4는 2 이후 병렬입니다. 11과 12는 파일이 다르지만 동시 빌드 금지 메모에 따라 실행은 순차로 합니다. FR-16(Should)은 별도 태스크가 없습니다. 구조(7)와 M-6으로 검증합니다. FR-17(Could)은 제외합니다.

### 위험
- **R-1 법적 표기와 안전 영역**: 지도가 안전 영역을 어떻게 그리는지와 `safeAreaPadding`이 법적 표기를 옮기는지는 T0 전까지 미확정입니다. 대체 수식어 규칙은 6번에 명시했고, 최종은 M-1·M-4로 확인합니다.
- **R-2 접근성 숨김의 부작용**: `children: .ignore` 때문에 VoiceOver 사용자는 지도를 직접 패닝할 수 없고 법적 표기 링크에도 닿지 못할 수 있습니다. PRD FR-12("하나의 요소")에 따른 의도된 결과이며 M-2에서 확인합니다.
- **R-3 드래그 신뢰성**: XCUITest 드래그가 첫 로딩 중에 무시될 수 있습니다. `journey.map` hittable을 기다린 뒤 드래그하고 `waitForValue`로 폴링합니다. AC-14·15는 이 흐름 하나에만 의존합니다.
- **R-4 시뮬레이터 차이**: `check-ios.py`는 `FOCUSMATE_SIMULATOR_ID`가 없으면 `max(candidates)`로 **가장 최신 iOS 런타임의 Pro(Max 제외)** 기종을 고릅니다(`scripts/check-ios.py:13-28`). 런타임이나 기기를 설치하면 대상이 바뀌어 AC-2·36의 frame 결과가 달라질 수 있습니다. UI 테스트 실행은 `FOCUSMATE_SIMULATOR_ID` 고정을 권고합니다.
  - 기준 기기(약 874pt)에서 `pause.midY`는 약 140으로 `0.2H` 약 175 안에 들어옵니다(상단에 DEBUG 시계 줄 44pt 포함).
- **R-5 애니메이션 부담**: 1초마다 카메라와 Annotation을 linear 1초로 계속 애니메이션하면 배터리와 GPU 부담이 있습니다. W14 실기기에서 확인합니다. Annotation 애니메이션이 안 되면 버스는 틱마다 점프합니다(QE-1 체감은 W14에서 확인).
- **R-6 도착지 불일치 시 대체**: 손상되었거나 과거 형식인 여정은 지도 없이 W05 화면으로 보입니다. 정상 경로(`JourneySnapshot.boarding`)에서는 생기지 않습니다. 시드는 T5에서 정정합니다.
- **R-7 Toggle 값**: XCUITest가 `"1"/"0"`을 보고하면 `Button` + `.isToggle`로 바꿉니다(T0에서 결정).
- **R-8 어두운 지도 표현**: 지도에만 `colorScheme` dark를 주는 방식의 효과는 M-5에서 확인합니다.
- **R-9 AC-23 UI 경로 없음**: W06에는 나가기 수단이 없습니다(`AppModel.swift:270-275`). 단위 테스트와 `onDisappear` 연결 리뷰로 검증하고, UI 검증은 W07에서 추가합니다.

---

## Testability 평가 (test-architect)

설계서 r1, PRD 수용 기준, 코드 맵, 프론트 테스트 규약 §2·§4를 근거로 평가했습니다. 다음 코드도 직접 확인했습니다: `scripts/check-ios.py`, `UITestBootstrap.swift:229-286`, `JourneyTimerController.swift:1-100`, `UITestLaunchSupport.swift`, `JourneyView.swift:145-152`, `project.pbxproj`.

공통 러너는 `python3 scripts/check-ios.py test <파일>`입니다. 단위 테스트는 `FocusMateTests`이고 앱 호스트형입니다(`TEST_HOST` 지정, 그래서 `Bundle.main`이 앱입니다). UI 테스트는 `FocusMateUITests`입니다. 아래 동작 컴포넌트는 모두 러너가 있습니다.

셀렉터는 프로젝트 기존 규약을 따르는 것이 맞습니다. 기존 규약은 `accessibilityIdentifier`(웹의 data-testid에 해당)에 접근성 라벨·값 단언을 더하는 방식이고, §4에 따르면 프로젝트 컨벤션이 우선합니다.

### 컴포넌트별 테스트 전략

#### JourneyCourse (코스 데이터)
- 레이어: 동작 (순수 규칙·데이터, §2 "순수 유틸")
- 러너: `check-ios.py test ios/FocusMateTests/JourneyCourseTests.swift`
- 단위 테스트: 확인할 것은 다섯 가지입니다. 정류장 9개, id 순서가 `RouteStops.all`과 같음, 좌표가 서로 모두 다름, 위경도 범위, `closedPath`가 10점이고 마지막 점이 첫 점과 같음.
- 통합 테스트: 불필요
- 모의 대상: 없음. `CoursePoint` 자체 타입이라 CoreLocation 없이 돕니다.
- 격리 전략: 정적 상수만 씁니다. `preconditionFailure` 경로는 좌표 표가 완전하면 실행되지 않으므로 테스트하지 않습니다(크래시 테스트 불가).
- AC 매핑: AC-5

#### JourneyCourseProgress (진도 → 위치·남은 값)
- 레이어: 동작 (순수 함수)
- 러너: `check-ios.py test ios/FocusMateTests/JourneyCourseProgressTests.swift`
- 단위 테스트
  - 정수 초를 입력하는 표 기반 테스트입니다. 0, 300, 750, 1500초와 역방향, 360분(2700초, 21600초, 30000초)을 다룹니다.
  - AC-9: 버스 3종 × 전체 구간을 1초 단위로 훑습니다. 최대 21600 × 3 반복이라 빠릅니다.
  - AC-39: 공식을 비교합니다.
  - 판정은 `JourneyCourse.point(at:)`와의 일치로 합니다. 좌표 상수를 쓰지 않습니다.
- 통합 테스트: 불필요
- 모의 대상: 없음
- 격리 전략: `CourseJourney`를 직접 만듭니다. 스냅샷 경로는 `init?(journey:)` 케이스 1~2건만 둡니다. 기존 `BoardingFixtures.journey(...)`를 재사용합니다.
- AC 매핑: AC-6, 7, 8, 9, 11(계산), 39(계산)
- 주의: AC-7의 heading 판정 대상이 모호합니다.
  - AC 문면대로 "같은 출발 i에서 정·역방향"을 비교하면 두 선분이 서로 다릅니다(i→i+1과 i→i-1). 그래서 정확히 180°가 나오지 않습니다.
  - 설계가 말하는 "같은 선분을 반대로 가면 180°"를 검증하려면 출발을 i+1로 둔 역방향 여정을 별도로 만들어야 합니다.
  - red 단계에서 비교 쌍을 명시해야 합니다.

#### JourneyMapState / JourneyCameraPolicy / JourneyMapRenderModel
- 레이어: 동작 (값 타입 상태 머신과 순수 정책)
- 러너: `check-ios.py test ios/FocusMateTests/JourneyMapStateTests.swift`
- 단위 테스트
  - 이벤트 열을 적용한 뒤 `Equatable` 상태를 비교합니다.
  - 덮을 전이: 초기값, `userMovedCamera`, `followTapped`(follow 유지, 비활성 시 무시), `openThemeSheet` 가드, `timerStatusChanged`(.paused/.arrived는 시트를 닫고 모드는 유지), `leave`
  - AC-32: 같은 이벤트 열을 상태에 넣으면 reduceMotion이 상태에 없으므로 같은 결과가 나옵니다. 더 의미 있는 단언은 `CameraPolicy.target`의 on/off 비교입니다. on/off 간에는 `animated`와 heading만 다르고 center·pitch·distance는 같아야 합니다.
  - RenderModel: showsStops on/off 각각에서 정류장 표시 9/0개, route 10개, bus·destination 존재, destination 좌표 일치를 봅니다.
- 통합 테스트: 불필요
- 모의 대상: 없음
- 격리 전략: 순수 값입니다. `JourneyTimerController.Status`는 중첩 enum이라 actor 격리 없이 쓸 수 있습니다(Swift 5, minimal concurrency).
- AC 매핑: AC-12, 13, 14(앱 갱신은 explore로 바뀌지 않음), 16, 18~25(전이), 30, 31, 32

#### JourneyMapController
- 레이어: 동작 (상태 연결부)
- 러너: `check-ios.py test ios/FocusMateTests/JourneyMapControllerTests.swift`
- 단위 테스트
  - 순수 값만 넣고 `sync(status:elapsedSeconds:)`를 호출합니다.
  - 확인할 것: follow에서는 `cameraTarget.revision`이 증가함, explore에서는 revision과 center가 변하지 않음(AC-17), `followTapped` 후 center가 bus 위치와 같음(AC-15), `setReduceMotion`이 다음 목표에 반영됨, 생성 직후 기본값(AC-27)
- 통합 테스트
  - 실제 `JourneyTimerController`, `ManualJourneyClock`, `FakeProgressSaver`를 묶은 Rig를 씁니다(`JourneyTimerControllerTests.swift:12-49` 패턴).
  - 흐름: 진행 → pause → advance → 위치 불변 → resume → 이어짐(AC-10)
  - 지도 조작 전후 `FakeProgressSaver` 기록 수가 같아야 합니다(AC-28). 지도 컨트롤러에 저장자가 없으므로 이 단언은 구조적으로 참입니다.
- 모의 대상: 시계와 저장자뿐이고 기존 더블을 그대로 씁니다.
- 격리 전략: 생성자 주입이고 MapKit에 의존하지 않습니다. `@MainActor` 테스트 클래스로 둡니다.
- AC 매핑: AC-10, 11, 12, 15, 17, 22·24(연동), 27(기본값), 28

#### JourneyMapDisplay
- 레이어: 동작 (문구 포맷터)
- 러너: `check-ios.py test ios/FocusMateTests/JourneyCourseProgressTests.swift`(설계상 같은 파일). 별도 `JourneyMapDisplayTests.swift`로 분리할 것을 권합니다(기존 `JourneyTimerDisplayTests` 대칭).
- 단위 테스트: `distanceText`(도착 "0.0", 반올림 경계 x.x5), `mapValue`, `followValue`, `selectedValue`, `switchValue`
- 통합 테스트: UI에서 `journey.timer.stops`, `journey.timer.distance` 값이 진단 값과 같은지 봅니다.
- 모의 대상: 없음
- 격리 전략: static 순수 함수
- AC 매핑: AC-33~35(문구), 39

#### JourneyMapView (SwiftUI Map 글루)
- 레이어: 동작 (얇은 글루). 마커 모양, 선 색, 다크 색감, pitch 값은 표현이라 범위 밖입니다.
- 러너: `check-ios.py test ios/FocusMateUITests/JourneyMapUITests.swift`
- 단위 테스트: 불가합니다. `positionedByUser` 감지, `onChange(cameraTarget)` 적용, `mapControls` 숨김은 MapKit 런타임이 있어야 합니다. 그래서 판단 로직은 Controller/State로 이미 빼냈고, 이 판단은 적절합니다.
- 통합 테스트 (XCUITest)
  - 실제 드래그로 explore 전환을 봅니다(AC-14).
  - `journey.map`의 라벨·값을 봅니다(AC-33).
  - blankMap 분기를 봅니다(AC-40).
- 모의 대상: 지도 타일 로딩. DEBUG `--fm-ui-map blank`로 대체 렌더를 띄웁니다.
- 격리 전략: 두 가지입니다.
  - DEBUG `test.map.userPan` 훅으로 전환 이후 시나리오를 드래그와 분리합니다.
  - 수동 시계라서 실시간 틱이 없고, 카메라 목표가 테스트 중에 저절로 바뀌지 않습니다.
- AC 매핑: AC-1, 4, 13(일부), 14, 29(UI 측), 33, 40
- 공허 통과 위험: AC-4와 AC-29의 UI 측 단언은 의미가 거의 없습니다.
  - 지도를 `.accessibilityElement(children: .ignore)`로 묶으면 MapKit 내부의 나침반, 2D/3D, 사용자 위치 요소가 접근성 트리에서 원래 사라집니다.
  - 그래서 "식별자 없음" 단언은 구현과 무관하게 항상 통과합니다.
  - AC-4는 코드 리뷰 체크(`.mapControls`의 `.hidden`, `interactionModes`에 `.pitch` 없음)와 M-항목으로 보완하고, 이 사실을 trust-ledger에 기록해야 합니다.

#### JourneyMapThemeSheet
- 레이어: 동작
- 러너: `check-ios.py test ios/FocusMateUITests/JourneyMapUITests.swift`, `.../JourneyMapAccessibilityUITests.swift`
- 단위 테스트: 상태 쪽은 StateTests로 대체합니다. 시트 뷰 자체는 해당 없음입니다.
- 통합 테스트 (XCUITest)
  - 확인할 것: `journey.map.themeSheet` 존재, dark/satellite 버튼의 `isSelected` 특성과 값, Toggle 값, 닫기
  - 시트가 열린 상태에서 배경의 pause와 `test.clock.advance60`을 탭합니다(AC-22, 24).
- 모의 대상: 없음
- 격리 전략: 시드와 수동 시계
- AC 매핑: AC-19, 20, 21, 22, 24, 25, 35, 36

#### JourneyTimerView (배치·하단 정보·도구·진단)
- 레이어: 동작. PRD가 AC-2의 frame 비교를 계약으로 정했습니다. 화면을 반으로 나눈 비교 수준이라 §3의 픽셀 단언에는 해당하지 않습니다. 글자 크기와 색은 표현이라 범위 밖입니다.
- 러너: `check-ios.py test ios/FocusMateUITests/JourneyMapUITests.swift`. 회귀는 `JourneyTimerUITests`, `JourneyTimerLifecycleUITests`, `JourneyTimerAccessibilityUITests`로 봅니다.
- 단위 테스트: 해당 없음. 로직은 Controller와 Display에 있습니다.
- 통합 테스트: 식별자 7종 존재, frame 비교식, 도구 `isEnabled`, 하단 값과 진단의 일치, AX 크기에서 hittable·44pt·겹침 없음, W05 회귀
- 모의 대상: 시계(수동), 저장 실패(`failNextSave`), reduceMotion(`--fm-ui-reduce-motion`)
- 격리 전략: `launchJourney(seed:)`와 기존 시드
- AC 매핑: AC-1, 2, 3, 26, 28(UI), 30·31(UI), 34, 36, 37, 38, 39(화면)

#### JourneyView (생성·이탈 연결)
- 레이어: 동작
- 러너: UI 테스트로만 간접 검증합니다(`JourneyMapUITests`).
- 단위 테스트: 없음. `leave()` 의미는 State·Controller 단위 테스트로 대체합니다.
- 통합 테스트: 진입 시 기본값만 확인 가능합니다. 이탈 경로가 없으므로 `onDisappear → map.leave()` 연결은 UI로 검증할 수 없습니다(R-5).
- 모의 대상: 없음
- 격리 전략: 해당 없음
- AC 매핑: AC-23(단위만), AC-27
- AC-27의 UI 검증도 약합니다. relaunch는 프로세스를 새로 띄우므로 기본값이 항상 나옵니다. 같은 프로세스 안에서 나갔다가 다시 들어오는 경로는 W07 이전에는 없습니다. 실질적 증거는 단위 테스트(init 기본값)와 "상태가 `@State`에만 있다"는 구조입니다.

#### DEBUG 장치 (JourneyServices.blankMap, UITestBootstrap `--fm-ui-map`, UITestLaunchSupport 도우미)
- 레이어: 동작 (테스트 하네스)
- 러너: UI 테스트로 간접 검증합니다. 잘못된 인자 처리는 기존 `HarnessUITests` 패턴으로 1건 추가할 수 있습니다.
- 단위·통합·모의·격리: 하네스 자체이므로 해당 없음
- AC 매핑: AC-40과 UI 전반의 기반

#### AppInfo (위치 키 부재)
- 레이어: 동작
- 러너: `check-ios.py test ios/FocusMateTests/AppInfoLocationTests.swift`. 호스트형이라 `Bundle.main`이 앱 번들입니다.
- 단위 테스트: `NSLocation*UsageDescription` 4종이 모두 nil이어야 합니다.
- 통합 테스트: 여행 화면에서 `app.alerts.count == 0`, springboard 권한 알림 없음
- 모의 대상: 없음
- 격리 전략: 해당 없음
- AC 매핑: AC-29

#### 표현 (범위 밖)
범위 밖인 표현 요소는 마커와 버스 아이콘 모양, 코스 선 색·굵기, 어두운 지도와 위성의 실제 색감(M-5), pitch와 distance의 구체 값, 카메라 애니메이션 곡선, 하단 정보 글자 크기·색, 실제 픽셀 렌더(M-7)입니다.

### Testability Score: 8/10

점수를 올린 근거
- 판단 로직이 전부 Foundation 수준의 순수 타입에 있어 MapKit 없이 단위 테스트할 수 있습니다. 대상은 Course, Progress, State, CameraPolicy, RenderModel, Display입니다.
- Controller는 생성자 주입이고 저장자 의존이 없어 BR-6을 구조로 보장합니다.
- 진도 계산은 정수 산술이라 AC-6의 "정확히 중간"과 AC-9의 "배수 시점"을 오차 허용 없이 판정할 수 있습니다.
- 수동 시계, DEBUG 진단, blank 지도, userPan 훅까지 테스트 장치가 갖춰져 있습니다.

점수를 깎은 근거
- AC-14의 핵심(`positionedByUser`)은 실제 드래그 XCUITest로만 검증되고, API 성질(R-1)도 미확정입니다.
- AC-3, AC-4, AC-27, AC-29의 UI 측 단언은 공허하게 통과하거나 수동 확인으로 대체될 가능성이 높습니다.
- AC-23의 UI 검증 경로가 없습니다.

### 판정

PASS (8 ≥ 7). 설계를 확정하고 red-green-refactor에 진입할 수 있습니다. 재설계는 필요 없습니다. red 단계에 들어가기 전에 아래 정정을 반영할 것을 권합니다.

1. **AC-7 heading 비교 쌍 명시**: 같은 선분을 반대로 지나는 두 여정(출발 i 정방향 vs 출발 i+1 역방향)으로 180°를 단언합니다. AC 문면의 "같은 i"를 그대로 쓰면 정확히 180°를 단언할 수 없습니다.
2. **R-6 시드 정정 선행**: `timerPaused90` 계열 시드의 `destinationStopID`를 `seongsuIntersection`으로 바꿉니다(`UITestBootstrap.swift:277`). UI 테스트에서 `seongdongSportsCenter`를 단언하는 곳은 없습니다(grep 확인). `JourneySnapshotV4StorageTests`의 기본값은 별도 픽스처라 영향이 없습니다. 정정하지 않으면 AC-33 값과 출발 안내의 도착지 이름이 서로 다르게 보입니다.
3. **사용자 관찰 값 우선 판정 (§4)**
   - 모드는 진단 `mode`보다 `journey.map.follow`의 접근성 값("따라가는 중"/"자유 탐색 중")으로 먼저 판정합니다.
   - 테마는 `isSelected` 특성으로, 정류장 표시는 Toggle 값으로 판정합니다.
   - `test.map` 진단은 화면에 노출되지 않는 값(render 개수, camera 목표, 좌표)에만 씁니다. 진단만으로 판정하면 내부 상태에 결합됩니다.
4. **AC-4, 29의 공허 통과 기록**: UI 단언과 별도로 리뷰 체크리스트에 두 항목을 넣고 trust-ledger에 남깁니다. 하나는 `.mapControls`의 `.hidden` 3종, 다른 하나는 `interactionModes`에 `.pitch`가 없는지입니다.
5. **R-4 서술 정정**: `check-ios.py`는 "처음 사용 가능한 기기"가 아니라 `max((iOS 버전, Pro이면서 Max 아님, 이름, udid))`로 기기를 고릅니다(24-28행). 보통 최신 Pro 6.1~6.3인치가 잡히지만, 설치된 런타임에 따라 달라집니다. AC-2와 AC-36 실행에는 `FOCUSMATE_SIMULATOR_ID`로 기기를 고정할 것을 권합니다.

### XCUITest 신뢰성 위험과 flaky 방지

- **지도 드래그 (AC-14)**
  - 위험: 첫 타일 로딩 중이나 카메라 애니메이션 도중의 드래그는 무시될 수 있습니다.
  - 드래그 전에 `journey.map`이 hittable이 될 때까지 기다리고, 수동 시계로 진행을 멈춘 상태에서 드래그합니다. 이 상태에서는 follow 목표가 갱신되지 않습니다.
  - `coordinate(withNormalizedOffset:)`로 드래그합니다. 시작점은 중앙(0.5, 0.45), 끝점은 (0.75, 0.7)이고, 0.1초 누른 뒤 끕니다. 시작점은 상단 바와 하단 정보를 피해야 합니다.
  - 판정은 폴링(`waitForMap` 또는 follow 버튼 값)으로 합니다. 재시도는 AC-14 한 건만 1회 허용합니다.
- **시트 배경 상호작용 (AC-22, 24)**
  - `.presentationBackgroundInteraction(.enabled(upThrough: .medium))`은 medium detent에서만 유효합니다.
  - AX 크기에서는 `.large` detent가 되어 배경 탭이 막힙니다. 그래서 AC-22와 AC-24는 기본 글자 크기에서만 실행해야 합니다.
  - 배경 탭 전에 `element.isHittable`을 먼저 단언합니다. 그래야 실패했을 때 "배경 입력 차단"이라는 원인이 바로 드러납니다.
  - `test.clock.advance60`은 상단 safeAreaInset에 있어 medium 시트에 가려지지 않습니다.
- **Toggle 값 (AC-21, 35)**
  - 위험: XCUITest가 Toggle 값을 `"1"`/`"0"`으로 보고할 수 있습니다(R-7).
  - 첫 red 테스트에서 실제 보고 값을 먼저 확인하고, 실패하면 설계상 대안인 `Button` + `.isToggle`로 즉시 바꿉니다.
  - 탭은 `switches["journey.map.stops"]`가 아니라 식별자로 찾은 요소의 중앙을 탭합니다. iOS 17의 SwiftUI Toggle은 라벨 영역을 탭해도 전환되지 않는 경우가 있습니다.
- **법적 표기 탐색 (AC-3)**
  - `children: .ignore`로 묶으면 표기가 접근성 트리에서 거의 확실히 사라집니다.
  - 탐색은 `app.descendants(matching: .any)`에서 라벨이 "Legal" 또는 "법적"을 포함하는 요소를 2초 안에 1회만 찾습니다.
  - 못 찾으면 `XCTContext`에 기록하고 `XCTSkip`이 아니라 통과 처리한 뒤 M-1로 넘깁니다. 무한 대기나 재시도는 금지합니다.
- **기타**
  - `test.map` JSON은 매 틱마다 갱신되므로 단언 직전에 다시 읽습니다. 값 하나로 판정하려면 폴링 도우미를 씁니다.
  - AC-28의 `persistedBytes` 비교는 조작 전후 사이에 시계를 진행하지 말아야 합니다. 진행하면 10초 체크포인트 저장이 섞입니다(`JourneyTimerController.swift:76`).
  - W05 `testV7_AC29`의 `scrollViews.count == 0`는 지도 도입 뒤 가장 먼저 깨질 수 있는 회귀 지점입니다. T11 착수 전에 단독으로 실행해 확인합니다.

> 1회차 설계 기준 평가(8/10 PASS). 2회차는 이 평가의 권고 1~5(AC-7 비교 쌍, 시드 정정, 사용자 관찰 값 우선, AC-4·29 공허 통과 기록, 시뮬레이터 고정)와 design-critic MUST-ADDRESS 2건을 반영했고 DEBUG 훅(blankMap·userPan)을 제거했다. 판단 로직의 순수 타입 분리는 그대로라 점수 근거가 유지된다.

## T0 스파이크 반영 (구현 확정 규칙 — spike-map-a11y.md)

- 지도 내부(MapKit 요소)는 `children: .ignore`로도 XCUITest 트리에서 숨겨지지 않는다. AC-4는 UI 단언(나침반·2D/3D·스케일·사용자 위치 버튼 요소 없음)을 쓰되 코드 리뷰 체크리스트를 병행한다.
- 지도 스타일은 dark·satellite 모두 `pointsOfInterest: .excludingAll`(실제 POI 숨김, BR-1). dark = `.standard(elevation: .realistic, pointsOfInterest: .excludingAll)` + colorScheme dark, satellite = `.hybrid(elevation: .realistic, pointsOfInterest: .excludingAll)`.
- 정류장·도착·버스 Annotation 제목은 빈 문자열이고 정류장 이름 텍스트를 그리지 않는다. AC-33 "개별 정류장 미노출"은 "정류장 이름(RouteStops 이름 9개)을 라벨로 가진 요소가 `journey.map` 하위에 없다"로 판정한다(POI 제외 후).
- AC-3 자동화: `app.links["Legal"]` frame이 남은 시간 위(maxY ≤ remaining.minY), 왼쪽 절반(midX < W/2), 하단 정보·도구·일시정지와 비교차. 찾지 못하면 2초 1회 탐색 후 기록·통과 + M-1.
- 안전 영역: Map에 `.ignoresSafeArea` 없음(지도는 전체 화면을 그림), `.safeAreaPadding(.bottom, 하단 정보 높이)`로 법적 표기를 하단 정보 위로 올림.
- 정류장 표시 컨트롤은 `Toggle`이 아니라 `Button` + `.accessibilityAddTraits(.isToggle)` + 값 "켜짐/꺼짐"(식별자 `journey.map.stops`).
- 시트 `.presentationBackgroundInteraction(.enabled)` 상태에서 배경 일시정지/재개가 hittable(확인).
- 사용자 드래그: `press(forDuration: 0.1, thenDragTo:)`가 커스텀 Binding setter의 `positionedByUser == true`를 일으킨다(확인).
- W05 `scrollViews.count == 0` 유지(확인).

## 리뷰 반영 메모 (phase-review R1)

- 위 Testability 평가(1회차 기준)의 `blankMap`·`--fm-ui-map blank`·`userPan` 언급은 2회차에서 제거된 장치다. AC-40은 M-6 수동 확인으로 대체했고 코드에 해당 인자가 없다.
- 외부로 나가는 정보: Apple 지도 타일 요청 시 Apple에 전달되는 것은 기기 IP와 보고 있는 지도 영역(가상 코스 주변 또는 사용자가 이동한 영역)뿐이다. 사용자 위치·권한은 쓰지 않는다(FR-14). 앱스토어 개인정보 라벨 작성(W14) 근거.
