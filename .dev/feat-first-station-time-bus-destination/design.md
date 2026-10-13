# 설계 초안 (최종): 첫 출발지 선택과 시간·버스·도착지 선택 (iOS, W02)

2회차에서 바뀐 점:
- **시간 선택 요소**: 휠에는 접근성 수정자를 하나도 붙이지 않습니다. 휠이 테스트로 조작되는지 확인하는 시험 UI 테스트(spike)를 T6의 첫 RED로 두고, 실패하면 쓸 대안도 지금 확정했습니다.
- **구현 순서**: AC 묶음 태스크 T1~T8로 다시 짰고, 각 태스크는 테스트를 먼저 씁니다.
- **동작 줄이기**: `MotionPolicy.swift`를 없애고 "앱이 직접 애니메이션을 넣지 않는다"는 규칙으로 바꿨습니다.
- **출발 위치 찾기**: id로만 찾습니다. 찾지 못했을 때의 처리는 모델 쪽 계산 속성으로 옮겼고, 진행 버튼에 전용 문구를 씁니다.
- **선택값 출처**: 준비 진입점에 넘기는 값의 출처를 하나(`preparedJourney`)로 합쳤습니다.
- **진행 버튼 연타**: 여러 번 눌러도 준비 화면이 한 번만 쌓입니다.
- **저장 실패 안내**: 검색 화면 전용 문구를 쓰고, 공용 문구와 겹치지 않게 했습니다.
- **키보드**: 키보드가 올라온 채로 확인하는 경로를 UI 테스트에 넣었습니다.
- **후속 인계** 절을 새로 만들었습니다.
- 사용자 답변을 반영했습니다. 같은 실행 중에는 메인에서 다시 들어와도 시간과 후보를 남깁니다.

> 구현 메모(2026-10-13): UI 테스트는 태스크 승인 시 `FirstStationTimeFlowTests` 한 파일 대신 FirstStationSearchUITests·StationSaveFailureUITests·TimeSelectionUITests·PreparationFlowUITests·LargeTextUITests 5개로 나눴다. 휠 spike는 통과해 대안 (c)는 쓰지 않았다. 큰 글자에서는 휠·진행 버튼을 하단에 고정하고 후보를 두 줄로 압축한다(T8).

## 설계 규모
**대형.** 새 화면 2개, 운영 코드에서 처음 부르는 저장, 네비게이션 목적지 추가, 처음 만드는 네이티브 여정 도메인 로직이 함께 들어갑니다.

## 배경 및 목적
- 웹 프로토타입의 첫 출발지 검색(`search`)과 시간·여정 선택(`time`)을 iOS로 옮깁니다. 지금 "최초 정류장 설정"은 자리표시뿐입니다(`RootView.swift:57-59`). "여행 준비"는 빈 화면입니다.
- 목표: 처음 쓰는 사용자가 출발 정류장을 한 번 고르고, 곧바로 "몇 분, 어떤 버스, 어디까지"를 정해 준비 단계로 넘어갑니다.
- 운영 코드가 저장을 처음 부르는 작업입니다. W00이 넘긴 "저장 갱신 경로"(`.dev/feat-domain-storage-schema-v2/design.md:267`)를 여기서 정합니다.

## 요구사항 및 수용 기준
PRD 원문은 `/Users/bonseung/Documents/ChatGPT/new-w02/.dev/feat-first-station-time-bus-destination/prd.md`에 있습니다.
- [Must] FR-1~FR-12, BR-1~BR-5
- [Should] BR-6, QE-1, QE-2
- 수용 기준 AC-1~AC-26

각 AC가 어디서 검증되는지는 아래 "구현 순서"의 태스크와 "테스트 전략" 표에 연결했습니다.

## 변경 범위

**신규 파일 (운영)**

| 경로 | 역할 |
|---|---|
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/RouteData.swift` | 9개 순환 정류장, 정류장 카탈로그 3건, 버스 3종 (순수 값) |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/JourneyPlanner.swift` | 후보 계산, 도착지 순환, 거리 표기, 시간 범위 (순수 함수) |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/StationSearchState.swift` | 검색 화면 상태 (값 타입) |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/JourneyPlanDraft.swift` | 시간 선택 상태와 진행 버튼 상태 (값 타입) |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/AppModel+JourneyStart.swift` | AppModel extension: 첫 출발지 저장, 출발 위치, 진행 상태, 준비로 진행 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/InitialStationSearchView.swift` | 검색 화면 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/TimeSelectionView.swift` | 시간 선택 화면 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/DestinationScreen.swift` | `navigationDestination` 본문 (기존 자리표시 이전, time 분기, preparation DEBUG 진단) |

**신규 파일 (테스트)**

| 경로 | 역할 |
|---|---|
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/StationCatalogTests.swift` | 검색 규칙 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/JourneyPlannerTests.swift` | 후보, 도착지, 거리, 레이블 문자열 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/StationSearchStateTests.swift` | 검색 선택, 확인 가능 여부, 확인 문구 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/JourneyPlanDraftTests.swift` | 시간 범위, 선택 해제, 진행 상태 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateTests/JourneyStartModelTests.swift` | AppModel 저장 바이트, 네비게이션, 출발 위치 찾기 실패 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateUITests/FirstStationTimeFlowTests.swift` | 두 화면 UI 테스트 (휠 spike 포함) |

**수정 파일** (줄 수 최소)

| 경로 | 바뀌는 줄 |
|---|---|
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/AppModel.swift` | `Destination`에 `case time`과 `title` 1줄(:6, :9 근처), `var journeyPlan = JourneyPlanDraft()` 1줄(:22 근처) |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/RootView.swift` | :15 공용 실패 문구 조건에 "정류장 설정 화면이 아닐 때" 추가 / :25-32를 `DestinationScreen(...)` 한 줄로 / :58-59 자리표시를 검색 화면으로(`case` 줄 :57은 그대로) / :67-68 메뉴 목록과 열 목적지 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/UITestBootstrap.swift` | :48-49 guard. 메인일 때만 시드 실패 저장을 일으키고, 다른 진입 상태에서는 그냥 돌아옵니다 |
| `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateUITests/Phase1FlowTests.swift` | :50 "여행 준비" 행의 기대 화면을 `screen.time`으로 / :165-170 버튼 수 테스트에서 "여행 준비" 행 제외. 준비 화면 검증은 새 UI 테스트로 옮깁니다 |

## 적용 컨벤션
- 별도 CLAUDE.md나 컨벤션 파일은 없습니다. 아래는 기존 코드에서 배운 내용입니다.
- 네이밍: 타입은 UpperCamelCase입니다. 접근성 식별자는 `screen.xxx`, `open.xxx`, `영역.요소` 형식입니다(`RootView.swift:27, 63, 69`). 테스트 파일 이름과 클래스 이름은 같아야 합니다(`scripts/check-ios.py:39`).
- 상태
  - `AppModel`은 `@MainActor @Observable`이고, 바깥에서 바꾸면 안 되는 값은 `private(set)`입니다(`AppModel.swift:17-22`).
  - `AppSnapshot`은 `private init`으로 막혀 있고 `updating…`으로만 바꿉니다(`AppSnapshot.swift:24-50`).
- 저장: `save`는 `Bool`을 돌려주고 실패 원인은 `saveFailure`에 남깁니다(`AppModel.swift:43-59`).
- 화면: 다크 모드 고정, `.padding(24)`, 제목은 `.largeTitle.bold()`입니다.
- 테스트
  - 저장소에 클로저를 주입하는 패턴은 `AppFoundationTests.swift:259-306`에 있습니다. 상태는 `stage(...)` 헬퍼로 만듭니다(`StorageTestSupport.swift:7`).
  - UI 테스트는 `--fm-ui-test-id`, `--fm-ui-seed`, `--fm-ui-save` 인자로 시작합니다. 결과는 `test.snapshot`과 `test.persistedBytes`로 확인합니다.
- 새 규칙 (이번 작업에서 정함)
  - 두 화면에서는 `withAnimation`, 자동 스크롤(`ScrollViewReader.scrollTo`), 커스텀 전환을 쓰지 않습니다.
  - 시스템 내비게이션 전환은 iOS가 "동작 줄이기"에 맞춰 처리하므로 앱이 막지 않습니다.

## 상세 설계

### 판단 1. 도메인 로직과 화면 상태 분리

**결정**
- 계산 규칙은 SwiftUI와 저장을 모르는 순수 값과 함수로 둡니다.
- 화면 상태는 View 밖의 값 타입 struct로 둡니다.
- View는 상태를 그리고, 사용자 조작을 상태 함수로 넘기기만 합니다.

**1) `RouteData.swift`**
- 현재: 이 값들은 웹에만 있습니다. `stopNames`(:788), `stationCatalog`(:670), `busOptions`(:642), `stationBound`(:647).
- 변경
  - 9개 순환 정류장에 고정 id를 줍니다.
  - 카탈로그는 "순환 index + 방향 + 별칭"으로 정의합니다.
  - 방면 문구는 `이름[wrap(index + 방향)] + " 방면"`입니다.
  - 검색: 검색어의 앞뒤 공백을 지우고 소문자로 바꿉니다. 비어 있으면 전체를 돌려줍니다. 그렇지 않으면 이름, 별칭 각각, 방면 문구 중 하나라도 부분 일치하는 항목을 돌려줍니다.
  - 별칭은 웹 값을 그대로 씁니다. 성수역 정방향은 "성수", "서울숲", 성수역 역방향은 "성수", "건대", 서울숲역은 "서울숲", "성수"입니다.

```swift
struct StopPosition: Equatable, Hashable { let index: Int; let direction: Int }
enum RouteStops {
    static let all: [(id: String, name: String)]          // 9건, 순환 순서
    static func wrap(_ offset: Int) -> Int
    static func name(at index: Int) -> String
    static func boundLabel(from position: StopPosition) -> String     // "성수동 방면"
    static func position(of station: StationSnapshot) -> StopPosition? // id로만 찾음
}
struct StationOption: Identifiable, Equatable {
    let id: String; let stopID: String; let position: StopPosition
    let name: String; let aliases: [String]
    var boundLabel: String { get }
    var snapshot: StationSnapshot { get }
}
enum StationCatalog {
    static let all: [StationOption]
    static func search(_ query: String) -> [StationOption]
}
struct BusLine: Identifiable, Equatable {
    let id: String; let number: String; let kind: String; let minutesPerStop: Int
    static let all: [BusLine]                               // 2014, 강남02(302), 343(421)
}
```

**2) `JourneyPlanner.swift`**
- 현재: 웹 `timeJourneyOptions`(:856)에만 있습니다.
- 변경
  - 분이 15~360 밖이면 빈 배열을 돌려줍니다.
  - 안이면 `minutes % minutesPerStop == 0`인 버스만 후보로 만듭니다.
  - 도착지는 `wrap(origin.index + origin.direction * stops)`입니다.
  - 거리는 0.01km 단위 정수 `stops * 55`로 계산합니다. 표기도 정수 연산으로 만들어 "2.75km", "5.5km", "11km"처럼 결과가 항상 같습니다.

```swift
struct JourneyCandidate: Identifiable, Equatable {
    let bus: BusLine; let minutes: Int; let stops: Int; let destination: String
    var id: String { bus.id }
    var distanceText: String { get }
    var accessibilityLabel: String { get }     // "지선 2014번, 성동구민체육센터, 60분, 12정류장"
}
struct JourneySelection: Equatable {           // 용어 사전의 "여정 선택"
    let origin: StopPosition; let minutes: Int
    let busID: String; let busNumber: String; let destination: String; let stops: Int
}
enum JourneyPlanner {
    static let minuteRange: ClosedRange<Int> = 15...360
    static let initialMinutes = 25
    static func clamp(_ minutes: Int) -> Int
    static func candidates(minutes: Int, from origin: StopPosition) -> [JourneyCandidate]
    static func distanceText(stops: Int) -> String
}
```

**3) `StationSearchState.swift`**

```swift
struct StationSearchState: Equatable {
    var query: String = ""
    private(set) var selectedID: String?
    var results: [StationOption] { get }
    var selectedOption: StationOption? { get }     // 현재 결과 안에 있을 때만 값이 있음
    var confirmationText: String? { get }          // "성수역 · 성수사거리 방면에서 출발"
    var canConfirm: Bool { get }
    mutating func select(_ optionID: String) -> Bool
}
```

- 검색어를 바꿔서 선택한 항목이 결과에서 빠지면 선택 효과가 사라집니다. 확인 버튼도 비활성이 됩니다.
- 결과가 0건이면 선택할 대상이 없습니다.

**4) `JourneyPlanDraft.swift`**

```swift
enum ProceedState: Equatable {
    case originUnavailable, noCandidates, needsSelection, ready(JourneySelection)
    var title: String { get }
    // "출발 정류장을 확인할 수 없어요" | "이 시간의 도착 후보가 없어요"
    // | "버스와 도착지를 선택하세요" | "이 여정 준비하기"
    var isEnabled: Bool { get }     // .ready일 때만 true
}
struct JourneyPlanDraft: Equatable {
    private(set) var minutes: Int = JourneyPlanner.initialMinutes
    private(set) var selectedBusID: String?
    mutating func setMinutes(_ value: Int)       // 범위 안으로 맞추고, 실제로 바뀌면 선택 해제
    mutating func choose(busID: String, from origin: StopPosition) -> Bool  // 현재 후보에 있을 때만 성공
    func candidates(from origin: StopPosition) -> [JourneyCandidate]
    func selectedCandidate(from origin: StopPosition) -> JourneyCandidate?
    func proceedState(from origin: StopPosition) -> ProceedState
}
```

- 시간이 실제로 바뀌면 선택을 항상 지웁니다. 같은 버스가 새 시간에도 후보에 있어도 지웁니다(AC-20).
- 15에서 줄이거나 360에서 늘리려 하면 값이 그대로이므로 선택도 그대로 둡니다.
- 1회차의 `selectedOrigin`은 **뺐습니다**. W02에서는 정류장을 한 번만 저장하므로 실행 중에 출발 위치가 바뀌는 경로가 없습니다. 출발 위치가 바뀔 때 선택을 무효로 만드는 처리는 W04에 넘깁니다(후속 인계 참고).

### 판단 2. `StationSnapshot.id` 체계와 출발 위치 찾기

**결정**
- id는 "카탈로그 항목"이 아니라 "순환 정류장" 단위입니다. 방향은 `direction` 필드가 담습니다.
- 출발 위치는 **id로만** 찾습니다. 1회차에 있던 이름으로 다시 찾는 단계는 뺐습니다.

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

- 카탈로그가 저장하는 값은 3가지입니다: `seongsu`/"성수역"/±1, `seoulForest`/"서울숲역"/1.
- 이 체계를 고른 이유
  - W04 이후에는 현재 정류장이 9곳 중 어디든 될 수 있습니다. 순환 정류장 단위로 찾아야 그때 다시 설계하지 않아도 됩니다.
  - 기존 값이 그대로 맞습니다. ready 시드의 `seoulForest`/-1은 index 4, 역방향으로 풀리고, 저장 실패 시나리오의 `ttukseom`도 풀립니다. 그래서 **시드를 바꾸지 않습니다**.
  - 시드를 카탈로그 값으로 바꾸는 안도 비교했습니다. `UITestBootstrap.swift:60-62`와 `Phase1FlowTests.swift` 여러 곳을 고쳐야 해서 W01과 겹칠 곳만 늘기 때문에 버렸습니다.
- 출발지 표시 이름은 저장된 `name`을 씁니다. 메인(`RootView.swift:63`)과 같은 값을 보여 주기 위해서입니다.
- **찾기 실패는 모델 쪽 계산 속성에서 처리합니다(판단 3).** `journeyOrigin == nil`이면 다음과 같이 됩니다.
  - `journeyProceedState`가 `.originUnavailable`이 되고, 진행 버튼에 "출발 정류장을 확인할 수 없어요"가 보이며 눌리지 않습니다.
  - 후보 목록은 비고, 저장 파일은 건드리지 않습니다.
  - 지금 운영 코드에서는 생길 수 없는 경우입니다. 카탈로그 밖 정류장은 W04 이후 다시 검토합니다.

### 판단 3. 저장 갱신 경로 (W00 인계에 대한 결정)

**결정**
- `AppModel.swift`에 범용 갱신 함수를 추가하지 않습니다.
- 기능별 extension을 새 파일 `AppModel+JourneyStart.swift`에 둡니다. 이 extension은 `snapshot`을 읽어 `updating…`으로 후보를 만들고 `save`를 부릅니다.
- 근거
  - 읽기와 저장이 둘 다 `@MainActor`에서 동기로 이어집니다. 그래서 클로저 방식이 주는 이득이 없습니다.
  - W01과 같은 곳에 함수를 넣어 충돌할 일이 사라집니다.
- BR-6은 이렇게 지킵니다. 두 작업 모두 `AppModel.save`를 쓰고, 최신 `snapshot`에서 출발합니다.

```swift
extension AppModel {
    var journeyOrigin: StopPosition? { get }            // snapshot?.currentStation → RouteStops.position(of:)
    var journeyCandidates: [JourneyCandidate] { get }   // origin이 없으면 []
    var journeyProceedState: ProceedState { get }       // origin이 없으면 .originUnavailable
    var preparedJourney: JourneySelection? { get }      // .ready의 값. 준비 진입점이 읽는 유일한 출처
    @discardableResult func confirmInitialStation(_ option: StationOption) -> Bool
    @discardableResult func proceedToPreparation() -> Bool
}
extension Destination {
    static var mainMenu: [Destination] { get }          // [.preparation, .records, .settings, .profile]
    var mainMenuTarget: Destination { get }             // .preparation → .time
}
```

- `confirmInitialStation`
  1. 진입 상태가 정류장 설정(`launchState == .ready(.initialStationEntry)`)이고 `snapshot`이 있는지 봅니다. 아니면 `false`를 돌려주고 저장하지 않습니다. 이것으로 BR-1과 "저장 1회"(BR-5)를 지킵니다.
  2. `save(current.updatingStage(cardIssued: current.cardIssued, initialStation: s, currentStation: s))`를 부릅니다. 카드, 진행 여정, 기록 영역은 `updatingStage`가 그대로 복사합니다(`AppSnapshot.swift:35-38`).
  3. 성공하면 `path = [.time]`으로 바꾸고 `true`를 돌려줍니다. 실패하면 `false`를 돌려주고, `saveFailure`는 `save`가 기록한 값을 그대로 둡니다.
- `proceedToPreparation`
  - `journeyProceedState`가 `.ready`가 아니면 `false`입니다.
  - `path.last == .preparation`이면 다시 넣지 않고 `true`를 돌려줍니다. 진행 버튼을 연타해도 준비 화면이 한 번만 쌓입니다.
  - 그 밖에는 `open(.preparation)`을 부릅니다.
- `AppModel.swift` 수정은 `case time`, `title`의 `"시간 선택"`, `var journeyPlan = JourneyPlanDraft()`입니다. 저장 프로퍼티는 extension에 둘 수 없어서 본 파일에 넣습니다.

### 판단 4. 네비게이션과 선택값 보관

- **저장 직후 이동(AC-7)**: `save`가 진입 상태가 바뀌어 `path = []`로 비운 뒤(`AppModel.swift:53`), extension이 `path = [.time]`을 넣습니다. 그 결과 메인 위에 시간 선택 화면이 올라갑니다. 검색 화면은 사라지고, 뒤로 가면 메인입니다.
- **메인 "여행 준비"**
  - `RootView.swift:67-68`을 `ForEach(Destination.mainMenu…)`와 `model.open(destination.mainMenuTarget)`으로 바꿉니다.
  - 문구 "여행 준비"와 식별자 `open.preparation`은 그대로 둡니다. `.time`은 메뉴에 나오지 않습니다.
- **선택값 보관**: `AppModel.journeyPlan`에 앱 실행 중 메모리로만 둡니다(사용자 답변 반영).
  - 준비 화면에서 뒤로 와도, 메인을 다녀와도 시간과 후보가 남습니다.
  - 앱을 다시 실행하면 처음 상태로 돌아갑니다(FR-12).
  - `AppSnapshot`에 들어가지 않으므로 저장 형식이 바뀌지 않습니다.
  - `Destination`에 연관값을 넣는 안은 버렸습니다. String rawValue, CaseIterable, `screen.\(rawValue)` 규칙이 깨지기 때문입니다.
- **`DestinationScreen.swift`**
  - `RootView.swift:25-32`의 자리표시 본문을 내용 그대로 옮깁니다.
  - `.time`이면 `TimeSelectionView`를 보여 줍니다.
  - `.preparation`에는 기존 제목만 두고, DEBUG 전용 숨김 진단 `test.journeySelection`을 붙입니다. 값은 `model.preparedJourney`의 JSON이고, 버튼은 아닙니다. 준비 화면 내용은 바꾸지 않습니다(W03 범위).

```swift
struct DestinationScreen: View { let destination: Destination; @Bindable var model: AppModel }
struct TimeSelectionView: View { @Bindable var model: AppModel }
struct InitialStationSearchView: View { @Bindable var model: AppModel }   // 내부 @State StationSearchState
```

### 판단 5. 저장 실패 (AC-8)

- 검색 화면은 `model.saveFailure != nil`일 때 확인 버튼 바로 위에 전용 문구를 보여 줍니다.
  - 식별자: `search.saveFailure`
  - 문구: **"출발 정류장 저장에 실패했어요. 확인을 다시 눌러 주세요."** 이 문구는 AC-8이 찾는 "저장에 실패했어요"를 그대로 포함합니다.
- 저장이 실패하면 스냅샷(메모리)도 바뀌지 않습니다. 그래서 공용 문구가 말하는 "변경 내용"이 없습니다. 이에 맞춰 `RootView.swift:15` 조건을 `model.saveFailure != nil && model.launchState != .ready(.initialStationEntry)`로 바꿉니다. 이렇게 하면 두 문구가 함께 나오지 않습니다.
- 실패해도 진입 상태와 검색 상태는 그대로 남습니다. 같은 선택으로 다시 "확인"을 누를 수 있습니다. 성공하면 `save`가 `saveFailure`를 지웁니다(`AppModel.swift:52`).
- `UITestBootstrap.swift:48-49`는 이렇게 바꿉니다.
  - `guard shouldFailSave, model.launchState == .ready(.main) else { return }`를 넣고, 그다음에 `snapshot`이 없으면 `invalidSaveState`를 던집니다.
  - 쓰기가 실패하는 저장소(`:42-45`)는 진입 상태와 관계없이 그대로 쓰입니다. 그래서 cardOnly 시드에 `--fm-ui-save fail`을 주면 검색 화면의 저장이 실패합니다.

### 판단 6. 화면, 접근성, 시간 선택 요소

**검색 화면**
- `ScrollView` 안에 다음 요소를 둡니다.
  - 검색창: 식별자 `search.query`, 레이블 "정류장 검색"
  - 결과 버튼: 식별자 `search.result.<id>`, 레이블 "{이름}, {방면}". 선택된 항목에는 `.isSelected`를 붙입니다.
  - 결과 없음: `search.empty` "결과가 없어요"
  - 확인 문구: `search.confirmation`
- "확인" 버튼(`search.confirm`, 레이블 "확인", hint "고른 정류장에서 출발해요")은 `.safeAreaInset(edge: .bottom)`에 고정합니다. 키보드가 올라오면 키보드 위에 있고, 글자가 가장 커져도 스크롤 없이 보입니다.
- 루트 식별자 `screen.initialStationEntry`는 유지합니다.

**시간 선택 화면**
- 화면 식별자는 `screen.time`입니다.
- 출발지 `time.origin`은 value가 저장된 이름이고, 옆에 방면 문구를 보여 줍니다.
- 시간 표시 `time.minutesLabel`(value "60")은 일반 Text라서 휠과 별개입니다.
- 후보 버튼
  - 식별자는 `time.candidate.<bus.id>`, 레이블은 `accessibilityLabel` 문자열입니다. 선택된 후보에는 `.isSelected`를 붙입니다.
  - 화면에는 유형·번호, 도착지, 분, 정류장 수, 거리를 보여 줍니다.
- 진행 버튼(`time.proceed`, 레이블 `ProceedState.title`, `.disabled(!isEnabled)`)은 아래에 고정합니다.

**(a) 시간 선택 요소: 휠 `Picker`(`.pickerStyle(.wheel)`, 15~360, 항목 문구 "N분")**
- 휠에는 **접근성 수정자를 하나도 붙이지 않습니다**. `accessibilityValue`, `accessibilityAdjustableAction`, `accessibilityIdentifier` 모두 해당합니다.
  - 근거: SwiftUI에서 이런 수정자를 붙이면 시스템 기본 조절을 대체할 수 있습니다. 그러면 XCUITest가 이 요소를 `PickerWheel`로 보지 못할 수 있습니다.
- 접근성 이름은 `Picker("여행 시간", selection:)`의 제목으로만 줍니다.
- VoiceOver의 위아래 쓸기는 시스템 기본대로 한 칸, 즉 1분씩 움직입니다.
- UI 테스트는 `app.pickerWheels.firstMatch`로 찾습니다. 화면에 휠은 하나뿐입니다.
- 바인딩: `Binding(get: { model.journeyPlan.minutes }, set: { model.journeyPlan.setMinutes($0) })`
- 범위가 15~360으로 정해져 있으므로 범위 밖 값이 나타날 수 없습니다(AC-10).

**(b) 휠 조작 spike: T6의 첫 RED.** 테스트 이름은 `testTimeWheelSpike`이고, 통과한 뒤에도 회귀 테스트로 남깁니다. 아래를 모두 만족해야 통과입니다.
1. `app.pickerWheels.count == 1`이고, `firstMatch.waitForExistence(timeout: 3)`이 참입니다.
2. 처음 진입했을 때 `wheel.value as? String == "25분"`이고 `time.minutesLabel`이 "25"입니다.
3. `adjust(toPickerWheelValue: "360분")`이 **20초 안에** 끝납니다. 걸린 시간은 `Date`로 재서 단언합니다. 끝난 뒤 휠 값은 "360분", `time.minutesLabel`은 "360"입니다.
4. 같은 방식으로 "15분"까지 20초 안에 도달하고 값이 일치합니다.
5. 이웃한 값으로 움직일 수 있습니다. "60분"에서 "61분"으로 가면 값이 일치합니다. AC-20 경로에 해당합니다.

하나라도 실패하면 T6은 설계를 다시 열지 않고 (c)의 대안으로 바꿉니다.

**(c) spike 실패 시 대안 (지금 확정)**
- 커스텀 조절 요소 하나와 별도 버튼 4개로 구성합니다.
  - **조절 요소** `time.minutes`
    - `.accessibilityElement(children: .ignore)`로 하나의 요소로 묶습니다.
    - 레이블은 "여행 시간", value는 "N분"입니다.
    - `.accessibilityAdjustableAction`으로 ±1 증감하며, `setMinutes`가 범위를 맞춥니다.
    - 화면에는 큰 "N분" 글자가 보입니다.
  - **버튼 4개**: `time.minus10`, `time.minus1`, `time.plus1`, `time.plus10`
    - 레이블은 "10분 줄이기", "1분 줄이기", "1분 늘리기", "10분 늘리기"입니다.
    - 경계에서는 `.disabled`입니다.
    - 조절 요소 바깥에 따로 두어 접근성 요소가 겹치지 않게 합니다.
- UI 테스트는 **실제 사용자 조작 경로**인 버튼 탭으로 값을 맞춥니다. DEBUG 직접 입력은 쓰지 않습니다.
  - 25에서 360까지는 +10을 33번, +1을 5번 눌러 약 38번이면 됩니다.
  - 탭 헬퍼 `setMinutes(to:)`는 "10 단위로 먼저, 나머지는 1 단위로" 누릅니다.
- AC-23 검증: `time.minutes`에 `XCUIElement.increment()`와 `decrement()`를 보내 value가 "61분"과 "60분"으로 바뀌는지, 15와 360에서 그대로인지 단언합니다. 대안으로 가면 이것이 첫 RED입니다.
- 휠을 쓰는 경우의 AC-23 검증
  - spike 1번(시스템 PickerWheel로 노출됨)과 5번(이웃 값으로 이동)으로 확인합니다.
  - VoiceOver를 켜고 한 칸에 1분씩 움직이는지는 실기기에서 수동으로 확인합니다(수동 확인 항목).

**동작 줄이기**
- 두 화면에서 `withAnimation`, 자동 스크롤, 커스텀 전환을 쓰지 않습니다. 그래서 시간을 바꾸면 후보와 진행 문구가 그 자리에서 바로 바뀝니다.
- 시스템 내비게이션 전환은 iOS에 맡깁니다. 1회차의 `MotionPolicy.swift`는 뺐습니다.
- 실기기에서 "동작 줄이기"를 켠 상태는 수동으로 확인합니다.

## 데이터 흐름

```
[검색] query ─▶ StationSearchState.results(StationCatalog.search) ─▶ 결과 탭 select ─▶ confirmationText/canConfirm
       확인 ─▶ model.confirmInitialStation(option)
               └ save(snapshot.updatingStage(initial=current=option.snapshot))
                   ├ 성공: launchState=.ready(.main), path=[] → path=[.time]
                   └ 실패: saveFailure, 상태 유지 → search.saveFailure (공용 문구는 숨김)
[시간] model.journeyOrigin(id로 찾기) ─nil─▶ journeyProceedState=.originUnavailable
       휠 ─▶ journeyPlan.setMinutes (범위 맞춤 + 바뀌면 해제)
       model.journeyCandidates / 후보 탭 ─▶ journeyPlan.choose(busID:from:)
       진행 ─▶ model.proceedToPreparation() (.ready만, 끝이 이미 .preparation이면 그대로)
[준비] DestinationScreen(.preparation) ─▶ model.preparedJourney ─▶ (DEBUG) test.journeySelection
       뒤로 ─▶ TimeSelectionView가 model.journeyPlan을 그대로 그림
```

## 테스트 전략

- **XCTest**: 규칙, 상태, 모델 저장·네비게이션을 맡습니다. 경우를 빠짐없이 덮습니다.
- **XCUITest**: 화면 연결, 식별자, 레이블, 실제 파일 바이트, 재실행을 대표 경로로 확인합니다.

| AC | 단위 | UI (`FirstStationTimeFlowTests`) |
|---|---|---|
| AC-1 | `StationSearchStateTests`: 초기 3건, 확인 불가 | cardOnly 시드: `screen.initialStationEntry`, 결과 3개, 확인 비활성 |
| AC-2, 3 | `StationCatalogTests`: 검색어별 결과 id | "성수" 3건, "  성수사거리  " 1건 |
| AC-4 | 0건이면 select 실패, 확인 불가 | "없는역": `search.empty`, 확인을 눌러도 `persistedBytes` 같음 |
| AC-5 | 확인 문구 | 역방향 탭: 문구와 확인 활성 |
| AC-6, 25 | `JourneyStartModelTests`: `writeData`가 받은 바이트를 `SnapshotCodec.decode`로 풀어 정류장 2개, `cardIssued`, 영역 3개를 단언 | `test.snapshot`: `seongsu`/성수역/-1 ×2, `journey.active` null, `records.items` [] |
| AC-7 | 성공 시 `path == [.time]`, 메인 | 검색창에 입력해 **키보드가 올라온 채로** 결과 탭, 확인 탭 → `screen.time`, `time.origin` = "성수역", 검색 화면 없음 |
| AC-8 | 실패 시 `false`, `path == []`, 상태 유지, 다시 시도해 성공 | cardOnly + fail: `search.saveFailure` 있음, `storage.saveFailure` 없음, 정류장 null, 다시 탭 가능 |
| AC-9 | 메인에서 `confirmInitialStation`을 부르면 `false`, 쓰기 0회 | 재실행하면 메인. 메인, 설정, 마이페이지, 기록에 `search.*`, `screen.initialStationEntry` 없음 |
| AC-10 | `setMinutes(14)` → 15, `setMinutes(361)` → 360, 경계에서 선택 유지 | spike 3, 4번. 15·360에서 휠을 더 끌어도 값이 그대로(대안이면 버튼 비활성) |
| AC-11 | 기본 25분, 후보 1건, `needsSelection` | 저장 직후 25, `time.candidate.2014` 하나, 진행 비활성 |
| AC-12~16 | `JourneyPlannerTests`: 분과 출발 위치별 후보 표 전체 | 120분 3건(검색으로 성수역 정방향을 거쳐 만듦) |
| AC-17, 18 | `noCandidates`, `needsSelection` 문구 | 비활성 진행 버튼을 탭해도 `screen.time` 유지 |
| AC-19, 20 | 고유 선택, 61분에서 해제, 60분으로 돌아와도 해제 | `isSelected`. 61로 바꾼 직후 **대기 없이** 문구 단언 |
| AC-21 | `proceedToPreparation`, `preparedJourney`, 연타 시 path 1회 | `screen.preparation`, `test.journeySelection`, `journey.active` null. 준비 화면 버튼이 뒤로 버튼 1개뿐(Phase1에서 옮겨 옴) |
| AC-22 | 진행 → 뒤로 → `journeyPlan` 유지 | ready 시드: 메인 → 시간 → 준비 → 뒤로 → 메인 → 다시 시간에서 60분, 2014번 유지 |
| AC-23 | `accessibilityLabel` 문자열 | 후보 레이블 일치, 확인·진행 레이블 있음, 1분 증감은 (b)/(c) 방법 |
| AC-24 | — | `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`: 확인·진행이 `isHittable`, 결과가 AC-6, 7, 21과 같음, 시간 변경 직후 대기 없이 상태 단언. 동작 줄이기는 수동 확인 |
| AC-26 | 새 `AppModel`의 `journeyPlan`이 기본값 | **정식 검증**: 종료 후 재실행 → 메인 → 여행 준비 → 25분, 선택 없음, `persistedBytes`가 첫 저장 직후와 같음 |

- 단위 테스트의 AppModel은 `readData`와 `writeData` 클로저를 주입해서 만듭니다.
- cardOnly 바이트는 `SnapshotCodec.encode(stage(true, nil, nil))`로 준비합니다.
- 찾기 실패는 id가 `"unknown"`인 스냅샷으로 `journeyOrigin == nil`과 `journeyProceedState == .originUnavailable`을 단언합니다.

## 의존성 및 영향도
- **새 라이브러리**: 없습니다.
- **기존 코드 영향**
  - "여행 준비"가 시간 선택을 엽니다. 그래서 `Phase1FlowTests.swift:49-54, 165-170`이 바뀝니다.
  - `Destination.allCases`에 `.time`이 생기지만, 이 목록을 순회하던 곳(`RootView.swift:67`)은 `mainMenu`로 바뀝니다.
  - 메인이 아닌 시드에 `--fm-ui-save fail`을 주면, 지금처럼 설정 오류가 나지 않고 정상으로 시작합니다.
  - 공용 저장 실패 문구는 정류장 설정 화면에서만 숨겨집니다.
- **하위 호환**: 저장 형식은 그대로입니다. 저장되는 정류장 id가 처음으로 의미를 갖게 되며, 기존 시드 값과 맞습니다.

### 기존 구조와의 차이
- **처음 생기는 네이티브 여정 도메인 코드**(`architecture.md:7, 17`): 규칙, 화면 상태 값, View가 나뉩니다. 웹은 한 파일에 모두 섞여 있습니다.
- **화면 상태 위치**: 지금까지 상태는 모두 `AppModel` 프로퍼티였습니다. 이번에는 `StationSearchState`(View의 `@State`)와 `JourneyPlanDraft`(AppModel이 보관하는 값)라는 값 타입을 씁니다.
- **기능별 저장 extension**: 저장 경로는 `AppModel+기능.swift`로 둡니다(W00 인계에 대한 답).
- **화면 흐름**: "메인 → 목적지" 1단계가 "메인 → 시간 → 준비" 2단계로 바뀝니다.
- **용어**: 용어 사전의 "여정 선택"은 `JourneySelection`입니다. 저장용 `JourneySnapshot`(W04)과는 별개입니다.
- **웹과 다른 점**
  - 검색: 웹(:671)은 문구를 이어 붙여 검색하고, 여기서는 필드마다 따로 일치를 봅니다.
  - 후보 순서: PRD 순서(2014, 강남02, 343)를 씁니다. 웹은 숫자형 키 정렬 때문에 302, 421, 2014 순서입니다. AC는 순서를 단언하지 않습니다.
  - 시간 선택: 눈금자 대신 휠을 쓰고, 안 되면 조절 요소와 ±버튼을 씁니다.

## 리스크
1. **W01과 병합 충돌 (높음)**
   - 충돌이 날 수 있는 곳: `RootView.swift`(:15, :54-59), `UITestBootstrap.swift:48-49`, `AppModel.swift`의 `Destination`
   - 완화
     - `case .ready(.initialStationEntry):` 줄(:57)을 그대로 두어, W01 변경과 W02 변경 사이에 바뀌지 않는 줄을 하나 남깁니다.
     - 나머지 로직은 새 파일에 둡니다.
     - guard와 :15 조건은 W01과 뜻을 맞춥니다(후속 인계 참고).
2. **휠 spike 실패**: 확정한 대안 (c)로 바꿉니다. 이 경우 대안 화면을 구현하는 만큼 T6 공수가 늘어납니다.
3. **"동작 줄이기"와 VoiceOver 한 칸 이동**은 자동으로 검증하지 못합니다. 실기기 수동 확인 항목으로 남깁니다.
4. **루트 교체와 path 추가가 동시에 일어남**: AC-7 UI 테스트로 확정합니다.
5. **식별자와 동작 불일치**: `open.preparation` 버튼이 실제로는 시간 선택을 엽니다. W03에 인계합니다.

## 구현 순서

모든 태스크는 **테스트를 먼저 쓰고 RED를 확인한 뒤** 구현합니다. 구현 후에 테스트를 쓰지 않습니다.

1. [Must] **T1 도메인 규칙** (의존: 없음)
   - AC: AC-2, 3, 12~16, AC-23 레이블 문자열
   - `StationCatalogTests`와 `JourneyPlannerTests`를 먼저 씁니다.
   - 컴파일 RED는 타입 뼈대로 넘기고, 동작 RED를 확인한 뒤 `RouteData.swift`와 `JourneyPlanner.swift`를 구현합니다.
2. [Must] **T2 화면 상태** (의존: 1)
   - AC: AC-1, 4, 5, 10, 11, 17~20
   - `StationSearchStateTests`와 `JourneyPlanDraftTests`를 먼저 씁니다.
   - 그다음 `StationSearchState.swift`와 `JourneyPlanDraft.swift`를 구현합니다.
3. [Must] **T3 모델 저장·네비게이션** (의존: 2)
   - AC: AC-6, 7, 8, 9, 21, 22, 25, 26(모델), 찾기 실패
   - `JourneyStartModelTests`를 먼저 씁니다. 저장 바이트를 디코드해 단언하고, 연타 시 path가 한 번만 쌓이는지도 봅니다.
   - 그다음 `AppModel.swift`(3줄)와 `AppModel+JourneyStart.swift`를 구현합니다.
4. [Must] **T4 검색 화면 UI** (의존: 3)
   - AC: AC-1~5, 7(키보드가 올라온 채로 확인)
   - `FirstStationTimeFlowTests`에 AC-1~5, 7 테스트를 먼저 씁니다.
   - 그다음 다음을 구현합니다.
     - `InitialStationSearchView.swift`
     - `DestinationScreen.swift`: 자리표시 이전과 `.time` 분기
     - `TimeSelectionView.swift` 뼈대: `screen.time`, `time.origin`만
     - `RootView.swift` :25-32, :58-59
5. [Must] **T5 저장 실패 UI** (의존: 4)
   - AC: AC-8
   - UI 테스트를 먼저 씁니다(cardOnly + fail).
   - 그다음 `UITestBootstrap.swift:48-49` guard, `search.saveFailure` 문구, `RootView.swift:15` 조건을 바꿉니다.
6. [Must] **T6 시간 화면 UI** (의존: 5. `RootView`와 UI 테스트 파일을 같이 고칩니다)
   - AC: AC-10~20, 23
   - **첫 RED는 휠 spike `testTimeWheelSpike`입니다.**
   - 같은 단계에서 `Phase1FlowTests`의 기대값도 바꿔 RED로 만듭니다. "여행 준비"는 `screen.time`을 기대하고, 버튼 수 테스트에서 준비 행을 뺍니다.
   - 이어서 AC-10~20, 23 UI 테스트를 쓰고 `TimeSelectionView.swift`와 `RootView.swift:67-68`을 구현합니다.
   - spike가 실패하면 대안 (c)로 바꾸고, `increment()`/`decrement()` 테스트를 첫 RED로 다시 시작합니다.
7. [Must] **T7 준비 진행·왕복·재실행 UI** (의존: 6)
   - AC: AC-21, 22, 9, 26
   - UI 테스트를 먼저 씁니다. 준비 화면 "완료 버튼 없음" 검증도 여기로 옮깁니다.
   - 그다음 `DestinationScreen`의 `test.journeySelection`과 진행 버튼 연결을 구현합니다.
8. [Must] **T8 큰 글자** (의존: 7)
   - AC: AC-24
   - 접근성 최대 글자 크기 UI 테스트를 먼저 쓰고, 레이아웃을 보완합니다.
   - 동작 줄이기와 VoiceOver 한 칸 이동은 수동 확인 기록으로 남깁니다.
9. [Must] **전체 회귀**: `python3 scripts/check-ios.py test` (의존: 8)

T4~T8은 같은 UI 테스트 파일과 `RootView.swift`를 고치므로 차례로 진행합니다. T1~T3은 단위 테스트와 새 파일 위주라 W01과 독립적으로 먼저 끝낼 수 있습니다.

## 후속 인계
1. **W01 저장 관례**: W02는 `snapshot` → `updating…` → `save`, 그리고 기능별 `AppModel+기능.swift` extension 방식을 씁니다. W01도 같은 관례를 쓰는지 병합 전에 확인해야 합니다. 다르면 둘 중 하나로 통일합니다.
2. **W03**
   - `open.preparation`(메인 "여행 준비")은 시간 선택을 엽니다. 준비 화면은 시간 선택의 진행 버튼으로만 들어갑니다.
   - 선택값은 `model.preparedJourney` 하나에서 읽습니다.
   - 준비 화면 "완료 버튼 없음" 검증은 `PreparationFlowUITests.testPreparationScreenExposesOnlyTheBackButtonAndNoCompletionAction`으로 옮겨 두었습니다. W03이 준비 화면에 버튼을 넣을 때 이 테스트를 고쳐야 합니다.
3. **UITestBootstrap guard의 새 의미**: `--fm-ui-save fail`은 "모든 쓰기 실패 + 메인일 때만 시드 실패 저장 1회"입니다. W01의 카드 발급 저장 실패 테스트도 같은 의미로 맞춥니다. 공용 실패 문구를 숨기는 조건(`RootView.swift:15`)도 W01 화면에 같은 방식으로 넓힐지 함께 정합니다.
4. **W04**
   - 카탈로그 밖 정류장(id로 찾지 못하는 경우)의 처리를 다시 검토합니다.
   - 실행 중에 현재 정류장이 바뀌면 `journeyPlan`의 선택을 무효로 만들어야 합니다. W02에서 뺀 `selectedOrigin`에 해당하며, 다시 넣거나 정류장을 저장할 때 초안을 초기화해야 합니다.

## 탐색 추가 항목
- `ios/FocusMate/AppModel.swift:5-14` → `Destination`. `.time`을 추가할 곳
- `ios/FocusMate/AppModel.swift:43-59` → `save`. :53에서 진입 상태가 바뀌면 path를 비웁니다. 그 뒤에 `path = [.time]`을 넣습니다
- `ios/FocusMate/AppModel.swift:61-64` → `open`은 메인에서만 동작합니다
- `ios/FocusMate/AppSnapshot.swift:35-38` → `updatingStage`가 영역 3개를 보존합니다
- `ios/FocusMate/RootView.swift:15-18` → 공용 저장 실패 문구. 정류장 설정 화면에서는 숨깁니다
- `ios/FocusMate/RootView.swift:24-33, 57-59, 67-70` → W02가 고칠 곳
- `ios/FocusMate/UITestBootstrap.swift:42-52` → 쓰기 실패 저장소, 메인 전용 시드 실패 저장
- `ios/FocusMate/UITestBootstrap.swift:60-62` → ready 시드의 id가 순환 정류장 id 체계와 맞습니다
- `ios/FocusMate/FocusMateApp.swift:57-59` → `applySaveScenario`를 부르는 곳
- `ios/FocusMateUITests/Phase1FlowTests.swift:43-70, 161-186` → 기대값을 바꾸거나 옮길 대상
- `ios/FocusMateTests/AppFoundationTests.swift:279-306` → 저장소 클로저 주입과 path 비우기 테스트 패턴
- `ios/FocusMateTests/StorageTestSupport.swift:7` → `stage` 헬퍼
- `scripts/check-ios.py:35-39` → 파일 이름과 클래스 이름이 같아야 하는 규칙
- `designs/final/animation-preview.html:647, 671, 642, 788, 856` → wrap·방면, 검색, 버스(웹 표시 순서 302, 421, 2014), 정류장 9개, 후보 계산

---

## 확인이 필요한 사항

추가 확인 사항 없음. 설계가 완료되었습니다.

## Testability 평가 (test-architect)

> 1회차 초안 기준 평가. 필수 권고 1(태스크 재구성)·권장 2·4는 최종 설계에 반영됨, 권장 3(MotionPolicy 순수 함수)은 MotionPolicy 제거로 해소.

**판정: PASS (8/10), 다만 구현 순서는 고쳐야 합니다.** 동작 컴포넌트는 대부분 순수 값이거나 클로저 주입으로 테스트할 수 있어서 재설계는 필요 없습니다. 감점의 대부분은 구현 순서에서 나옵니다. 4~8단계에는 먼저 실패하는 테스트가 없고, UI 테스트는 9단계에서 구현이 끝난 뒤에 한꺼번에 작성됩니다. RED가 성립하지 않으므로 아래 "권고 1"처럼 재구성하는 것을 착수 조건으로 겁니다.

**러너 확인**
- `scripts/check-ios.py`는 `-only-testing:<폴더>/<파일명>`으로 실행합니다(:35-39).
- `project.pbxproj`가 `PBXFileSystemSynchronizedRootGroup`을 쓰므로(:22-25) 새 테스트 파일은 타깃에 자동으로 포함됩니다. 하네스는 따로 필요 없습니다.
- 주의할 점이 하나 있습니다. Swift 테스트 타깃은 한 번에 컴파일됩니다. 그래서 RED가 "심볼 없음" 컴파일 오류이면, 그동안 같은 타깃의 다른 테스트도 함께 빌드에 실패합니다. 태스크를 순서대로 진행하면 문제가 없지만, 병렬 RED는 피해야 합니다.

### 컴포넌트별 테스트 전략

#### RouteData (`RouteStops`, `StationCatalog`, `BusLine`)
- 레이어: 동작 (순수 유틸)
- 러너: `python3 scripts/check-ios.py test ios/FocusMateTests/StationCatalogTests.swift`
- 단위 테스트
  - 검색어별 결과 id 목록을 확인합니다: "서울숲" 2건, "건대" 1건, "성수" 3건, "  성수사거리  "는 공백 없는 검색과 같은 결과, 공백만이거나 빈 검색어는 3건, "없는역" 0건.
  - 방면 문구와 `snapshot`의 (id, 이름, 방향)을 확인합니다.
  - `wrap` 경계(-1, 9, 72)와 `position(of:)`을 확인합니다. id로 찾는 경우, 이름으로 다시 찾는 경우, 둘 다 실패하는 경우, ready 시드 `seoulForest`/-1이 index 4·역방향이 되는 경우를 봅니다.
- 통합 테스트: 없음
- 모의 대상: 없음 (`static let` 상수)
- 격리 전략: SwiftUI와 저장소를 import하지 않습니다.
- AC 매핑: AC-2, AC-3 (AC-1, 4, 5의 데이터 기반)

#### JourneyPlanner (`JourneyCandidate`, `JourneySelection`)
- 레이어: 동작 (순수 유틸)
- 러너: `.../FocusMateTests/JourneyPlannerTests.swift`
- 단위 테스트
  - 분과 출발 위치 조합의 표를 그대로 단언합니다: 25, 24, 120, 15, 360분 정방향, 60분 역방향, 60분 서울숲역 출발.
  - `distanceText(stops:)`는 정수 연산이라 결과가 항상 같습니다. 2.75, 11, 1.65, 24.75, 39.6, 33을 확인합니다.
  - 14, 361분이면 빈 배열인지, `clamp`가 맞는지 확인합니다.
  - `accessibilityLabel`이 "지선 2014번, 성동구민체육센터, 60분, 12정류장"인지 확인합니다.
- 통합 테스트: 없음
- 모의 대상: 없음
- 격리 전략: 순수 함수입니다.
- AC 매핑: AC-11(후보 부분), 12, 13, 14, 15, 16, AC-23(레이블 문자열)

#### StationSearchState
- 레이어: 동작 (상태 로직)
- 러너: 설계서에 **테스트 파일이 없습니다**. `StationSearchStateTests.swift`를 새로 만들거나, `StationCatalogTests`에 넣는다고 명시해야 합니다.
- 단위 테스트
  - 처음에는 결과 3건이고 `canConfirm == false`입니다.
  - 0건이면 `select`가 false를 돌려줍니다.
  - 역방향을 고르면 `confirmationText`가 "성수역 · 성수사거리 방면에서 출발"이고 `canConfirm == true`입니다.
  - 검색어를 바꿔서 고른 항목이 결과에서 빠지면 `selectedOption`이 nil이 되고 확인 버튼도 꺼집니다.
- 모의 대상: 없음
- 격리 전략: 값 타입이라 View의 `@State` 없이 생성합니다.
- AC 매핑: AC-1, AC-4, AC-5

#### JourneyPlanDraft / ProceedState
- 레이어: 동작 (상태 로직)
- 러너: `.../FocusMateTests/JourneyPlanDraftTests.swift`
- 단위 테스트
  - 기본값은 25분, 선택 없음, `needsSelection`입니다.
  - `setMinutes(14/361)`은 15/360으로 맞춰지고, `step` 경계에서도 같습니다. 범위 맞춤 때문에 값이 그대로면 선택이 유지됩니다.
  - 17분이면 `noCandidates`, 60분 미선택이면 `needsSelection`이고, `title`과 `isEnabled`를 함께 봅니다.
  - `choose`는 하나만 고를 수 있고, 후보에 없는 버스는 false입니다.
  - 60→61→60분으로 바꾸면 선택이 풀린 채로 남습니다.
  - 고를 때와 다른 출발 위치를 넘기면 `selectedCandidate`가 nil입니다.
- 모의 대상: 없음
- 격리 전략: `private(set)`이지만 변경 함수로 모든 상태에 도달할 수 있습니다.
- AC 매핑: AC-10(모델), 11, 17, 18, 19, 20, AC-23(`step` ±1)

#### AppModel+JourneyStart (+ `Destination.time`, `journeyPlan`)
- 레이어: 동작 (상태와 라우팅 가드)
- 러너: `.../FocusMateTests/JourneyStartModelTests.swift`
- 주입 가능성: **좋습니다.**
  - `LocalSnapshotStore.init(fileURL:readData:createDirectory:writeData:)`가 클로저 3개를 모두 주입받습니다(`LocalSnapshotStore.swift:14-17`).
  - `AppModel(store:)` 패턴은 `AppFoundationTests.swift:259-306`에서 이미 검증되었습니다.
  - `readData`는 `SnapshotCodec.encode(stage(true, nil, nil))`를 돌려주게 합니다(`SnapshotCodec.swift:36`, `StorageTestSupport.swift:7` 확인).
- 단위 테스트
  - AC-6, 25: `writeData`가 받은 `Data`를 붙잡아 디코드하고 정류장 2개와 카드·여정·기록 영역을 단언합니다. `model.snapshot`만 보는 것보다 강하고, 실제로 파일에 쓰인 바이트를 확인합니다.
  - AC-7: `launchState == .ready(.main)`이고 `path == [.time]`입니다. `save`가 :53에서 `path = []`로 비운 다음에 들어가는 순서까지 확인됩니다.
  - AC-8: 쓰기 실패 클로저로 false, `path == []`, 진입 상태 유지, `.writeFailed`를 봅니다. 플래그를 바꿔 다시 시도하면 성공하는지도 봅니다.
  - AC-9, BR-1: 메인 상태에서 `confirmInitialStation`을 부르면 false이고 `writeCalls == 0`입니다.
  - AC-21: `proceedToPreparation()`의 반환값, `preparedJourney`, `path`, 쓰기 0회를 확인합니다. 미선택이거나 후보가 없으면 nil이고 path가 그대로인지도 봅니다(BR-2의 두 번째 방어).
  - AC-22: 준비로 진행한 뒤 `goBack()`해도 `journeyPlan`이 그대로입니다.
  - `journeyOrigin`이 nil이 되는 경로: 미지 id 스냅샷을 `stage(true, x, x)`로 만들어 확인합니다.
- 통합 테스트: 실제 파일 바이트는 UI 테스트의 `test.persistedBytes`가 확인합니다.
- 모의 대상: `readData`, `createDirectory`, `writeData` 클로저 (호출 횟수 카운터 포함)
- 격리 전략: 새 파일의 extension이라 `AppModel` 본체와 W01 변경에 영향을 받지 않습니다.
- AC 매핑: AC-6, 7, 8, 9, 21, 22, 25, AC-26(모델)
- 짚을 점 두 가지
  - AC-26 단위 테스트 "새 `AppModel`의 `journeyPlan == JourneyPlanDraft()`"는 기본값 선언을 다시 확인하는 데 그칩니다. 실제 검증은 UI 재실행 테스트가 맡는다고 명시하면 충분합니다.
  - 출발 위치를 찾지 못했을 때 "후보를 비우고 진행을 막는" 분기의 위치가 정해져 있지 않습니다. `JourneyPlanDraft.proceedState(from:)`가 Optional이 아닌 출발 위치만 받기 때문에, 이 분기가 View에 들어가면 단위 테스트를 할 수 없습니다. `AppModel` extension에 `timeProceedState`와 `timeCandidates`를 두거나, 인자를 Optional로 받게 하라고 권고합니다.

#### UITestBootstrap guard 변경
- 레이어: 동작 (테스트 하네스)
- 러너: UI 테스트로 간접 검증합니다.
- 확인 사항
  - `modelStore`의 쓰기 실패 저장소(:42-45)는 시드와 상관없이 적용됩니다.
  - `prepare()`는 실패하지 않는 별도 저장소로 시드를 씁니다(:32).
  - 그래서 guard만 "메인이 아니면 그냥 넘어감"으로 바꾸면 cardOnly 시드와 `--fm-ui-save fail` 조합이 성립합니다. 기존 `Phase1FlowTests:123-146`(ready 시드와 fail 조합)도 그대로 유지됩니다.
- AC 매핑: AC-8(UI)

#### MotionPolicy (`performNavigation`)
- 레이어: 대부분 표현. "애니메이션이 없음"은 §3의 "애니메이션 타이밍·트랜지션"에 해당해 범위 밖이고 감점하지 않습니다.
- 동작으로 볼 수 있는 부분은 "어느 분기를 타는지"와 "어느 분기든 기능이 같은지"입니다.
- 현재 설계에서는 단위 검증이 불가능하다고 보고 수동 확인으로 둡니다. 하지만 간단히 테스트 가능하게 바꿀 수 있습니다(권고 3).
  - 순수 함수 `navigationTransaction(reduceMotion:) -> Transaction`을 분리합니다.
  - XCTest에서 `.disablesAnimations`를 단언합니다. `Transaction`은 테스트에서 바로 만들 수 있는 값입니다.
- 남는 한계
  - `EnvironmentValues.accessibilityReduceMotion`은 읽기 전용이고, 시뮬레이터에서 켜는 실행 인자도 확실하지 않습니다. 그래서 자동 UI 테스트는 "동작 줄이기 = 켜짐" 분기를 실행하지 못합니다.
  - 이 한계를 trust-ledger에 "수동: 실기기에서 동작 줄이기를 켜고 AC-24 경로를 확인"으로 기록하는 처리가 타당합니다.
- AC 매핑: AC-24(부분)

#### InitialStationSearchView / TimeSelectionView / DestinationScreen / RootView 연결
- 레이어: 동작(조건부 표시, 비활성, 이동)과 표현(레이아웃)이 섞여 있습니다. 동작 부분만 평가합니다.
- 러너: `python3 scripts/check-ios.py test ios/FocusMateUITests/FirstStationTimeFlowTests.swift`와 `.../Phase1FlowTests.swift`
- 셀렉터 규약(§4): **적합합니다.**
  - 버튼 문구와 접근성 레이블(role/텍스트)을 쓰고, 기존 규약대로 `accessibilityIdentifier`(data-testid에 해당)를 씁니다.
  - 구조 셀렉터나 스타일 단언은 없습니다.
  - AC-17, 18은 `isEnabled == false`, `label` 문구, 탭한 뒤 `screen.time`이 남아 있는지를 함께 봅니다. "비활성이면서 실제로 이동하지 않는다"까지 검증하므로 §5의 원칙에 맞습니다.
- 휠 Picker 조작성: 표준 API로 다룰 수는 있지만 **가장 큰 리스크입니다.**
  - `adjust(toPickerWheelValue: "60분")`은 항목 문구와 정확히 같아야 합니다.
  - 더 큰 위험이 있습니다. Picker에 `.accessibilityValue`와 `.accessibilityAdjustableAction`을 직접 붙이면 SwiftUI가 요소를 `pickerWheel`이 아닌 다른 타입으로 노출할 수 있습니다. 그러면 `pickerWheels.firstMatch` 조회가 깨질 수 있습니다.
  - VoiceOver 1분 증감(AC-23)은 XCUITest로 직접 확인할 수 없습니다. 그래서 `step(by:)` 단위 테스트와 연결 코드 리뷰로 대신합니다.
  - 휠을 조작하는 첫 UI 테스트를 가장 먼저 RED로 세워서 탐색 검증(spike)으로 삼으라고 권고합니다. 실패하면 설계서에 적힌 대안(Stepper와 DEBUG 직접 입력)으로 바로 바꿉니다.
- DEBUG `test.journeySelection` 진단: **타당합니다.**
  - 준비 화면 내용(W03)을 건드리지 않고 AC-21의 "전달된 선택값"을 바깥에서 관찰할 수 있는 유일한 수단입니다.
  - 기존 진단 규약(`RootView.swift:36-47`의 `test.snapshot`)과 같은 방식입니다.
  - 조건 세 가지를 지켜야 합니다.
    - (a) `#if DEBUG`로 감싸고 버튼이 아닌 `Text`로 둡니다. 그래야 `Phase1FlowTests:178-179`의 버튼 수 단언에 영향이 없습니다.
    - (b) JSON은 `sortedKeys`로 만들고, 테스트는 문자열 비교 대신 파싱해서 비교합니다.
    - (c) 값이 `model.preparedJourney`를 그대로 읽는다는 것은 단위 테스트(`proceedToPreparation() == preparedJourney`)가 1차로 보장합니다.
  - 선택 사항: RootView 오버레이에 두고 nil이면 "null"을 내보내면 AC-26("선택 없음")도 확인할 수 있습니다. 하지만 RootView 수정 줄이 늘어 W01과 충돌할 위험이 커지므로 지금 안을 유지해도 됩니다.
- 실행 인자 `-UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXXXL`과 `isHittable`로 AC-24의 "도달 가능"을 확인할 수 있습니다.
- 기존 테스트 영향: `AppFoundationTests.swift:220`의 `allCases` 순회는 cardEntry 상태라 `open`이 무시되므로 `.time`을 추가해도 영향이 없습니다.
- AC 매핑: AC-1~5(UI 대표), 7, 8, 9, 10~23(UI 대표), 24(큰 글자), 26(재실행과 `persistedBytes`)

### Testability Score: 8/10 (동작 컴포넌트 기준)

| 컴포넌트 | 점수 | 근거 |
|---|---|---|
| RouteData, JourneyPlanner | 10 | 순수 함수이고 경우의 표를 그대로 단언할 수 있음 |
| StationSearchState, JourneyPlanDraft | 9 | 값 타입. 테스트 파일 이름이 빠진 것만 보완하면 됨 |
| AppModel+JourneyStart | 9 | 클로저 3개 주입 패턴이 이미 검증됨. 출발 위치 nil 분기의 위치가 정해지지 않음 |
| 화면과 연결 | 6 | 휠 조작성 리스크, VoiceOver와 동작 줄이기는 자동 검증 불가 (일부는 표현이라 감점 대상 아님) |
| 태스크 분해 | 감점 | 4~8단계에 RED가 없고, UI 테스트는 구현 뒤에 몰아서 작성 |

### 판정: PASS (조건부)

- **사유:** 핵심 규칙과 상태는 시뮬레이터 없이 XCTest로 AC를 모두 덮고, 저장 경로는 클로저 주입으로 완전히 격리됩니다. 재설계(인터페이스 추출 등)는 필요 없습니다.

**권고 (착수 전에 반영)**

1. **[필수] 태스크 재구성.** 지금은 4(bootstrap), 5(MotionPolicy), 6~8(View·RootView)에 각자 실패하는 테스트가 없고, 9단계에서 UI 테스트를 몰아서 씁니다. 이렇게 하면 test-after가 되어 RED를 목격할 수 없습니다. 태스크를 AC 묶음으로 바꾸고, 각 태스크가 UI 테스트를 먼저 쓰도록 합니다.
   - T1 도메인: AC-2, 3, 12~16, 23(문자열)
   - T2 화면 상태: AC-1, 4, 5, 10, 11, 17~20 (`StationSearchStateTests`를 명시)
   - T3 모델 저장·네비게이션: AC-6, 7, 8, 9, 21, 22, 25, 26
   - T4 검색 화면 UI: AC-1~5, 7. `FirstStationTimeFlowTests`를 먼저 쓰고 InitialStationSearchView와 RootView :58-59를 고칩니다.
   - T5 저장 실패 UI: AC-8. UI 테스트를 먼저 쓰고 bootstrap guard를 고칩니다.
   - T6 시간 화면 UI: AC-10~20, 23. 휠 조작 테스트를 맨 앞에 둡니다. `Phase1FlowTests:50, :166` 기대값 변경도 RED로 먼저 넣고, TimeSelectionView, DestinationScreen, RootView :25-32, :67-68을 고칩니다.
   - T7 준비 진행·왕복·재실행 UI: AC-21, 22, 9, 26
   - T8 큰 글자와 MotionPolicy: AC-24. 권고 3의 순수 함수 단위 테스트를 함께 씁니다.

   T1~T3은 단위 테스트 러너, T4~T8은 UI 테스트 러너로 RED를 확인합니다.
2. **[권장] 출발 위치를 찾지 못했을 때의 처리를 모델 쪽 계산 속성에 둡니다.** 그러면 `time.originUnavailable` 분기를 단위 테스트할 수 있습니다.
3. **[권장] `navigationTransaction(reduceMotion:)`을 순수 함수로 분리하고 단위 테스트합니다.** "애니메이션 없음"을 눈으로 확인하는 일과 VoiceOver 증감은 수동 확인으로 trust-ledger에 기록합니다.
4. **[권장] AC-6, 25 단위 테스트는 `writeData`가 받은 바이트를 붙잡아 단언합니다.** AC-26 단위 테스트는 단언 내용이 약하다는 점을 명시하고, 재실행 UI 테스트를 정식 검증으로 둡니다.

### 탐색 추가 항목
- `ios/FocusMate/LocalSnapshotStore.swift:14-17`: 클로저 3개 주입 시그니처. JourneyStartModelTests의 근거입니다.
- `ios/FocusMate.xcodeproj/project.pbxproj:22-25`: 동기화 그룹이라 새 파일이 타깃에 자동으로 포함됩니다.
- `ios/FocusMate/FocusMateApp.swift:20, 53-59`: `modelStore` 주입과 `prepare()`, `applySaveScenario` 호출 순서. cardOnly와 fail 조합이 성립하는 근거입니다.
- `ios/FocusMate/RootView.swift:36-47`: DEBUG 진단 오버레이 규약. `test.journeySelection`도 같은 방식으로 둡니다.
- `ios/FocusMateTests/AppFoundationTests.swift:205-229`: `Destination.allCases`를 순회하지만 cardEntry 상태라 `.time`을 추가해도 영향이 없습니다.
- `ios/FocusMateUITests/Phase1FlowTests.swift:161-186`: 버튼 수 단언. 진단 `Text`는 버튼이 아니므로 영향이 없습니다.
- `ios/FocusMate/AppSnapshot.swift:52-59`: `validate()`가 방향 1|-1과 빈 id·이름을 막습니다. 카탈로그 값은 이 검증을 통과합니다.