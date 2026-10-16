import Foundation
import XCTest
@testable import FocusMate

/// W16b 신규 테스트 공용 픽스처. 카탈로그는 RouteCatalogFixture로 직접 만든다 (손계산 가능한 값).
///
/// 정류장 A(에이) B(비) C(씨) D(디), 노선 id "r-100"(번호 "100", 간선) A→B→C→D:
/// 구간 초 [600, 540, 360], 미터 [500, 600, 700]. 누적 [0, 600, 1140, 1500]. 25분 = 1500초에 D가 정확히 맞는다.
enum W16bFixtures {
    typealias F = RouteCatalogFixture

    static let cardID = "FM-01234567"
    static let boardedAt = Date(timeIntervalSince1970: 1_791_882_000)

    static var stops: [RouteCatalog.Stop] {
        [F.stop("A", "에이", 1), F.stop("B", "비", 2), F.stop("C", "씨", 3), F.stop("D", "디", 4)]
    }

    private static func route100(_ stops: [RouteCatalog.Stop]) -> RouteCatalog.Route {
        F.route(
            "r-100", number: "100", kind: "간선", stops: ["A", "B", "C", "D"], in: stops,
            seconds: [600, 540, 360, 60], meters: [500, 600, 700, 100]
        )
    }

    /// 노선 r-100 하나.
    static func single() throws -> RouteCatalog {
        let s = stops
        return try F.make(stops: s, routes: [route100(s)])
    }

    /// r-100 + 지선 r-200(번호 "200", A→D 직행 1500초 3000m) + 후보가 못 되는 r-300(A→B 3000초).
    static func multi() throws -> RouteCatalog {
        let s = stops
        return try F.make(stops: s, routes: [
            route100(s),
            F.route("r-200", number: "200", kind: "지선", stops: ["A", "D"], in: s, seconds: [1500, 60], meters: [3000, 100]),
            F.route("r-300", number: "300", kind: "지선", stops: ["A", "B"], in: s, seconds: [3000, 60], meters: [900, 100]),
        ])
    }

    /// r-100이 없고 정류장 A는 다른 노선 r-900만 지난다 (노선 사라짐 시나리오).
    static func withoutRoute100() throws -> RouteCatalog {
        let s = stops
        return try F.make(stops: s, routes: [
            F.route("r-900", number: "900", kind: "지선", stops: ["A", "B"], in: s, seconds: [100, 60], meters: [100, 100]),
        ])
    }

    /// 정류장 A가 없는 카탈로그.
    static func withoutStopA() throws -> RouteCatalog {
        let s = [F.stop("B", "비", 2), F.stop("C", "씨", 3)]
        return try F.make(stops: s, routes: [F.route("r-900", number: "900", stops: ["B", "C"], in: s)])
    }

    static let tag = JourneySnapshot.Tag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)

    /// 저장 필드는 일부러 카탈로그 이름과 다르게("옛 에이", "옛 디") 둬서 표시값이 저장 필드에서 오는지 구분한다.
    static func journey(
        id: String = "journey-1",
        cardID: String = W16bFixtures.cardID,
        originStopID: String = "A",
        originName: String = "옛 에이",
        minutes: Int = 25,
        busID: String = "r-100",
        busNumber: String = "100",
        busKind: String = "간선",
        destinationStopID: String = "D",
        destinationName: String = "옛 디",
        phase: JourneySnapshot.Phase = .departed,
        elapsedSeconds: Int = 600,
        paused: Bool = true
    ) -> JourneySnapshot {
        JourneySnapshot(
            id: id, cardID: cardID, originStopID: originStopID, originName: originName, minutes: minutes,
            busID: busID, busNumber: busNumber, busKind: busKind,
            destinationStopID: destinationStopID, destinationName: destinationName,
            tag: tag, task: "책 읽기", sound: .bus, boardedAt: boardedAt,
            phase: phase, progress: JourneySnapshot.Progress(elapsedSeconds: elapsedSeconds), paused: paused
        )
    }

    static let stationA = StationSnapshot(id: "A", name: "에이")

    static let record = RecordSnapshot(
        id: "seed-record-1", completedAt: "2026-10-13T01:00:00Z", date: "2026-10-13", bus: "버스2014",
        tag: "독서", tagColor: "#12ABef", task: "책 한 챕터 읽기", minutes: 25, sound: "빗소리",
        from: "성수역", to: "서울숲 입구", memo: ""
    )

    /// 카드 1장 + 기록 1건 + 정류장(선택) + 여정(선택)을 가진 v5 스냅숏.
    static func appSnapshot(
        station: StationSnapshot? = stationA, active: JourneySnapshot? = nil
    ) -> AppSnapshot {
        AppSnapshot.empty
            .updatingStage(cardIssued: true, initialStation: station, currentStation: station)
            .issuingCard(CardSnapshot(id: cardID, issuedAt: boardedAt))
            .updating(records: RecordSection(items: [record]))
            .updating(journey: JourneySection(active: active))
    }

    /// v5로 인코딩한 뒤 version을 낮추고 정류장에 direction 키를 붙여 옛 파일처럼 만든다 (v2~v4).
    /// activeJourney를 주면 옛 형식 진행 여정 객체를 넣는다(v3·v4).
    static func legacyData(
        version: Int, station: StationSnapshot? = stationA, activeJourney: Bool = false
    ) throws -> Data {
        let data = try SnapshotCodec.encode(appSnapshot(station: station, active: nil))
        var root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        var state = try XCTUnwrap(root["state"] as? [String: Any])
        for key in ["initialStation", "currentStation"] {
            if var s = state[key] as? [String: Any] {
                s["direction"] = 1
                state[key] = s
            }
        }
        if activeJourney {
            var active: [String: Any] = [
                "id": "journey-1", "cardID": cardID, "originStopID": "seongsu", "direction": 1, "minutes": 25,
                "busID": "2014", "destinationStopID": "seoulForestGate",
                "tag": ["id": "reading-fixture", "name": "독서", "icon": "reading", "color": "sand"],
                "task": "책 읽기", "sound": "bus", "boardedAt": "2026-10-13T09:00:00Z",
                "phase": "departed", "progress": ["elapsedSeconds": 300],
            ]
            if version >= 4 { active["paused"] = true }
            state["journey"] = ["active": active]
        }
        root["state"] = state
        root["version"] = version
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    /// 읽기 전용 스토어(저장은 probe에 기록).
    static func store(bytes: Data, probe: LifecycleProbe) -> LocalSnapshotStore {
        LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in bytes },
            createDirectory: { _ in },
            writeData: { data, _ in try probe.record(data) }
        )
    }

    /// 로딩이 끝난 RouteCatalogStore (failed).
    @MainActor
    static func failedStore() async -> RouteCatalogStore {
        let store = RouteCatalogStore(load: { throw W16bLoadFailure() })
        await store.startLoading().value
        return store
    }

    /// 로딩을 시작하지 않은 RouteCatalogStore (.loading).
    @MainActor
    static func loadingStore(_ catalog: RouteCatalog) -> RouteCatalogStore {
        RouteCatalogStore(load: { catalog })
    }

    @MainActor
    static func model(
        snapshot: AppSnapshot, routeData: RouteCatalogStore, probe: LifecycleProbe
    ) throws -> AppModel {
        let bytes = try SnapshotCodec.encode(snapshot)
        return try model(bytes: bytes, routeData: routeData, probe: probe)
    }

    @MainActor
    static func model(bytes: Data, routeData: RouteCatalogStore, probe: LifecycleProbe) throws -> AppModel {
        let model = AppModel(
            store: store(bytes: bytes, probe: probe),
            journeyFactory: ActiveJourneyFactory(makeID: { "new-journey" }, now: { boardedAt }),
            routeData: routeData
        )
        model.loadIfNeeded()
        return model
    }
}

struct W16bLoadFailure: Error {}

final class W16bCallCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.lock(); value += 1; lock.unlock() }
    var count: Int { lock.lock(); defer { lock.unlock() }; return value }
}
