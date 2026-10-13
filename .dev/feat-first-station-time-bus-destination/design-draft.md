# 설계 초안: 첫 출발지 선택과 시간·버스·도착지 선택 (iOS, W02)

## 설계 규모
**대형.** 새 화면 2개, 운영 코드에서 처음으로 저장을 호출하는 경로, 네비게이션 목적지 추가, 처음 만드는 네이티브 여정 도메인 로직이 함께 들어갑니다.

## 배경 및 목적
- 웹 프로토타입에 있는 첫 출발지 검색(`search`)과 시간·여정 선택(`time`)을 iOS로 옮깁니다. 지금 iOS에는 두 화면이 없고, "최초 정류장 설정"은 제목만 있는 자리표시 화면입니다(`RootView.swift:57-59`).
- 목표: 처음 쓰는 사용자가 출발 정류장을 한 번 고르고, 곧바로 "몇 분 동안, 어떤 버스로, 어디까지 갈지" 정한 뒤 준비 단계로 넘어갑니다.
- 앱이 운영 코드에서 저장을 처음 호출하는 작업입니다. W00이 넘긴 "저장 갱신 경로"(`.dev/feat-domain-storage-schema-v2/design.md:267`)를 여기서 정합니다.

## 요구사항 및 수용 기준
PRD(`/Users/bonseung/Documents/ChatGPT/new-w02/.dev/feat-first-station-time-bus-destination/prd.md`)의 항목을 그대로 씁니다.
- 기능 요구사항: FR-1~FR-12 (모두 [Must])
- 비즈니스 규칙: BR-1~BR-5는 [Must], BR-6은 [Should]
- 품질 기대: QE-1, QE-2 ([Should])
- 수용 기준: AC-1~AC-26

이 설계에서는 각 AC가 어디서 검증되는지만 아래 "테스트 전략" 표에 연결합니다.

## 변경 범위

**영향 모듈:** `ios/FocusMate` (도메인, 상태, 화면), `ios/FocusMateTests`, `ios/FocusMateUITests`

**신규 파일**
| 경로 | 역할 |
|---|---|
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/RouteData.swift` | 9개 순환 정류장(`RouteStops`), 정류장 카탈로그 3건(`StationCatalog`), 버스 3종(`BusLine`). 순수 값 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/JourneyPlanner.swift` | 후보 계산, 도착지 순환, 거리 표기, 시간 범위. 순수 함수 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/StationSearchState.swift` | 검색 화면 상태(검색어, 선택). 값 타입 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/JourneyPlanDraft.swift` | 시간 선택 화면 상태(분, 후보 선택, 진행 버튼 상태). 값 타입 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/AppModel+JourneyStart.swift` | `AppModel` extension: 첫 출발지 저장, 출발 위치, 준비로 진행 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/InitialStationSearchView.swift` | 검색 화면 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/TimeSelectionView.swift` | 시간 선택 화면 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/DestinationScreen.swift` | `navigationDestination` 본문(기존 자리표시 이전 + time 분기 + preparation DEBUG 진단) |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/MotionPolicy.swift` | "동작 줄이기"일 때 애니메이션 없이 화면을 바꾸는 헬퍼 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/StationCatalogTests.swift` | 검색 규칙 단위 테스트 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/JourneyPlannerTests.swift` | 후보·도착지·거리 단위 테스트 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/JourneyPlanDraftTests.swift` | 시간·선택 해제·진행 상태 단위 테스트 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/JourneyStartModelTests.swift` | AppModel 저장·네비게이션 단위 테스트 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateUITests/FirstStationTimeFlowTests.swift` | 두 화면 UI 테스트 |

**수정 파일** (W01과 겹칠 가능성을 줄이려고 줄 수를 최소로 잡았습니다)
| 경로 | 바뀌는 줄 |
|---|---|
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/AppModel.swift` | `Destination`에 `case time`을 추가하고 `title`에 1줄(:6, :9 근처). 저장 프로퍼티 `journeyPlan` 1줄(:22 근처). 모두 3줄 안팎 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/RootView.swift` | :58-59 자리표시를 검색 화면으로 교체(`case` 줄 :57은 그대로 둠). :67-68 메뉴 목록과 열 목적지 교체. :25-32를 `DestinationScreen(...)` 한 줄로 교체 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/UITestBootstrap.swift` | :48-49 저장 실패 시나리오의 guard를 "메인일 때만 실패 저장을 일으키고, 다른 진입 상태에서는 그냥 넘어감"으로 변경 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateUITests/Phase1FlowTests.swift` | :50, :166 "여행 준비" 행의 기대 화면이 `screen.preparation`에서 `screen.time`으로 바뀝니다. 버튼 수를 세는 테스트(:161-186)에서는 "여행 준비" 행을 제외합니다 |

## 적용 컨벤션
- 문서: 별도 CLAUDE.md나 컨벤션 파일은 없습니다. 아래는 기존 코드에서 배운 내용입니다.
- 네이밍: 타입은 UpperCamelCase, 접근성 식별자는 `screen.xxx`, `open.xxx`, `영역.요소` 형식입니다(`RootView.swift:27, 63, 69`). 테스트 파일 이름과 클래스 이름은 같아야 합니다(`scripts/check-ios.py:39`).
- 상태
  - `AppModel`은 `@MainActor @Observable`입니다. 바깥에서 쓰지 못하는 값은 `private(set)`으로 둡니다(`AppModel.swift:17-22`).
  - 스냅샷은 `private init`으로 막혀 있고 `updating…`으로만 바꿉니다(`AppSnapshot.swift:24-50`).
- 화면: `RootView`는 `launchState`의 `switch`로 진입 화면을 나눕니다. 다크 모드 고정, `.padding(24)`, 제목은 `.largeTitle.bold()`입니다.
- 오류: `save`는 `Bool`을 돌려주고 `saveFailure`에 실패 원인을 남깁니다(`AppModel.swift:43-59`).
- 테스트
  - 저장소에는 클로저를 주입합니다(`AppFoundationTests.swift:259-306`). 상태는 `stage(...)` 헬퍼로 만듭니다(`StorageTestSupport.swift:7`).
  - UI 테스트는 `--fm-ui-test-id`, `--fm-ui-seed`, `--fm-ui-save`로 시작하고, `test.snapshot`과 `test.persistedBytes`로 확인합니다.

## 상세 설계

### 판단 1. 도메인 로직과 화면 상태를 분리

**결정**
- 계산 규칙은 SwiftUI와 저장을 모르는 순수 값과 함수로 둡니다(`RouteData.swift`, `JourneyPlanner.swift`).
- 화면 상태는 View 밖의 **값 타입 struct**로 둡니다(`StationSearchState`, `JourneyPlanDraft`).
- View는 상태를 그리고 사용자 조작을 상태 함수로 넘기기만 합니다. 이렇게 하면 AC 대부분이 시뮬레이터 없이 XCTest로 검증됩니다.

**1) `RouteData.swift` (신규)**
- 현재: 웹 `stopNames`(:788), `stationCatalog`(:670), `busOptions`(:642)에만 있습니다.
- 변경 내용
  - 9개 순환 정류장에 각각 고정 id를 줍니다.
  - 카탈로그 3건은 "순환 정류장 index + 방향 + 별칭"으로 정의합니다.
  - 방면 문구는 웹 `stationBound`(:647)처럼 `RouteStops[wrap(index + 방향)] + " 방면"`으로 만듭니다.

```swift
struct StopPosition: Equatable, Hashable { let index: Int; let direction: Int }   // index 0..<9, direction 1|-1

enum RouteStops {
    static let all: [(id: String, name: String)]          // 9건, 순서 = 순환 순서
    static func wrap(_ offset: Int) -> Int                 // ((v % 9) + 9) % 9
    static func name(at index: Int) -> String
    static func boundLabel(from position: StopPosition) -> String   // "성수동 방면"
    static func position(of station: StationSnapshot) -> StopPosition?
}

struct StationOption: Identifiable, Equatable {
    let id: String               // "seongsu:1" 형식(목록 식별용)
    let stopID: String           // 저장되는 StationSnapshot.id
    let position: StopPosition
    let name: String
    let aliases: [String]
    var boundLabel: String { get }
    var snapshot: StationSnapshot { get }   // (stopID, name, direction)
}
enum StationCatalog {
    static let all: [StationOption]                     // 성수역 정·역방향, 서울숲역 정방향
    static func search(_ query: String) -> [StationOption]
}

struct BusLine: Identifiable, Equatable {
    let id: String               // 내부 코드 "2014" | "302" | "421"
    let number: String           // "2014" | "강남02" | "343"
    let kind: String             // "지선" | "마을" | "간선"
    let minutesPerStop: Int      // 5 | 6 | 8
    static let all: [BusLine]    // PRD 나열 순서: 2014, 강남02, 343
}
```

- 검색 규칙
  - 검색어는 앞뒤 공백을 지우고 소문자로 바꿉니다. 비어 있으면 전체를 돌려줍니다.
  - 그렇지 않으면 이름, 별칭 각각, 방면 문구 중 하나라도 부분 일치하면 결과에 넣습니다.
  - 웹은 세 문구를 공백으로 이어 붙여 검색합니다(:671). 여기서는 필드마다 따로 봅니다. 그래서 "역 성"처럼 두 필드에 걸친 검색어는 맞지 않습니다. 이 점은 아래 "기존 구조와의 차이"에 적었습니다.
- 별칭은 웹 값을 그대로 씁니다.
  - 성수역 정방향: "성수", "서울숲"
  - 성수역 역방향: "성수", "건대"
  - 서울숲역: "서울숲", "성수"

**2) `JourneyPlanner.swift` (신규)**
- 현재: 웹 `timeJourneyOptions`(:856)에만 있습니다.
- 변경 내용
  - 분이 15~360 밖이면 빈 배열을 돌려줍니다.
  - 그 안이면 `minutes % minutesPerStop == 0`인 버스만 후보로 만듭니다.
  - 도착지는 `RouteStops.wrap(origin.index + origin.direction * stops)`로 구합니다.
  - 거리는 부동소수점을 쓰지 않습니다. 0.01km 단위 정수 `stops * 55`로 계산하고 표기도 정수 연산으로 만듭니다. 그래서 2.75, 5.5, 11처럼 끝의 0이 빠진 문자열이 항상 같은 결과로 나옵니다.

```swift
struct JourneyCandidate: Identifiable, Equatable {
    let bus: BusLine
    let minutes: Int
    let stops: Int
    let destination: String
    var id: String { bus.id }
    var distanceText: String { get }          // "6.6km"
    var accessibilityLabel: String { get }    // "지선 2014번, 성동구민체육센터, 60분, 12정류장"
}
struct JourneySelection: Equatable {          // 용어 사전의 "여정 선택". 준비 진입점에 넘기는 값
    let origin: StopPosition
    let minutes: Int
    let busID: String
    let busNumber: String
    let destination: String
    let stops: Int
}
enum JourneyPlanner {
    static let minuteRange: ClosedRange<Int> = 15...360
    static let initialMinutes = 25
    static func clamp(_ minutes: Int) -> Int
    static func candidates(minutes: Int, from origin: StopPosition) -> [JourneyCandidate]
    static func distanceText(stops: Int) -> String
}
```

**3) `StationSearchState.swift` (신규, 값 타입)**

```swift
struct StationSearchState: Equatable {
    var query: String = ""
    private(set) var selectedID: String?
    var results: [StationOption] { get }               // StationCatalog.search(query)
    var selectedOption: StationOption? { get }         // 현재 결과 안에 있을 때만 값이 있음
    var confirmationText: String? { get }              // "성수역 · 성수사거리 방면에서 출발"
    var canConfirm: Bool { get }                       // selectedOption != nil
    mutating func select(_ optionID: String) -> Bool   // 결과에 없는 id면 false
}
```

- 검색어를 바꿔서 선택한 항목이 결과에서 빠지면 `selectedOption`이 nil이 됩니다. 확인 버튼도 함께 비활성이 됩니다(FR-3).
- 결과가 0건이면 선택할 대상이 없으므로 `canConfirm == false`입니다(AC-4).

**4) `JourneyPlanDraft.swift` (신규, 값 타입)**

```swift
enum ProceedState: Equatable {
    case noCandidates, needsSelection, ready(JourneySelection)
    var title: String { get }      // "이 시간의 도착 후보가 없어요" | "버스와 도착지를 선택하세요" | "이 여정 준비하기"
    var isEnabled: Bool { get }
}
struct JourneyPlanDraft: Equatable {
    private(set) var minutes: Int = JourneyPlanner.initialMinutes
    private(set) var selectedBusID: String?
    private(set) var selectedOrigin: StopPosition?
    mutating func setMinutes(_ value: Int)                          // 범위 안으로 맞추고, 실제로 바뀌면 선택 해제
    mutating func step(by delta: Int)                               // VoiceOver 증감용(±1)
    mutating func choose(busID: String, from origin: StopPosition) -> Bool   // 현재 후보에 있을 때만 성공
    func candidates(from origin: StopPosition) -> [JourneyCandidate]
    func selectedCandidate(from origin: StopPosition) -> JourneyCandidate?    // 고를 때의 출발 위치와 같아야 유효
    func proceedState(from origin: StopPosition) -> ProceedState
}
```

- 시간 변경 시 선택 해제
  - `setMinutes`가 실제로 값을 바꾸면 선택을 항상 지웁니다. 같은 버스가 새 시간에도 후보에 있어도 지웁니다(FR-8, AC-20).
  - 15에서 줄이거나 360에서 늘리면 범위 맞춤 때문에 값이 그대로입니다. 값이 바뀌지 않았으므로 선택도 유지합니다.
- 출발 위치를 선택과 함께 기억합니다. 나중에(W04 이후) 현재 정류장이 바뀌면 이전 선택은 자동으로 무효가 됩니다. 웹 `key = id:origin:heading:minutes`(:856)와 같은 생각입니다.

### 판단 2. `StationSnapshot.id` 체계와 출발 위치 찾기

**결정: id는 "카탈로그 항목"이 아니라 "순환 정류장" 단위입니다.** 방향은 이미 `direction` 필드에 있습니다.

| index | id | name |
|---|---|---|
| 0 | `seongsu` | 성수역 |
| 1 | `seongsuDong` | 성수동 |
| 2 | `ttukseom` | 뚝섬역 |
| 3 | `seongdongSportsCenter` | 성동구민체육센터 |
| 4 | `seoulForest` | 서울숲역 |
| 5 | `seoulForestGate` | 서울숲 입구 |
| 6 | `seongsuBridgeNorth` | 성수대교 북단 |
| 7 | `ttukseomHangangPark` | 뚝섬한강공원 |
| 8 | `seongsuIntersection` | 성수사거리 |

- 카탈로그 3건이 저장하는 값은 다음과 같습니다. 이름은 순환 정류장 이름과 같습니다.
  - `seongsu`/"성수역"/1
  - `seongsu`/"성수역"/-1
  - `seoulForest`/"서울숲역"/1
- 출발 위치는 `RouteStops.position(of:)`로 찾습니다. 먼저 **id**로 9개 정류장 index를 찾고, `direction`은 저장값을 그대로 씁니다. id가 없으면 이름이 정확히 같은 정류장으로 한 번 더 찾습니다.
- 이 체계를 고른 이유
  - W04(하차 후 다음 출발지 저장) 이후에는 현재 정류장이 9개 중 어느 곳이든 될 수 있습니다. 카탈로그 3건 기준으로 찾으면 그때 다시 설계해야 합니다.
  - 기존 값과 바로 맞습니다.
    - ready 시드 `seoulForest`/"서울숲"/-1은 index 4, 역방향으로 풀립니다. 카탈로그에는 없는 조합이지만 시간 선택은 정상 동작합니다. 예를 들어 25분이면 2014번이 성수사거리로 갑니다.
    - 저장 실패 시나리오 값 `ttukseom`도 index 2로 풀립니다.
  - 그래서 **시드를 바꾸지 않습니다**. 시드를 카탈로그 값으로 바꾸는 안도 검토했지만, `UITestBootstrap.swift:60-62`와 `Phase1FlowTests.swift:35-40, 67, 82-87, 144-145`를 함께 고쳐야 합니다. W01과 겹칠 곳만 늘고 얻는 것이 없어 버렸습니다.
- 출발지 표시 이름은 저장된 `name`을 씁니다. 메인(`RootView.swift:63`)과 같은 값을 보여 주기 위해서입니다. AC-7에서는 "성수역"이 나옵니다.
- **찾기 실패**(가정): v1에서 옮겨 온 사용자나 앞으로 생길 수 있는 미지 id가 해당합니다. 운영 코드가 정류장을 저장한 적이 없으므로 현재는 생길 수 없는 경우입니다.
  - 시간 선택 화면에 "출발 정류장을 확인할 수 없어요"를 보여 줍니다(`time.originUnavailable`).
  - 후보는 비우고 진행 버튼은 "이 시간의 도착 후보가 없어요"로 막습니다.
  - 저장 파일은 건드리지 않고, 앱도 멈추지 않습니다.

### 판단 3. 저장 갱신 경로 (W00 인계 결정)

**결정**
- `AppModel.swift`에 범용 갱신 함수(변환 클로저 저장)를 **추가하지 않습니다**.
- 대신 기능별 extension을 **새 파일**에 둡니다. 이 extension은 `model.snapshot`을 읽어 `updating…`으로 후보를 만들고 `save(_:)`를 부릅니다.
- 근거
  - `snapshot` 읽기와 `save` 호출이 둘 다 `@MainActor`에서 동기로 이어집니다. 그래서 클로저 갱신이 주는 원자성 이득이 없습니다.
  - W01도 `AppModel.swift`에 같은 자리에 함수를 넣을 가능성이 큽니다. 새 파일에 두면 병합 충돌이 생기지 않습니다.
  - BR-6(같은 저장 경로)은 "둘 다 `AppModel.save`를 쓰고, 둘 다 최신 `snapshot`에서 `updating…`으로 출발한다"로 지킵니다.
- 후속 작업에 넘길 원칙: 저장은 `snapshot`에서 `updating…`을 거쳐 `save`로 합니다. 기능별 저장은 `AppModel+기능.swift` extension에 둡니다.

**5) `AppModel+JourneyStart.swift` (신규)**

```swift
extension AppModel {
    var journeyOrigin: StopPosition? { get }        // snapshot?.currentStation → RouteStops.position(of:)
    @discardableResult
    func confirmInitialStation(_ option: StationOption) -> Bool
    func proceedToPreparation() -> JourneySelection?    // ready일 때만 path에 .preparation 추가
    var preparedJourney: JourneySelection? { get }     // 준비 진입점이 읽는 전달값
}
extension Destination {
    static var mainMenu: [Destination] { get }          // [.preparation, .records, .settings, .profile]
    var mainMenuTarget: Destination { get }             // .preparation → .time, 나머지는 자기 자신
}
```

`confirmInitialStation`은 다음 순서로 동작합니다.
1. 진입 상태가 정류장 설정(`launchState == .ready(.initialStationEntry)`)이고 `snapshot`이 있는지 확인합니다. 아니면 `false`를 돌려줍니다. 이미 정류장이 있으면 여기서 막히므로 저장이 일어나지 않습니다(BR-1, BR-5의 "1회").
2. `let station = option.snapshot`
3. `save(current.updatingStage(cardIssued: current.cardIssued, initialStation: station, currentStation: station))`를 부릅니다. 카드 영역, 진행 여정, 기록은 `updatingStage`가 그대로 복사합니다(`AppSnapshot.swift:35-38`). 그래서 AC-6과 AC-25를 만족합니다.
4. 성공하면 `path = [.time]`으로 바꾸고 `true`를 돌려줍니다. 실패하면 `false`를 돌려주고 `saveFailure`는 `save`가 이미 기록한 값을 씁니다.

`AppModel.swift` 수정 내용은 다음과 같습니다.
- `Destination`에 `case time`을 넣고 `title`에 `"시간 선택"`을 추가합니다.
- 저장 프로퍼티 `var journeyPlan = JourneyPlanDraft()`를 1줄 추가합니다. 이유는 판단 4에 있습니다. extension에는 저장 프로퍼티를 둘 수 없어서 본 파일에 넣습니다.

### 판단 4. 네비게이션과 선택값 보관

- **저장 직후 이동(AC-7)**
  - `save`는 진입 상태가 바뀌면 `path = []`로 비웁니다(`AppModel.swift:53`). 그 **다음 줄에서** extension이 `path = [.time]`을 넣습니다.
  - 같은 실행 흐름 안에서 바뀌므로 SwiftUI는 "루트가 메인이고 그 위에 시간 선택"인 상태를 한 번에 그립니다. 검색 화면은 사라지고, 시간 선택에서 뒤로 가면 메인이 나옵니다.
- **메인 "여행 준비"**
  - `RootView.swift:67-68`을 `ForEach(Destination.mainMenu…)`와 `model.open(destination.mainMenuTarget)`으로 바꿉니다.
  - 버튼 문구 "여행 준비"와 식별자 `open.preparation`은 그대로 둡니다. 기존 테스트가 이 식별자를 씁니다.
  - `.time`은 메뉴에 나오지 않습니다.
- **"이 여정 준비하기"**: `model.proceedToPreparation()`이 진행 상태가 `.ready`일 때만 `open(.preparation)`을 부릅니다. 버튼 비활성과 함께 BR-2를 두 겹으로 막습니다.
- **선택값 보관 (FR-10, FR-12)**
  - `AppModel.journeyPlan`에 메모리로만 둡니다. `AppSnapshot`에는 들어가지 않으므로 저장 형식이 바뀌지 않습니다(AC-26). 앱을 다시 실행하면 `AppModel`이 새로 만들어져 25분, 선택 없음으로 시작합니다.
  - `Destination`에 연관값을 넣는 안은 버렸습니다. `String` rawValue와 `CaseIterable`(`AppModel.swift:5`)이 깨지고, `screen.\(rawValue)` 식별자 규칙도 깨지기 때문입니다.
  - 준비 진입점은 `model.preparedJourney`를 읽어 전달값을 받습니다. 시간 선택이 스택 아래에 남아 있고 준비 화면에서는 초안을 바꿀 수 없으므로 값이 일정합니다.
  - 뒤로 돌아와도 `journeyPlan`이 그대로라 60분과 2014번 선택이 남습니다(AC-22). View의 `@State`가 살아 있는지에 기대지 않습니다.
- **`DestinationScreen.swift` (신규)**
  - `RootView.swift:25-32`의 자리표시 본문을 이 파일로 옮깁니다. 내용은 바꾸지 않습니다. RootView 쪽은 `DestinationScreen(destination: destination, model: model)` 한 줄이 됩니다.
  - `.time`이면 `TimeSelectionView`를 보여 줍니다.
  - `.preparation`이면 기존 자리표시(제목만)에 DEBUG 전용 숨김 진단 `test.journeySelection`을 붙입니다. 값은 `{"minutes":60,"busID":"2014","destination":"성동구민체육센터"}` 같은 JSON이고, 버튼은 아닙니다.
  - 이렇게 하면 준비 화면 내용을 바꾸지 않으면서(W03 범위) AC-21의 "전달된 선택값"을 UI 테스트로 확인할 수 있습니다.

```swift
struct DestinationScreen: View { let destination: Destination; @Bindable var model: AppModel }
struct TimeSelectionView: View { @Bindable var model: AppModel }
```

### 판단 5. 저장 실패 (AC-8)

- 실패 문구는 기존 `RootView.swift:15-18`의 `storage.saveFailure` 문구("저장에 실패했어요. …")를 그대로 씁니다. 같은 문구를 두 곳에 두지 않기 위해서입니다.
- 실패하면 `launchState`가 그대로 `initialStationEntry`이므로 검색 화면이 남습니다. 검색 상태(`@State StationSearchState`)도 그대로라서 같은 선택으로 다시 "확인"을 누를 수 있습니다.
- 검색 화면은 `model.saveFailure != nil`일 때 확인 버튼 위에 "확인을 다시 눌러 주세요."(`search.retryHint`)를 보여 줍니다. 다음 행동을 문구로 알리기 위해서입니다(QE-1).
- 다시 확인해서 성공하면 `save`가 `saveFailure = nil`로 지웁니다(`AppModel.swift:52`).
- UI 테스트를 가능하게 하려면 `UITestBootstrap.swift:48-49`를 고쳐야 합니다.
  - 지금은 `--fm-ui-save fail`이고 메인이 아니면 `invalidSaveState`를 던져서 설정 오류가 납니다.
  - 고친 뒤에는 메인일 때만 시드 실패 저장을 일으키고, 다른 진입 상태에서는 아무것도 하지 않고 돌아옵니다. 쓰기 실패 저장소(`modelStore`, :42-45)는 그대로 쓰입니다.

### 판단 6. 화면과 접근성

**`InitialStationSearchView.swift` (신규)**
- 구조: `ScrollView` 안에 다음을 둡니다.
  - 검색창 `TextField`: `search.query`, 레이블 "정류장 검색"
  - 결과 버튼: `search.result.<option.id>`. 레이블은 "{이름}, {방면}"이고, 선택된 항목에는 `.isSelected`를 붙입니다.
  - 결과가 없을 때 `search.empty` "결과가 없어요"
  - 확인 문구 `search.confirmation`
- "확인" 버튼(`search.confirm`, 레이블 "확인", hint "고른 정류장에서 출발해요")은 `.safeAreaInset(edge: .bottom)`에 고정합니다. 글자가 가장 커져도 스크롤 없이 항상 보이고, 키보드가 올라오면 키보드 위로 올라갑니다.
- 루트 식별자 `screen.initialStationEntry`는 유지합니다. 기존 테스트(`Phase1FlowTests.swift:23`)가 이 식별자를 씁니다.

**`TimeSelectionView.swift` (신규)**
- 화면 식별자는 `screen.time`입니다.
- 출발지 표시는 `time.origin`(value=저장된 이름)과 방면 문구입니다.
- 시간 조절 요소 `time.minutes`
- 후보 버튼
  - 식별자는 `time.candidate.<bus.id>`입니다.
  - 레이블은 `candidate.accessibilityLabel`이고, 선택된 후보에는 `.isSelected`를 붙입니다.
  - 화면에는 유형·번호, 도착지, 분, 정류장 수, 거리를 보여 줍니다.
- 진행 버튼 `time.proceed`
  - 레이블은 `ProceedState.title`이고, `.disabled(!isEnabled)`입니다.
  - 검색 화면과 같은 방식으로 아래에 고정합니다.
- 시간 표시 `time.minutesLabel`(value="60")도 둡니다. UI 테스트에서 값을 확인할 때 씁니다.

**시간 조절 요소: 휠 `Picker`(`.pickerStyle(.wheel)`, 15~360 항목, 항목 문구 "N분")**

| 후보 | 1분 정확도 | VoiceOver 1분 증감 | UI 테스트에서 정확히 맞추기 | 큰 글자 |
|---|---|---|---|---|
| **휠 Picker (선택)** | 항목 단위라 정확 | 기본 지원(한 칸) | `pickerWheels.firstMatch.adjust(toPickerWheelValue: "60분")` | 높이 고정이라 화면을 차지하는 크기가 일정 |
| Stepper만 | 정확 | 기본 지원 | 360까지 335번 탭이 필요해 느림 | 좋음 |
| Slider(step 1) | 끌기로는 1분 단위가 어려움 | 직접 정의 필요 | `adjust(toNormalizedSliderPosition:)`이 부정확 | 좋음 |

- 웹의 눈금자(손가락으로 끄는 연속 선택)에 가장 가까운 iOS 표준 컨트롤이 휠입니다.
- 범위가 15~360으로 정해져 있어서 범위 밖 값이 나타날 수 없습니다(AC-10).
- 접근성 처리
  - `.accessibilityValue("\(minutes)분")`을 붙입니다.
  - 기본 증감 동작은 그대로 두되 `.accessibilityAdjustableAction`으로 `journeyPlan.step(by: ±1)`을 명시합니다. 어느 경우든 1분 단위로 움직입니다(AC-23).
- 바인딩: `Binding(get: { model.journeyPlan.minutes }, set: { model.journeyPlan.setMinutes($0) })`

**`MotionPolicy.swift` (신규)**

```swift
@MainActor func performNavigation(reduceMotion: Bool, _ change: () -> Void)
// reduceMotion이면 Transaction(disablesAnimations = true)으로 감싸고, 아니면 그대로 실행
```

- 두 화면에서 일어나는 이동(확인 후 시간 선택, 진행 후 준비)은 모두 이 함수를 거칩니다. 각 View는 `@Environment(\.accessibilityReduceMotion)`을 읽어서 넘깁니다.
- 시간을 바꿀 때 후보 목록 갱신에는 처음부터 `withAnimation`이나 `ScrollViewReader`의 자동 스크롤을 쓰지 않습니다. 그래서 "동작 줄이기"와 관계없이 즉시 바뀝니다(AC-24).

## 데이터 흐름

```
[검색] TextField ─▶ StationSearchState.query ─▶ StationCatalog.search ─▶ results
       결과 탭 ─▶ state.select(id) ─▶ confirmationText / canConfirm
       확인 ─▶ performNavigation { model.confirmInitialStation(option) }
                 └ AppModel.save(snapshot.updatingStage(..., initial=current=option.snapshot))
                     ├ 성공: launchState=.ready(.main), path=[] → (extension) path=[.time]
                     └ 실패: saveFailure 설정, launchState 유지 → 검색 화면 + storage.saveFailure + retryHint
[시간] model.journeyOrigin (currentStation.id → RouteStops index, direction)
       휠 ─▶ model.journeyPlan.setMinutes(m) (범위 맞춤 + 바뀌면 선택 해제)
       journeyPlan.candidates(from: origin) ─▶ JourneyPlanner.candidates
       후보 탭 ─▶ journeyPlan.choose(busID:from:)
       진행 ─▶ proceedState(from:) == .ready ─▶ performNavigation { model.proceedToPreparation() } ─▶ path += [.preparation]
[준비 진입점] DestinationScreen(.preparation) ─▶ model.preparedJourney (DEBUG test.journeySelection)
       뒤로 ─▶ path.removeLast ─▶ TimeSelectionView가 model.journeyPlan을 그대로 그림
```

## 테스트 전략 (초안)

경계는 이렇게 나눕니다.
- 계산 규칙과 상태 규칙, 그리고 AppModel 저장·네비게이션은 **XCTest 단위 테스트**가 맡습니다. 빠르고 경우를 빠짐없이 덮습니다.
- 화면 연결, 식별자, 접근성 레이블, 실제 파일 바이트, 재실행은 **XCUITest**가 맡습니다. 대표 경로만 봅니다.

| AC | 단위 (XCTest) | UI (XCUITest `FirstStationTimeFlowTests`) |
|---|---|---|
| AC-1 | `StationSearchState` 초기 결과 3건, `canConfirm == false` | cardOnly 시드: `screen.initialStationEntry`, `search.result.*` 3개, `search.confirm` 비활성 |
| AC-2, 3 | `StationCatalogTests`: 검색어별 결과 id 목록 | "성수"를 넣으면 3건(대표 1개) |
| AC-4 | 0건이면 `canConfirm == false`, `select` 실패 | "없는역": `search.empty`가 보이고, 확인을 눌러도 `persistedBytes`가 같음 |
| AC-5 | `confirmationText` | 역방향 탭: `search.confirmation` 문구, 확인 활성 |
| AC-6, 25 | `JourneyStartModelTests`: 저장 후보의 정류장 2개와 영역 3개 보존(`stage` 헬퍼 + 클로저 저장소) | `test.snapshot`의 initial/current = `seongsu`/성수역/-1, `cardIssued` true, `journey.active` null, `records.items` [] |
| AC-7 | 성공 시 `path == [.time]`, `launchState == .ready(.main)` | `screen.time`, `time.origin` = "성수역", 검색 화면 없음 |
| AC-8 | 쓰기 실패: `false`, `path == []`, `launchState` 유지, `saveFailure == .writeFailed`. 다시 시도해 성공 | cardOnly + `--fm-ui-save fail`: 검색 화면 유지, `storage.saveFailure`, 정류장 null, 다시 탭 가능 |
| AC-9, BR-1 | 메인 상태에서 `confirmInitialStation`을 부르면 `false`이고 쓰기 0회 | 재실행하면 메인. 메인, 설정, 마이페이지, 기록에 `screen.initialStationEntry`, `search.*`, "출발지" 버튼이 없음(기존 버튼 수 테스트와 함께) |
| AC-10 | `setMinutes(14)` → 15, `setMinutes(361)` → 360, `step` 경계, 15와 360 허용 | 휠을 15로 맞춘 뒤 아래로 끌어도 `time.minutesLabel` = 15 |
| AC-11 | 초안 기본값 25, 후보 1건(서울숲 입구, 5, "2.75km"), `needsSelection` | 저장 직후 `time.minutesLabel` = 25, `time.candidate.2014` 하나, 진행 비활성 |
| AC-12~16 | `JourneyPlannerTests`: 분과 출발 위치별 후보 표 전체 | 120분 3건(대표 1개) |
| AC-17, 18 | 17분 → `noCandidates`, 60분 미선택 → `needsSelection` | 비활성 진행 버튼을 탭해도 `screen.time`이 유지됨 |
| AC-19, 20 | 고유 선택, 61분에서 해제, 60분으로 돌아와도 해제 상태 | `isSelected` 확인, 61분으로 바꾸면 문구 바뀜 |
| AC-21 | `proceedToPreparation` 반환값과 path | `screen.preparation`, `test.journeySelection` JSON, `journey.active` null |
| AC-22 | 진행 → 뒤로 → `journeyPlan` 유지 | ready 시드에서 메인 → 시간 → 준비 → 뒤로: 60분과 2014번 선택 유지 |
| AC-23 | `accessibilityLabel` 문자열 | `time.candidate.2014.label`, 진행·확인 레이블 존재 |
| AC-24 | (동작 줄이기 분기는 `performNavigation` 단위 확인이 어려워 수동 확인) | 실행 인자 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`: 확인·진행이 `isHittable`, 이후 결과가 AC-6, 7, 21과 같음 |
| AC-26 | 새 `AppModel`의 `journeyPlan == JourneyPlanDraft()` | 종료 후 재실행: 메인 → 여행 준비 → 25분, 선택 없음, `persistedBytes`가 첫 저장 직후와 같음 |

- AC-12~16 UI 테스트 주의: 성수역 정방향, 역방향, 서울숲역 출발은 시드를 늘리지 않고 cardOnly 시드에서 검색과 확인을 거쳐 만듭니다.
- 단위 테스트에서 AppModel은 기존처럼 `LocalSnapshotStore`에 `readData`/`writeData` 클로저를 주입해서 만듭니다(`AppFoundationTests.swift:279-306`과 같은 패턴). cardOnly 스냅샷 바이트는 `SnapshotCodec.encode(stage(true, nil, nil))`로 준비합니다.

## 의존성 및 영향도
- **새 라이브러리**: 없습니다. SwiftUI와 XCTest만 씁니다.
- **기존 코드 영향**
  - 메인 "여행 준비"가 시간 선택을 엽니다. `Phase1FlowTests.swift:49-54, 165-170`의 기대값을 바꿉니다. 시간 선택 화면에는 버튼이 많으므로 버튼 수 단언(:178-179)에서는 "여행 준비" 행을 뺍니다.
  - `Destination.allCases`에 `.time`이 생깁니다. 이 목록을 순회하는 곳은 메인 메뉴(`RootView.swift:67`) 하나뿐이고, `mainMenu`로 바꿉니다.
  - `UITestBootstrap.applySaveScenario`: 메인이 아닌 시드에 `--fm-ui-save fail`을 주면 지금은 설정 오류가 나지만 앞으로는 정상 시작합니다. 기존 테스트 중 이 오류에 기대는 것은 없습니다.
- **하위 호환**: 저장 형식은 그대로입니다. 저장되는 정류장 id 값(`seongsu`, `seoulForest`)이 처음으로 의미를 갖고, 기존 시드 값과도 맞습니다.

### 기존 구조와의 차이
- **처음 생기는 네이티브 여정 도메인 코드**: `architecture.md:7, 17`은 "이 도메인의 네이티브 기능은 아직 없다"고 적고 있습니다. `RouteData`와 `JourneyPlanner`가 처음입니다. 웹처럼 상태·화면·규칙이 한 파일에 섞인 구조가 아니라, 순수 규칙과 화면 상태 값 타입과 View가 나뉩니다.
- **화면 상태가 AppModel 밖의 값 타입**: 지금까지 상태는 모두 `AppModel` 프로퍼티였습니다. 이번에는 `StationSearchState`(View의 `@State`)와 `JourneyPlanDraft`(AppModel이 들고 있는 값)를 새로 씁니다.
- **기능별 AppModel extension 파일**: 저장 경로는 `AppModel+기능.swift`로 둡니다. 이것이 W00 인계에 대한 답입니다.
- **준비 진입점 앞에 시간 선택이 끼어듦**: Phase 1의 "메인 → 목적지" 1단계 구조가 "메인 → 시간 → 준비" 2단계로 바뀝니다.
- **용어**: 용어 사전의 "여정 선택"은 `JourneySelection`으로 씁니다. 저장용 `JourneySnapshot`(W04)과는 별개입니다.
- **웹과 다른 점**
  - 검색은 필드마다 따로 일치를 봅니다. 웹은 문구를 이어 붙여 검색합니다(:671).
  - 후보 순서는 PRD 나열 순서(2014, 강남02, 343)입니다. JS 객체의 숫자형 키는 오름차순으로 정렬되므로 웹은 302, 421, 2014 순서로 보입니다. AC는 순서를 단언하지 않습니다.
  - 시간 조절은 눈금자 대신 휠입니다.

## 리스크
1. **W01과 병합 충돌 (높음)**
   - 충돌 예상 위치: `RootView.swift` cardEntry(:54-56)와 W02의 :58-59, `UITestBootstrap.swift:48-49`, `AppModel.swift` `Destination`.
   - 완화: `case .ready(.initialStationEntry):` 줄(:57)을 그대로 두어 두 변경 사이에 바뀌지 않는 줄을 하나 남깁니다. 나머지 로직은 모두 새 파일에 둡니다.
   - `UITestBootstrap`의 guard는 W01도 같은 방향("메인이 아니면 그냥 넘어감")으로 고칠 가능성이 큽니다. 충돌이 나면 같은 뜻의 한쪽을 남기면 됩니다.
2. **휠 Picker를 XCUITest에서 다루기**
   - `adjust(toPickerWheelValue:)`는 화면에 보이는 문구("60분")와 정확히 같아야 합니다. 휠을 `ScrollView` 안에 두면 세로 끌기가 서로 부딪칠 수 있습니다.
   - 완화: 휠은 스크롤 영역 위쪽에 고정 높이로 둡니다. 실패하면 대안은 Stepper(±1)에 DEBUG 전용 직접 입력을 더하는 것입니다.
3. **"동작 줄이기"는 자동 검증이 어렵습니다.** SwiftUI의 `accessibilityReduceMotion`은 읽기 전용이고, 시뮬레이터에서 실행 인자로 켤 방법도 확실하지 않습니다. 대신 이렇게 확인합니다.
   - 코드 규칙: 이동은 모두 `performNavigation`을 거치고, 다른 애니메이션은 쓰지 않습니다.
   - 실기기 수동 확인
   - UI 테스트에서 "기다리지 않고 바로 존재하는지"를 단언합니다.
4. **루트 교체와 경로 추가가 동시에 일어남**: 저장 성공 시 진입 상태와 `path`가 같은 실행 흐름에서 바뀝니다. iOS 17 `NavigationStack`에서는 정상 동작이 예상되지만, UI 테스트로 확정합니다(AC-7).
5. **메인 메뉴의 식별자와 실제 목적지가 다름**: `open.preparation`이 시간 선택을 엽니다. 기존 테스트를 안정적으로 유지하려고 고른 방식이며, W03 때 다시 볼 수 있습니다.

## 구현 순서
1. [Must] 도메인 규칙: `RouteData.swift`, `JourneyPlanner.swift` + `StationCatalogTests`, `JourneyPlannerTests` (의존: 없음)
   - AC: AC-2, 3, 12, 13, 14, 15, 16, 23(레이블 문자열)
2. [Must] 화면 상태: `StationSearchState.swift`, `JourneyPlanDraft.swift` + `JourneyPlanDraftTests` (의존: 1)
   - AC: AC-1, 4, 5, 10, 11, 17, 18, 19, 20
3. [Must] 저장·네비게이션
   - `AppModel.swift`: `case time`, `title`, `journeyPlan`
   - `AppModel+JourneyStart.swift`
   - `JourneyStartModelTests`
   - (의존: 2)
   - AC: AC-6, 7, 8, 9(모델 차단), 21, 22, 25, 26(모델)
4. [Must] UI 테스트 준비: `UITestBootstrap.swift:48-49` guard 변경 (의존: 없음)
   - AC: AC-8(UI 준비)
5. [Must] `MotionPolicy.swift` (의존: 없음)
   - AC: AC-24
6. [Must] `InitialStationSearchView.swift` (의존: 2, 3, 5)
   - AC: AC-1~8, 23, 24
7. [Must] `TimeSelectionView.swift`, `DestinationScreen.swift` (의존: 2, 3, 5)
   - AC: AC-10~24
8. [Must] `RootView.swift` 연결: :58-59, :67-68, :25-32 (의존: 6, 7)
   - AC: AC-1, 7, 9, 22
9. [Must] UI 테스트: `FirstStationTimeFlowTests` 신규, `Phase1FlowTests` 기대값 갱신 (의존: 4, 8)
   - AC: 표의 UI 열 전체
10. [Must] 전체 회귀: `python3 scripts/check-ios.py test` (의존: 9)

병렬로 할 수 있는 것:
- 1, 4, 5는 서로 독립입니다.
- 6과 7은 서로 다른 파일이라 병렬로 진행합니다.
- 3과 8은 각각 `AppModel.swift`, `RootView.swift`만 고칩니다. W01과 합칠 때는 이 두 단계만 조정하면 됩니다.

## 탐색 추가 항목
- `ios/FocusMate/AppModel.swift:5-14` → `Destination`(String rawValue, CaseIterable). `.time`을 추가할 곳
- `ios/FocusMate/AppModel.swift:43-59` → `save`. :53에서 진입 상태가 바뀌면 `path = []`가 되므로, 저장 직후 extension이 `path = [.time]`을 넣습니다
- `ios/FocusMate/AppModel.swift:61-64` → `open`은 메인일 때만 동작합니다. 저장 성공 후에는 메인이므로 사용할 수 있습니다
- `ios/FocusMate/AppSnapshot.swift:35-38` → `updatingStage`가 영역 3개를 보존합니다(BR-5 근거)
- `ios/FocusMate/RootView.swift:15-18` → `storage.saveFailure` 문구. AC-8에서 그대로 씁니다
- `ios/FocusMate/RootView.swift:24-33, 57-59, 67-70` → W02가 고칠 세 군데
- `ios/FocusMate/UITestBootstrap.swift:47-52` → 메인이 아니면 `invalidSaveState`를 던집니다. AC-8 UI 테스트를 막는 지점입니다
- `ios/FocusMate/UITestBootstrap.swift:60-62` → ready 시드의 id(`seongsu`, `seoulForest`)가 순환 정류장 id 체계와 맞습니다
- `ios/FocusMate/FocusMateApp.swift:57-59` → `applySaveScenario`를 부르는 곳
- `ios/FocusMateUITests/Phase1FlowTests.swift:43-70, 161-186` → "여행 준비"를 `screen.preparation`으로 기대하는 테스트와 버튼 수 단언. 갱신 대상입니다
- `ios/FocusMateTests/AppFoundationTests.swift:279-306` → AppModel 저장과 path 비우기 테스트 패턴
- `scripts/check-ios.py:35-39` → 파일 이름과 클래스 이름이 같아야 하는 실행 규칙
- `designs/final/animation-preview.html:647` → `wrap`, `stationBound`(방면 문구 = 다음 정류장 + " 방면")
- `designs/final/animation-preview.html:671` → `searchStations`(trim, 소문자, 이름+별칭+방면을 이어 붙여 검색)
- `designs/final/animation-preview.html:642` → `busOptions`의 키가 숫자형이라 웹 표시 순서가 302, 421, 2014입니다

---

## 확인이 필요한 사항

1. 메인에서 "여행 준비"로 시간 선택에 다시 들어올 때, 같은 실행 중 이전에 고른 시간과 후보를 남길까요?
   - 맥락:
     - PRD가 정한 것은 두 가지입니다. 준비 진입점에서 뒤로 돌아오면 유지합니다(FR-10). 앱을 다시 실행하면 처음 상태가 됩니다(FR-12).
     - "시간 선택 → 메인으로 뒤로 → 다시 여행 준비"는 정해져 있지 않습니다.
     - 이 설계는 선택값을 `AppModel.journeyPlan`(앱 실행 중 메모리)에 둡니다. 그대로 두면 "남김"이 되고, 화면에 들어올 때 초기화하면 "매번 처음부터"가 됩니다. 어느 쪽이든 AC는 모두 만족하고 코드 차이는 1~2줄입니다.
   - 유형: 선택
   - 선택지:
     - (a) 같은 실행 중에는 남김 (권장) — 웹 프로토타입의 동작과 같고, FR-12의 "앱 실행 중 메모리에 유지"와도 맞습니다. 메인을 잠깐 다녀와도 다시 고르지 않아도 됩니다. 출발 정류장이 바뀌면 선택은 자동으로 풀립니다.
     - (b) 메인에서 들어올 때마다 25분, 선택 없음으로 시작 — 매번 같은 시작 화면이라 예측하기 쉽습니다. 대신 메인을 잠깐 다녀오면 다시 골라야 합니다. 메인 진입 시 초기화 1줄이 추가됩니다.
     - (c) 직접 입력 — 위 선택지 외 다른 방식을 직접 입력합니다