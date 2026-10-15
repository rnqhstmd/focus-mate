# W16b T3 인터페이스 명세 (red-writer·구현 공통 계약)

이 명세가 design.md W16b 보완본의 코드 수준 계약이다. 테스트는 이 시그니처로만 쓴다.

## 삭제
- `RouteData.swift` 전체: `StopPosition`, `RouteStops`, `StationOption`, `StationCatalog`, `BusLine`.
- `JourneyPlanner`의 `candidates`·`distanceText`·`JourneyCandidate`. **남는 것**: `enum JourneyPlanner { static let minuteRange: ClosedRange<Int> = 15...360; static let initialMinutes = 25; static func clamp(_:) -> Int }`.
- `JourneyCourse` enum의 `seoulBounds`·`coordinates`·`stops`·`point(at:)`·`closedPath`(enum 자체 삭제). `CoursePoint`, `CourseStop`은 남는다.
- `JourneyReach` enum(`reachedStops`, `station(originStopID:direction:stops:)`), `JourneySnapshot.reachedStation`(프로퍼티).
- `JourneySnapshot.Format`, `CodingUserInfoKey.journeyFormat`, `JourneySnapshot.bus`, `ActiveJourneyValidationIssue.invalidDirection/unknownStop/unknownBus`, `SnapshotValidationIssue.invalidDirection`, `AlightingIssue.unknownCatalog`.

## 저장(v5)
```swift
struct StationSnapshot: Codable, Equatable { let id: String; let name: String }   // 옛 JSON의 direction 키는 무시
enum SnapshotValidationIssue { case inconsistentStage, emptyStationID, emptyStationName, multipleCards(Int), cardWithoutIssuance, invalidCardID, invalidRecords(RecordValidationIssue), invalidCardStyle(CardStyleValidationIssue), invalidCardPhoto, invalidActiveJourney(ActiveJourneyValidationIssue) }

struct JourneySnapshot: Equatable, Codable {
    // 멤버와이즈 init 순서 그대로:
    let id, cardID, originStopID, originName: String
    let minutes: Int
    let busID, busNumber, busKind, destinationStopID, destinationName: String
    let tag: Tag; let task: String; let sound: JourneySound; let boardedAt: Date
    let phase: Phase; let progress: Progress; let paused: Bool
    static func boarding(details: PreparedJourneyDetails, cardID: String, id: String, boardedAt: Date) -> JourneySnapshot
        // originStopID/originName/minutes/busID/busNumber/busKind/destinationStopID/destinationName ← details.journey
}
enum ActiveJourneyValidationIssue: Error, Equatable { case emptyField(String), cardMismatch, invalidMinutes(Int), invalidTask, invalidTag, invalidProgress, invalidPausedState, nameTooLong(String) }
// validate: 빈 값(공백만 포함)이면 emptyField(필드명) — 필드명 "id","cardID","originStopID","originName","busID","busNumber","busKind","destinationStopID","destinationName","tag.id".
//           originName/destinationName/busNumber/busKind가 UTF-16 500 초과면 nameTooLong(필드명). 카탈로그 검사 없음.
// 인코딩 키: id, cardID, originStopID, originName, minutes, busID, busNumber, busKind, destinationStopID, destinationName, tag, task, sound, boardedAt, phase, progress, paused

enum SnapshotMigration: Equatable { case routeDataReset }
enum SnapshotCodec {
    static let currentVersion = 5
    static func decode(_ data: Data) throws -> AppSnapshot                // = decodeReport(data).snapshot
    static func decodeReport(_ data: Data) throws -> (snapshot: AppSnapshot, migration: SnapshotMigration?)
    static func encode(_ snapshot: AppSnapshot) throws -> Data           // version 5
}
// 버전 1~4: 옛 형식 그대로 읽고(카드·기록 포함) → validate()(기존 손상 판정 유지: 실패면 StorageIssue.invalidState) →
//   최초·현재 정류장 nil, 진행 여정 비움. 카드·기록 그대로. 정류장이나 여정이 실제로 있었을 때만 migration = .routeDataReset.
//   v3·v4 진행 여정은 내용을 해석하지 않는다(있는지만 본다). 버전 5만 현재 형식. 6 이상 unsupportedVersion.
// LocalSnapshotStore: func loadReport() throws -> (snapshot: AppSnapshot, migration: SnapshotMigration?)?   // 파일 없으면 nil. load()는 이것의 snapshot.
```

## 카탈로그 연결
```swift
struct RouteOrigin: Equatable { let stopIndex: Int; let stopID: String; let name: String; let boundLabel: String? }
struct JourneySelection: Equatable {
    let originStopID: String; let originName: String; let boundLabel: String?
    let minutes: Int
    let busID: String          // 노선 id(RouteCandidate.routeID)
    let busNumber: String; let busKind: String
    let destinationStopID: String; let destination: String
    let stops: Int; let distanceMeters: Int
}
enum ProceedState: Equatable {
    case routeDataLoading, routeDataFailed, originUnavailable, noCandidates, needsSelection, ready(JourneySelection)
    // title: routeDataLoading "정류장 정보를 불러오는 중이에요" · routeDataFailed "정류장 정보를 불러오지 못했어요. 앱을 다시 실행해 주세요"
    //        originUnavailable "출발 정류장을 확인할 수 없어요" · noCandidates "이 시간에 맞는 버스가 없어요" · needsSelection "버스와 도착지를 선택하세요" · ready "이 여정 준비하기"
}
struct JourneyPlanDraft: Equatable {
    private(set) var minutes: Int                 // 초기 JourneyPlanner.initialMinutes
    private(set) var selectedRouteID: String?
    mutating func setMinutes(_ value: Int)        // clamp, 바뀌면 선택 해제(AC-24)
    mutating func choose(routeID: String, origin: RouteOrigin, catalog: RouteCatalog) -> Bool
    func candidates(origin: RouteOrigin, catalog: RouteCatalog) -> [RouteCandidate]
    func selectedCandidate(origin: RouteOrigin, catalog: RouteCatalog) -> RouteCandidate?
    func proceedState(origin: RouteOrigin, catalog: RouteCatalog) -> ProceedState   // ready는 후보에서 JourneySelection을 만든다
}
extension RouteCandidates { static func distanceText(meters: Int) -> String }     // RouteCandidate.distanceText와 같은 규칙
struct PreparedJourneyDetails { journey: JourneySelection; tag; task; sound
    var originName: String { journey.originName }; var boundLabel: String? { journey.boundLabel }
    var distanceText: String { RouteCandidates.distanceText(meters: journey.distanceMeters) } }

struct StationSearchState: Equatable {
    var query: String
    private(set) var selectedID: String?
    func result(in catalog: RouteCatalog) -> StationSearchResult
    func selectedOption(in catalog: RouteCatalog) -> StopSearchOption?
    func confirmationText(in catalog: RouteCatalog) -> String?   // "이름 · 방면에서 출발", 방면 없으면 "이름에서 출발"
    func canConfirm(in catalog: RouteCatalog) -> Bool
    mutating func select(_ optionID: String, in catalog: RouteCatalog) -> Bool   // 현재 결과 안에 있을 때만
}
extension StopSearchOption { var snapshot: StationSnapshot { StationSnapshot(id: id, name: name) } }
```

## 코스·진도
```swift
struct CourseJourney: Equatable {
    let stops: [CourseStop]           // 코스 위치 0…k(출발 포함). CourseStop.index = 코스 위치, id·name·point = 카탈로그 정류장
    let segmentSeconds: [Int]; let segmentMeters: [Int]; let cumulativeSeconds: [Int]   // 0 포함 k+1개
    var totalSeconds: Int { cumulativeSeconds.last! }
    init(leg: RouteLeg, catalog: RouteCatalog)
    init?(journey: JourneySnapshot, catalog: RouteCatalog)   // 노선·출발 정류장 없음, leg 없음, 재계산 도착 id ≠ 저장 destinationStopID → nil(BR-12)
}
// JourneyCourseProgress (기존 이름 유지, 입력만 새 CourseJourney):
//   position(of:elapsedSeconds:) -> CourseBusPosition  // segmentFrom/segmentTo는 코스 위치. j = max{i | cum[i] ≤ e}, fraction = (e−cum[j])/seg[j]. 도착이면 마지막 정류장, isArrived true
//   nextStopIndex(of:elapsedSeconds:) -> Int          // 코스 위치 min(k, j+1)
//   remainingStops(of:elapsedSeconds:) -> Int         // k − j
//   remainingDistanceTenthsKm(of:elapsedSeconds:) -> Int   // 남은 m를 0.1km half-up (AC-28: 420초 → 14)
// 좌표가 같은 구간의 방위는 직전 구간 방위를 쓴다(첫 구간이면 0).
// JourneyMapController: routePoints = journey.stops.map(\.point)(닫는 선 없음), visibleStops = showsStops ? journey.stops : [], destinationStop = journey.stops.last!
```

## 도달·하차·생명주기
```swift
enum ReachResolution: Equatable { case station(StationSnapshot), stayAtOrigin(StationSnapshot), reselectStation }
enum ReachAttempt: Equatable { case notLoaded, resolved(ReachResolution) }
extension JourneySnapshot {
    var arrivedStation: StationSnapshot? { isArrived ? StationSnapshot(id: destinationStopID, name: destinationName) : nil }
    func reachedStation(in availability: RouteDataAvailability) -> ReachAttempt
    // 도착 → .resolved(.station(arrivedStation)) (로딩 무관)
    // .loading → .notLoaded
    // .ready(c): leg 재계산 성공(도착 id 일치) → j = max{i | cum[i] ≤ elapsed}의 정류장 {id, 카탈로그 이름}
    //            실패(노선 없음·leg 없음·도착 id 불일치) → 출발 정류장이 c에 있으면 .stayAtOrigin({originStopID, 카탈로그 이름}), 없으면 .reselectStation
    // .failed → .stayAtOrigin({originStopID, originName})
}
extension AppSnapshot {
    func endingActiveJourney(at station: StationSnapshot) -> AppSnapshot      // 기존
    func clearingStationsAndJourney() -> AppSnapshot                         // 최초·현재 정류장 nil + 여정 비움, 카드·기록 유지
}
enum AlightingIssue: Error, Equatable { case noActiveJourney, notArrived }
extension RecordCompletionInput { init(alighting journey: JourneySnapshot, completedAt: Date) }   // bus = busNumber, from = originName, to = destinationName
// AppSnapshot.alightingActiveJourney: 도착 정류장 = arrivedStation(AC-78·79). 하차 뒤 currentStation == {destinationStopID, destinationName}.

struct ActiveJourneyCardContent { init(journey: JourneySnapshot) }   // non-failable. busText "\(busKind) \(busNumber)", routeText에 destinationName
struct ArrivalBriefingContent { init(journey: JourneySnapshot) }     // non-failable. routeText "\(busNumber) · \(destinationName) 도착"
enum JourneyLiveActivityPolicy { static func attributes(for: JourneySnapshot) -> JourneyActivityAttributes }   // non-optional
// BoardingPassContent: busText "\(journey.busKind) \(journey.busNumber)번 버스"
```

## AppModel
```swift
enum StationResetReason: Equatable { case routeDataReplaced, stationRemoved
    var text: String   // routeDataReplaced "정류장 데이터가 서울 전체로 바뀌어 출발 정류장을 다시 골라 주세요"
                       // stationRemoved   "저장된 출발 정류장이 서울 버스 데이터에서 사라져 다시 골라 주세요"
}
@MainActor final class AppModel {
    init(store: LocalSnapshotStore, cardFactory: = .init(), soundPreview: = nil, journeyFactory: = .init(),
         recordClock: RecordClock = .live, routeData: RouteCatalogStore = RouteCatalogStore(load: { try RouteCatalogLoader.bundled() }))
    let routeData: RouteCatalogStore
    var routeAvailability: RouteDataAvailability { get }
    var routeCatalog: RouteCatalog? { get }
    var stationResetNotice: StationResetReason?          // 메모리만. 이전 감지·BR-13·BR-16에서 설정, confirmInitialStation 성공 시 nil
    func start()                                          // loadIfNeeded → persistMigrationIfNeeded(이전이 있었으면 v5로 1회 저장 + stationResetNotice = .routeDataReplaced) → supplementCardIfNeeded. 카탈로그 로딩은 시작하지 않는다(AC-55)
    @discardableResult func startRouteData() -> Task<Void, Never>   // 로딩 시작, 완료 후 BR-16: 진행 여정 없고 현재 정류장 id가 카탈로그에 없으면 restartStationSelection(.stationRemoved)
    @discardableResult func restartStationSelection(reason: StationResetReason) -> Bool   // clearingStationsAndJourney 저장 → 경로 initialStationEntry, notice 설정
    var journeyOrigin: RouteOrigin? { get }               // 카탈로그 준비 + 현재 정류장 id가 카탈로그에 있을 때
    var journeyCandidates: [RouteCandidate] { get }
    var journeyProceedState: ProceedState { get }         // loading → .routeDataLoading, failed → .routeDataFailed, origin 없음 → .originUnavailable
    var currentStationBound: String? { get }              // 현재 정류장 방면(카탈로그 준비 시). 로딩·실패·없음 nil
    var canEndActiveJourney: Bool { get }                 // routeAvailability != .loading
    @discardableResult func confirmInitialStation(_ option: StopSearchOption) -> Bool
    // confirmNewJourney()/abandonJourney(timerPaused:): reachedStation(in: routeAvailability)
    //   .notLoaded → .rejected(저장 0회) / .station·.stayAtOrigin → endingActiveJourney / .reselectStation → clearingStationsAndJourney 저장, stationResetNotice = .stationRemoved, .done
    //   포기 성공 시 abandonNotice = 결과 정류장 이름(.reselectStation이면 nil)
}
protocol JourneyAbandoning { func abandonJourney(timerPaused: Bool) -> LifecycleActionResult; var canEndActiveJourney: Bool { get } }
```

## UI 테스트 부트스트랩(앱 타깃, T3에서 구현 — UI 테스트 단언은 T5)
- 인자 `--fm-ui-route-data fixture|bundled|pending|failed`(기본 fixture = `RouteCatalog.uiTestFixture()`), `UITestBootstrap.makeRouteCatalogStore()`.
- 시드는 uiTestFixture id로: 정방향 `seongsu`… 역방향 `seongsu-r`…, 노선 `2014`/`2014-r`/`302`/`421`.
