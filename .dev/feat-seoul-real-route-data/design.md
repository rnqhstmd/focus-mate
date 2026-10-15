# 설계 초안: 서울 전체 실데이터 번들 (W16 · 정류장·노선·버스·구간 시간) — 2회차 확정본

### 설계 규모
대형. 이번 작업에는 데이터 원천 교체, 후보·코스·도달 규칙 교체, 저장 형식 버전 올림, 신규 변환 스크립트(xlsx 2개 입력), 신규 화면 1개가 함께 들어갑니다. 영향 범위는 앱 소스 약 30개, 테스트 약 25개입니다.

### 배경 및 목적
- **현재 상태**
  - 가상 순환 정류장 9개(`ios/FocusMate/RouteData.swift:10-21`), 검색 3건(:60-65), 버스 3종(:83-87)으로 동작합니다.
  - 후보는 "정확히 나누어떨어지는 버스"만 됩니다(`JourneyPlanner.swift:27`).
  - 거리는 정류장당 0.55km로 계산합니다(:19).
  - 지도 코스는 근사 좌표 9개를 이은 닫힌 선입니다(`JourneyCourse.swift:23-43`).
- **목표**
  - 서울 전역 12,897개 정류장 중에서 검색해 출발지를 고릅니다.
  - 그 정류장을 실제로 지나는 노선이 ±60초 규칙으로 후보가 됩니다.
  - 지도에 실제 좌표 코스를 그립니다.
  - 오프라인에서 동작합니다.
  - 매월 원천 파일 2개(OA-1095, OA-15066)로 스크립트를 한 번 실행하면 갱신됩니다.
- **원천**: 서울특별시, 공공누리 제1유형.
  - `서울시버스노선별정류소정보(20260902).xlsx`: 41,688행, 노선 718개, 정류장 12,897개
  - `서울시버스노선기본정보(20260902).xlsx`: 822행

### 요구사항 및 수용 기준
- 개정 중인 PRD(`.dev/feat-seoul-real-route-data/prd.md`)를 따릅니다.
  - [Must] FR-1~14, BR-1~12, BR-14
  - [Should] FR-15, BR-13, QE-1~5
  - AC-1~55
- 이번 개정으로 바뀌는 항목은 아래 이름으로 참조합니다.
  - BR-4(운행시간 비례 배분) — 개정 AC-45·46
  - 가상 지점 제거
  - 한강·관광 제외 — 개정 AC-48
  - BR-13(노선 소실 → 출발 정류장 유지, 출발 정류장 소실 → 최초 정류장 화면)
  - 메인 방면 표시 — 신규 "AC-메인방면"
  - 로딩 전 생명주기 차단 — 신규 "AC-로딩차단"
- 이미 확정된 결정
  - 비례 조정 뒤 마지막 구간이 0초 이하가 되면 그 노선은 그 시간 후보에서 제외합니다.
  - 노선 번호는 자연 정렬합니다(스크립트가 순위를 결정).
  - 원천 파일은 보관하지 않습니다.

### 변경 범위

**영향 모듈**
- journey 도메인 전체(검색·후보·코스·진도·도달)
- 저장(`AppSnapshot`/`JourneySnapshot`/`SnapshotCodec`/`LocalSnapshotStore`)
- 마이페이지(출처 항목)
- 메인 화면
- UI 테스트 부트스트랩
- `scripts/`

**신규 파일**

| 파일 | 역할 |
|---|---|
| `ios/FocusMate/RouteCatalog.swift` | 값 타입 카탈로그. 정류장·노선·파생 색인·방면(BR-10)을 담습니다. |
| `ios/FocusMate/RouteCatalogLoader.swift` | 번들 JSON DTO를 `RouteCatalog`와 `RouteDataMetadata`로 바꿉니다. |
| `ios/FocusMate/RouteCatalogStore.swift` | `@MainActor @Observable` 로딩 상태(`RouteDataAvailability`)를 가집니다. 테스트가 로딩 완료를 기다릴 수 있습니다. |
| `ios/FocusMate/StationSearch.swift` | `StationOption`과 BR-9 검색 |
| `ios/FocusMate/RouteLeg.swift` | 도착지(BR-6), 비례 조정(BR-7), 누적 초 |
| `ios/FocusMate/DataSourceView.swift` | 출처 화면과 `DataSourceContent` |
| `ios/FocusMate/RouteCatalog+Fixture.swift` | `#if DEBUG`. `acceptance`(PRD 픽스처 + 번호 없는 정류장)와 `uiTest`(레거시 재현 노선 추가) |
| `ios/FocusMate/Resources/RouteData/seoul-route-data.json` | 스크립트 산출물 |
| `scripts/build_route_data.py` | 변환 스크립트(표준 라이브러리만 사용) |
| `scripts/tests/__init__.py`, `scripts/tests/xlsx_fixture.py`, `scripts/tests/test_build_route_data.py` | Python 테스트 |
| 단위 테스트 | `RouteCatalogTests`, `StationSearchTests`(`StationCatalogTests` 대체), `RouteLegTests`, `RouteDataMigrationTests`, `RouteCatalogStoreTests`, `RouteDataBundleTests`, `DataSourceContentTests` |

**삭제**
- `ios/FocusMate/RouteData.swift`

**수정 파일**
- 앱
  - 규칙: `JourneyPlanner`, `JourneyPlanDraft`, `JourneyCourse`, `JourneyCourseProgress`, `JourneyReach`
  - 저장: `JourneySnapshot`, `AppSnapshot`, `SnapshotCodec`, `LocalSnapshotStore`
  - 모델: `AppModel`, `AppModel+JourneyStart`, `AppModel+JourneyLifecycle`, `AppModel+Profile`
  - 화면 상태·표시: `StationSearchState`, `PreparationDraft`, `BoardingPassContent`, `ActiveJourneyCardContent`, `JourneyLiveActivityPolicy`, `JourneyLifecycleText`
  - 화면: `InitialStationSearchView`, `TimeSelectionView`, `JourneyMapController`, `JourneyMapView`, `JourneyTimerView`, `JourneyView`, `JourneyAbandonBar`, `RootView`, `DestinationScreen`, `ProfileView`
  - 시작·테스트 지원: `UITestBootstrap`, `FocusMateApp`
- 문서: `scripts/data/README.md`, `context/journey/architecture.md`, `context/journey/glossary.md`

### 적용 컨벤션
- 프로젝트 루트에 CLAUDE.md는 없습니다. `.claude/config.json`만 있습니다.
- **네이밍**
  - 규칙 모음은 `enum`, 값은 `struct`로 둡니다.
  - 문구는 `…Text`/`…Copy` enum에 모읍니다.
  - 접근성 식별자는 `영역.요소` 형식입니다(`search.result.<id>`, `time.candidate.<id>`).
- **구조**
  - 순수 규칙에는 의존성이 없습니다.
  - 컨트롤러는 `@MainActor @Observable final class`입니다.
  - 생성자 주입과 클로저 주입을 씁니다(`LocalSnapshotStore(readData:…)`).
  - 저장은 `snapshot.updating…`으로 만들고 `AppModel.save`를 거칩니다. 읽기와 쓰기는 분리합니다(`AppModel.start`).
- **수치**: 정수 산술로 계산하고, 반올림은 `(2a+b)/(2b)` 형태로 합니다(`JourneyCourseProgress.swift:80`).
- **저장 결정성**: `sortedKeys`를 쓰고, 날짜는 문자열로 직접 씁니다(`JourneySnapshot.swift:129-146`).
- **DEBUG 인자**: `--fm-ui-*`
- **리소스**: 동기화 폴더의 비소스 파일은 번들 루트로 평탄화되어 복사됩니다(`AVSoundPreviewPlayer.swift:22-28`). 그래서 같은 이름의 파일을 두면 안 됩니다. `Fonts/SOURCE.md`가 이미 있습니다.
- **빌드 설정**: Swift 5, strict concurrency minimal, iOS 17(`project.pbxproj:72`)
- **Python**: 표준 라이브러리만 씁니다(`scripts/check-ios.py` 선례).

---

### 상세 설계

#### A. 번들 데이터 형식과 로딩 (FR-1, FR-12, QE-1, QE-4)

**형식 결정: 행 단위 JSON(노선 1줄, 정류장 1줄)**

| 형식 | 크기(추정) | 로딩 | 결정성·검토 | 판단 |
|---|---|---|---|---|
| 행 단위 JSON, 노선이 정류장 id를 직접 참조 | 약 1.6~2MB | `JSONDecoder` + unkeyed 행 디코드 | 줄마다 `json.dumps`로 바이트 동일. 월별 diff가 바뀐 노선·정류장 줄만 보여 줌 | **채택** |
| 열 지향 한 줄 JSON | 약 1.5MB | 약간 빠름 | 한 줄이라 diff를 읽을 수 없음(1회차의 "diff 가독" 근거 철회) | 불채택 |
| 압축 JSON / 바이너리 / SQLite | 0.5~3MB | 다양 | 압축 해제 단계, 이중 파서, sqlite 바이트 비결정성 | 불채택 |

노선이 정류장 **색인**이 아니라 **id**를 참조합니다. 정류장이 하나만 늘어도 모든 노선 줄이 바뀌는 문제를 막기 위해서입니다. 이 선택으로 약 0.4MB가 더 들지만 한도 10MB에 여유가 큽니다.

**파일 구조**
- 줄바꿈 위치는 스크립트가 고정합니다. 숫자는 모두 정수입니다.
- 1행: `{"format":1,"source":{…},"stops":[`
  - `source` 키(정렬): `baseDate`("2026-09-02"), `copyright`("서울특별시"), `dataset`("서울시버스노선별정류소정보"), `datasetID`("OA-1095"), `license`("공공누리 제1유형"), `provider`("서울 열린데이터광장"), `routeInfoDatasetID`("OA-15066"), `routeInfoFile`·`stopsFile`(두 원본 파일 이름)
- 정류장 줄: `["<NODE_ID>","<정류소명>","<ARS 또는 빈 문자열>",<위도×1e6>,<경도×1e6>]`
  - id 사전순으로 정렬하고, 줄 끝에 쉼표를 둡니다(마지막 줄 제외).
- `],"routes":[`
- 노선 줄: `["<ROUTE_ID>","<노선명>","<유형 표시명>",["<NODE_ID>",…],[구간 초…],[구간 m…]]`
  - **배열 순서가 곧 노선 번호의 자연 정렬 순위**입니다.
  - 구간 배열의 i번째는 정류장 i에서 (i+1) mod n까지입니다. 마지막 원소는 회차 구간입니다(BR-5).
- `]}` + `\n`

**로딩 방식 비교와 결정**

| 방식 | 장점 | 단점 |
|---|---|---|
| 동기(`AppModel.start`에서 디코드) | 상태 기계가 없어 경쟁 조건이 없음 | 디코드 시간이 그대로 첫 화면 지연이 됨. Debug 시뮬레이터나 구형 기기에서 QE-4 여유가 불확실 |
| **비동기(채택)** | 첫 화면이 카탈로그와 무관해 QE-4가 기기 성능과 무관 | loading/failed 상태와 생명주기 차단이 필요 |

- 비동기를 채택한 이유
  - 메인 첫 화면, 진행 여정 카드, Live Activity 정리가 모두 **저장된 이름만** 쓰도록 바꿨습니다(C절). 그래서 첫 화면은 카탈로그를 기다릴 이유가 없습니다.
  - 개정 PRD가 "AC-로딩차단"을 요구합니다.
- 동기 방식은 대안으로 남깁니다. 디코드 실측(AC-43)이 50ms 미만으로 안정되면 이후 단순화 후보로 기록만 해 둡니다.

**리소스 포함**
- `ios/FocusMate/Resources/RouteData/`에 두면 앱 타깃 리소스로 자동 포함됩니다. pbxproj는 수정하지 않습니다.
- 출처 문서는 번들 이름 충돌을 피하려고 `scripts/data/README.md`에 둡니다.

**1. `ios/FocusMate/RouteCatalogLoader.swift`(신규)**
- **변경**
  - `RouteBundleFile: Decodable`이 행을 `unkeyedContainer`로 읽습니다.
  - 정류장 id → 색인 맵을 만든 다음 `RouteCatalog`를 생성합니다.
  - 다음 경우 `RouteCatalogIssue`를 던집니다.
    - 배열 길이 불일치
    - 모르는 정류장 id
    - 노선 정류장 2개 미만
    - 구간 1초 미만
- **시그니처**
  - `enum RouteCatalogLoader { static func load(data: Data) throws -> RouteCatalog; static func bundledURL(_ bundle: Bundle = .main) -> URL?; static func bundled(_ bundle: Bundle = .main) throws -> RouteCatalog }`
  - `struct RouteDataMetadata: Equatable, Sendable { baseDate; dataset; datasetID; provider; copyright; license; stopsFile; routeInfoFile }`

**2. `ios/FocusMate/RouteCatalogStore.swift`(신규)**
- **변경**
  - `enum RouteDataAvailability: Equatable { case loading, ready(RouteCatalog), failed }`
    - 초기값은 `.loading`입니다. "아직 안 끝남"과 "영구 실패"를 타입으로 구분합니다.
  - 생성자에 `load: @Sendable () throws -> RouteCatalog`를 주입합니다.
  - `startLoading()`은 `Task.detached(priority: .userInitiated)`에서 디코드하고 메인 액터에서 상태를 바꿉니다.
  - **반환한 `Task` 핸들**과 `func loaded() async -> RouteDataAvailability`로 테스트가 완료를 기다릴 수 있습니다.
  - 두 번 불러도 한 번만 로딩합니다.
- **시그니처**
  - `init(load:)`
  - `convenience init(ready: RouteCatalog)`
  - `@discardableResult func startLoading() -> Task<Void, Never>`
  - `func loaded() async -> RouteDataAvailability`
  - `var availability: RouteDataAvailability`
  - `var catalog: RouteCatalog?`
- **failed 상태 화면(재시도 없음, 번들 결함)**
  - 최초 정류장 화면: "정류장 정보를 불러오지 못했어요. 앱을 다시 실행해 주세요"(`search.dataFailed`). 확인 버튼은 비활성입니다.
  - 시간 선택: 진행 버튼 제목이 같은 문구이고 비활성입니다(`ProceedState.routeDataFailed`).
  - 메인: 방면을 생략합니다.
  - 여행 화면: 지도를 생략합니다(W05 배치).
  - 출처 화면: 고정 문구는 보이고 기준일만 "확인할 수 없어요"로 바꿉니다.
  - 생명주기: F절 참조. 여정을 끝낼 수는 있고, 출발 정류장을 유지합니다.

#### B. 데이터 접근 경계와 전역 static 대체

**3. `ios/FocusMate/RouteCatalog.swift`(신규)**
- **변경**: `struct RouteCatalog: Sendable`
  - 원천: `stops: [Stop]`, `routes: [Route]`(순위 순서), `metadata`
  - init에서 만드는 파생값
    - `stopIndexByID`, `routeIndexByID`
    - `visitsByStop: [[RouteVisit(route, firstPosition)]]`: 노선마다 첫 지점만 넣습니다(BR-6).
    - `searchKeys`: 앞뒤 공백 제거 + 소문자
    - `boundStopIndex: [Int?]`(BR-10): 노선별 첫 지점의 다음 정류장을 셉니다(마지막 지점이면 회차해 첫 정류장). 최다를 고르고, 동률이면 순위가 낮은 노선의 다음 정류장을 씁니다.
  - 방면은 앱에서 계산합니다. O(41,688)이라 수 ms이고, 소형 픽스처로 AC-9·10을 검증할 수 있습니다.
- **시그니처**
  - `struct Stop: Equatable, Sendable { id; name; ars: String?; point: CoursePoint }`
  - `struct Route: Equatable, Sendable { id; number; kind; stops: [Int]; seconds: [Int]; meters: [Int] }`
  - `init(stops:routes:metadata:) throws`
  - `stop(id:)`, `route(id:)`, `boundLabel(stopIndex:) -> String?`

**4. `ios/FocusMate/RouteCatalog+Fixture.swift`(신규, `#if DEBUG`)**
- `acceptance`
  - PRD 표의 S1~S10, X~Z, P1~P3과 R1·R2·R3·R5·R7을 그대로 넣습니다.
  - **번호 없는 정류장**(AC-11)을 추가합니다: 오메가(S11, ARS 없음)와 시그마(S12, 50001). 노선 R8 지선 "8888"은 S11→S12 300초, 회차 300초입니다. S1을 지나지 않고 번호 "100" 접두와도 겹치지 않으므로 AC-1~4·12~21에 영향이 없습니다.
- `uiTest` = `acceptance` + 레거시 재현 노선
  - 기존 9개 이름과 W06 좌표(`JourneyCourse.swift:23-33`)를 쓰고 승강장은 양쪽 2벌입니다.
  - 300초 등간격 순환 "2014"(지선)와 반대쪽 승강장 순환 노선을 둡니다.
  - 기존 25·60분 UI 시나리오를 유지하는 용도입니다.
- AC-7(정류장 60개)과 AC-21(노선 25개)은 **단위 테스트 안에서 즉석으로 만드는 전용 카탈로그**입니다. 공용 픽스처에 넣지 않습니다.

**5. 호출부 교체**

| 호출부(현재) | 변경 |
|---|---|
| `JourneySnapshot.originName/destinationName/bus` (`JourneySnapshot.swift:73-75`) | 저장 필드로 바꿉니다(C절). |
| `PreparedJourneyDetails` (`PreparationDraft.swift:139-141`) | `JourneySelection`의 `originName`/`boundLabel`/`distanceMeters` |
| `TimeSelectionView` 방면 (:45-47) | `model.journeyOrigin?.boundLabel` |
| `BoardingPassContent` (:32-33) | `journey.busKind`/`busNumber` |
| `ActiveJourneyCardContent` (:21), `JourneyLiveActivityPolicy` (:30) | 저장 필드(카탈로그 없음) |
| `CourseJourney.init?(journey:)` (`JourneyCourseProgress.swift:23-30`) | `init?(journey:catalog:)` |
| `reachedStation` (`JourneyReach.swift:20-29`) | F절 |
| `RootView` "정방향/역방향" (:190-191) | `main.bound`에 "○○ 방면"을 표시합니다(AC-메인방면). 로딩 중이거나 실패하면 생략합니다. |
| `JourneyMapView`(:28, :67), `JourneyTimerView`(:274) | `map.journey.stops` |
| `UITestBootstrap` (:214-216, :229, :273-332, :363-367) | I절 |

**6. `AppModel.swift`, `AppModel+JourneyStart.swift`**
- **변경**
  - `AppModel.init(…, routeData: RouteCatalogStore = .init(load: { try RouteCatalogLoader.bundled() }))`
  - `FocusMateApp.start()`에서 `model.start()` 다음에 `routeData.startLoading()`을 부릅니다.
  - `journeyOrigin: RouteOrigin?`(`stopIndex`, `stopID`, `name`, `boundLabel`)
  - `journeyProceedState` 분기
    - 로딩 중: `.routeDataLoading`
    - 실패: `.routeDataFailed`
    - 현재 정류장 id가 데이터에 없음: `.originUnavailable`
  - 카탈로그가 준비됐을 때 진행 여정이 없고 현재 정류장 id가 데이터에 없으면 `restartStationSelection(reason: .stationRemoved)`를 1회 실행합니다. BR-13의 "출발 정류장 소실 → 최초 정류장 화면"을 여정이 없는 경우로 확장한 것입니다.
- **시그니처**
  - `var routeAvailability: RouteDataAvailability`
  - `var routeCatalog: RouteCatalog?`
  - `var currentStationBound: String?`
  - `func restartStationSelection(reason: StationResetReason) -> Bool`
  - `enum StationResetReason { case routeDataReplaced, stationRemoved }`

#### C. 저장 형식 (FR-11, BR-12, BR-13, FR-14)

**7. `AppSnapshot.swift`**
- `StationSnapshot`을 `{id, name}`으로 줄입니다.
- `SnapshotValidationIssue.invalidDirection`을 삭제합니다.

**8. `JourneySnapshot.swift`: v5 필드**
- **필드**: `id, cardID, originStopID, originName, minutes, busID(=노선 id, 키 유지), busNumber, busKind, destinationStopID, destinationName, tag, task, sound, boardedAt, phase, progress, paused`. `direction`은 삭제합니다.
- **이름 저장 원칙**
  - 표시 이름은 **그 이벤트 시점의 카탈로그 이름을 복사해 저장**하고, 저장 후에는 고치지 않습니다.
  - 이벤트 시점은 정류장 확정, 승차, 도달 계산입니다.
  - 그래서 도달 정류장(계산 시점 카탈로그 이름)과 도착 정류장(승차 시점 이름)이 같은 원칙을 따릅니다.
  - 기존 주석(:3-4)의 "다시 계산할 수 있는 값은 저장하지 않는다"를 이 원칙으로 바꿉니다.
- **비례 조정 구간은 저장하지 않고 매번 다시 계산합니다**
  - 노선 id, 출발 정류장(첫 지점), 분이면 결과가 결정적입니다.
  - BR-12는 도착 id 비교로 지킵니다.
  - **월별 갱신 뒤 도착 id는 같은데 중간 구간이 바뀐 경우는 수용합니다.** 지도에는 새 경로가 보이고, 타이머는 분 기준이라 그대로입니다. 이 내용을 architecture.md에 명시합니다.
- **validate**
  - 카탈로그 검사와 direction 검사를 삭제합니다. 카탈로그가 없는 decode 시점에도 판정할 수 있어야 하기 때문입니다.
  - 이름 4종이 비어 있지 않은지 검사합니다.
  - `invalidDirection/unknownStop/unknownBus`를 삭제합니다.
  - `Format`/`journeyFormat`(:8, :118, :149-151)을 삭제합니다.
- **`boarding(details:…)`**: `JourneySelection`의 값을 복사합니다.

**9. `SnapshotCodec.swift`**
- **버전**: `currentVersion = 5`. W09가 버전을 올렸다면 그 다음 번호를 씁니다.
- **이전 규칙**: W16 이전의 모든 버전을 "예시 데이터 시절"로 봅니다.
  - 신규 `LegacySnapshotV3V4` DTO가 카드·기록은 현재 타입으로, 정류장은 `LegacyStationSnapshot`으로 읽고, 여정은 존재 여부만 봅니다.
  - v1/v2도 같은 공통 `migrateLegacyRouteData`를 거칩니다.
  - 정류장과 여정은 비우고 카드·기록은 유지합니다(AC-36).
- **이전 보고**: 실제로 비운 것이 있을 때만 `SnapshotMigration.routeDataReset`을 돌려줍니다.
- **시그니처**: `static func decodeReport(_:) throws -> (snapshot: AppSnapshot, migration: SnapshotMigration?)`. 기존 `decode`는 래퍼로 남깁니다.
- **테스트**: 버전 숫자를 직접 쓰지 않고 `SnapshotCodec.currentVersion`을 참조합니다.

**10. `LocalSnapshotStore.swift`, `AppModel.swift`: 안내 1회**
- `loadReport()`를 추가합니다(`load()`는 래퍼).
- `loadSnapshot`이 이전을 보고받으면 메모리 값 `stationResetNotice = .routeDataReplaced`를 둡니다.
- `start()`에 `persistMigrationIfNeeded()`를 둡니다. `supplementCardIfNeeded`(:116-126)와 같은 패턴으로 v5를 즉시 저장합니다.
- `confirmInitialStation`이 성공하면 안내를 지웁니다.
- 플래그는 파일에 두지 않습니다. 즉시 저장이 성공했다면 재시작해도 이전이 일어나지 않습니다(AC-38). 저장이 실패하면 다음 실행에서 다시 이전하고 안내합니다.
- 안내 문구
  - `.routeDataReplaced`: "정류장 데이터가 서울 전체로 바뀌어 출발 정류장을 다시 골라 주세요"
  - `.stationRemoved`: "출발 정류장이 새 데이터에 없어 다시 골라 주세요"

#### D. 검색 BR-9 (FR-2, FR-3, QE-2, QE-5)

**11. `StationSearch.swift`(신규), `StationSearchState.swift`**
- **입력 정규화**: 앞뒤 공백을 지우고 `lowercased()`합니다.
- **빈 입력**: `.prompt` — "정류장 이름이나 5자리 번호를 입력하세요"
- **숫자만 입력**
  - 단계 0: 번호 정확 일치
  - 단계 1: 번호 앞자리 일치
  - 번호순으로 정렬합니다(AC-4).
- **그 밖 입력**
  - 단계 2: 이름 정확 일치
  - 단계 3: 이름 앞부분 일치
  - 단계 4: 이름 부분 일치
  - 같은 단계에서는 이름(String `<`, 완성형 한글은 가나다순), 번호, id 순으로 정렬합니다.
- **결과 수**: 50건에서 자르고 `overflow`를 표시합니다.
- **인덱스 없음**: 12,897개 선형 탐색입니다. AC-41이 실측합니다.
- **시그니처**
  - `struct StationOption: Identifiable, Equatable { id(=stopID); name; ars: String?; boundLabel: String?; snapshot: StationSnapshot; accessibilityLabel }`
    - 낭독: 번호가 있으면 "알파, 10001, 베타 방면", 없으면 "오메가, 시그마 방면"(AC-8, AC-11)
  - `enum StationSearchResult { case prompt, empty, results([StationOption], overflow: Bool) }`
  - `StationSearch.search(_:in:)`
  - `StationSearchState.result(in:)`

#### E. 후보·비례 조정·코스·진도 (FR-4~8, BR-5~8, BR-12, QE-3)

**12. `RouteLeg.swift`(신규)**
- **도착지(BR-6)**
  - 출발 정류장의 첫 지점을 p0, 목표를 T = 분×60으로 둡니다.
  - k = 1, 2, …마다 q = (p0+k) mod n으로 진행하며 회차 구간과 여러 바퀴를 허용합니다.
  - `stops[q]`가 출발 정류장이면 건너뜁니다.
  - |t_k − T| ≤ 60이면 후보입니다. 차이가 엄격히 작을 때만 교체하므로 동률이면 더 이른 지점이 남습니다.
  - t_k > T+60이면 멈춥니다. 최대 약 722걸음입니다.
- **비례 조정(BR-7)**
  - 원래 누적 시간 O = T이면 조정하지 않습니다.
  - 그 밖에는 앞 구간부터 `(2·seg·T + O) / (2·O)`로 구하고, 마지막 구간 = T − Σ(앞 구간)입니다.
  - **마지막 구간이 1초 미만이면 nil을 돌려 그 노선을 그 시간 후보에서 제외합니다**(확정 결정).
  - 검산 값: AC-12 [333, 267], AC-15 [319, 255, 446], AC-19 [310, 248, 434, 372, 124, 312]
- **시그니처**
  - `struct RouteLeg: Equatable, Sendable { routeIndex; originPosition; stopIndices: [Int]; segmentSeconds: [Int]; segmentMeters: [Int]; cumulativeSeconds: [Int]; differenceSeconds; distanceMeters }`
  - `enum RouteLegFinder { static let toleranceSeconds = 60; static func leg(route:originStop:minutes:in:) -> RouteLeg? }`

**13. `JourneyPlanner.swift`**
- **후보 생성**: `candidates(minutes:origin:in:)`는 `visitsByStop[origin]`의 노선마다 leg를 구합니다.
- **정렬**: (차이 초, 노선 순위 색인) 순이고 상위 20건입니다(BR-8).
- **거리**: `distanceText(meters:)`는 `(m+50)/100`을 0.1km 단위로 표시합니다. 정수 km이면 "3km"입니다(AC-23).
- **`JourneyCandidate`**: `{ routeID; busNumber; busKind; minutes; stops; destinationStopID; destination; leg; distanceText; accessibilityLabel }`
  - `id`는 노선 id입니다.
  - 낭독 형식은 기존과 같습니다(AC-24).

**14. `JourneyPlanDraft.swift`**
- `selectedRouteID`
- `choose/candidates/proceedState(origin:catalog:)`
- 시간이 바뀌면 선택을 해제합니다(:37-42, AC-22).
- `ProceedState`에 `.routeDataLoading`, `.routeDataFailed`를 추가합니다. `.noCandidates` 문구는 "이 시간에 맞는 버스가 없어요"입니다(FR-15).
- `JourneySelection { originStopID; originName; boundLabel?; minutes; busID; busNumber; busKind; destinationStopID; destination; stops; distanceMeters }`

**15. `JourneyCourseProgress.swift`, `JourneyCourse.swift`**
- **`CourseJourney`**: `{ stops: [CourseStop](index = 코스 위치 0…k); segmentSeconds; segmentMeters; cumulativeSeconds; totalSeconds }`
- **`init?(journey:catalog:)`**: 다시 계산합니다. 다음 경우 nil을 돌려주고, 그러면 지도를 생략합니다.
  - 노선이나 정류장이 데이터에 없음
  - leg를 구할 수 없음
  - 도착 id가 저장값과 다름(BR-12, AC-29)
- **진도**: j = max{i | cum[i] ≤ e}이고 구간 안 위치는 (e − cum[j]) / seg[j]입니다(AC-26, AC-28).
- **다음 정류장·남은 정류장**: 다음 정류장 = j+1, 남은 정류장 = k − j(AC-27)
- **남은 거리(0.1km)**: `(2·(m_j·(seg_j − r) + rest·seg_j) + 100·seg_j) / (200·seg_j)`(AC-26)
- **코스 선**: 경로는 `stops.map(\.point)`이고 닫는 선이 없습니다(AC-25).
- **정리**: `JourneyCourse`에서 `coordinates/stops/closedPath/seoulBounds`를 삭제합니다(AC-30).
- **고려사항**
  - 같은 정류장이 다시 나올 수 있으므로 지도 `ForEach`의 식별자는 `stop.index`로 씁니다(`JourneyMapView.swift:28`).
  - 좌표가 같은 구간은 직전 방위를 유지합니다.

**16. `JourneyMapController/View`, `JourneyTimerView`, `JourneyView`**
- `routePoints/visibleStops/destinationStop`을 `journey.stops`에서 가져옵니다(`JourneyMapController.swift:30-32`).
- `JourneyView.ensureTimer`(:43)는 `model.routeCatalog`를 씁니다. 카탈로그가 준비된 뒤에는 `onChange`로 지도를 한 번 더 시도합니다.

#### F. 도달 정류장 BR-14와 생명주기 (FR-9, BR-13, FR-14, AC-로딩차단)

**17. `JourneyReach.swift`**
- **타입**
  - `enum ReachAttempt: Equatable { case notLoaded, resolved(ReachResolution) }` — 일시적 상태
  - `enum ReachResolution: Equatable { case station(StationSnapshot), stayAtOrigin(StationSnapshot), reselectStation }` — 확정 결과
- **`JourneySnapshot.arrivedStation: StationSnapshot?`**: 도착이면 `{destinationStopID, destinationName}`입니다. 카탈로그가 필요 없습니다(AC-54).
- **`reachedStation(in availability: RouteDataAvailability) -> ReachAttempt`**
  - 도착: `.resolved(.station(arrivedStation))`. 로딩 상태와 무관합니다.
  - `.loading`: `.notLoaded`
  - `.ready`
    - leg 계산 성공: j = max{i | cum[i] ≤ elapsed}인 정류장을 카탈로그 이름으로 돌려줍니다(AC-31~33).
    - 노선이 없거나, leg가 없거나, 도착 id가 불일치하면 출발 정류장 존재 여부로 갈립니다.
      - 출발 정류장이 데이터에 있음: `.stayAtOrigin({originStopID, 카탈로그 이름})`, 안내 없음
      - 출발 정류장이 데이터에 없음: `.reselectStation`
  - `.failed`: `.stayAtOrigin({originStopID, originName})`. 확인할 수 없으므로 유지하고, 여정은 끝낼 수 있게 합니다.

**18. `AppModel+JourneyLifecycle.swift`, `JourneyAbandonBar.swift`, `RootView.swift`**
- `confirmNewJourney`(:36), `abandonJourney`(:50) 처리
  - `.notLoaded`: `.rejected`를 돌려주고 저장하지 않습니다.
  - `.station`/`.stayAtOrigin`: `endingActiveJourney(at:)`를 실행합니다.
  - `.reselectStation`: 최초·현재 정류장 비우기와 여정 삭제를 **한 스냅샷**으로 저장합니다. 안내는 `.stationRemoved`이고 최초 정류장 화면으로 갑니다(FR-11 재사용, `persist`가 경로를 바꿈).
- `var canEndActiveJourney: Bool`(도착이거나 `.notLoaded`가 아닐 때 true)
  - 포기 확인 버튼과 메인 '새 여정 시작' 확인 버튼을 이 값으로 비활성화합니다.
  - 힌트는 "정류장 정보를 불러오는 중이에요"입니다(AC-로딩차단).
- `abandonNotice`(:53)는 결과 정류장 이름을 그대로 씁니다.

#### G. 화면 (FR-2, FR-15, QE-5, AC-메인방면)

**19. `InitialStationSearchView.swift`**
- 상태별 문구와 식별자
  - prompt
  - empty: `search.empty`
  - overflow: `search.overflow`
  - loading: `search.loading`
  - failed: `search.dataFailed`
  - 안내: `search.resetNotice`
- 결과 행은 이름과 "10001 · 베타 방면"을 `fixedSize(horizontal: false, vertical: true)`로 보여 줍니다.
- 낭독은 `option.accessibilityLabel`을 씁니다.

**20. `TimeSelectionView.swift`**
- 후보 거리를 표시하고 식별자는 `time.candidate.<routeID>`입니다.
- 0건이거나 로딩 중이거나 실패하면 진행 버튼을 비활성화합니다.

**21. `RootView.swift`**
- 메인 정류장 이름 아래 `main.bound`에 `model.currentStationBound`를 표시합니다.
- `main.direction`을 삭제합니다.

#### H. 데이터 출처 화면 (FR-10, AC-39)

**22. `DataSourceView.swift`, `AppModel+Profile.swift`, `ProfileView.swift`, `DestinationScreen.swift`, `AppModel.swift`**
- `Destination.dataSource`의 제목은 "데이터 출처"입니다.
- `ProfileMenuItem.dataSource`를 추가하고 `destination`은 switch로 바꿉니다(`AppModel+Profile.swift:4-7`).
- 설정 행 아래에 `profile.dataSource` 행을 둡니다.
- `DataSourceContent(metadata:)` 문구
  - "서울특별시", "서울 열린데이터광장", "서울시버스노선별정류소정보", "서울시버스노선기본정보", "공공누리 제1유형"
  - "데이터 기준일 2026.09.02"
  - 구간 시간은 앱이 계산한 값이라는 안내
- 전체 스크롤, header trait, 줄 수 제한 없음
- `AppFoundationTests.swift:220`(`Destination.allCases`)을 갱신합니다.

#### I. UI 테스트 주입

**23. `UITestBootstrap.swift`, `FocusMateApp.swift`**
- `--fm-ui-route-data fixture|bundled|pending|failed` 인자를 받습니다. 기본은 fixture입니다.
  - `pending`: 로더가 끝나지 않습니다. AC-로딩차단 UI용입니다.
  - `failed`: 로더가 오류를 던집니다.
- `makeRouteCatalogStore()`를 `AppModel(routeData:)`로 주입합니다.
- 시드의 `seongsu`/`2014`/`direction`을 `uiTest` 픽스처의 id와 이름 필드로 바꿉니다.
- `lifecycleSnapshot`은 픽스처 leg로 도착지를 구합니다.
- `v3Bytes`·`rawSeeds`(v1/v2)는 이제 "이전으로 정류장 비움"을 검증합니다. `legacyV4Stations` 시드를 추가합니다(AC-36~38).
- `profileRecords`는 v5로 다시 씁니다.
- `seeds`(:148)를 갱신합니다.

#### J. 변환 스크립트 (FR-13, BR-1, BR-2, BR-4, BR-11)

**24. `scripts/build_route_data.py`(신규)**
- **CLI**: `python3 scripts/build_route_data.py --stops "<서울시버스노선별정류소정보(YYYYMMDD).xlsx>" --routes "<서울시버스노선기본정보(YYYYMMDD).xlsx>" --out ios/FocusMate/Resources/RouteData/seoul-route-data.json [--base-date YYYY-MM-DD] [--min-join-rate 0.95] [--max-bytes 10000000]`
- 다운로드는 하지 않습니다. 절차는 README에 둡니다: OA-1095, OA-15066 페이지의 내려받기. `seq`가 매월 바뀝니다.

**xlsx 읽기(표준 라이브러리)**
- `zipfile` + `xml.etree.ElementTree`를 씁니다.
- **첫 시트**는 `xl/workbook.xml`의 첫 `<sheet>`에서 `xl/_rels/workbook.xml.rels`로 경로를 찾습니다. 시트가 없으면 실패합니다.
- **sharedStrings**: `<si>` 아래 모든 `<t>`를 이어 붙입니다(리치 텍스트 `<r><t>` 포함). 읽기 기호 `<rPh>` 안의 `<t>`는 제외합니다.
- **열 위치**: 셀의 `r` 속성(예: `C12`) 문자 부분으로 정합니다. 빠진 셀이 있어도 밀리지 않습니다.
- **셀 타입**
  - `s`: 공유 문자열
  - `inlineStr`: `<is>` 아래 `<t>` 연결
  - `str`: 수식 결과 문자열
  - `b`: 불리언
  - 생략 또는 `n`: 숫자 원문
  - 결과는 (값, 문자열셀 여부)로 둡니다.
- **헤더**: `r="1"` 행만 헤더로 봅니다. 필수 열이 하나라도 없으면 누락 열 이름을 모두 출력하고 종료 코드 2로 끝내며 파일은 쓰지 않습니다(AC-51).
  - OA-1095 필수 열: `ROUTE_ID, 노선명, 순번, NODE_ID, ARS_ID, 정류소명, X좌표, Y좌표`
  - OA-15066 필수 열: `노선번호, 유형, 운행시간`

**정규화**
- **ROUTE_ID·NODE_ID·노선번호(숫자 셀일 때)·순번**
  - `Decimal(원문)`으로 읽습니다. 지수 표기(`1.0E8`)와 `.0`을 허용합니다.
  - 정수가 아니면 그 행을 오류로 집계하고 해당 노선을 제외 사유로 보고합니다.
  - 정수 문자열(`format(int, 'd')`)로 씁니다.
- **ARS_ID**
  - 문자열 셀: 앞뒤 공백을 지운 값을 그대로 씁니다(앞자리 0 보존).
  - 숫자 셀: 정수 문자열로 만들고 5자리 미만이면 **0을 채워 5자리**로 만듭니다. 경고 건수로 셉니다.
  - 빈 값, `~`, 전부 0인 값은 "번호 없음"입니다.
  - 숫자 5자리가 아닌 값("7832" 등)은 그대로 두고 이상 건수로 셉니다.
  - 요약에 숫자 셀 건수, 0 채움 건수, 5자리 아님 건수, 번호 없음 건수를 출력합니다.
- **좌표**: **X좌표 = 경도, Y좌표 = 위도**입니다. 마이크로도로 바꿀 때 `Decimal`로 계산하고 반올림 방식은 half-up입니다.
- **문자열**: 정류소명·노선명·노선번호·유형은 앞뒤 공백을 지웁니다.

**노선 정리(순서대로)**
1. ROUTE_ID별로 묶고 순번(정수) 오름차순으로 정렬합니다. 순번이 연속이 아니어도 순서만 씁니다. 같은 순번이 있으면 원본 행 순서를 따릅니다.
2. BR-11을 적용합니다: 좌표가 비었거나 위도 33~39, 경도 124~130 밖인 행이 있으면 노선 전체를 제외합니다(AC-47).
3. 정류소명에 "(가상)"이 들어간 지점을 제거합니다. 앞뒤 정류장은 직결되고 거리는 제거 후 직선으로 계산합니다.
4. 제거 후 같은 NODE_ID가 연속되면 하나로 합칩니다.
5. 마지막 NODE_ID가 첫 NODE_ID와 같으면 마지막 행을 제거합니다(1회).
6. 정류장이 2개 미만이면 제외합니다.

**노선 기본 정보 결합(BR-1)**
- 결합 키는 OA-1095 `노선명` = OA-15066 `노선번호`(정규화한 문자열)입니다.
- OA-15066에 같은 번호가 여러 행이면(공동운행) **첫 행**을 쓰고, 중복 건수를 요약에 냅니다.
- **결합률** = 결합된 노선 수 ÷ OA-1095 노선 수(정리 전)입니다.
  - `--min-join-rate`(기본 0.95) 미만이면 결합 실패 노선 목록을 출력하고 종료 코드 3으로 끝냅니다. 파일은 쓰지 않습니다.
  - 기준 이상이면 실패 노선만 제외하고 목록을 출력합니다.
- **유형**
  - 지선·마을·간선·공항·광역·순환: 그대로 씁니다.
  - 빈 값: "심야"로 포함합니다.
  - **한강·관광**: 제외합니다(개정 AC-48).
  - 그 밖 유형: 포함하고 속도는 "그 밖"을 씁니다. 요약에 목록을 냅니다.
- 폐지 열은 원천에 없습니다. 두 파일에 모두 있는 노선을 운행 중으로 봅니다(개정 BR-1).

**구간 시간(개정 BR-4, 결정적 정의)**
- 거리 d_i는 하버사인(R = 6,371,008.8m)으로 구하고 `floor(d+0.5)`로 정수 m를 만듭니다.
  - 배분과 저장 모두 이 **정수 m**을 씁니다. 이후 계산은 `fractions.Fraction`으로 하므로 부동소수가 결과에 영향을 주지 않습니다.
- 구간은 n개입니다(회차 포함).

**운행시간 R분 > 0일 때**
1. 목표 합 S = round_half_up(R × 60)으로 둡니다. R이 소수이면 `Decimal`로 계산합니다.
2. S < 30·n이면 모든 구간을 30초로 둡니다. **최소 30초가 운행시간보다 우선**하고, 합은 S를 넘습니다. 요약에 "최소 보정으로 운행시간 초과 노선" 수를 냅니다.
3. 그 밖에는 **최소값 고정 반복**을 합니다.
   - 처음에는 고정 집합 F = ∅, 미고정 집합 U = 전체입니다.
   - 반복할 때마다 B = S − 30·|F|로 두고, 이상값을 구합니다.
     - D_U > 0이면 x_i = B·d_i / D_U
     - D_U = 0이면 x_i = B / |U|
   - x_i < 30인 구간을 모두 F로 옮기고 반복합니다. 새로 옮길 구간이 없으면 끝납니다.
4. U에 **최대 잔여 방식**을 적용합니다.
   - base_i = floor(x_i)이고, 남는 초 r = B − Σbase_i입니다.
   - 소수 부분(x_i − base_i)이 큰 순으로 r개 구간에 1초씩 더합니다. 동률이면 **구간 색인이 작은 순**입니다.
   - F의 구간은 30초입니다.
   - 결과: 모든 구간 ≥ 30초이고, 합은 정확히 S입니다.

**운행시간 없음 또는 0일 때(약 56노선)**
- s_i = max(30, round_half_up(d_i × 36 / (v×10)))입니다.
- v(km/h, 유형별 실측 중앙값): 간선 13.4, 지선 11.6, 마을 8.8, 광역 19.6, 공항 34.8, 심야 17.3, 순환 9.4, 그 밖 11.6
- 계산은 `Fraction`으로 합니다.
- 요약에 "속도 대체 노선" 수를 냅니다.

**정류장·순위·출력**
- **정류장**: 포함된 노선이 참조하는 NODE_ID만 넣습니다. 대표값은 (ROUTE_ID, 순번) 정렬 기준 첫 행이고, id 사전순으로 정렬합니다(AC-50).
- **노선 순위**: 노선명의 자연 정렬 키로 정합니다. 숫자 묶음은 정수 크기, 나머지는 코드 포인트로 비교하고, 동률이면 ROUTE_ID입니다.
- **기준일**: 두 파일 이름의 `\((\d{8})\)`에서 읽습니다. OA-1095 날짜를 `baseDate`로 쓰고(AC-52), 두 날짜가 다르면 경고합니다. 날짜를 찾을 수 없으면 `--base-date`를 요구합니다.
- **출력**
  - A절의 행 단위 형식으로 씁니다. 각 행은 `json.dumps(ensure_ascii=False, separators=(",",":"))`입니다.
  - 같은 폴더에 임시 파일을 쓰고 `os.replace`합니다. 어느 단계에서 실패해도 기존 산출물은 그대로 남습니다(AC-49, AC-51).
  - 크기가 `--max-bytes`를 넘으면 종료 코드 4로 끝내고 교체하지 않습니다.
- **요약(stdout)**
  - 입력 행 수, 노선 수(입력/포함), 정류장 수
  - 제외 노선: 사유별(좌표, 결합 실패, 한강·관광, 정류장 부족, ID 오류) ROUTE_ID 목록
  - 가상 지점 제거 수, 끝 중복 제거 노선 수
  - ARS 이상 건수, 공동운행 중복 수, 속도 대체 노선 수, 최소 보정 노선 수
  - 결합률, 산출 바이트 수, 산출 SHA-256

**25. `scripts/tests/`**
- `__init__.py`를 둡니다.
- `xlsx_fixture.py`는 `zipfile`로 최소 xlsx를 만듭니다. sharedStrings와 리치 텍스트, inlineStr, 숫자 셀, 빠진 셀(`r` 건너뜀)을 만들 수 있습니다.
- `test_build_route_data.py`의 검증 범위
  - 파서: 리치 텍스트, `rPh` 제외, `r` 위치, 헤더 누락, 숫자 ID의 지수·소수 정규화, ARS 숫자 셀 0 채움
  - 정리: 가상 지점 제거, 끝 중복 제거, BR-11(AC-47)
  - 결합: 결합률 미달 실패, 공동운행 첫 행, 한강·관광 제외, 심야 표시(개정 AC-48)
  - 배분: 운행시간 비례, 최소 30초 고정 반복, 최대 잔여 동률, S < 30n, 속도 대체(개정 AC-45·46)
  - 출력: AC-44, 49(두 번 실행 바이트 비교), 50, 51(종료 코드, 메시지, 기존 파일 불변), 52, 크기 한도(`--max-bytes`를 작게 주입)
- 실행: `python3 -m unittest discover -s scripts/tests -t scripts -v`

---

### 테스트 측정 설계 (AC-40~43, AC-53)
- **AC-41 검색**
  - `RouteDataBundleTests`가 번들 카탈로그를 로드한 뒤 2글자 검색어(예: "역삼")로 `StationSearch.search`를 `ContinuousClock`으로 20회 측정합니다.
  - **평균 < 0.3초**를 assert합니다.
- **AC-42 후보**
  - 출발지는 `visitsByStop` 노선 수가 최다인 정류장입니다(동률이면 낮은 색인).
  - 15~360분을 1분씩 진행하며, 화면 한 번 그릴 때 부르는 만큼 측정합니다: `JourneyPlanDraft.candidates` 1회 + `proceedState` 1회(내부 2회).
  - 단계마다 < 0.2초를 assert하고, 20회 반복 평균도 기록합니다.
- **AC-43 크기·시작**
  - 번들 파일 크기 ≤ 10,000,000바이트
  - `RouteCatalogLoader.bundled()` 디코드 시간 상한 0.8초
  - **구조 테스트**: 끝나지 않는 로더를 주입한 `AppModel.start()`가 `launchState == .ready(.main)`에 도달하는지 봅니다. 첫 화면이 카탈로그를 기다리지 않음을 증명합니다.
- **AC-40 오프라인**
  - 카운팅 `URLProtocol`을 등록한 상태에서 검색과 후보 계산을 수행하고 요청 0건을 확인합니다.
  - `bundledURL()?.isFileURL == true`를 확인합니다.
  - 근거: 규칙은 네트워크 의존성이 없는 순수 함수입니다.
- **측정 기준**
  - 위 수치는 **Debug 빌드 시뮬레이터 기준 상한**입니다.
  - 초과하면 같은 테스트를 Release 구성으로 다시 측정합니다: `xcodebuild test -configuration Release ENABLE_TESTABILITY=YES -only-testing:FocusMateTests/RouteDataBundleTests`
  - Release에서도 초과하면 A절의 디코드 방식을 `JSONSerialization`으로 바꿉니다.
- **AC-53 실데이터 변환**
  - 수동 증거로 보고서에 실행 명령, 요약 출력 전문, 산출 SHA-256을 기록합니다.
  - 회귀는 `RouteDataBundleTests`가 맡습니다: 메타데이터 `baseDate`·파일 이름 일치, 정류장 > 10,000, 노선 > 600, 모든 노선 구간 ≥ 30초.

### 의존성 및 영향도
- **새 외부 의존성**: 없습니다.
- **번들 증가**: 약 1.6~2MB(추정)이고 AC-43이 실측합니다.
- **저장 형식**: v4에서 v5로 올라갑니다(W09가 먼저 올렸다면 그 다음 번호). 이전 앱은 새 파일을 `unsupportedVersion`으로 거부합니다. 외부 배포 전이라 개발 기기에만 영향이 있습니다.
- **테스트 영향**
  - 단위 테스트 18개 파일: `StationCatalogTests`, `JourneyPlannerTests`, `JourneyCourseTests`, `JourneyCourseProgressTests`, `JourneyMapControllerTests`, `JourneyReachTests`, `JourneySnapshotTests`, `JourneyPlanDraftTests`, `StationSearchStateTests`, `LifecycleSeedTests`, `JourneyStartModelTests`, `PreparationModelTests`, `BoardingModelTests`, `BoardingPassContentTests`, `CardCustomizationAppModelTests`, `JourneyTimerModelTests`, `PreparationDetailsTests`, `BoardingTestDoubles`
  - UI 테스트 13개 파일: `search.result.seongsu:1`, `time.candidate.2014`, `main.direction` 참조
- **문서**: glossary의 "도달 정류장" 정의를 누적 초 기준으로 바꾸고, architecture.md에 다음을 반영합니다.
  - 카탈로그 주입
  - 저장 v5와 이름 저장 원칙
  - 월별 중간 구간 변화 수용

#### 기존 구조와의 차이
- **카탈로그**: 전역 static 상수에서 주입되는 값 타입 카탈로그로 바뀝니다. 모든 규칙 함수가 `RouteCatalog` 인자를 받습니다.
- **앱 시작**: 백그라운드 데이터 로딩이 생기고, loading/failed 상태와 생명주기 차단이 추가됩니다.
- **진행 여정**: 이벤트 시점의 표시 이름을 저장합니다. 저장 검증은 카탈로그와 무관해집니다. "카탈로그 밖 여정은 읽을 때 버림"(`JourneySnapshot.swift:4`)이 "지도 생략 + 도달 정류장 대체"로 바뀝니다.
- **방향**: ±1 방향이 없어지고 정류장은 승강장 단위가 됩니다. 메인 표시는 방향 대신 방면입니다.
- **지도 코스**: 열린 선이고 같은 정류장이 반복될 수 있습니다. 서울 경계 상자는 삭제합니다.
- **BR-12**: 유지합니다. 다만 계산 근거가 "순환 계산"에서 "노선 위 누적 초 ±60초"로 바뀝니다.
- **데이터 파이프라인**: xlsx 2개를 읽어 결정적 JSON을 만드는 Python 파이프라인이 처음 생깁니다.

#### W09 경계 (FR-14)
- **겹치는 지점**
  - `reachedStation`(`JourneyReach.swift:20-29`)
  - `destinationStopID`·`destinationName`
  - `CourseJourney.init?`
  - `ActiveJourneyCardContent.Kind.arrived`(:22)
  - `AppSnapshot.endingActiveJourney`(:34)
  - `SnapshotCodec.currentVersion`
  - `UITestBootstrap` 시드
- **W16 원칙**: 도착 여정은 저장값(`arrivedStation`)만 읽습니다. 하차 후 현재 정류장은 저장된 도착 정류장입니다. W09의 하차 로직은 바꾸지 않고 데이터 접근 부분만 교체합니다.

**W09 머지 후 재확인 체크리스트**
1. `SnapshotCodec.currentVersion`을 확인합니다. W09가 올렸다면 W16은 그 +1입니다. W09가 추가한 필드는 legacy DTO에 반영합니다.
2. W09가 `JourneySnapshot`/`AppSnapshot`에 추가한 필드를 v5 필드 목록과 `with(...)`(:67-71)에 합칩니다.
3. 하차 저장이 `reachedStation`을 부르면 `arrivedStation`으로 바꾸고, 동작이 같은지 확인합니다(AC-54·55).
4. 완료 기록 `from/to/bus`의 출처를 저장 필드 `originName/destinationName/busNumber`로 바꿉니다.
5. 도착 안내의 `CourseJourney.init?(journey:)`를 `init?(journey:catalog:)`로 바꿉니다. BR-12는 그대로입니다.
6. `ActiveJourneyCardContent.Kind.arrived`가 하차 진입으로 바뀌었는지, `journey.bus` 의존이 남았는지 확인합니다.
7. 하차 완료 시 `StationSnapshot(direction:)`을 만드는 곳이 있으면 제거합니다.
8. W09가 추가한 UI 시드와 UI 테스트에서 `RouteStops`/`seongsu`/`2014`를 `uiTest` 픽스처로 바꿉니다.
9. W09 문서의 "도달 정류장"·"도착지 일관성" 문구를 다시 맞춥니다.
10. `RouteStops.wrap` grep 결과가 0건이어야 합니다.
11. 하차 화면에서 로딩 전 차단(`canEndActiveJourney`)이 필요한지 판단합니다. 도착 여정은 카탈로그가 필요 없으므로 차단하지 않는 것이 기본입니다.

### 작업 분할 권고
- **W16a(데이터 파이프라인)는 W09와 무관하므로 지금 진행할 수 있습니다.**
  - 범위: `scripts/build_route_data.py`, `scripts/tests/`, `scripts/data/README.md`, 실데이터 산출물 JSON
  - 앱 코드, 저장 형식, `reachedStation`을 건드리지 않습니다.
  - 산출 JSON은 W16a에서 `scripts/data/out/`이나 PR 첨부로 검증만 하고, **번들 리소스 위치에 커밋하는 일은 W16b에서** 합니다. 사용하지 않는 리소스로 번들이 커지는 것을 피하기 위해서입니다.
- **선택적 W16a+(순수 앱 모듈, 추가만)**
  - 범위: `RouteCatalog`, `RouteCatalogLoader`, `RouteCatalog+Fixture`, `StationSearch`, `RouteLeg`와 각 단위 테스트
  - 신규 파일만 추가하고 기존 파일은 수정하지 않습니다. W09와 충돌할 지점은 없습니다.
  - 다만 PRD의 "W16 구현 착수 조건: W09 머지"를 문자 그대로 적용하면 이 범위도 W16에 해당합니다. 그래서 확인 사항으로 남깁니다.
- **W16b(통합)는 W09 머지 후에 합니다.** 기존 파일 교체, 저장 v5, 화면, 시드, UI 테스트가 여기에 들어갑니다.

### 구현 순서
각 단계는 AC 단위 태스크로 나눌 수 있게 묶었습니다. 괄호 안은 의존 단계입니다.

**W16a — 지금 가능**
1. [Must] JSON 형식 명세와 다운로드 절차를 `scripts/data/README.md`에 작성 (의존: 없음)
2. [Must] xlsx 읽기와 헤더 검증 — AC-51(누락 열), 파서 단위 테스트 (의존: 1)
3. [Must] 정규화(ID, ARS, 좌표)와 노선 정리(가상, 끝 중복, BR-11) — AC-47, AC-50, 가상 지점 개정 AC (의존: 2)
4. [Must] 노선 기본 정보 결합(결합률, 공동운행, 한강·관광 제외, 심야) — 개정 AC-48 (의존: 2)
5. [Must] 구간 시간 배분(비례, 최소 고정, 최대 잔여, 속도 대체) — 개정 AC-45, AC-46 (의존: 3, 4)
6. [Must] 출력·결정성·원자 교체·요약·크기 한도·기준일 — AC-44, AC-49, AC-51(보존), AC-52 (의존: 5)
7. [Must] 실데이터 변환과 증거 기록 — AC-53 (의존: 6)
8. [Must] (W16a+ 선택) `RouteCatalog`·`Loader`·`Fixture` — AC-9, AC-10 (의존: 1)
9. [Must] (W16a+ 선택) `StationSearch` — AC-1~4, AC-7, AC-8, AC-11 단위 (의존: 8)
10. [Must] (W16a+ 선택) `RouteLeg` — AC-12~15, AC-17~20 구간·도착지 단위 (의존: 8)
11. [Must] (W16a+ 선택) `JourneyPlanner` — AC-12~21, AC-23, AC-24 (의존: 10)

**W16b — W09 머지 후**

12. [Must] W09 체크리스트 1~11 점검. C절(저장 필드·버전)과 F절(도달·생명주기)을 W09 결과에 맞춰 다시 검토하고 차이를 기록 (의존: W09 머지)
13. [Must] 저장 v5(`StationSnapshot`, `JourneySnapshot`, 검증, `SnapshotCodec` 이전, `loadReport`) — AC-36 단위 (의존: 12)
14. [Must] `RouteCatalogStore`(availability, Task 핸들, `loaded()`) — AC-43 구조 테스트 (의존: 8)
15. [Must] `JourneyPlanDraft`·`JourneySelection`·`ProceedState`·`boarding` — AC-22, AC-16·17 상태 (의존: 11, 13)
16. [Must] `CourseJourney`·진도·`JourneyCourse` 정리 — AC-25~30 (의존: 10, 13)
17. [Must] `JourneyReach`(`ReachAttempt`/`ReachResolution`, `arrivedStation`) — AC-31~35, AC-54 (의존: 10, 13, 14)
18. [Must] `AppModel` 주입, 이전 즉시 저장, 안내, `restartStationSelection`, 생명주기 차단 — AC-37, AC-38, AC-55, AC-로딩차단, BR-13 모델 (의존: 14, 15, 17)
19. [Must] 최초 정류장 화면 — AC-5~8, AC-11 UI, AC-37 UI, failed 화면 (의존: 9, 18)
20. [Must] 시간 선택·준비·승차권·진행 카드·Live Activity — AC-16, AC-17, AC-24 UI (의존: 15, 18)
21. [Must] 메인 방면과 생명주기 버튼 비활성 — AC-메인방면, AC-로딩차단 UI (의존: 18)
22. [Must] 지도 연결 — AC-25~29 UI (의존: 16, 18)
23. [Must] 데이터 출처 화면 — AC-39 (의존: 8, 18)
24. [Must] 번들 리소스 커밋(7의 산출물)과 `RouteDataBundleTests` 회귀 — AC-43 크기, AC-53 회귀 (의존: 7, 14)
25. [Must] `UITestBootstrap` 픽스처·pending/failed 주입, 시드 전환, 기존 UI 테스트 갱신 — AC-36~38 UI (의존: 19~23)
26. [Should] 성능·오프라인 측정 — AC-40~43, 후보 0건 비율 보고 (의존: 24)
27. [Must] 문서 갱신(glossary, architecture, status) (의존: 25)

- 병렬로 진행할 수 있는 묶음
  - 3과 4
  - 9와 10(8 이후)
  - 16과 17
  - 19~23
- 2~7과 8~11은 서로 독립입니다.

### 탐색 추가 항목
- `ios/FocusMate/SnapshotCodec.swift:49-79` → 버전 분기와 v3 해석. v5 이전 통합 지점입니다.
- `ios/FocusMate/LocalSnapshotStore.swift:88-115` → `load()`/`save()`(저장 전에 다시 읽음). `loadReport` 추가 위치입니다.
- `ios/FocusMate/AppModel.swift:111-126, 184-230` → `start()`의 읽기·쓰기 분리, `persist`의 경로 재설정. 이전 즉시 저장과 정류장 다시 고르기의 선례입니다.
- `ios/FocusMate/AppModel+JourneyLifecycle.swift:33-55` → 새 여정과 포기에서 도달 정류장을 소비하는 지점이자 차단 지점입니다.
- `ios/FocusMate/JourneyView.swift:34-47` → 지도 생성(BR-12 nil 분기)입니다.
- `ios/FocusMate/JourneyMapView.swift:28, 67` → 정류장 `ForEach` id와 다음 정류장 낭독입니다.
- `ios/FocusMate/JourneyTimerView.swift:268-283` → 지도 진단 JSON입니다.
- `ios/FocusMate/ActiveJourneyCardContent.swift:20-30`, `ios/FocusMate/JourneyLiveActivityPolicy.swift:29-33` → 카탈로그 없이 이름을 읽어야 하는 지점입니다.
- `ios/FocusMate/RootView.swift:186-212` → 메인 정류장, 방향 표시, 새 여정 확인입니다.
- `ios/FocusMate/DestinationScreen.swift:11-24`, `ios/FocusMate/AppModel+Profile.swift:4-27` → 출처 화면 라우팅입니다.
- `ios/FocusMate/FocusMateApp.swift:17-51, 92-108` → `AppModel` 생성과 시작 순서(로딩 시작 위치)입니다.
- `ios/FocusMate/UITestBootstrap.swift:148, 214-234, 273-367` → 시드와 라우트 주입입니다.
- `ios/FocusMate/AVSoundPreviewPlayer.swift:22-28`, `ios/FocusMate/Resources/**` → 리소스가 번들 루트로 평탄화되는 선례입니다.
- `ios/FocusMate.xcodeproj/project.pbxproj:35, 72` → 동기화 루트 그룹과 빌드 설정입니다.
- `ios/FocusMateTests/AppFoundationTests.swift:220` → `Destination.allCases` 순회입니다.
- `scripts/check-ios.py:10-40` → build/test 인자 규약(Release 재측정은 xcodebuild를 직접 실행)입니다.
- `scripts/data/README.md` → 데이터 출처 문서 위치입니다.

---

---

## 설계 정합 (2026-10-15, 개정 PRD 대조 — 아래가 본문보다 우선)
- 구간 배분·정리 순서·결합 안전장치·ARS·자연 정렬 위치·BR-13/15/16/17은 prd.md 끝 "설계 정합 개정" 절을 따른다.
- 결정: 거리 합 0 노선은 균등 배분(B-1 설계안 채택). "(가상)" 판정은 "끝나는" 기준(B-3 PRD안).
- 스크립트: 요약 사유 이름은 PRD("기본정보에 없는 노선", "유형 제외", "좌표 이상"). AC-77 SHA-256은 원본 2개+산출 1개. 픽스처 테스트는 `--min-join-rate 0`. 스크립트 노선 출력 순서는 ROUTE_ID 순(자연 정렬은 앱 `RouteNumberOrder`가 `RouteCatalog.init`에서 계산).
- 앱: 빈 입력 문구 "정류장 이름이나 번호를 입력하세요". BR-13 문구 "저장된 출발 정류장이 서울 버스 데이터에서 사라져 다시 골라 주세요". 로딩 중 `main.bound`는 빈 문자열로 존재. 픽스처는 PRD 표(S11 무번호정류장, R8 "8888" S11→S4 600초·회차 60초) — 오메가·시그마 안 폐기. AC-7·9·22·23 데이터는 테스트 안 즉석 카탈로그.
- 측정: AC-52·53·54는 PRD 방식(검색어 20개 평균, 18분 간격 20값 평균, 준비 시간 20회 평균 ≤1초).
- AC-76 검사(저장소 1MB 이상 xlsx 0개)는 1단계 `scripts/tests`에 둔다.
- 이번 실행 범위(사용자 결정 2026-10-15): 구현 순서 1~11(W16a 스크립트·데이터 + W16a+ 새 파일만 추가하는 앱 계산 모듈). 12~27은 W09 머지 후. 7단계 산출 JSON은 번들 위치(`ios/FocusMate/Resources/RouteData/`)에 두지 않고 `scripts/data/out/`(gitignore 여부는 구현 때 결정)에서 검증만 한다.

## 구현 단계 ↔ 개정 PRD AC 매핑

| 단계 | 내용(2회차 설계 구현 순서) | 개정 PRD AC |
|---|---|---|
| 1 | 형식 명세·README, 원천 xlsx 비보관(1MB 이상 xlsx 검사 테스트 추가) | AC-76 |
| 2 | xlsx 읽기·헤더 검증 | AC-74(누락 열 실패), AC-57(읽기 부분) |
| 3 | 정규화·노선 정리(ID, ARS, 순번 정렬, 가상 지점, 끝 중복, BR-11) | AC-61(가상 제거), AC-62(끝 중복), AC-63, AC-64, AC-71, AC-73 |
| 4 | 기본정보 결합·유형 처리 | AC-57, AC-58, AC-59, AC-60 |
| 5 | 구간 시간 배분 | AC-61, AC-62, AC-65, AC-66, AC-67, AC-68, AC-69, AC-70 |
| 6 | 출력·결정성·원자 교체·요약·크기 한도·기준일 | AC-72, AC-74(기존 파일 보존), AC-75, AC-56(스크립트 한도) |
| 7 | 실데이터 변환·증거 | AC-77 |
| 8 | `RouteCatalog`·`Loader`·`Fixture`(+ 앱 쪽 노선 번호 자연 정렬, D-1) | AC-10, AC-11, AC-23 |
| 9 | `StationSearch` | AC-1~AC-9, AC-12(단위) |
| 10 | `RouteLeg` | AC-13~AC-16, AC-18~AC-21(구간·도착지 계산) |
| 11 | `JourneyPlanner` | AC-13~AC-22, AC-25, AC-26 |
| 12 | W09 체크리스트, C·F절 재검토 | AC-78, AC-79(계약 확인) |
| 13 | 저장 v5·이전 | AC-46(단위), AC-48(코덱 부분) |
| 14 | `RouteCatalogStore` | AC-55(구조 테스트), AC-42(상태 전이) |
| 15 | `JourneyPlanDraft`·`ProceedState` | AC-17, AC-18(상태), AC-24 |
| 16 | 코스·진도 | AC-27~AC-32 |
| 17 | 도달 정류장(`ReachAttempt`) | AC-33~AC-36, AC-78 |
| 18 | `AppModel` 연결·생명주기·BR-13·BR-16 | AC-37~AC-40, AC-43~AC-45, AC-47, AC-48, AC-79 |
| 19 | 최초 정류장 화면 | AC-5~AC-8, AC-12(UI), AC-47(UI) |
| 20 | 시간 선택·준비·승차권·카드 | AC-17, AC-18(UI), AC-26 |
| 21 | 메인 방면·버튼 비활성 | AC-41, AC-42, AC-43·AC-44(UI) |
| 22 | 지도 연결 | AC-31(UI), AC-27~AC-30(UI) |
| 23 | 데이터 출처 화면 | AC-49 |
| 24 | 번들 리소스 커밋·회귀 테스트 | AC-50, AC-56, AC-77(회귀) |
| 25 | `UITestBootstrap`·UI 시드 | AC-46~AC-48(UI), AC-43(UI, `pending`) |
| 26 | 성능·오프라인 측정 | AC-51, AC-52, AC-53, AC-54, AC-55, AC-56 |
| 27 | 문서 | (AC 없음) |

AC-23은 D-1 권고(자연 정렬을 앱에서 계산)를 채택한다는 전제로 8단계에 둡니다. 채택하지 않으면 AC-23은 6단계(스크립트 노선 순서)와 11단계(순위 사용)로 나뉘어 검증됩니다.


## Testability 평가 (test-architect)

설계서(`design-draft.md`), PRD 수용 기준, 코드 맵, 프론트 테스트 규약 §2·§4를 읽고 평가했습니다. `check-ios.py`, 테스트 타깃의 `Bundle.main` 사용 선례(`AudioResourceTests` 등 호스팅 테스트), `scripts/`에 Python 테스트가 아직 없다는 점도 직접 확인했습니다.

### 컴포넌트별 테스트 전략

#### 1. RouteCatalog(파생 색인, 방면 BR-10)
- 레이어: 동작(상태·데이터 로직). 순수 값 타입입니다.
- 러너: XCTest. 실행 명령은 `python3 scripts/check-ios.py test ios/FocusMateTests/RouteCatalogTests.swift`입니다.
- 단위 테스트: `RouteCatalog.acceptance` 픽스처로 `boundLabel(stopIndex:)`를 확인합니다. S1은 "베타 방면", S1b는 "델타 방면"입니다. `visitsByStop`이 노선마다 첫 지점만 담는지 봅니다. 정류장 2개 미만이거나 구간 초가 1 미만이면 init이 throw하는지 봅니다.
- 통합 테스트: 없음(Loader 쪽에서 다룹니다).
- 모의 대상: 없음. 생성자에 값을 넣으면 됩니다.
- 격리 전략: 전역 static을 없애고 인자로 주입합니다. 테스트마다 카탈로그를 따로 만들 수 있습니다.
- AC 매핑: AC-9, AC-10(방면 부분)

#### 2. RouteCatalogLoader(JSON DTO → 카탈로그)
- 레이어: 동작(순수 변환)
- 러너: XCTest
- 단위 테스트: `load(data:)`에 작은 JSON `Data`를 넣습니다. 정상 경우, 배열 길이 불일치, 색인 범위 밖, 마이크로도 좌표 변환, metadata 값을 확인합니다.
- 통합 테스트: `RouteDataBundleTests`에서 `bundled(.main)`로 실제 번들을 디코드합니다. 테스트가 앱에 호스팅되어 있어 `Bundle.main`이 앱 번들입니다.
- 모의 대상: `Bundle`은 인자로 주입되므로 모의가 필요 없습니다.
- 격리 전략: `Data`만 입력으로 받습니다.
- AC 매핑: AC-43(크기, 디코드 시간), AC-40(번들에서만 읽는다는 근거)

#### 3. RouteCatalogStore(`@MainActor @Observable`, 백그라운드 로딩)
- 레이어: 동작(상태 전이 idle → loading → ready/failed)
- 러너: XCTest(async)
- 단위 테스트: `init(load:)`에 동기 클로저를 넣어 ready와 failed 전이를 봅니다. `init(ready:)`이면 바로 ready입니다. `startLoading()`을 부르지 않으면 idle이고, 이 상태로 `.routeDataLoading` 분기를 검증합니다.
- 통합 테스트: AppModel과 함께 다룹니다(아래 7).
- 모의 대상: 로드 클로저
- 격리 전략: 클로저 주입입니다(`LocalSnapshotStore(readData:writeData:)`와 같은 패턴).
- 주의: `startLoading()`이 `Void`를 돌려주고 안에서 `Task.detached`를 띄우기 때문에, 테스트가 완료 시점을 기다릴 방법이 없습니다. `@discardableResult func startLoading() -> Task<Void, Never>`처럼 기다릴 수 있는 핸들을 돌려주거나 `func load() async`를 따로 두라고 권고합니다. 이게 없으면 폴링 기반의 깜빡이는(flaky) 테스트가 됩니다.
- AC 매핑: 간접(AC-43 시작 시간 근거, 로딩 상태 UI)

#### 4. StationSearch + StationSearchState(BR-9, BR-10 표시, QE-5 낭독)
- 레이어: 동작(순수 규칙과 포맷터)
- 러너: XCTest
- 단위 테스트: `search(_:in:)`의 결과 `StationSearchResult`를 직접 비교합니다. 대상은 AC-1(순서), AC-2(공백·대소문자), AC-3, AC-4(번호 앞자리, 번호순), AC-6(`.prompt`), AC-5(`.empty`)입니다. AC-7은 테스트 안에서 정류장 60개짜리 카탈로그를 인라인으로 만들어 50건과 `overflow: true`를 봅니다. AC-8과 AC-11은 `StationOption.accessibilityLabel`로 봅니다.
- 통합 테스트: `StationSearchState.result(in:)`의 선택 유효성 규칙
- 모의 대상: 없음
- 격리 전략: 카탈로그 인자 주입
- 결함: PRD 픽스처 표에는 정류장 번호가 없는 정류장이 하나도 없습니다. 그래서 `acceptance` 픽스처만으로는 AC-11을 검증할 수 없습니다. 번호 없는 정류장을 넣은 별도 픽스처를 테스트에서 만들거나, `uiTest` 픽스처에 추가해야 합니다.
- AC 매핑: AC-1~4, 7, 8, 11은 단위 테스트, AC-5·6은 단위 테스트와 UI 테스트

#### 5. RouteLegFinder / RouteLeg(BR-6 도착지, BR-7 비례 조정, FR-7 회차)
- 레이어: 동작(순수 규칙, 정수 산술)
- 러너: XCTest
- 단위 테스트: `leg(route:originStop:minutes:in:)`의 `stopIndices`, `segmentSeconds`, `differenceSeconds`를 확인합니다. AC-12 [333,267], AC-13, AC-14(조정 없음), AC-15 [319,255,446], AC-17(nil), AC-18(여러 바퀴), AC-19 [310,248,434,372,124,312], AC-20(동률이면 더 이른 쪽)입니다. 경계 60초는 후보이고 61초는 제외인지도 봅니다.
- 통합 테스트: 없음
- 모의 대상: 없음
- 격리 전략: 카탈로그와 색인만 입력으로 받습니다. 공식 `(2·seg·T+O)/(2·O)`가 PRD 검산값과 맞아서 결정적입니다.
- 미결: 질문 3(마지막 구간이 0초 이하가 되는 경우)이 정해지면 그 극단 경우를 담은 픽스처 테스트가 1건 필요합니다. 결정 전에는 RED를 쓸 수 없습니다.
- AC 매핑: AC-12~15, 17~20

#### 6. JourneyPlanner / JourneyPlanDraft(후보 정렬, 20건, 거리, 낭독, 진행 상태)
- 레이어: 동작
- 러너: XCTest
- 단위 테스트: `candidates(minutes:origin:in:)`의 순서와 개수를 봅니다. AC-12는 "1111" 다음 "2222"이고 동률이면 노선 순위 색인으로 가립니다. AC-21은 노선 25개짜리 인라인 카탈로그로 20건을 확인합니다. `distanceText(meters:)`는 AC-23 "2.5km", `accessibilityLabel`은 AC-24입니다. `JourneyPlanDraft`는 시간이 바뀌면 선택이 해제되는지(AC-22), 0건이면 `.noCandidates` 문구인지(AC-16·17), `.routeDataLoading` 상태를 봅니다.
- 통합 테스트: TimeSelectionView UI 테스트(아래 10)
- 모의 대상: 없음
- 격리 전략: `(origin: RouteOrigin, catalog:)` 인자 주입
- AC 매핑: AC-12~24(16·17은 상태 단위 테스트와 UI 테스트)

#### 7. AppModel(+JourneyStart / +JourneyLifecycle / +Profile): 주입, `journeyOrigin`, 이전 후 즉시 저장, 안내 플래그, `.unresolved` 처리
- 레이어: 동작(상태와 라우팅 분기)
- 러너: XCTest
- 단위 테스트: `AppModel(routeData: RouteCatalogStore(ready: .acceptance), store: LocalSnapshotStore(readData:writeData:))`로 만듭니다. 확인할 것은 다음과 같습니다.
  - v4 바이트를 넣고 `start()` 하면 `routeDataResetNotice == true`이고 즉시 저장이 1회 일어난다. 이때 써진 바이트가 v5다.
  - `confirmInitialStation`을 하면 플래그가 지워진다(AC-37 모델 부분).
  - 저장된 v5 바이트로 다시 시작하면 플래그가 없다(AC-38).
  - 노선이 없는 카탈로그에서 포기하면 출발 정류장이 유지되고 `stationReselectNotice`가 켜진다(AC-35).
  - 도착 후 하차하면 현재 정류장 id가 저장된 도착 id와 같다(AC-55).
- 통합 테스트: 위가 사실상 모델 통합 테스트입니다. 저장 클로저는 메모리 버퍼로 대체합니다.
- 모의 대상: 저장소 read/write 클로저, 카탈로그 스토어
- 격리 전략: 생성자 주입. 기존 `JourneyServices` 패턴을 그대로 씁니다.
- 미결: 질문 2(다시 고르기 동작)가 정해져야 AC-35의 후속 화면 전이를 RED로 쓸 수 있습니다.
- AC 매핑: AC-35, 36(모델), 37, 38, 55

#### 8. 저장 v5: AppSnapshot / JourneySnapshot / SnapshotCodec / LocalSnapshotStore
- 레이어: 동작(직렬화와 이전)
- 러너: XCTest
- 단위 테스트: `decodeReport`에 v1~v4 바이트를 넣으면 정류장과 여정이 비워지고, 카드 1장과 기록 3건은 그대로이며, `migration == .routeDataReset`인지 봅니다(AC-36). v5 바이트는 `migration == nil`이고 같은 내용으로 다시 직렬화되는지 봅니다. validate에서는 `emptyField`를 봅니다. `arrivedStation`은 카탈로그 없이 저장값을 돌려줘야 합니다(AC-54).
- 통합 테스트: `LocalSnapshotStore.loadReport`의 복구 경로
- 모의 대상: 없음. 바이트 픽스처만 씁니다.
- 격리 전략: 순수 codec입니다. 이전 여부를 예시 id 목록이 아니라 버전으로 판정해서 결정적입니다.
- 주의: W09 체크리스트 1·2에 따라 버전 번호가 5가 될지 6이 될지가 달라집니다. 테스트에서 버전을 숫자로 박지 말고 `SnapshotCodec.currentVersion`을 참조하라고 권고합니다.
- AC 매핑: AC-36, 38, 54

#### 9. CourseJourney / JourneyCourseProgress / JourneyReach(코스, 진도, 도달)
- 레이어: 동작(순수 규칙)
- 러너: XCTest
- 단위 테스트:
  - `init?(journey:catalog:)`: 점 4개이고 닫는 선분이 없다(AC-25). 경과 420초에 구간 안 위치 0.5, 남은 거리 14(1.4km)다(AC-26). 공식을 손으로 검산해 보니 맞습니다.
  - AC-27: 다음 정류장과 남은 정류장 수, 도착 상태
  - AC-28: 319초에 버스가 S2 좌표에 있다
  - AC-29: 저장된 도착이 S5이면 nil
  - AC-30: 서울 밖 좌표가 있어도 nil이 아니다
  - `reachedStation(in:)`: AC-31(700초 → S3), AC-32, AC-33(경계 318·319·573·574초), AC-34(도착한 여정은 저장값), AC-35(카탈로그에 노선이 없으면 `.unresolved`)
- 통합 테스트: JourneyMapController 단위 테스트(`journey.stops`에서 경로 얻기). AC-29의 지도 생략은 UI 테스트로 봅니다.
- 모의 대상: 없음
- 격리 전략: 스냅샷과 카탈로그를 값으로 주입합니다. 시간은 경과 초를 인자로 넣습니다.
- AC 매핑: AC-25~35, 54

#### 10. 화면: InitialStationSearchView / TimeSelectionView / DataSourceView / ProfileView 항목
- 레이어: 동작(조건부 표시, 버튼 잠금, 이동). `.fixedSize`로 큰 글자에서 잘리지 않게 하는 부분(QE-5 표현 쪽)은 표현이므로 범위 밖입니다.
- 러너: XCUITest. 앱을 `--fm-ui-route-data fixture`와 `--fm-ui-*` 시드 인자로 띄우고 `python3 scripts/check-ios.py test ios/FocusMateUITests/<File>.swift`로 실행합니다.
- 셀렉터(§4 준수): 접근성 식별자 `search.empty`, `search.overflow`, `search.loading`, `search.dataResetNotice`, `search.result.<stopID>`, `time.candidate.<routeID>`, `profile.dataSource`와 화면에 보이는 문구를 씁니다. 버튼 비활성은 `isEnabled`로 봅니다. 스타일이나 구조에 기대는 셀렉터는 없습니다.
- 단위 테스트: `DataSourceContent(metadata:)`의 문구 5종과 "2026.09.02" 날짜 변환(AC-39). `Destination.allCases` 순회 테스트도 갱신합니다.
- 모의 대상: 카탈로그는 부트스트랩이 고른 `uiTest` 픽스처, 저장 상태는 시드
- 격리 전략: UITestBootstrap 인자로 주입합니다.
- 주의: AC-7 overflow를 UI에서 보려면 `uiTest` 픽스처에 "테스트1~60" 정류장이 있어야 하고, AC-11을 UI에서 보려면 번호 없는 정류장이 있어야 합니다. 설계는 `uiTest` = acceptance + 레거시 노선이라고만 적고 있습니다. 둘 다 넣거나, AC-7·11은 단위 테스트로만 검증한다고 명시하라고 권고합니다.
- AC 매핑: AC-5, 6, 7, 16, 17, 37, 39(UI). AC-8, 11, 24는 단위 테스트를 주로 쓰고 UI는 보조입니다.

#### 11. UITestBootstrap(픽스처 주입, 시드 전환)
- 레이어: 테스트 하네스(검증 대상이 아니라 다른 테스트를 가능하게 하는 쪽)
- 러너: XCTest(`LifecycleSeedTests` 계열)와 XCUITest
- 단위 테스트: `makeRouteCatalogStore()`가 인자에 따라 fixture 또는 bundled를 고르는지, `legacyV4Stations` 시드를 디코드하면 이전이 일어나는지 봅니다.
- 격리 전략: `#if DEBUG`
- AC 매핑: AC-36~38(UI)

#### 12. scripts/build_route_data.py(변환 스크립트)
- 레이어: 동작(순수 변환과 CLI)
- 러너: Python unittest. 저장소에 아직 없으므로 새로 만듭니다. 실행 명령은 `python3 -m unittest discover -s scripts/tests -t scripts -v`입니다.
- import 경로 주의: 설계의 `-s scripts/tests`만으로는 `import build_route_data`가 실패합니다. top-level 디렉터리가 `scripts/tests`로 잡혀서 `scripts/`가 `sys.path`에 들어가지 않기 때문입니다. 해결책은 둘 중 하나입니다.
  - `-t scripts`를 붙이고 `scripts/tests/__init__.py`를 둔다.
  - 테스트 파일 맨 위에서 `sys.path.insert(0, str(Path(__file__).resolve().parents[1]))`를 한다.

  어느 쪽인지 설계에 명시해야 합니다. 파일 이름에 밑줄을 쓴 것은 import에 맞습니다(기존 스크립트들은 하이픈입니다).
- 단위 테스트: 변환 함수를 직접 부릅니다. AC-44(노선 3개, 중복 제거, 순번 순서), AC-45(225초와 200초, ±1초), AC-46(30초), AC-47(제외 노선 2개가 요약에 나옴), AC-48(폐지 노선 제외), AC-50(id 안정성), AC-52(파일 이름에서 기준일)입니다.
- 통합 테스트: `subprocess`로 실행합니다. AC-49는 두 번 실행해 바이트를 비교하고, AC-51은 종료 코드 2, 메시지의 누락 열 이름, 기존 산출 파일이 그대로인지 봅니다. 출력은 `tempfile.TemporaryDirectory()`에 씁니다.
- 모의 대상: 원천 xlsx는 `xlsx_fixture.py` 생성기로 대체합니다. 네트워크 의존은 없습니다.
- 격리 전략: 표준 라이브러리만 쓰고, 입력 경로와 출력 경로를 인자로 받습니다.
- 차단 요인: 질문 1(노선 기본 정보 원천과 열 이름)이 정해지지 않아 AC-48 픽스처의 형식을 정할 수 없습니다. 결정 전에는 AC-48의 RED가 가정 위에 서게 됩니다.
- AC 매핑: AC-44~52(단위와 subprocess), AC-53(수동 실행)

### 실데이터·오프라인 AC 검증 방식의 현실성

**AC-41(검색 0.3초): 대리 측정이면 현실적입니다. 테스트 방식을 고쳐야 합니다.**
- XCTest의 `measure{}`는 기준값이 없으면 실패하지 않습니다. 그래서 RED/GREEN 판정 수단이 되지 못합니다.
- `ContinuousClock`로 `StationSearch.search` 20회 평균을 재고 `XCTAssertLessThan(avg, .milliseconds(300))`로 판정하라고 권고합니다.
- 측정은 Debug(-Onone) 시뮬레이터에서 이루어지므로 보수적인 상한입니다. 실패하면 Release 빌드로 다시 재 보고 나서 재설계 여부를 판단하는 절차를 명시하세요.
- 실데이터에서 "서울" 같은 2글자 검색은 수천 건과 일치합니다. 방면 해석과 `StationOption` 생성을 50건으로 자른 뒤에만 하는지 테스트에서 함께 확인해야 합니다.
- "결과가 보인다"는 화면 수준의 표현이지만, 함수 시간으로 대신 재는 것으로 충분합니다. 이 대체를 보고서에 명시하세요.

**AC-42(후보 갱신 0.2초 × 346회): 현실적입니다.**
- 출발 정류장을 "지나는 노선이 많은 정류장"이라고 하면 모호합니다. 테스트 안에서 `visitsByStop[i].count`가 가장 큰 i로 정하면 결정적입니다.
- 화면 한 번에 `candidates`가 3~4회 불린다는 설계 메모를 반영해 1회 측정값 × 4로 판정하라고 권고합니다.

**AC-43(크기 10MB, 시작 지연 1초): 크기는 현실적이고, 시작 시간은 그대로는 비현실적입니다.**
- 크기는 `Bundle.main.url` → `FileManager` 파일 크기로 결정적으로 잴 수 있습니다.
- 시작 시간을 `XCTApplicationLaunchMetric`으로 fixture 실행과 bundled 실행을 비교하면 시뮬레이터 잡음이 커서 1초 판정이 깜빡입니다.
- 두 가지로 나눠 검증하라고 권고합니다.
  - (a) `RouteCatalogLoader.bundled()` 디코드 시간 < 1초를 단위 테스트로 잰다. 지연 시간의 상한이 된다.
  - (b) 첫 화면이 카탈로그를 기다리지 않는다는 구조를 단위 테스트로 본다. idle 상태 스토어로 `AppModel.start()`와 메인 상태가 완성되는지 확인한다.

**AC-40(오프라인, 데이터 네트워크 요청 0건): 그대로는 검증 수단이 없습니다. 구조로 증명하는 쪽으로 정의하라고 권고합니다.**
- 시뮬레이터는 호스트 네트워크를 공유하므로 XCUITest에서 네트워크를 끌 수 없습니다.
- 앱 소스에 `URLSession` 사용은 0건입니다(grep으로 확인했습니다). 로더는 `Data`와 `Bundle`만 입력으로 받습니다.
- 다음 셋을 함께 쓰라고 권고합니다.
  1. 카운팅 `URLProtocol`을 등록한 상태에서 번들 카탈로그로 검색과 후보 계산을 하고 요청 0건을 assert한다. 등록 범위가 `URLSession` 기본 구성에 한정된다는 한계를 명시한다.
  2. `bundled()`가 읽는 URL이 `isFileURL`인지 assert한다.
  3. "AC-1~24와 같은 값"은 픽스처 기준으로 이미 순수 함수 테스트가 보장한다고 보고서에 적는다.
- 설계 구현 순서 18에 "AC-40"이 있지만 방법이 비어 있으니 위 내용을 채워야 합니다.

**AC-53(실데이터 변환): 자동화할 수 없는 수동 증거 항목이고, 그렇게 분류하면 현실적입니다.**
- 질문 5의 권장안(a)이 원천 파일을 커밋하지 않는 것이므로 CI나 unittest로 재현할 수 없습니다.
- 증거는 다음 세 가지로 정의하라고 권고합니다.
  - 실행 명령, 요약 출력 원문, 산출 JSON의 SHA-256을 보고서에 남긴다.
  - 커밋된 산출 JSON에 대해 `RouteDataBundleTests`가 크기와 디코드 성공을 회귀 테스트로 지킨다.
  - 스크립트 자체의 10MB 초과 실패 처리를 소형 픽스처 테스트로 1건 확인한다. 한도 인자를 주입할 수 있게 하면 쉽다.
- 이 항목은 질문 1(노선 기본 정보 원천)이 확정되어야 시작할 수 있습니다.

### Testability Score: 8/10

근거:
- 검증 대상인 순수 규칙(검색, 방면, 도착지와 비례 조정, 후보, 코스 진도, 도달, codec)이 전역 static을 없애고 주입되는 값 타입 `RouteCatalog` 하나만 입력으로 받습니다. 모의 없이 PRD 픽스처로 바로 단위 테스트할 수 있습니다.
- `AppModel`은 기존 생성자 주입과 클로저 주입 패턴을 확장하고, UI는 `--fm-ui-route-data`로 픽스처를 주입합니다.
- Python 스크립트는 표준 라이브러리만 쓰고, 경로를 인자로 받고, xlsx 생성기를 둬서 격리가 잘 됩니다.

감점 요인:
- `RouteCatalogStore.startLoading()`의 완료를 테스트가 기다릴 수 없습니다.
- 성능, 시작, 오프라인 AC의 판정 방식이 불명확합니다.
- Python 러너의 import 경로가 정해지지 않았습니다.
- 픽스처에 빈 곳이 있습니다(번호 없는 정류장, UI용 60개 정류장).
- 미결 질문 1·2·3에 따라 일부 RED를 쓸 수 없습니다.

어느 것도 구조를 다시 짜야 하는 결함은 아니고, 보완 항목입니다.

### 판정

✅ TESTABILITY PASS (8/10). red-green-refactor에 들어가도 됩니다. 다만 아래 보완 사항을 설계 확정본에 반영하라고 권고합니다. 재설계는 아닙니다.

1. `RouteCatalogStore.startLoading()`이 기다릴 수 있는 `Task` 핸들을 돌려주거나 `load() async`를 둔다.
2. Python 러너를 `python3 -m unittest discover -s scripts/tests -t scripts -v`와 `scripts/tests/__init__.py`로 정한다(또는 `sys.path` 삽입). 산출물 10MB 한도를 인자로 주입할 수 있게 한다.
3. 픽스처를 보완한다. 번호 없는 정류장(AC-11)을 넣고, UI용 60개 정류장(AC-7)을 `uiTest`에 넣을지 단위 테스트로만 볼지 정한다.
4. AC-41·42는 `ContinuousClock`으로 재서 assert로 판정한다(`measure{}` 금지). AC-42의 출발 정류장은 노선 수가 가장 많은 정류장으로 정한다.
5. AC-43 시작 시간은 디코드 시간 상한과 "첫 화면이 카탈로그를 기다리지 않음" 구조 테스트로 나눠 검증한다.
6. AC-40은 카운팅 `URLProtocol`, `isFileURL` 확인, 순수 함수 근거로 검증한다고 정의한다.
7. AC-53은 수동 증거 항목(명령, 요약 원문, SHA-256)으로 분류한다. 회귀는 `RouteDataBundleTests`가 맡는다.
8. 테스트에서 저장 버전을 숫자로 박지 않고 `SnapshotCodec.currentVersion`을 참조한다(W09 대비).
9. 미결 질문 1(AC-48 픽스처 형식), 2(AC-35 후속 화면 전이), 3(마지막 구간 0초 이하 극단 경우)은 해당 RED를 쓰기 전에 확정해야 합니다.

### 탐색 추가 항목
- `/Users/bonseung/projects/focus-mate/next-step-w16/scripts/check-ios.py`: Swift 테스트 파일만 받습니다(`FocusMateTests`·`FocusMateUITests`). Python 테스트는 별도 명령이 필요하고, 마지막 전체 테스트 절차에 함께 넣어야 합니다.
- `/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMateTests/AudioResourceTests.swift:19`: 호스팅 테스트에서 `Bundle.main` 리소스를 확인하는 선례입니다. `RouteDataBundleTests`가 이를 따릅니다.
- `/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMate/UITestBootstrap.swift`: `--fm-ui-route-data`와 `legacyV4Stations` 시드를 추가할 위치입니다. 시드 이름 집합은 :148에 있습니다.
- `/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMate/LocalSnapshotStore.swift`: `readData`/`writeData` 클로저 주입 구조입니다. AC-36~38 모델 테스트에서 메모리 버퍼로 대체합니다.
- `/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMate/JourneyCourseProgress.swift:80`: 정수 반올림 관례입니다. AC-26 남은 거리 공식을 검산해 보니 1400m에서 14가 나와 맞습니다.

---

# W16b 설계 보완 (2026-10-15, W09 #23 대조 — 본문·정합 절보다 우선)

## W16b 앱 연결 — W09 머지(main 6542996) 반영 보완

> 이 문서는 `.dev/feat-seoul-real-route-data/design.md`의 **차이분**만 담습니다. 여기 적지 않은 절(A·B·D·E·G 본문, J절)은 확정본 그대로 유효합니다. 확정본과 이 문서가 다르면 이 문서를 따릅니다.

### 설계 규모
대형입니다. 저장 형식 v4→v5 이전, 전역 카탈로그 제거, W09 하차 경로 재연결이 한 컴파일 단위에 묶여 있습니다. 앱 소스 약 35개, 단위 테스트 약 40개, UI 테스트 20개 파일에 영향이 있습니다.

### 배경 및 목적
- W09a(#23)가 하차 태그, 요약, 기록, 메모를 넣었습니다. 저장 형식은 v4 그대로입니다(`context/journey/status.md:47`, `.dev/plan.md:83`).
- W16a(#22)가 계산 모듈 5개를 추가만 했습니다. W16b는 이 모듈을 앱에 연결하고, 예시 데이터 전역 상수(`RouteData.swift`)를 없앱니다.

### 요구사항 및 수용 기준
- 범위: PRD `.dev/feat-seoul-real-route-data/prd.md`의 AC-24, AC-27~55, AC-78, AC-79와 "설계 정합 개정" 절(BR-4 보강 포함)
- 사용자 결정: ±1분 규칙 유지
- 함께 처리: `reports/review-deferred.md`의 security MEDIUM 항목(아래 "보안 유예 항목 처리" 참조)

---

### 1. W09 체크리스트 1~11 판정 (실제 코드 기준)

| # | 항목 | 판정 | 근거(파일:라인) | W16b 조치 |
|---|---|---|---|---|
| 1 | `currentVersion` | **W09가 올리지 않음. 그대로 4** | `ios/FocusMate/SnapshotCodec.swift:49`, v3 분기 `:65-69` | W16 = **v5**로 확정. legacy DTO에 W09 필드 없음 |
| 2 | 새 필드 | **저장 필드 추가 없음** | `JourneySnapshot.swift:24-38`, `AppSnapshot.swift:18-24`, `RecordSection.swift:3-16`(memo는 W08부터 있음). 메모리 값만 늘었음: `AppModel.swift:87`(`alightingSummary`), `:98`(`recordClock`), `Destination`에 `.alighting/.alightingSummary`(`:6`) | v5 필드 목록 변경 없음. `AppModel.init` 마지막 인자는 `recordClock` 다음에 `routeData:`로 붙임 |
| 3 | 하차 저장의 도달 정류장 | **`reachedStation` 사용 중** | `JourneyAlighting.swift:44`(`active.reachedStation`) → `endingActiveJourney(at:)` `:49`. 카탈로그 조회 실패 시 `.unknownCatalog` `:4, :46` | `arrivedStation`(저장값)으로 교체. `.unknownCatalog` 삭제 |
| 4 | 기록 from/to/bus 출처 | **카탈로그 조회** | `JourneyAlighting.swift:28-35`(`journey.bus`, `originName`, `destinationName`, 실패 시 nil) | 저장 필드 `originName`/`destinationName`/`busNumber`. 생성자는 실패하지 않게(non-failable) 바꿈 |
| 5 | 도착 안내의 `CourseJourney` | **도착 안내는 `CourseJourney`를 쓰지 않음** | 지도만 `JourneyView.swift:50` `CourseJourney(journey:)`. 도착 안내는 `ArrivalBriefingContent(journey:)` `ArrivalBriefingController.swift:22-27`이고 `journey.bus`·`destinationName`을 씀. `.dev/plan.md:86`의 "도착 안내도 같은 규칙"은 코드와 맞지 않음 | 지도: `init?(journey:catalog:)`. 도착 안내: 저장 이름을 쓰는 non-failable로 바꿔 BR-12와 무관하게 늘 표시 |
| 6 | 진행 카드 | **`Kind.arrived` 유지. 하차 진입은 `showsAlight`** | `ActiveJourneyCardContent.swift:5, 16, 24`. `journey.bus`·`destinationName` 의존이 남아 있음 `:23, :27` | 저장 필드로 non-failable. `AppModel+JourneyLifecycle.swift:6`의 `flatMap`을 `map`으로 |
| 7 | `StationSnapshot(direction:)` 생성처 | 하차 자체는 직접 만들지 않음(`reachedStation` 경유) | `JourneyReach.swift:14, 23`, `UITestBootstrap.swift:215, 409-412, 421`, `RouteData.swift:48` | 모두 `{id, name}`으로 |
| 8 | W09 UI 시드와 UI 테스트 | **카탈로그 의존 있음** | 시드 `UITestBootstrap.swift:315-318`(`alight*`), 생성 `:360-377`(`BusLine`, `JourneyReach.station`). `recordSeeds` `:325-358`은 문자열만 쓰므로 영향 없음. UI: `AlightingFlowUITests.swift:11, 149, 275("seongsu"), 330` | I절 delta 참조 |
| 9 | 문서 | **낡은 문구 있음** | `context/journey/glossary.md:18`(정류장 간격 분 몫), `:21`("도착 여정은 도착지" — W09 이후 도착 여정은 새 여정이 거절됨), `.dev/plan.md:86` | T7에서 갱신 |
| 10 | `RouteStops.wrap` | 현재 **12곳** | `JourneySnapshot.swift:42, 44`, `JourneyCourseProgress.swift:12, 51, 55, 56, 67`, `JourneyCourse.swift:40`, `JourneyReach.swift:13`, `UITestBootstrap.swift:275, 287`, `RouteData.swift:24` | T3 완료 조건: `RouteStops\|BusLine\|StationCatalog\|StopPosition` grep 0건 |
| 11 | 하차 화면 로딩 차단 | **차단 불필요** | `beginAlighting`/`confirmArrival`/`alightJourney`(`AppModel+Alighting.swift:15-43`)는 3번 변경 후 카탈로그를 쓰지 않음. 도착 여정은 새 여정 확정도 이미 거절함(`AppModel+JourneyLifecycle.swift:37-38` `!active.isArrived`). 메인 메뉴에서도 빠짐(`AppModel+Alighting.swift:67-69`) | `canEndActiveJourney`는 "도착하지 않은 여정"에만 적용 |

**판정에서 나온 PRD 영향**
- AC-36("도착한 여정에서 새 여정 시작 → S4")은 W09 규칙 때문에 그 경로로 실행할 수 없습니다. 하차 경로로 검증하자고 제안합니다(확인 사항 1).
- PRD 정합 개정 "도착한 여정의 새 여정 확정은 로딩 중에도 허용"은 해당 경로가 없으므로 효력이 없습니다.

---

### 2. C절 delta — 저장 v5

**버전**
- `SnapshotCodec.currentVersion = 5`.
- 테스트는 숫자를 직접 쓰지 않고 `SnapshotCodec.currentVersion`을 참조합니다(확정본 유지).

**v5 필드(확정. W09 추가분 없음)**
- `JourneySnapshot`: `id, cardID, originStopID, originName, minutes, busID, busNumber, busKind, destinationStopID, destinationName, tag, task, sound, boardedAt, phase, progress, paused`
- `StationSnapshot`: `{id, name}`
- `AppSnapshot` 키는 그대로입니다.

**검증 보강(신규)**
- 이름 4종(`originName`, `destinationName`, `busNumber`, `busKind`)은 공백만 있으면 안 되고 **UTF-16 500 이하**여야 합니다.
- 이유: 하차 때 기록의 `from/to/bus` 검증(`RecordSection.swift:146-149`, 500 상한)이 실패하면 하차 저장이 막힙니다. 저장 시점에 미리 보장합니다.

**삭제 대상**
- `JourneySnapshot.Format`, `.journeyFormat` (`JourneySnapshot.swift:8, 117-119, 149-151`)
- v3 분기 (`SnapshotCodec.swift:65-69`)
- 이유: v3 여정은 이제 이전 과정에서 모두 버려지므로 v3 `paused` 해석이 필요 없습니다.

**legacy DTO(단순화)**
- `LegacyStationSnapshot`은 만들지 않습니다. 새 `StationSnapshot{id,name}`이 옛 JSON의 `direction` 키를 무시하고 그대로 읽습니다(Decodable 기본 동작).
- 신규 `LegacySnapshotV3V4: Decodable`
  - 필드: `cardIssued`, `initialStation: StationSnapshot?`, `currentStation: StationSnapshot?`, `cards: CardSection`(v3·v4 같은 형식, 현 `:65-70`이 같은 Envelope로 읽는 근거), `journey: LegacyJourneyPresence`, `records: RecordSection`
  - `LegacyJourneyPresence`: `active`가 null이면 false, 객체면 내용을 해석하지 않고 true
- **주의**: 현재 v5 `JourneySection` 디코드는 `try?`로 손상 여정을 조용히 버립니다(`JourneySection.swift:17`). 그래서 legacy 파일을 v5 Envelope로 읽으면 이전 보고가 누락됩니다. legacy는 반드시 별도 DTO로 읽어야 합니다.

**이전 규칙(순서 고정)**
1. 버전 1·2는 기존 `migrateV1`/`migrateV2`(`SnapshotCodec.swift:94-107`), 3·4는 `LegacySnapshotV3V4`로 **이전 형태 그대로** `AppSnapshot`을 만듭니다(여정은 `.empty`).
2. **비우기 전에 `validate()`를 실행합니다.**
   - 기존 손상 판정(단계 불일치, 카드, 기록)을 지키기 위해서입니다.
   - 예: v1 `invalidState` 시드(`UITestBootstrap.swift:421`)는 cardIssued=false인데 정류장이 있습니다. 정류장을 먼저 비우면 유효한 상태로 바뀌어 `StorageRecoveryFlowTests.swift:19`가 깨집니다.
3. `migrateLegacyRouteData`가 `updatingStage(cardIssued:, initialStation: nil, currentStation: nil).updating(journey: .empty)`로 비웁니다. 카드와 기록은 그대로 둡니다.
4. 보고: `initialStation/currentStation != nil || journeyPresent`일 때만 `.routeDataReset`을 돌려줍니다.
5. `sortedNewestFirst()`는 기존대로 적용합니다.

**하차 대기 여정과 완료 기록**
- 도착했지만 하차하지 않은 v4 여정도 **비웁니다**. 완료 기록은 **만들지 않습니다**(PRD 영향 범위 :160, 하차 접촉 성공만 기록 — `context/journey/README.md:34`).
- W09가 이미 만든 기록의 `from/to/bus` 문자열은 손대지 않습니다. 기록은 id를 담지 않습니다.

**`LocalSnapshotStore`**
- `loadReport()`를 추가하고 `load()`는 래퍼로 둡니다.
- `save()`는 쓰기 전에 `load()`를 다시 부릅니다(`LocalSnapshotStore.swift:108`). legacy 파일도 이전 디코드가 성공하므로 쓰기가 막히지 않습니다.

**`AppModel.start()` 순서**
- `loadIfNeeded()` → `persistMigrationIfNeeded()` → `supplementCardIfNeeded()`
- 보충이 필요한 사용자는 마이그레이션 저장 뒤 한 번 더 저장합니다(둘 다 v5).

**시그니처**
- `static func decodeReport(_ data: Data) throws -> (snapshot: AppSnapshot, migration: SnapshotMigration?)`
- `enum SnapshotMigration { case routeDataReset }`
- `func loadReport() throws -> (snapshot: AppSnapshot, migration: SnapshotMigration?)?`

### 3. F절 delta — 도달 정류장, 하차, 생명주기

**하차 흐름의 도착 정류장 연결(AC-78·79)**
- `JourneySnapshot.arrivedStation: StationSnapshot?`: `isArrived`이면 `{destinationStopID, destinationName}`, 아니면 nil입니다. 카탈로그를 쓰지 않습니다.
- `AppSnapshot.alightingActiveJourney` (`JourneyAlighting.swift:41-50`)
  - `guard let station = active.arrivedStation`으로 바꿉니다. `isArrived` 검사 뒤라 nil일 수 없습니다.
  - `RecordCompletionInput(alighting:completedAt:)`은 non-failable입니다: `bus: journey.busNumber`, `from: journey.originName`, `to: journey.destinationName`.
  - `bus`는 번호만 씁니다. 현재 `bus.number`와 같고 `AlightingSnapshotTests.swift:45`가 기대값 "2014"를 유지합니다.
  - `AlightingIssue`는 `{ noActiveJourney, notArrived }`로 줄입니다.
- 결과: 하차는 로딩 상태와 무관하게 동작합니다(체크리스트 11). 하차 후 `currentStation.id == destinationStopID`입니다(AC-79).

**`reachedStation(in:) -> ReachAttempt`**
- 확정본의 분기를 유지합니다.
- 실제 호출자는 도착하지 않은 여정뿐입니다. `confirmNewJourney`·`abandonJourney`가 모두 `!isArrived`로 막습니다(`AppModel+JourneyLifecycle.swift:38, 51`).
- 도착 분기(`.resolved(.station(arrivedStation))`)는 API 일관성과 AC-78 단위 검증용으로 둡니다.

**`AppModel+JourneyLifecycle.swift`**
- `confirmNewJourney` (`:36-45`)와 `abandonJourney` (`:49-57`)
  - 기존 guard는 유지하고, `let station = active.reachedStation`만 `switch active.reachedStation(in: routeAvailability)`로 바꿉니다.
  - `.notLoaded` → `.rejected`, 저장 0회(AC-43·44)
  - `.station(s)`/`.stayAtOrigin(s)` → `endingActiveJourney(at: s)`
    - 포기: 기존처럼 `abandonNotice = s.name`. AC-37의 "안내 문구 없음"은 BR-13 재선택 안내(`stationResetNotice`)가 없다는 뜻으로 해석합니다.
  - `.reselectStation` → `snapshot.clearingStationsAndJourney()`를 한 번 저장합니다. `persist`가 경로를 `.initialStationEntry`로 바꾸고 `path = []`로 만듭니다(`AppModel.swift:230-233`). `stationResetNotice = .stationRemoved`, 결과는 `.done`.
    - 새 여정 쪽은 `discardConfirmedPreparation()`만 하고 `open(.time)`은 하지 않습니다. 라우트가 메인이 아니라 어차피 동작하지 않습니다.
- `var canEndActiveJourney: Bool { routeAvailability != .loading }`
  - 확정본의 "도착이면 true" 조건은 뺍니다. 도착 여정은 이 두 버튼에 닿지 않습니다.

**BR-16(AC-40) 시점**
- `AppModel.startRouteData() -> Task<Void, Never>`를 신규로 둡니다.
  - 스토어의 `startLoading()`을 부르고, 완료 후 메인 액터에서 `resolveStationAfterRouteDataReady()`를 1회 실행합니다.
  - 진행 여정이 없고 현재 정류장 id가 카탈로그에 없으면 `restartStationSelection(reason: .stationRemoved)`를 실행합니다.
- `FocusMateApp.start()`(`FocusMateApp.swift:100` 다음)에서 부릅니다. 테스트는 반환된 Task를 `await`합니다.
- `AppModel.start()`는 로딩을 시작하지 않습니다. AC-55 구조 테스트의 근거입니다.

**`AppModel.swift`**
- `init(…, recordClock: RecordClock = .live, routeData: RouteCatalogStore = .bundled())`
- `var stationResetNotice: StationResetReason?`(메모리)
- `Destination`에 `.dataSource`(제목 "데이터 출처")를 **이 파일에서** 추가합니다. 화면 연결은 T4가 합니다(파일 겹침 회피).

### 4. G·H절 delta(작음)
- **표시 이름 출처**: `RouteOrigin.name`은 승차 시점의 카탈로그 이름입니다. 그 이름이 `JourneySelection.originName` → `JourneySnapshot.originName` → 기록 `from`으로 이어집니다. 메인 현재 정류장 표시는 저장된 `currentStation.name`입니다.
- **도착 안내** `ArrivalBriefingContent(journey:)`: non-failable. `routeText = "\(busNumber) · \(destinationName) 도착"`.
- **Live Activity** `JourneyLiveActivityPolicy.attributes(for:)` (`:29-33`): non-failable. `busNumber`·`busKind`·`destinationName`을 씁니다.
- **H. 출처 화면**: 보안 유예 항목을 반영합니다.
  - `source`에 `sourceURL`(OA-1095 페이지), `routeInfoSourceURL`(OA-15066 페이지) 키를 추가합니다. 스크립트는 T1, 로더 필수 키는 T2.
  - 화면 문구에 "구간 시간과 거리는 원천 데이터를 가공·계산한 값이에요"를 넣습니다.
  - URL은 텍스트로 표시하고 링크 동작은 없습니다(오프라인 FR-12).

### 5. I절 delta — UI 테스트 주입과 시드

**`RouteCatalog+Fixture.swift`(앱, `#if DEBUG`, 신규)**
- `static func acceptanceFixture() throws -> RouteCatalog`: PRD 표 그대로. 현재 테스트 전용 `RouteCatalogFixture.acceptance()`(`ios/FocusMateTests/RouteCatalogTestFixtures.swift:37-57`) 내용을 옮깁니다. 테스트 헬퍼는 이것을 위임 호출합니다(중복 제거).
- `static func uiTestFixture() throws -> RouteCatalog` = acceptance + 레거시 재현
  - 정방향 승강장: **기존 id 9개를 그대로** 씁니다(`seongsu` 등, `RouteData.swift:12-20`). 이름과 W06 좌표도 그대로입니다.
  - 역방향 승강장: id에 `-r`을 붙이고 이름은 같게 둡니다.
  - 노선(9정류장 순환, 구간 초 균등)

| id | 번호 | 유형 | 구간 | 방향 |
|---|---|---|---|---|
| `2014` | 2014 | 지선 | 300초 | 정방향 |
| `2014-r` | 2014 | 지선 | 300초 | 역방향 |
| `302` | 강남02 | 마을 | 450초 | 정방향 |
| `421` | 343 | 간선 | 424초 | 정방향 |

  - 검산(출발 `seongsu`, ±60초 규칙). UI 테스트가 쓰는 분 값에서 후보 집합이 기존과 같습니다.

| 분 | 후보 | 비고 |
|---|---|---|
| 17 | 0건 | |
| 25 | `2014`만 | 5정류장, 서울숲 입구 (`TimeSelectionUITests.swift:44-47`) |
| 60 | `2014`, `302` | `2014` 12정류장 → 성동구민체육센터. `302`는 8정류장, 차이 0 |
| 120 | 3건 | `2014` 24정류장, `302` 16정류장, `421` 17×424=7208초, 차이 8 |

  - 방면: `seongsu`는 "성수동 방면", `seongsu-r`은 "성수사거리 방면"으로 기존 표시와 같습니다.
- AC-7(60개 정류장)은 단위 테스트에서만 봅니다(정합 절 유지).

**`UITestBootstrap.swift`**
- `--fm-ui-route-data fixture|bundled|pending|failed`(기본 fixture) → `makeRouteCatalogStore()`
- 시드의 `direction` 필드를 제거하고 `routeID`를 추가합니다. `lifecycleSnapshot`은 `RouteLegFinder.leg`로 도착지를 구하고 이름 4종을 복사합니다.

| 시드 | 변경 |
|---|---|
| `lifeReverse300` | 출발 `seongsu-r`, 노선 `2014-r` → 성수사거리 |
| `lifeWrap900` | 출발 `seongsuBridgeNorth` → 성수역(기존 값 유지) |
| `alightMismatchArrived` | `destinationStopID: "ttukseom"`, `destinationName: "뚝섬역"`을 저장 → 지도 생략, 하차 후 현재 정류장은 ttukseom(BR-12 UI, AC-79) |
| `timerJourney` | 출발 `seoulForest-r`, `2014-r`, 25분 → 성수사거리(기존 주석 `:286`과 같음) |
| `readySnapshot` | `initial {seongsu, 성수}`, `current {seoulForest-r, 서울숲}`(저장 이름은 그대로 둠) |
| `applySaveScenario` (`:215`) | `StationSnapshot(id: "ttukseom", name: "뚝섬")` |
| `applyRoute` (`:229`) | `choose(routeID: "2014", …)` |

- 신규 시드

| 시드 | 내용 | 대상 AC |
|---|---|---|
| `lifeRouteGone700` | 노선 `gone-route`, 출발 seongsu | AC-37 UI |
| `lifeOriginGone700` | 노선 gone, 출발 `gone-stop` | AC-38·39 UI |
| `stationGone` | 여정 없음, 현재 정류장 `gone-stop` | AC-40 UI |
| `legacyV4Stations` | v5 인코딩 뒤 station·journey에 `direction`을 넣고 `version=4`. 진행 여정, 카드 1장, 기록 3건 포함 | AC-46~48 UI |
| `invalidMinutesJourney` | 현재 버전, 분 361 → 여정만 버림 | 기존 `v3InvalidMinutes`의 "카드 없는 메인" 의도를 대체 |

- `v3Seeds`(`:281`)는 이제 **이전 시드**입니다. 정류장과 여정이 비워지고 최초 정류장 화면으로 갑니다.
- `rawSeeds`
  - `profileRecords`(v2, `:430-431`)는 이전 때문에 메인이 아니라 최초 정류장 화면으로 가게 됩니다. **v5 빌더 시드로 다시 씁니다.**
  - 나머지 손상 시드는 "비우기 전 validate" 규칙 덕분에 그대로 실패합니다.

### 6. 보안 유예 항목 처리(`reports/review-deferred.md:17-26`)

| 항목 | 처리 | 태스크 |
|---|---|---|
| 로더/카탈로그 값 범위·중복 id | `RouteCatalogIssue.duplicateID(String)`, `.outOfRange(String)` 추가. 기준: 좌표 위도 33e6~39e6·경도 124e6~130e6(BR-11과 같은 범위), 구간 초 1~21,600(최대 여정 360분), 구간 m 0~200,000, 노선당 정류장 2~1,000, id·이름은 공백 아님·UTF-16 200 이하. 상한은 기술적 방어선이고 실데이터 통과는 T6 회귀 테스트가 확인합니다. Bool이 Int로 받아들여지는 문제는 `NSNumber`의 `objCType`으로 거부 | T2 |
| leg minutes 상한 | `RouteLegFinder.leg`에 `guard (1...JourneySnapshot.maximumMinutes).contains(minutes)` | T2 |
| 출처 "가공·계산" 문구·원천 URL | 4절 H | T1(키), T2(로더), T4(화면) |
| 스크립트: zip·XML·행 수 상한, DOCTYPE/ENTITY 거부, 지수 표기 정수 상한, 손상 xlsx → 종료 코드 2, SHA를 쓰기 전 바이트로 계산·임시 파일 정리·fsync | **포함 권고.** 출처 URL 키 때문에 T1에서 어차피 스크립트를 고치고 산출물을 다시 만들어야 합니다. 파일이 `scripts/**`뿐이라 앱 태스크와 겹치지 않습니다 | T1 |
| "--out이 Resources/ 아래면 경고" | **철회.** W16b의 표준 출력 위치가 Resources입니다 | — |
| 라이선스 하드코딩 | README의 매월 재확인 절차로 유지(자동 검증 없음) | T7 |
| "(가상)" 판정 문구 차이 | 문서만 정리 | T7 |

### 7. 번들 포함 방식 재확인(요구 4)
- 위치: `ios/FocusMate/Resources/RouteData/seoul-route-data.json`. 동기화 루트(`project.pbxproj:35`, exceptions 비어 있음)라 앱 타깃 리소스로 자동 포함됩니다. pbxproj는 수정하지 않습니다.
- 위젯 타깃은 `FocusMateWidgets`/`Shared` 그룹만 쓰므로(`:39, :49`) 포함되지 않습니다.
- 평탄화 충돌이 없습니다. 현재 번들 루트 이름은 `travel-*.wav` 4개, `SOURCE.md`, `SeoulAlrim-*.ttf` 2개뿐이고, `ios/FocusMate` 아래 다른 `.json`도 없습니다. 같은 폴더에 `README.md`를 두지 않습니다.
- `.gitignore:22-23`(`scripts/data/out/`, `*.xlsx`)은 Resources의 JSON에 영향이 없으므로 JSON은 커밋됩니다.
- `RouteCatalogLoader.bundledURL()` = `bundle.url(forResource: "seoul-route-data", withExtension: "json")`. 호스팅 테스트의 `Bundle.main` 선례는 `AudioResourceTests.swift:19`입니다.
- 로더는 `JSONSerialization`을 유지합니다(W16a 구현 그대로). 확정본 A절의 Decodable 기술은 폐기합니다. AC-54가 1초를 넘을 때만 다시 봅니다.

---

### 변경 범위(W16b 전체)

**신규**
- `RouteCatalogStore.swift`, `RouteCatalog+Fixture.swift`(DEBUG), `DataSourceView.swift`
- `Resources/RouteData/seoul-route-data.json`
- 테스트: `RouteCatalogStoreTests`, `RouteDataMigrationTests`, `RouteDataLifecycleModelTests`, `RouteDataBundleTests`, `RouteDataOfflineTests`, `DataSourceContentTests`
- UI: `RouteDataUITests`(로딩·실패·BR-13·이전), `DataSourceUITests`

**삭제**
- 앱: `RouteData.swift`, `JourneyPlanner.swift`(`RouteCandidates`가 대체)
- 테스트: `StationCatalogTests.swift`, `JourneyPlannerTests.swift`(`StationSearchTests`·`RouteCandidatesTests`가 이미 있음)

**수정(앱)**

| 영역 | 파일 |
|---|---|
| 저장 | `AppSnapshot`, `JourneySnapshot`, `JourneySection`(주석만), `SnapshotCodec`, `LocalSnapshotStore` |
| 규칙 | `JourneyReach`, `JourneyAlighting`, `JourneyCourse`, `JourneyCourseProgress`, `JourneyPlanDraft`, `PreparationDraft` |
| 표시 | `ActiveJourneyCardContent`, `ArrivalBriefingController`(Content), `JourneyLiveActivityPolicy`, `BoardingPassContent`, `StationSearchState` |
| 모델 | `AppModel`, `AppModel+JourneyStart`, `AppModel+JourneyLifecycle` |
| 화면 | `InitialStationSearchView`, `TimeSelectionView`, `RootView`, `JourneyView`, `JourneyMapController`, `JourneyMapView`, `JourneyTimerView`, `JourneyAbandonBar`, `DestinationScreen`, `ProfileView`, `AppModel+Profile` |
| 시작·테스트 지원 | `FocusMateApp`, `UITestBootstrap` |
| W16a 모듈 | `RouteCatalog`, `RouteCatalogLoader`, `RouteLeg` |

**테스트 영향(단위, T3 컴파일 대상)**
- 아래 파일이 `RouteStops`/`BusLine`/`direction:`/`seongsu`/`CourseJourney(journey:)`를 참조합니다(grep 42개 파일, 329곳).
  - 공용 픽스처: `BoardingTestDoubles.swift:10-50`(`details`·`journey()`·`snapshot()`) — 고치면 파급이 큼
  - 그 밖: `JourneyReachTests`(33), `JourneyMapControllerTests`(27), `LifecycleSeedTests`(15, 특히 `:161-167`), `SnapshotCodecTests`, `StorageV2Tests`, `RecordStorageTests`, `AppSnapshotSectionsTests`, `JourneySnapshotTests`, `JourneySnapshotStorageTests`, `JourneySnapshotV4StorageTests`, `JourneyCourseTests`, `JourneyCourseProgressTests`, `JourneyStartModelTests`, `CardCustomizationAppModelTests`, `ProfileModelTests`, `CardSupplementTests`, `AppRecoveryTests`, `RecoveryBootstrapTests`, `AlightingSnapshotTests`(`:57` direction), `AlightingModelTests`(`:10-11`), `StationSearchStateTests`, `JourneyPlanDraftTests`, `PreparationDetailsTests`, `BoardingPassContentTests`, `JourneyLiveActivityPolicyTests`, `JourneyMapStateTests` 외
- 의미가 바뀌는 테스트: v1~v4 입력 뒤 "정류장 유지"를 단언하던 저장 테스트는 "비움 + `.routeDataReset`"으로 뒤집힙니다.

**테스트 영향(UI, T5)**
- 20개 파일, 131곳: `search.result.seongsu:1` → `search.result.seongsu`, `main.direction`과 `persistedCurrentStation().direction` 삭제, v3 시드 의미 변경
- 해당 위치: `JourneyTimerLifecycleUITests.swift:132-160`, `MainActiveJourneyCardUITests.swift:110-131`, `NewJourneyUITests.swift:284-298`

### 적용 컨벤션
확정본 그대로입니다. 추가 사항은 하나입니다: 하차 확장 패턴(`AppModel+Alighting.swift`)처럼 결과는 `LifecycleActionResult`(`.done/.saveFailed/.rejected`)로 돌려주고, 저장은 `saveHandlingFailure` 한 번으로 합니다.

---

### 8. W16b 구현 순서 — 태스크 7개(AC 묶음, 파일 겹침 없음)

전역 제거와 저장 v5는 한 컴파일 단위(앱 타깃 + 단위 테스트 타깃)입니다. 쪼개면 중간 빌드가 깨지므로 **T3 하나로 묶습니다.** 대신 추가형 작업(T2), 출처 화면(T4), UI 테스트 단언(T5), 실데이터 측정(T6)은 밖으로 뺍니다. UI 테스트 시드(`UITestBootstrap`)는 앱 타깃이라 T3가 맡습니다. UI 테스트 파일은 별도 타깃이고 `@testable`이 없어 T3 동안에도 컴파일되므로 T5로 분리합니다.

| 태스크 | 내용 | 파일 | AC | 의존 |
|---|---|---|---|---|
| **T1** [Must] | 스크립트 보안 보강, 출처 URL 키, 산출물 재생성과 번들 배치 | `scripts/build_route_data.py`, `scripts/route_data/{xlsx,routes}.py`, `scripts/tests/*`, `scripts/data/README.md`, `ios/FocusMate/Resources/RouteData/seoul-route-data.json` | AC-77(재생성 증거: 명령, 요약, SHA 3개), 보안 5건 | 없음 |
| **T2** [Must] | 카탈로그 기반(추가형) | `RouteCatalogStore.swift`(신규), `RouteCatalog+Fixture.swift`(신규), `RouteCatalog.swift`, `RouteCatalogLoader.swift`(`bundledURL/bundled`, URL 키, 범위·중복), `RouteLeg.swift`(분 상한), `FocusMateTests/RouteCatalogTestFixtures.swift`, `RouteCatalogStoreTests`(신규), 기존 `RouteCatalogTests`·`RouteLegTests` 보강 | AC-55(스토어 전이), AC-50(`bundledURL` 단위) | 없음(키 이름은 이 문서로 T1과 공유) |
| **T3** [Must] | 전환 코어: 저장 v5·이전·안내, 카탈로그 주입, 전역 제거, 도달·하차·생명주기, 화면 연결, UI 시드 | 위 "수정(앱)"에서 T2·T4 파일을 뺀 전부, 삭제 2개, 단위 테스트 전부(신규 `RouteDataMigrationTests`·`RouteDataLifecycleModelTests`) | AC-24, AC-27~48(모델·단위), AC-55(구조), AC-78, AC-79, AC-5~8·12·17·18의 화면 상태 | T2 |
| **T4** [Must] | 데이터 출처 화면 | `DataSourceView.swift`(신규), `DestinationScreen.swift`, `ProfileView.swift`, `AppModel+Profile.swift`, `DataSourceContentTests`(신규), `FocusMateUITests/DataSourceUITests.swift`(신규) | AC-49 | T3(`Destination.dataSource`, `routeAvailability`) |
| **T5** [Must] | UI 테스트 전환과 신규 UI 검증 | `ios/FocusMateUITests/**`(T4 신규 파일 제외), 신규 `RouteDataUITests.swift` | AC-5~8·12·17·18·31·37~48·79의 UI | T3 |
| **T6** [Should] | 실데이터 회귀·성능·오프라인 | `RouteDataBundleTests.swift`, `RouteDataOfflineTests.swift`(신규) | AC-50·51·52·53·54·56, 후보 0건 비율 보고 | T1, T3(오프라인 코스 계산에 `CourseJourney(journey:catalog:)` 필요) |
| **T7** [Must] | 문서 | `context/journey/{glossary,architecture,status}.md`, `.dev/plan.md`(:86 정정), `scripts/data/README.md`의 "(가상)" 문구 | — | T3~T6 |

- 병렬 가능: T1 ∥ T2, 그 다음 T3, 그 다음 T4 ∥ T5 ∥ T6, 마지막 T7

**T3 내부 커밋 순서(권고)**
1. 저장 v5·이전 + 단위 테스트
2. `JourneyReach`·`JourneyAlighting`·표시 Content 4종
3. 코스·진도·지도
4. `AppModel` 주입, 안내, BR-13·16, 차단
5. 화면 3종(`InitialStationSearchView`, `TimeSelectionView`, `RootView`)과 `JourneyAbandonBar`
6. `UITestBootstrap` 시드
7. `RouteData.swift`·`JourneyPlanner.swift` 삭제, grep 0건 확인

- 1~6 동안은 `RouteData.swift`를 남겨 두고, 7에서 지웁니다.
- focused 테스트는 매 커밋에서 실행하고, 전체 테스트는 W16b 마지막에 한 번만 합니다(사용자 메모).

### 9. AC 매핑 delta(확정본 "구현 단계 ↔ AC 매핑"의 12~27행 대체)

| AC | 태스크 | 검증 수단 |
|---|---|---|
| AC-24 | T3 | `JourneyPlanDraftTests` |
| AC-27~30, 32 | T3 | `JourneyCourseProgressTests`(`CourseJourney(journey:catalog:)`) |
| AC-31 | T3 + T5 | 단위: 저장 도착 S5 → nil. UI: `alightMismatchArrived` 지도 없음 |
| AC-33~35 | T3 | `JourneyReachTests`(`ReachAttempt`) |
| AC-36 | T3 | 하차 경로(`alightJourney` → S4)로 검증(확인 사항 1) |
| AC-37~39 | T3 + T5 | 모델: `RouteDataLifecycleModelTests`. UI: `lifeRouteGone700`, `lifeOriginGone700` |
| AC-40 | T3 + T5 | `startRouteData()` Task await. UI: `stationGone` |
| AC-41·42 | T3 + T5 | `currentStationBound`. UI: `main.bound`, `pending` |
| AC-43~45 | T3 + T5 | 쓰기 카운터 0, `pending` → 준비 후 재시도 |
| AC-46~48 | T3 + T5 | `RouteDataMigrationTests`, `AppModel` 즉시 저장. UI: `legacyV4Stations` |
| AC-49 | T4 | `DataSourceContentTests` + UI |
| AC-50·51·52·53·54·56 | T6 (AC-50 일부 T2) | ContinuousClock, `isFileURL`, 카운팅 URLProtocol |
| AC-55 | T2 + T3 | 스토어 전이와 끝나지 않는 로더로 `start()` → `.ready(.main)` |
| AC-78 | T3 | `arrivedStation`(카탈로그 없음) |
| AC-79 | T3 + T5 | `AlightingSnapshotTests`, `AlightingFlowUITests` |

### 의존성 및 영향도
- 새 외부 의존성은 없습니다.
- 저장 v5로 올리면 이전 앱은 `unsupportedVersion`을 냅니다. 외부 배포 전이라 개발 기기에만 영향이 있습니다.
- **W09b(분석, 대기 — `.dev/plan.md:15`)**: 기록 문자열만 읽으므로 W16b와 충돌할 가능성은 낮습니다. 다만 W09b가 먼저 머지되면서 저장 버전을 올리면 W16b의 v5는 그 +1이 되고, legacy DTO에 W09b 필드를 반영해야 합니다.
- 하차 대기 중이던 개발 기기 여정은 이전 때 기록 없이 사라집니다(PRD 영향 범위에 명시됨).

### 탐색 추가 항목
- `ios/FocusMate/JourneyAlighting.swift:4, 28-36, 41-50` → 하차 저장, 기록 입력 생성, `.unknownCatalog`
- `ios/FocusMate/AppModel+Alighting.swift:15-69` → 하차 진입, 확인, 커밋, 메뉴 필터. 카탈로그 차단 불필요의 근거
- `ios/FocusMate/ArrivalBriefingController.swift:18-27` → 도착 안내 문구. 지도 규칙과 무관
- `ios/FocusMate/JourneyView.swift:46-53` → 도착 안내와 지도 생성 지점
- `ios/FocusMate/AppModel+JourneyLifecycle.swift:36-57` → W09가 넣은 `!active.isArrived` guard
- `ios/FocusMate/JourneySection.swift:17` → 손상 여정 `try?` 무시. legacy를 별도 DTO로 읽어야 하는 이유
- `ios/FocusMate/LocalSnapshotStore.swift:88-115` → `save` 전에 다시 읽기. 이전 디코드와의 상호작용
- `ios/FocusMate/SnapshotCodec.swift:49, 65-70, 82-86` → 버전, v3 분기, 여정만 버리는 완화
- `ios/FocusMate/UITestBootstrap.swift:148-149, 273-322, 360-391, 408-431` → 시드 전체, v3 바이트, rawSeeds
- `ios/FocusMate/RouteCatalogLoader.swift:6-48`, `ios/FocusMate/RouteCatalog.swift:89-112` → 값 범위 검사와 중복 id 처리 위치(현재 `uniquingKeysWith`로 조용히 첫 값만 씀)
- `ios/FocusMate/RouteLeg.swift:19-36` → 분 상한 guard 위치
- `ios/FocusMateTests/BoardingTestDoubles.swift:10-50` → 공용 여정 픽스처. T3 파급의 중심
- `ios/FocusMateTests/LifecycleSeedTests.swift:117-168` → W09 시드 검증. `CourseJourney(journey:)` 호출 포함
- `ios/FocusMateUITests/TimeSelectionUITests.swift:40-63` → uiTest 픽스처 구간 초를 고른 근거(17·25·60·120분 후보 집합)
- `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:19`, `ios/FocusMateTests/RecoveryBootstrapTests.swift:20` → "비우기 전 validate" 규칙의 근거
- `ios/FocusMate.xcodeproj/project.pbxproj:35, 39, 49` → 앱 동기화 루트와 위젯 그룹 분리
- `scripts/build_route_data.py:29-35` → `source` 고정 키. URL 키 추가 위치
- `.gitignore:22-23` → xlsx 제외. Resources JSON은 추적됨

---


### 사용자 결정 (2026-10-15)
- ±1분 규칙 유지.
- AC-36은 하차 경로로 검증(W09의 도착 여정 새 여정 거절 규칙 유지).
- 스크립트 보안 보강 5건을 T1에서 함께 처리.
