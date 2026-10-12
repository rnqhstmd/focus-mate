## 설계 초안: Phase 2 카드·여행 준비·승차 인식

### 설계 규모

**대형** — 카드 발급, 최초 정류장 설정, 여행 준비, 오디오, 승차 인식, 저장 호환성 및 생명주기를 함께 연결한다.

설계만 작성했다. 파일 저장·수정, 빌드·테스트는 실행하지 않았다. 아래 Swift 선언은 구현 본문을 제외한 계약이며, 신규 파일은 제안 경로다.

### 배경 및 목적

- 기존 `AppSnapshot → LocalSnapshotStore → AppModel → RootView` 구조를 확장한다.
- 신규 사용자는 카드 발급과 최초 정류장 설정을 한 번 완료하고 시간 선택으로 이동한다.
- 재방문 사용자는 저장된 현재 정류장과 방면을 그대로 유지한다.
- 승차 인식 성공 순간에 준비값을 저장하고 Phase 3가 읽을 수 있는 인계 상태를 남긴다.
- 실제 여행 타이머·지도 이동·일시정지·도착·완료 기록은 생성하지 않는다.

기준 문서는 [승인된 PRD](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/.dev/codex-feat-phase-2-card-boarding/prd.md:1)다. 도메인 문서의 “Swift 소스는 아직 존재하지 않는다”는 설명과 `FLOWS.md`의 이전 승차권 필드 설명은 현재 코드 및 승인 PRD보다 우선하지 않는다.

### 요구사항 및 수용 기준

다음은 PRD의 기능 요구사항 제목을 그대로 발췌했다. 모두 `[Must]`다.

| 요구사항 | 설계 책임 | 수용 기준 |
|---|---|---|
| **P2-FR-1: 집중동행카드 1회 발급** | ID 생성, 발급 저장, 기존 사용자 ID 보완 | AC-1, AC-15 |
| **P2-FR-2: 최초 정류장 1회 설정** | 최초 설정 제한, 최초·현재 정류장 동시 저장 | AC-2, AC-3 |
| **P2-FR-3: 재방문 메인과 여행 준비 진입** | 읽기 전용 현재 정류장, 여행 준비 진입 | AC-3 |
| **P2-FR-4: 시간·버스·도착지 확정** | 가상 노선 정책과 명시적 후보 선택 | AC-4~6 |
| **P2-FR-5: 태그와 할 일 준비** | 태그 선택·추가, 정규화·길이 검증 | AC-7, AC-8 |
| **P2-FR-6: 여행 소리 선택** | 확정값·초안 분리, 로컬 미리듣기 | AC-9 |
| **P2-FR-7: 간결한 승차권** | 필수 준비 검증, 여섯 필드 표시 | AC-10 |
| **P2-FR-8: 승차 접촉 인식** | 공통 입력 처리, 시간 순서, 취소 | AC-11~13 |
| **P2-FR-9: 지속 가능한 1회 인계와 기존 사용자 보호** | 성공 시 저장, 복원, 오류 보호 | AC-13~18 |

수용 기준의 핵심 `Then`은 다음과 같다. 원문을 인용하며, 검증 경계는 뒤의 상세 설계에서 연결한다.

| AC | PRD 인용 |
|---|---|
| 1 | “`FM-12345678` 형식의 동일한 카드 ID가 표시되고 카드 발급을 다시 요구하지 않는다.” |
| 2 | “최초·현재 정류장이 모두 `성수역`과 `정방향`으로 보존되고 바로 시간 선택으로 이동한다.” |
| 3 | “현재 정류장 메인에서 시작하고 `성수역 · 정방향`을 읽기 전용으로 표시하며 검색·변경·워프·초기화 행동을 제공하지 않는다.” |
| 4 | “`25분 · 2014번 · 서울숲 입구`가 확정되고 여행 준비로 이동할 수 있다.” |
| 5 | “이동이 차단되고 버스·도착지 선택이 필요하다는 안내가 표시된다.” |
| 6 | “`2014번 · 서울숲 입구` 선택이 해제되고 새 후보를 선택하기 전까지 준비로 이동할 수 없다.” |
| 7 | “기존 태그 선택과 새 태그 추가만 제공되고 최근 할 일·기본 시간·편집 행동은 없으며, 중복 태그는 저장되지 않는다.” |
| 8 | “확정이 차단되며, `책 한 챕터 읽기`처럼 공백이 아닌 80자 이하의 할 일만 승차권 진행 조건을 충족한다.” |
| 9 | “초기 확정값은 `소리 없음`이고 음량은 기기 볼륨을 따르며, 시간·버스·도착지·태그·할 일 초안은 그대로 유지된다.” |
| 10 | “이 여섯 항목만 표시되고 태그·할 일·소리·상태 문구는 표시되지 않으며 진행 여정이나 완료 기록도 생성되지 않는다.” |
| 11 | “모두 동일한 카드 ID와 준비값으로 승차 인식 성공 상태에 도달한다.” |
| 12 | “승차 성공·Phase 3 인계·타이머 진도·완료 기록이 생성되지 않는다.” |
| 13 | “해당 값과 승차 인식 완료 상태가 1400ms 안내 및 450ms 전환 전에 정확히 한 번 보존된다.” |
| 14 | “P2-AC-13의 동일한 값으로 하나의 인계 상태만 확인되며 늦은 화면 전환, 실제 남은 시간, 진행률, 이동 정류장, 일시정지, 도착, 완료 기록은 생성되지 않는다.” |
| 15 | “최초·현재 정류장과 방면은 정확히 유지되고 카드 ID만 한 번 생성되며, 두 번째 실행에서도 같은 ID를 사용하고 재발급·정류장 재설정을 요구하지 않는다.” |
| 16 | “빈 상태나 카드 재발급 상태로 진행하지 않고 기존 파일을 변경하지 않으며 불러오기 또는 보완 성공으로 안내하지 않는다.” |
| 17 | “원본을 빈 상태·신규 카드·Phase 2 인계로 덮어쓰지 않고 성공 화면으로 이동하지 않는다.” |
| 18 | “기존 최초·현재 정류장과 방면 및 기존 파일이 정확히 유지되고 실패한 변경은 성공으로 안내되거나 다음 단계에 확정되지 않는다.” |

### 변경 범위

기존 단일 앱 타깃을 유지한다. 별도 패키지·DB·서버·범용 상태 관리 프레임워크는 추가하지 않는다.

| 구분 | 파일 |
|---|---|
| 저장 값 수정 | `ios/FocusMate/AppSnapshot.swift` |
| 저장 형식 확장 | `ios/FocusMate/LocalSnapshotStore.swift` |
| 상태·탐색·명령 통합 | `ios/FocusMate/AppModel.swift` |
| 화면·의존성 연결 | `ios/FocusMate/RootView.swift`, `FocusMateApp.swift` |
| 시험 진입 확장 | `ios/FocusMate/UITestBootstrap.swift` |
| 신규 값·정책 | `ios/FocusMate/Phase2Values.swift`, `VirtualRouteCatalog.swift`, `PreparationPolicy.swift` |
| 신규 외부 효과 처리 | `ios/FocusMate/BoardingCoordinator.swift`, `SoundPreviewPlayer.swift` |
| 신규 네이티브 화면 | `ios/FocusMate/CardViews.swift`, `StationViews.swift`, `PreparationViews.swift`, `BoardingViews.swift`, `MapBackdropView.swift` |
| 신규 리소스 | `ios/FocusMate/Resources/Audio/`, `ios/FocusMate/Assets.xcassets/CityMap.imageset/` |
| 기존 테스트 조정 | `ios/FocusMateTests/AppFoundationTests.swift`, `ios/FocusMateUITests/Phase1FlowTests.swift` |
| 신규 테스트 대상 | `Phase2PolicyTests.swift`, `BoardingCoordinatorTests.swift`, `Phase2StorageTests.swift`, `Phase2FlowTests.swift` |

신규 단위 테스트는 `ios/FocusMateTests/`, UI 테스트는 `ios/FocusMateUITests/`에 둔다.

### 적용 컨벤션

- **프로젝트 타입 SSOT:** [.claude/config.json:52](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/.claude/config.json:52). Node와 `ios-swiftui`가 함께 등록되어 있으며 이번 기능의 구현 대상은 iOS다.
- **작업 기준:** iOS 17, Swift 언어 모드 5, SwiftUI·Observation·XCTest. [project.pbxproj:54](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate.xcodeproj/project.pbxproj:54)
- **네이밍:** 타입은 UpperCamelCase, 프로퍼티·함수는 lowerCamelCase. 기존 정류장 ID와 `direction: Int`의 `1/-1` 표현을 유지한다.
- **상태:** `@MainActor @Observable AppModel`이 앱 상태를 소유하고 뷰는 `@Bindable`로 연결한다.
- **저장 값:** `Codable, Equatable` 구조체와 명시적 검증을 사용한다.
- **외부 의존성:** 저장소의 기존 클로저 주입을 유지한다. 오디오와 지연 실행에만 작은 대체 가능 경계를 둔다.
- **테스트:** `XCTest`, `@testable import FocusMate`, 고유 임시 디렉터리, 실제 파일 및 주입 실패 조건을 사용한다.
- **파일 등록:** 앱·단위 테스트·UI 테스트가 Xcode 동기화 그룹이다. [project.pbxproj:23](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate.xcodeproj/project.pbxproj:23)

탐색한 범위에는 별도 `CLAUDE.md`, 린터·포맷터 설정이 없었다. 상위 `AGENTS.md`가 참조하는 `RTK.md`도 확인되지 않았다. 현재 코드 패턴과 제공된 지시로 설계할 수 있어 차단 사항은 아니다.

### 상세 설계

#### 1. `Phase2Values.swift` — 저장 값과 준비 초안의 계약

**현재:** 카드 발급 여부와 두 정류장만 저장한다. [AppSnapshot.swift:14](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/AppSnapshot.swift:14)

**변경:** 화면 초안, 확정 준비값, 영속 인계를 분리한다. 준비 초안은 화면 왕복 동안 메모리에 유지하고, 승차 성공 시 확정 준비값 전체를 저장한다. 새로 저장한 사용자 태그는 별도로 영속화한다.

다음 값 타입은 모두 `internal`이며 테스트에서 `@testable`로 접근한다. 불변 구조체는 아래 필드 순서의 memberwise initializer를 제공한다.

```swift
enum SoundChoice: String, Codable, CaseIterable {
    case none, pinkNoise, rain, forest, bus
}

enum TagIcon: String, Codable, CaseIterable {
    case book, briefcase, cap, code, pen
}

enum TagColor: String, Codable, CaseIterable {
    case sand = "#d7b378"
    case blue = "#82aaf2"
    case purple = "#b49ce1"
    case green = "#91b9ab"
    case pink = "#d596a6"
}

struct TagSnapshot: Codable, Equatable {
    let id: String
    let name: String
    let icon: TagIcon
    let color: TagColor
}

struct JourneyOption: Codable, Equatable {
    let id: String
    let origin: StationSnapshot
    let destination: StationSnapshot
    let minutes: Int
    let busID: String
    let busNumber: String
    let stopCount: Int
    let distanceMeters: Int
}

struct PreparedJourney: Codable, Equatable {
    let journey: JourneyOption
    let tag: TagSnapshot
    let task: String
    let sound: SoundChoice
}

enum BoardingStatus: String, Codable {
    case recognized
}

struct BoardingHandoff: Codable, Equatable {
    let id: UUID
    let cardID: String
    let preparation: PreparedJourney
    let status: BoardingStatus
}

struct NewTagDraft: Equatable {
    var name: String = ""
    var icon: TagIcon = .book
    var color: TagColor = .sand
}

struct PreparationDraft: Equatable {
    var minutes: Int = 25
    var selectedJourney: JourneyOption? = nil
    var tagID: String? = nil
    var taskDraft: String = ""
    var confirmedTask: String? = nil
    var selectedSound: SoundChoice = .none
    var pendingSound: SoundChoice = .none
    var newTag: NewTagDraft = NewTagDraft()
}
```

**값 처리**

- 출발 정류장은 저장된 현재 정류장의 ID·이름·방면을 그대로 복사하며 이름을 보정하지 않는다.
- 승차권을 열 때 확정한 준비값은 승차 인식에 전달한 후 변경하지 않는다.
- 인계에는 현재 시각·남은 시간·진도·일시정지·완료 기록을 추가하지 않는다.
- 인계 ID는 완료 기록 ID가 아니다.
- 공통 카드 이름은 `집중동행카드`이며 이름·외형 편집 저장값은 추가하지 않는다.

#### 2. `AppSnapshot.swift` / `LocalSnapshotStore.swift` — 단순한 Codable 확장과 호환성

**현재:** version 1 envelope, 검증 후 저장, 기존 파일 재확인, sorted-key JSON, atomic write를 사용한다. [LocalSnapshotStore.swift:24](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/LocalSnapshotStore.swift:24)

**변경 결정:** **version 1과 2를 읽고, 새 저장은 version 2로 기록한다.** 별도 마이그레이션 프레임워크나 중간 DTO는 만들지 않는다. 동일 `AppSnapshot`의 선택 필드 디코딩으로 이전 파일을 읽는다.

version 2를 쓰면 기존 Phase 1 앱은 이를 미지원으로 분류하므로 새 필드를 모르는 구버전 앱이 조용히 제거하는 일을 피할 수 있다.

```swift
struct AppSnapshot: Codable, Equatable {
    let cardIssued: Bool
    let initialStation: StationSnapshot?
    let currentStation: StationSnapshot?
    let cardID: String?
    let customTags: [TagSnapshot]
    let boardingHandoff: BoardingHandoff?

    init(
        cardIssued: Bool,
        initialStation: StationSnapshot?,
        currentStation: StationSnapshot?,
        cardID: String? = nil,
        customTags: [TagSnapshot] = [],
        boardingHandoff: BoardingHandoff? = nil
    )

    init(from decoder: Decoder) throws
    func encode(to encoder: Encoder) throws
    func validate() throws
    func launchRoute() throws -> LaunchRoute
}
```

기존 세 인자의 초기화 호출은 계속 컴파일되는 계약이다.

**디코딩 및 검증 규칙**

1. 기존 `cardIssued`는 필수다. 기존 정류장 검증과 오류 우선순위를 유지한다.
2. 새 필드는 `decodeIfPresent`로 읽는다. 누락·`null`인 `cardID`와 인계는 `nil`, `customTags`는 `[]`다.
3. 새 필드가 존재하지만 타입·enum 값이 잘못되면 기본값으로 삼키지 않는다.
4. 기존 정류장 두 필드는 인코딩 시 지금처럼 `null`을 명시한다. 기존 UI 테스트가 이를 검사한다.
5. `cardIssued == true && cardID == nil`은 유효한 이전 데이터다. 보완은 디코더나 저장소의 `load()`가 아니라 `AppModel`이 담당한다.
6. 존재하는 카드 ID는 정확히 `FM-`와 ASCII 숫자 8자리여야 한다.
7. 사용자 태그 ID는 비어 있지 않고 기본 태그·다른 사용자 태그 ID와 겹치지 않아야 한다. 이름도 동일한 정규화 규칙으로 중복되지 않아야 한다.
8. 인계가 있으면 카드가 발급되어 있고, 인계 카드 ID가 상위 `cardID`와 같아야 한다.
9. 인계 출발지는 `currentStation`과 **ID·이름·방면 모두 일치**해야 한다. 최초 정류장과 현재 정류장이 다를 수 있다는 기존 계약은 유지한다.
10. 인계의 태그는 기본 태그 또는 저장된 사용자 태그의 정의와 일치해야 한다. 준비값은 아래 정책 검증을 통과해야 한다.
11. 기존 정류장 자체에 가상 카탈로그 소속 검사를 추가하지 않는다. 알 수 없는 과거 정류장을 손상 데이터로 바꾸지 않는다.

기존 `SnapshotValidationIssue`의 네 case는 유지하고 다음을 추가한다.

```swift
case invalidCardID
case invalidTags
case invalidBoardingHandoff
```

검증 순서는 **기존 단계·정류장 검증 → 카드 → 사용자 태그 → 인계**다.

**저장소 계약은 그대로 유지한다.**

```swift
func load() throws -> AppSnapshot?
func save(_ snapshot: AppSnapshot) throws
```

| 상황 | 결과 |
|---|---|
| 파일 없음 | `nil`, 디렉터리 생성·쓰기 없음 |
| 기타 읽기 실패 | `.unreadable` |
| 깨진 JSON·잘못된 타입 | `.corrupt` |
| version 1·2 이외 | payload보다 먼저 `.unsupportedVersion(version)` |
| 의미적으로 잘못된 snapshot | `.invalidState(issue)` |
| 저장 전 기존 파일 재확인 실패 | `.writeBlocked(issue)`, 쓰기 없음 |
| 인코딩·디렉터리·쓰기 실패 | `.writeFailed` |

`save()`는 지금처럼 **후보 검증 → 기존 파일 재확인 → 인코딩 → 디렉터리 → atomic write** 순서다. 저장소의 `load()`는 ID 보완이나 파일 재작성 없이 읽기만 한다.

#### 3. `VirtualRouteCatalog.swift` — 실제 프로토타입 데이터와 일치하는 후보

**근거:** [프로토타입 버스 정의:375](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/designs/final/animation-preview.html:375), [정류장:521](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/designs/final/animation-preview.html:521), [후보 계산:571](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/designs/final/animation-preview.html:571).

앱에 고정된 값 카탈로그를 두고 HTML을 런타임에 파싱하지 않는다.

| 순서 | 네이티브 ID | 이름 |
|---|---|---|
| 0 | `seongsu` | 성수역 |
| 1 | `seongsuDong` | 성수동 |
| 2 | `ttukseom` | 뚝섬역 |
| 3 | `sportsCenter` | 성동구민체육센터 |
| 4 | `seoulForest` | 서울숲역 |
| 5 | `seoulForestEntrance` | 서울숲 입구 |
| 6 | `seongsuBridgeNorth` | 성수대교 북단 |
| 7 | `ttukseomHangangPark` | 뚝섬한강공원 |
| 8 | `seongsuIntersection` | 성수사거리 |

기존 `seongsu`, `seoulForest`, `ttukseom` ID를 그대로 사용한다. 카탈로그 위치는 ID로 찾고, 저장된 이름은 교체하지 않는다.

최초 선택 목록은 현재 프로토타입과 같은 세 조합이다.

- `seongsu / 성수역 / +1`
- `seongsu / 성수역 / -1`
- `seoulForest / 서울숲역 / +1`

| 내부 버스 ID | 표시 번호 | 정류장당 분 |
|---|---|---:|
| `2014` | `2014` | 5 |
| `302` | `강남02` | 6 |
| `421` | `343` | 8 |

```swift
enum VirtualRouteCatalog {
    static var initialStations: [StationSnapshot] { get }
    static var defaultTags: [TagSnapshot] { get }

    static func searchInitialStations(query: String) -> [StationSnapshot]
    static func candidates(
        minutes: Int,
        origin: StationSnapshot
    ) -> [JourneyOption]
}
```

**결정적 출력 규칙**

- 범위 밖 시간, 알 수 없는 출발 ID, `±1`이 아닌 방면이면 후보는 `[]`.
- `minutes % minutesPerStop == 0`인 버스만 반환한다.
- 정류장 수는 몫이며 여러 바퀴를 돌아도 축약하지 않는다.
- 도착 인덱스는 음수도 처리하는 양의 modulo 9다.
- 거리는 `stopCount × 550`미터로 보관한다.
- 후보 ID는 `"<busID>:<originID>:<direction>:<minutes>"`.
- 후보 순서는 표의 버스 순서다. 첫 후보를 자동 선택하지 않는다.
- 거리 표시는 km 소수 첫째 자리 반올림이다. `2750m → 2.8 km`.

고정 예시는 다음과 같다.

| 입력 | 출력 |
|---|---|
| 성수역/+1, 25분 | 2014, 서울숲 입구, 5개, 2750m |
| 성수역/+1, 26분 | 후보 없음 |
| 성수역/+1, 30분 | 2014와 강남02 후보 |
| 성수역/+1, 15분 | 2014, 성동구민체육센터, 3개 |
| 성수역/+1, 360분 | 세 버스 후보, 각자의 전체 정류장 수 유지 |

기본 태그는 `read/독서/book/sand`, `study/공부/cap/purple`, `work/업무/briefcase/blue`, `rest/휴식/pen/green`이다. 프로토타입에 있는 예시 할 일은 가져오지 않는다.

#### 4. `PreparationPolicy.swift` — RED 작성자가 사용할 순수 정책

```swift
enum PreparationIssue: Error, Equatable {
    case invalidMinutes(Int)
    case unknownOrigin(String)
    case journeyRequired
    case journeyMismatch
    case tagRequired
    case unknownTag(String)
    case invalidTagID
    case duplicateTagID
    case emptyTagName
    case tagNameTooLong(Int)
    case duplicateTagName
    case emptyTask
    case taskTooLong(Int)
}

enum PreparationPolicy {
    static func normalizedTagName(_ raw: String) -> String
    static func tagComparisonKey(_ raw: String) -> String

    static func makeTag(
        id: String,
        name: String,
        icon: TagIcon,
        color: TagColor,
        existing: [TagSnapshot]
    ) throws -> TagSnapshot

    static func validatedTask(_ raw: String) throws -> String

    static func changingMinutes(
        to minutes: Int,
        in draft: PreparationDraft
    ) throws -> PreparationDraft

    static func selectingJourney(
        id: String,
        origin: StationSnapshot,
        in draft: PreparationDraft
    ) throws -> PreparationDraft

    static func prepare(
        draft: PreparationDraft,
        origin: StationSnapshot,
        tags: [TagSnapshot]
    ) throws -> PreparedJourney

    static func validate(
        preparation: PreparedJourney,
        origin: StationSnapshot,
        tags: [TagSnapshot]
    ) throws
}
```

**문자열 계약**

- 태그 표시·저장 이름: 앞뒤 공백·개행 제거 후 NFKC 정규화.
- 중복 키: 위 결과에 `.caseInsensitive` folding, 고정 `en_US_POSIX` locale 적용.
- 길이는 정규화된 문자열의 `String.count`로 센다. UTF-8 바이트 수나 UTF-16 길이를 쓰지 않는다.
- `Work`와 `ｗｏｒｋ`는 같은 중복 키다.
- 태그 검증 순서: 빈 이름 → 20자 초과 → 이름 중복 → 잘못된 ID → ID 중복.
- 할 일은 앞뒤 공백·개행만 제거한다. 본문 내부 공백과 줄바꿈은 보존한다.
- 할 일은 `String.count` 1~80자다. 빈 값은 `.emptyTask`, 81자는 `.taskTooLong(81)`이다.
- 입력을 자동 잘라서 성공시키지 않는다.

**선택·초안 계약**

| 동작 | 결과 |
|---|---|
| 유효한 다른 시간으로 변경 | 시간 변경, 후보 선택만 해제, 태그·할 일·소리 유지 |
| 같은 시간 재설정 | 선택 유지 |
| 범위 밖 시간 | throw, 기존 draft 불변 |
| 후보 ID 선택 | 현재 시간·출발지 후보에서 다시 찾아 저장 |
| 이전 시간의 후보 선택 | `.journeyMismatch` |
| 태그 선택 | 선택 ID 반영 후 준비 허브의 할 일 입력에 포커스 |
| 할 일 입력 변경 | `taskDraft` 변경, `confirmedTask = nil` |
| 소리 선택 화면에서 선택 | `pendingSound`만 변경 |
| 소리 확정 | `selectedSound = pendingSound` |
| 소리 화면 뒤로 가기 | 확정값 유지, 작성 중 pending 값도 유지 |
| 화면 왕복 | draft 재생성 없음 |

`prepare()`의 오류 우선순위는 **시간 → 출발지 → 후보 선택·일치 → 태그 → 할 일**이다. 성공 시 현재 초안을 검증한 `PreparedJourney`를 반환한다. 과거 `confirmedTask`만 보고 통과시키지 않는다.

#### 5. `AppModel.swift` — 저장 성공 후에만 확정하는 명령

**현재:** `save(_:)`는 실제 저장 이후 snapshot과 launch state를 교체한다. [AppModel.swift:42](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/AppModel.swift:42)

이 구조를 유지한다. 별도 Repository·Service 계층을 추가하지 않고 순수 정책 계산만 분리한다.

```swift
enum Phase2Issue: Error, Equatable {
    case validation(PreparationIssue)
    case storage(StorageIssue)
    case notReady
    case invalidCardID
    case invalidInitialStation
    case initialStationAlreadySet
    case handoffAlreadyExists
}
```

추가 관찰 상태와 주요 명령 계약은 다음과 같다.

```swift
private(set) var preparationDraft: PreparationDraft?
private(set) var ticketPreparation: PreparedJourney?
private(set) var preparationIssue: Phase2Issue?
private(set) var previewIssue: SoundPreviewIssue?
private(set) var boarding: BoardingCoordinator?

init(
    store: LocalSnapshotStore,
    makeCardID: @escaping () -> String = /* 기본 생성기 */,
    makeUUID: @escaping () -> UUID = UUID.init,
    soundPlayer: any SoundPreviewing = /* 기본 플레이어 */
)

@discardableResult func issueCard() -> Bool
@discardableResult
func confirmInitialStation(_ station: StationSnapshot) -> Bool

@discardableResult func beginPreparation() -> Bool
@discardableResult func setMinutes(_ minutes: Int) -> Bool
@discardableResult func selectJourney(id: String) -> Bool
@discardableResult func continueToPreparation() -> Bool

@discardableResult func selectTag(id: String) -> Bool
func updateTaskDraft(_ text: String)
func updateNewTagDraft(_ draft: NewTagDraft)
@discardableResult func saveNewTag() -> Bool

func selectPendingSound(_ sound: SoundChoice)
func previewSound(_ sound: SoundChoice)
func stopSoundPreview()
func confirmSound()

@discardableResult func openTicket() -> Bool
@discardableResult func openBoarding() -> Bool
func setSceneActive(_ active: Bool)
func openHandoff()
```

`Bool` 실패는 해당 명령의 snapshot·경로를 확정하지 않았다는 의미다. 검증 실패는 `preparationIssue`, 저장 실패는 기존 `saveFailure`와 `.storage(...)`로 노출한다.

**카드 발급·보완**

- 기본 생성기는 `0...99_999_999`에서 숫자를 만들고 8자리로 패딩한다.
- 발급된 ID가 있으면 `issueCard()`는 같은 값을 유지하고 생성·저장을 반복하지 않는다.
- 잘못된 주입 ID는 `.invalidCardID`로 거절한다.
- 성공적으로 저장하기 전에는 발급 완료로 표시하지 않는다.
- 기존 발급 상태에 ID만 없다면 `loadIfNeeded()`가 원본 전체를 복사하고 ID만 채운 후보를 한 번 저장한다.
- 보완 성공 후에만 `.ready(...)`를 게시한다.
- 보완 실패 시 읽어 둔 원래 snapshot은 유지하고 `.failed(issue)`로 진입한다. 새 ID·재발급·정류장 설정 화면을 게시하지 않는다.
- 손상·읽기 실패는 기존처럼 `snapshot == nil`로 실패 상태를 유지한다. 실패한 load 이후 일반 `save()`는 추가 파일 접근 없이 차단한다.

**최초 정류장**

- 카드 발급이 완료되고 두 정류장이 모두 없을 때만 설정할 수 있다.
- 최초 선택 목록의 ID·이름·방면이 정확히 일치하는 값을 받는다.
- 최초·현재 정류장을 동일하게 저장한다.
- 저장 성공 후 `.main` 상태 위에서 시간 선택 경로를 연다.
- 다음 앱 실행에서는 경로를 복원하지 않으므로 현재 정류장 메인에서 시작한다.

**새 태그**

- 기본 태그와 `customTags`를 합쳐 중복을 검사한다.
- ID는 `"custom-" + UUID 소문자 문자열`이다.
- 전체 snapshot의 `customTags`에 추가해 저장한다.
- 저장 성공 후에만 선택 태그를 바꾸고 할 일 입력으로 돌아간다.
- 실패하면 새 태그 이름·아이콘·색 초안과 기존 선택을 유지한다.

**인계 중복 방지**

- snapshot에 인계가 있으면 새로운 승차 인계를 만들거나 기존 인계를 교체하지 않는다.
- 내부 승차 commit은 기존 인계가 같은 고정 준비값·카드 ID이면 저장 없이 같은 인계를 반환한다. 다른 값이면 `.handoffAlreadyExists`다.
- Phase 2는 인계 소비·삭제 API를 제공하지 않는다.
- 재실행은 메인에서 시작하고, 저장된 인계의 “승차 인계 확인”으로 연결한다. 실제 여행 재개·남은 시간은 표시하지 않는다.

#### 6. `BoardingCoordinator.swift` — 접촉, 저장, 연출, 취소

`AppModel`이 승차 화면당 코디네이터 하나를 보유한다. SwiftUI `body`나 `onAppear`에서 새로 만들지 않는다. 코디네이터의 commit closure는 승차권에서 확정한 불변 `PreparedJourney`를 캡처한다.

```swift
enum BoardingInput: Equatable {
    case tap
    case accessibilityActivate
    case drop(cardCenter: CGPoint, target: CGRect)
}

enum BoardingPhase: Equatable {
    case idle
    case moving
    case recognized(UUID)
    case fading(UUID)
    case waiting(UUID)
    case interrupted(UUID)
    case failed(Phase2Issue)
}

@MainActor @Observable
final class BoardingCoordinator {
    private(set) var phase: BoardingPhase

    init(
        sleep: @escaping @MainActor (Duration) async throws -> Void,
        commit: @escaping @MainActor
            () -> Result<BoardingHandoff, Phase2Issue>,
        recognitionFeedback: @escaping @MainActor () -> Void,
        finished: @escaping @MainActor (BoardingHandoff) -> Void
    )

    @discardableResult
    func start(
        input: BoardingInput,
        reduceMotion: Bool
    ) -> Bool

    func setVisible(_ visible: Bool)
    func setSceneActive(_ active: Bool)
    func cancel()
}
```

초기 상태는 `.idle`이다. `start()`의 `true`는 입력 수락이지 저장 성공이 아니다.

**정상 시간 계약**

| 순서 | 상태·효과 |
|---|---|
| 입력 수락 | `.moving`, 추가 입력 차단 |
| 300ms 지연 완료 | token·취소·활성·가시성 재검사 |
| 이어서 | 동기식 commit 실행 |
| 저장 성공 직후 | `.recognized(id)`, 카드 이름·ID 표시, 지원 시 햅틱 |
| 1400ms 지연 완료 | `.fading(id)` |
| 450ms 지연 완료 | `.waiting(id)`, `finished(handoff)` 한 번 |
| 최종 화면 | Phase 3 인계 대기 |

**저장 성공이 인식 성공의 확정점이다.** 저장 시간이 걸리면 성공 표시와 1400ms 유지의 시작도 그 뒤로 이동한다. 화면 연출 완료 callback을 저장 트리거로 사용하지 않는다.

동작 줄이기에서는 `.moving` 공간 이동·300ms 지연·페이드·450ms 지연·햅틱을 생략한다. 입력 검증 후 저장하고, 인식 성공 안내는 1400ms 유지한다.

**취소 계약**

- 코디네이터는 소유한 `Task`와 증가하는 generation token을 함께 사용한다.
- 각 `await` 직후 token·활성 상태·가시성·취소 여부를 재검사한다.
- 취소를 무시하는 시험용 지연기가 늦게 반환해도 저장·전환하지 않는다.
- commit 직전 확인부터 동기 저장과 성공 게시 사이에는 `await`가 없다.
- `scenePhase != .active`, 경로에서 승차 화면 제거, 실제 화면 이탈 모두 같은 인스턴스를 취소한다.
- 저장 전 취소는 `.idle`로 돌아가며 인계가 없다. 다시 활성화되어도 자동 재시작하지 않는다.
- 저장 후 취소는 `.interrupted(id)`다. 저장된 인계는 보존하고 `finished`는 호출하지 않는다.
- 재활성화 시 연출을 다시 예약하지 않는다. 명시적인 “승차 인계 확인”으로 이동한다.
- 실패는 `.failed(issue)`이며 성공 안내·햅틱·1400ms 유지·페이드가 없다. 유효한 재입력으로 다시 시도할 수 있다.
- `.moving`, `.recognized`, `.fading`, `.waiting`, `.interrupted` 상태에서는 중복 입력을 거절한다.

**드래그 판정**

`BoardingView`에 `"boardingSurface"`라는 공통 좌표계를 둔다. 단말기 영역과 드래그 종료 카드 중심을 모두 이 좌표계로 변환한다.

- target의 너비·높이는 양수이고 모든 좌표는 유한해야 한다.
- 카드 중심이 target 내부일 때만 `.drop` 입력을 수락한다.
- 영역 밖 드롭은 카드만 원위치로 돌아가고 상태·저장 횟수는 바뀌지 않는다.
- 이동이 드래그로 판정된 경우 뒤따르는 tap을 중복 전달하지 않는다.
- 카드 버튼의 기본 접근성 활성화와 명명된 접근성 동작도 같은 `start()` 경로를 사용한다.

#### 7. `SoundPreviewPlayer.swift` — 실제 WAV 미리듣기

**실제 자산:** [오디오 매핑:376](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/designs/final/animation-preview.html:376).

| 선택 | 기존 파일 |
|---|---|
| 소리 없음 | 파일 없음 |
| 핑크 노이즈 | `designs/final/assets/audio/pink-noise-cc0-v1.wav` |
| 빗소리 | `designs/final/assets/audio/rain-windshield-cc0-v1.wav` |
| 숲 소리 | `designs/final/assets/audio/forest-edge-cc0-v1.wav` |
| 버스 주행 | `designs/final/assets/audio/bus-london-cc0-v1.wav` |

프로토타입의 핑크 노이즈 내부 키는 `white`지만 네이티브 저장값은 `pinkNoise`로 정한다. 브라우저 localStorage 이관은 대상이 아니다.

```swift
enum SoundPreviewIssue: Error, Equatable {
    case resourceMissing(SoundChoice)
    case playbackFailed(SoundChoice)
}

@MainActor
protocol SoundPreviewing: AnyObject {
    var failureHandler: ((SoundPreviewIssue) -> Void)? { get set }
    func preview(_ sound: SoundChoice) throws
    func stop()
}
```

- 구현체는 `AVAudioPlayer` 하나를 소유한다.
- `.none`은 기존 재생을 멈추고 파일을 열지 않는다.
- 다른 소리를 시작하기 전에 기존 재생을 중지한다.
- URL 누락은 `.resourceMissing`, 디코딩·세션·`prepareToPlay()`·`play()` 실패는 `.playbackFailed`다.
- `volume = 1.0`을 사용하고 앱 음량 슬라이더·별도 저장 음량을 추가하지 않는다.
- 명시적인 미리듣기에만 `.playback`과 `.mixWithOthers` 오디오 세션을 활성화한다. 백그라운드 오디오 capability는 추가하지 않는다.
- 소리 화면 이탈, 앱 비활성, 오디오 인터럽트는 미리듣기를 중지한다. 복귀 시 자동 재생하지 않는다.
- 비동기 delegate 실패는 현재 플레이어 인스턴스와 일치할 때만 전달한다.
- 실패는 `previewIssue`만 바꾸며 준비 초안·확정 소리·여정 선택을 변경하지 않는다.
- 승차권·승차 화면·앱 재실행에서는 소리를 자동 재생하지 않는다.

#### 8. 네이티브 화면과 리소스 연결

**현재:** [RootView.swift:50](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/RootView.swift:50)의 진입 화면과 네 목적지는 기본 placeholder다.

기존 `NavigationStack(path: $model.path)`를 유지하고 `Destination`을 확장한다.

```swift
// 기존 case 유지
case preparation, records, settings, profile

// 추가
case prepare, tags, newTag, sound, ticket, boarding, handoff
```

`preparation`은 시간·버스 선택 진입점이다. 메인 메뉴는 기존 네 목적지를 명시적으로 나열하고 확장된 `Destination.allCases`를 순회하지 않는다.

| 화면 | 구성·전환 |
|---|---|
| 카드 진입 | 공통 네이티브 카드와 발급 행동. 저장 후 최초 정류장 화면에 동일 ID 표시 |
| 최초 정류장 | 제공된 정류장·방면 검색과 선택. 완료 후 시간 선택 |
| 메인 | 지도 배경, 읽기 전용 현재 정류장·방면, 작은 여행 시작 영역 |
| 시간 선택 | 1분 단위 15~360분 조절, 최대 세 후보, 명시적 선택 |
| 준비 허브 | 태그 선택 행, 선택 후 할 일 입력, 소리 행, 승차권 행동 |
| 태그 목록 | 기존 태그 선택과 새 태그 추가만 |
| 새 태그 | 이름·아이콘·색 입력. 기존 태그 편집 경로 없음 |
| 소리 | 다섯 선택지, 미리듣기, 확정 |
| 승차권 | 아래 여섯 정보 필드와 탐색 행동 |
| 승차 | 단말기·공통 카드, 인식 상태 |
| 인계 대기 | 보존된 카드·준비값 확인, 여행 진행 UI 없음 |

**지도 우선 배치**

- `MapBackdropView`는 기존 `designs/final/city-map.png`를 정적 배경으로 사용한다.
- 정류장·시간·준비 컨트롤은 작은 하단 영역에 배치한다.
- 화면 전체를 큰 폼이나 불필요한 `ScrollView`로 감싸지 않는다.
- 키보드·큰 글자·작은 화면에서 필요한 경우에만 입력·목록 영역이 스크롤된다.
- 지도 이동, 줌, 추적, GPS, MapKit 네트워크 지도, 버스 이동 애니메이션은 추가하지 않는다.

**승차권 표시 계약**

정보 콘텐츠는 정확히 다음 여섯 개다.

```swift
struct TicketPresentation: Equatable {
    let busNumber: String
    let departure: String
    let destination: String
    let duration: String
    let stopCount: String
    let distance: String
}
```

AC-10 fixture의 출력은 `2014번`, `성수역`, `서울숲 입구`, `25분`, `5개`, `2.8 km`다. 태그·할 일·소리·카드 ID·발급/출발 상태·추가 운행 설명을 넣지 않는다. 화면 제목과 뒤로가기·승차 행동은 정보 필드와 구분한다.

**승차 단말기**

- 대기: `Focus Mate`, 실제 로컬 `HH:mm`, `작은 시작이 오늘을 바꿔요.`
- 성공: `집중동행카드`와 저장 완료된 카드 ID.
- 로컬 시계 갱신은 표시 전용이며 여행 타이머가 아니다.
- 최신 FLOWS에 따라 별도 수동 태그 버튼과 외부 제목을 추가하지 않는다. 카드 자체를 접근 가능한 버튼으로 만든다.
- 화면 취소는 내비게이션 제거·접근성 escape·앱 비활성을 통해 동일하게 처리한다.

**리소스 처리**

- WAV 네 파일과 기존 `SOURCE.md`, `sources.json`을 `Resources/Audio/`로 복사한다.
- 고유한 WAV basename으로 `Bundle.main.url(forResource:withExtension:)`을 조회한다. 폴더 구조가 유지된다고 가정하는 URL 문자열은 만들지 않는다.
- `city-map.png`는 `CityMap.imageset`에 등록한다.
- 카드는 `TransitCardView(cardID:)`에서 네이티브 도형·텍스트로 그린다. 기존 `transit-card-next-step.png`의 브랜드·고정 ID를 제품 카드로 사용하지 않는다.
- 버스 SVG·서울알림체는 이번 설계의 필수 리소스가 아니다. 시스템 글꼴·네이티브 아이콘을 사용한다.
- 오디오 출처 문서에는 CC0 및 원본 정보가 기록되어 있다. 이번 턴에서 외부 라이선스 페이지나 실제 청취를 재검증했다는 의미는 아니다.
- 동기화 앱 그룹으로 리소스를 포함하되 실제 번들 포함 여부는 후속 검증에서 확인한다.

#### 9. 승인된 세 검증 경계와 관찰 계약

새 경계를 승인받을 필요 없이 PRD의 세 경계를 그대로 사용한다.

| 승인 경계 | 대상 | 주요 판정 |
|---|---|---|
| 값·정책 단위 | `PreparationPolicy`, 카탈로그, snapshot 검증, 코디네이터 지연·commit 경계 | AC-4~8, AC-11~13, 중복·순서 |
| 실제 로컬 파일 + 실패 조건 | 기존 저장소 클로저와 고유 임시 파일 | AC-1, AC-13~18 |
| 실제 앱 화면·재실행·생명주기 | XCUITest와 실제 앱 경로 | AC-1~3, AC-7~14, 오류 안내 |

코디네이터의 지연 대체는 첫 번째 경계 안에서 시간 순서를 결정적으로 확인하는 수단이다. 실제 앱 생명주기 검증을 대신하지 않는다.

**단위 계약 예시**

- 일반 동작의 요청 지연은 순서대로 `[300, 1400, 450]ms`.
- 300ms 완료 전 commit 0회, 완료 후 성공 commit 1회.
- 저장 실패 후 나머지 두 지연·성공 callback·햅틱 0회.
- 동작 줄이기의 요청 지연은 `[1400]ms`, 햅틱 0회.
- 취소된 generation을 뒤늦게 깨워도 commit·최종 전환 횟수가 늘지 않는다.
- 동일 입력 반복은 하나의 인계만 만든다.

**파일 경계**

- 기존 version 1 원문 fixture를 직접 기록한 뒤 ID 보완을 확인한다.
- 최초·현재 정류장이 서로 다른 fixture를 반드시 사용한다.
- 실패 주입은 기존 파일을 수정하기 전에 throw하는 조건으로 한다.
- 손상·미지원·읽기 실패·디렉터리 실패·쓰기 실패 각각에서 snapshot과 기존 바이트 보존을 확인한다.
- 새 저장소 인스턴스 round-trip과 실제 앱 terminate/launch를 별도로 구분한다.
- 전원 장애·OS 파일 교체 실패·다중 writer 보장은 이 경계의 판정 대상이 아니다.

**UI 관찰값**

기존 `screen.cardEntry`, `screen.initialStationEntry`, `screen.main`, `main.currentStation`, `main.direction`, `storage.saveFailure`, `test.snapshot`, `test.persistedBytes`, `test.setupError`를 유지한다.

신규 식별자는 다음처럼 고정한다.

| 대상 | 식별자 |
|---|---|
| 시간·후보 | `time.minutes`, `journey.option.<id>`, `journey.continue`, `journey.error` |
| 태그·할 일 | `tag.option.<id>`, `tag.add`, `tag.name`, `tag.save`, `task.input`, `preparation.error` |
| 소리 | `sound.option.<rawValue>`, `sound.preview.<rawValue>`, `sound.confirm`, `sound.error` |
| 승차권 필드 | `ticket.bus`, `ticket.departure`, `ticket.destination`, `ticket.duration`, `ticket.stops`, `ticket.distance` |
| 승차 | `boarding.card`, `boarding.target`, `boarding.phase`, `boarding.cardID`, `boarding.error` |
| 인계 | `screen.handoff`, `handoff.id` |

`UITestBootstrap`은 기존 UUID 경로·재seed 금지·Release 제외 규칙을 유지한다.

- 일반 `ready/cardOnly` seed에는 고정 카드 ID를 넣는다.
- 별도 `legacyReady/legacyCardOnly`는 ID 없는 원래 version 1 bytes를 사용한다.
- 읽기 실패는 seed 작성 후 모델의 `readData`에서 주입한다. 바이트 진단은 원본 파일을 읽는다.
- 발급·최초 정류장·새 태그·승차 저장 실패는 해당 작업 시점에만 주입할 수 있도록 구분한다.
- 승차 전후 숨김을 안정적으로 관찰할 필요가 있으면 DEBUG에서 contact/hold 지연을 멈추는 gate를 둔다. 실제 Home·background·terminate 동작은 앱에 수행하며, gate 없는 정상 흐름도 별도로 다룬다.
- DEBUG gate와 진단은 제품 Release UI에 포함하지 않는다.

#### 10. 기존 테스트 호환성

그대로 유지할 계약과 승인된 기능 변경으로 갱신할 기대값을 구분한다.

| 기존 근거 | 처리 |
|---|---|
| [AppFoundationTests.swift:39](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMateTests/AppFoundationTests.swift:39) | 기존 검증 오류 순서 유지 |
| [AppFoundationTests.swift:62](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMateTests/AppFoundationTests.swift:62) | 파일 없음의 무쓰기 계약 유지 |
| [AppFoundationTests.swift:110](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMateTests/AppFoundationTests.swift:110) | 보호된 원본의 정확한 bytes 유지 |
| [AppFoundationTests.swift:141](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMateTests/AppFoundationTests.swift:141) | 잘못된 후보는 파일 접근 전에 거절 |
| [AppFoundationTests.swift:239](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMateTests/AppFoundationTests.swift:239) | 일반 ready fixture에 ID 추가. 탐색 자체의 무쓰기 보장은 유지 |
| [AppFoundationTests.swift:266](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMateTests/AppFoundationTests.swift:266) | 저장 실패 전후 snapshot·route·path 유지 |
| [Phase1FlowTests.swift:43](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMateUITests/Phase1FlowTests.swift:43) | 준비 목적지를 실제 시간 선택 흐름으로 변경 |
| [Phase1FlowTests.swift:161](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMateUITests/Phase1FlowTests.swift:161) | ‘뒤로가기 외 버튼 없음’은 기록·설정·프로필에 유지. 준비는 Phase 2 기대값으로 변경 |
| [UITestBootstrap.swift:47](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/UITestBootstrap.swift:47) | 시험용 snapshot 복사 시 카드 ID·태그·인계도 보존 |

ID 보완 때문에 늘어난 쓰기를 기존 탐색 테스트의 기대값에 섞지 않는다. **일반 ready fixture와 명시적인 legacy fixture를 분리**한다.

테스트 파일명과 XCTest 클래스명을 일치시킨다. 기존 focused runner가 이를 기준으로 `-only-testing`을 구성한다. [check-ios.py:33](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/scripts/check-ios.py:33)

#### 11. 오류 경로

| 오류·취소 | 유지할 값 | 화면 결과 |
|---|---|---|
| 초기 읽기 실패·손상·미지원 | 원본 파일 | 저장 오류 화면, 신규 발급 진입 금지 |
| 기존 카드 ID 보완 저장 실패 | 읽은 기존 snapshot·원본 파일 | 보완 실패, 생성 ID 게시 금지 |
| 발급·최초 정류장 저장 실패 | 이전 snapshot·경로 | 현재 화면에 실패 안내 |
| 시간 범위 밖 | 기존 draft 전체 | 시간 오류 |
| 후보 없음·미선택·불일치 | 시간 및 준비 초안 | 준비 진입 차단 |
| 알 수 없는 기존 정류장 ID | 원래 ID·이름·방면 | 후보 제공 불가 안내, 자동 정류장 변경 없음 |
| 태그 이름·중복 오류 | 새 태그 초안·기존 선택 | 태그 화면 유지 |
| 새 태그 저장 실패 | 원본 snapshot·새 태그 초안 | 추가·선택 성공으로 안내하지 않음 |
| 빈 할 일·80자 초과 | 입력 원문 | 승차권 진입 차단 |
| 미리듣기 실패 | 준비 초안·확정 소리 | 소리 오류만 표시 |
| 잘못된 드롭 | 모든 준비값 | 카드 원위치, 인계 없음 |
| 인식 전 취소·숨김 | 준비값 | 인계·성공 없음 |
| 승차 저장 실패 | 이전 snapshot·고정 준비값 | 승차 실패, 성공 연출 없음 |
| 인식 후 숨김·이탈 | 저장된 인계 | 늦은 전환 취소 |
| 인계가 있는 재실행 | 동일 인계 하나 | 현재 정류장 메인에서 인계 확인 |

### 의존성 및 영향도

- 외부 라이브러리는 추가하지 않는다. Foundation·SwiftUI·Observation·AVFAudio/AVFoundation·UIKit의 기존 SDK 기능을 사용한다.
- 저장 경로는 `Application Support/FocusMate/app-state.json`을 유지한다.
- 기존 `LaunchRoute`의 세 상태는 유지한다. 최초 설정 직후 이동은 저장 데이터가 아닌 현재 실행의 navigation path로 표현한다.
- version 1 입력 호환성을 유지하며 새 저장은 version 2다. 구버전 앱으로의 역방향 사용은 미지원 상태로 보호된다.
- 기존 HTML·Pencil·웹 회귀 동작은 변경하지 않는다.
- Phase 2에는 인계 소비 API가 없다. Phase 3가 이 값을 받아 실제 여행 상태를 만드는 변경은 후속 설계 대상이다.
- 카드 도메인 전체 완료, 실제 타이머·지도·기록 구현 완료로 표시하지 않는다.

불확실했던 API는 설치된 공식 SDK 선언을 직접 확인했다.

- [Foundation 정규화·folding](/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/Foundation.framework/Modules/Foundation.swiftmodule/arm64e-apple-ios.swiftinterface:22530)
- [Foundation atomic write 설명](/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/Foundation.framework/Headers/NSData.h:36)
- [AVAudioPlayer 초기화·재생 API](/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioPlayer.h:33)
- [AVAudioPlayer volume](/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/AVFAudio.framework/Headers/AVAudioPlayer.h:78)
- [SwiftUI 동작 줄이기 환경값](/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk/System/Library/Frameworks/SwiftUICore.framework/Modules/SwiftUICore.swiftmodule/arm64e-apple-ios.swiftinterface:23405)

이 확인은 API 선언·의미에 대한 근거다. 앱의 컴파일·재생·실기기 동작 검증 결과는 아니다.

### 구현 순서

일정이 아닌 파일 간 기술 의존 관계다. 모두 `[Must]`다.

1. 값 타입·가상 카탈로그·순수 준비 정책 계약 구현 및 해당 단위 경계 구성. **(의존: 없음)**
2. snapshot 디코딩·검증과 version 1/2 저장 호환성 확장, 실제 파일 경계 구성. **(의존: 1)**
3. 코디네이터의 시간·취소·commit 계약과 결정적 지연 검증 구성. **(의존: 1)**
4. 오디오 어댑터와 WAV·지도 리소스 연결. **(의존: 1)**
5. `AppModel`의 발급·보완·준비·인계 명령과 navigation 통합. **(의존: 2, 3, 4)**
6. 네이티브 화면, 접근성 입력, scenePhase·경로 이탈 연결. **(의존: 5)**
7. 기존 bootstrap·회귀 기대값을 갱신하고 실제 화면·재실행·생명주기 경계 연결. **(의존: 6)**

2·3·4는 서로 다른 파일을 다루므로 병렬 작업이 가능하다. `AppModel`과 `RootView` 통합은 각각 한 단계가 소유한다.

### 탐색 추가 항목

- [AppSnapshot.swift:20](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/AppSnapshot.swift:20) → 기존 단계·정류장 검증 순서.
- [LocalSnapshotStore.swift:44](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/LocalSnapshotStore.swift:44) → 원본 재확인과 atomic write 경계.
- [AppModel.swift:27](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/AppModel.swift:27) → 1회 load와 ID 보완 통합 지점.
- [FocusMateApp.swift:48](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/FocusMateApp.swift:48) → DEBUG seed 이후 앱 상태 로드 순서.
- [UITestBootstrap.swift:10](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/ios/FocusMate/UITestBootstrap.swift:10) → UUID별 시험 파일과 실패 주입.
- [animation-preview.html:403](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/designs/final/animation-preview.html:403) → 최초 선택 정류장·방면.
- [assets/audio/SOURCE.md:5](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/designs/final/assets/audio/SOURCE.md:5) → 실제 WAV 이름과 출처 기록.
- [docs/FLOWS.md:26](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/docs/FLOWS.md:26) → 최신 승차 단말기 표시·시간·취소 계약.
- [context/card/architecture.md:13](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/context/card/architecture.md:13) → 카드가 ID·외형을 공급하고 여정이 접촉 결과를 소유하는 경계.
- [context/journey/glossary.md:14](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/context/journey/glossary.md:14) → pending/selected 및 draft/confirmed 용어.
- [docs/PHASE-1-FOUNDATION.md:40](/Users/bonseung/.codex/worktrees/phase-2-card-boarding/new/docs/PHASE-1-FOUNDATION.md:40) → 시험 데이터·운영 데이터 분리와 검증 범위.

---

## 확인이 필요한 사항

추가 확인 사항 없음. 설계가 완료되었습니다.
