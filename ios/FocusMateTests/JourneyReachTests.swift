import Foundation
import XCTest
@testable import FocusMate

/// 도달 정류장(uiTestFixture 카탈로그)과 여정 종료 후보 (BR-3, BR-4).
/// 정방향 순서(리터럴): 0 seongsu, 1 seongsuDong, 2 ttukseom, 3 seongdongSportsCenter, 4 seoulForest,
/// 5 seoulForestGate, 6 seongsuBridgeNorth, 7 ttukseomHangangPark, 8 seongsuIntersection (9개 순환).
/// 구간 초: 2014 = 300, 302 = 450, 421 = 424. 역방향은 id 뒤에 "-r".
/// 도달 정류장의 카탈로그 상태별 판정(누적 시간·노선 사라짐·로딩/실패)은 RouteReachTests가, 도착지 탐색 규칙(칸 수·허용 오차·순환)은 RouteLegTests가 다룬다.
@MainActor
final class JourneyReachTests: XCTestCase {
    private typealias F = BoardingFixtures

    private let catalog = BoardingFixtures.uiCatalog()

    private func departed(
        busID: String = "2014", number: String = "2014", kind: String = "지선", minutes: Int = 25,
        origin: String = "seongsu", originName: String = "성수역",
        destination: String = "seoulForestGate", elapsed: Int, paused: Bool = true,
        phase: JourneySnapshot.Phase = .departed
    ) -> JourneySnapshot {
        F.journey(
            originStopID: origin, originName: originName, minutes: minutes, busID: busID,
            busNumber: number, busKind: kind, destinationStopID: destination,
            destinationName: "도착지", phase: phase, elapsedSeconds: elapsed, paused: paused
        )
    }

    private func reached(_ journey: JourneySnapshot) -> StationSnapshot? {
        guard case let .resolved(.station(station)) = journey.reachedStation(in: .ready(catalog)) else { return nil }
        return station
    }

    // 깨짐: 칸 수 계산(몫)·카탈로그 이름 매핑이 틀리면 경계 표에서 실패한다.
    func testAC17_일시정지_여정의_도달_정류장_경계값() {
        let cases: [(bus: String, number: String, kind: String, minutes: Int, destination: String, elapsed: Int, id: String, name: String)] = [
            ("2014", "2014", "지선", 25, "seoulForestGate", 0, "seongsu", "성수역"),
            ("2014", "2014", "지선", 25, "seoulForestGate", 299, "seongsu", "성수역"),
            ("2014", "2014", "지선", 25, "seoulForestGate", 300, "seongsuDong", "성수동"),
            ("2014", "2014", "지선", 25, "seoulForestGate", 600, "ttukseom", "뚝섬역"),
            ("2014", "2014", "지선", 25, "seoulForestGate", 1499, "seoulForest", "서울숲역"),
            ("302", "강남02", "마을", 60, "seongsuIntersection", 450, "seongsuDong", "성수동"),
            ("421", "343", "간선", 120, "seongsuIntersection", 424, "seongsuDong", "성수동"),
        ]
        for c in cases {
            let journey = departed(
                busID: c.bus, number: c.number, kind: c.kind, minutes: c.minutes,
                destination: c.destination, elapsed: c.elapsed
            )
            let station = reached(journey)
            XCTAssertEqual(station?.id, c.id, "\(c.bus) \(c.elapsed)")
            XCTAssertEqual(station?.name, c.name, "\(c.bus) \(c.elapsed)")
        }
    }

    // 깨짐: 역방향 노선(2014-r)을 정방향 순서로 읽으면 seongsuDong-r 이 되어 실패한다.
    func testAC18_가_역방향_300초는_성수사거리_역방향_정류장이다() {
        let journey = departed(
            busID: "2014-r", origin: "seongsu-r", destination: "seoulForest-r", elapsed: 300
        )
        let station = reached(journey)
        XCTAssertEqual(station?.id, "seongsuIntersection-r")
        XCTAssertEqual(station?.name, "성수사거리")
    }

    // 깨짐: 순환 wrap이 없으면 인덱스 9에서 도달 정류장을 못 찾아 실패한다.
    func testAC18_나_성수대교_북단_900초는_성수역으로_이어진다() {
        let journey = departed(origin: "seongsuBridgeNorth", originName: "성수대교 북단", destination: "ttukseom", elapsed: 900)
        let station = reached(journey)
        XCTAssertEqual(station?.id, "seongsu")
        XCTAssertEqual(station?.name, "성수역")
    }

    // 깨짐: 출발 대기 여정에서 출발지가 아닌 값을 내면 실패한다.
    func testFR8_출발_대기_여정은_출발_정류장이다() {
        let awaiting = departed(elapsed: 0, paused: false, phase: .awaitingDeparture)
        XCTAssertEqual(reached(awaiting)?.id, "seongsu")
    }

    // 깨짐: 도착인데 재계산 값을 쓰면(식과 다른 도착지 픽스처) 저장된 도착지와 달라져 실패한다.
    func testAC24_도착_여정은_저장된_도착지를_따른다() {
        let arrived = departed(destination: "ttukseomHangangPark", elapsed: 1500)
        XCTAssertEqual(reached(arrived)?.id, "ttukseomHangangPark")
        XCTAssertEqual(reached(arrived)?.name, "도착지")
    }

    // 깨짐: 카탈로그 밖 출발지를 기본 정류장으로 대체하면 reselectStation 단언에서 실패한다.
    func testBR1_카탈로그_밖_출발지_여정은_정류장_다시_고르기다() {
        let journey = departed(origin: "nowhere", elapsed: 300)
        XCTAssertEqual(journey.reachedStation(in: .ready(catalog)), .resolved(.reselectStation))
    }

    // 깨짐: records/cards/initialStation을 비우거나 journey를 안 비우거나 currentStation을 안 바꾸면 실패한다.
    func testBR1_4_종료_후보는_기록과_카드와_최초정류장을_보존하고_여정을_비우며_현재정류장만_바꾼다() {
        let initial = StationSnapshot(id: "seongsu", name: "성수역")
        let record = RecordSnapshot(
            id: "seed-record-1", completedAt: "2026-10-13T01:00:00Z", date: "2026-10-13", bus: "버스2014",
            tag: "독서", tagColor: "#12ABef", task: "책 한 챕터 읽기", minutes: 25, sound: "빗소리",
            from: "성수역", to: "서울숲 입구", memo: ""
        )
        let before = XCTestCase.stage(true, initial, initial)
            .issuingCard(CardSnapshot(id: F.cardID, issuedAt: F.boardedAt))
            .updating(records: RecordSection(items: [record]))
            .updating(journey: JourneySection(active: departed(elapsed: 600)))
        let target = StationSnapshot(id: "ttukseom", name: "뚝섬역")

        let after = before.endingActiveJourney(at: target)

        XCTAssertEqual(after.currentStation, target)
        XCTAssertEqual(after.initialStation, initial)
        XCTAssertNil(after.journey.active)
        XCTAssertEqual(after.records.items, [record])
        XCTAssertEqual(after.cards, before.cards)
        XCTAssertTrue(after.cardIssued)
    }
}
