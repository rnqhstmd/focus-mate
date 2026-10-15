import Foundation
import XCTest
@testable import FocusMate

/// 도달 정류장 규칙 (BR-1, BR-2)과 여정 종료 후보 (BR-3, BR-4).
/// 카탈로그 순서(리터럴): 0 seongsu, 1 seongsuDong, 2 ttukseom, 3 seongdongSportsCenter, 4 seoulForest,
/// 5 seoulForestGate, 6 seongsuBridgeNorth, 7 ttukseomHangangPark, 8 seongsuIntersection (9개 순환).
@MainActor
final class JourneyReachTests: XCTestCase {
    private typealias F = BoardingFixtures

    private func departed(
        busID: String = "2014", minutes: Int = 25, origin: String = "seongsu", direction: Int = 1,
        destination: String = "seoulForestGate", elapsed: Int, paused: Bool = true
    ) -> JourneySnapshot {
        F.journey(
            originStopID: origin, direction: direction, minutes: minutes, busID: busID,
            destinationStopID: destination, phase: .departed, elapsedSeconds: elapsed, paused: paused
        )
    }

    // 깨짐: 몫 대신 반올림/올림을 쓰면 299초(→1칸)나 1499초(→5칸)에서 실패한다.
    func testAC17_칸_수는_경과를_간격_초로_나눈_몫이다() {
        let cases: [(elapsed: Int, minutes: Int, interval: Int, stops: Int)] = [
            (0, 25, 5, 0), (299, 25, 5, 0), (300, 25, 5, 1), (600, 25, 5, 2), (1499, 25, 5, 4),
            (360, 30, 6, 1), (480, 40, 8, 1),
        ]
        for c in cases {
            XCTAssertEqual(
                JourneyReach.reachedStops(elapsedSeconds: c.elapsed, minutes: c.minutes, minutesPerStop: c.interval),
                c.stops, "elapsed \(c.elapsed) interval \(c.interval)"
            )
        }
    }

    // 깨짐: 총 정류장 수 상한(min)을 빼면 경과가 총 시간을 넘을 때 6칸이 되어 실패한다.
    func testBR1_칸_수는_총_정류장_수를_넘지_않는다() {
        XCTAssertEqual(JourneyReach.reachedStops(elapsedSeconds: 1800, minutes: 25, minutesPerStop: 5), 5)
    }

    // 깨짐: 방향을 무시하거나 wrap을 하지 않으면 역방향·순환 케이스에서 실패한다.
    func testAC18_순환_구간과_역방향_정류장() {
        XCTAssertEqual(JourneyReach.station(originStopID: "seongsu", direction: -1, stops: 1)?.id, "seongsuIntersection")
        XCTAssertEqual(JourneyReach.station(originStopID: "seongsuBridgeNorth", direction: 1, stops: 3)?.id, "seongsu")
        XCTAssertEqual(JourneyReach.station(originStopID: "seongsu", direction: -1, stops: 1)?.direction, -1)
        XCTAssertEqual(JourneyReach.station(originStopID: "seongsuBridgeNorth", direction: 1, stops: 3)?.direction, 1)
    }

    // 깨짐: 카탈로그 밖 id를 기본 정류장으로 대체하면 nil 단언에서 실패한다.
    func testBR1_카탈로그_밖_출발지는_nil이다() {
        XCTAssertNil(JourneyReach.station(originStopID: "nowhere", direction: 1, stops: 2))
    }

    // 깨짐: 칸 수 계산·카탈로그 이름 매핑이 틀리면 경계 표에서 실패한다.
    func testAC17_일시정지_여정의_도달_정류장_경계값() {
        let cases: [(bus: String, minutes: Int, elapsed: Int, id: String, name: String)] = [
            ("2014", 25, 0, "seongsu", "성수역"),
            ("2014", 25, 299, "seongsu", "성수역"),
            ("2014", 25, 300, "seongsuDong", "성수동"),
            ("2014", 25, 600, "ttukseom", "뚝섬역"),
            ("2014", 25, 1499, "seoulForest", "서울숲역"),
            ("302", 30, 360, "seongsuDong", "성수동"),
            ("421", 40, 480, "seongsuDong", "성수동"),
        ]
        for c in cases {
            let station = departed(busID: c.bus, minutes: c.minutes, elapsed: c.elapsed).reachedStation
            XCTAssertEqual(station?.id, c.id, "\(c.bus) \(c.elapsed)")
            XCTAssertEqual(station?.name, c.name, "\(c.bus) \(c.elapsed)")
            XCTAssertEqual(station?.direction, 1, "\(c.bus) \(c.elapsed)")
        }
    }

    // 깨짐: 역방향 부호를 무시하면 seongsuDong이 되어 실패한다.
    func testAC18_가_역방향_300초는_성수사거리_방향_마이너스1이다() {
        let station = departed(direction: -1, elapsed: 300).reachedStation
        XCTAssertEqual(station?.id, "seongsuIntersection")
        XCTAssertEqual(station?.name, "성수사거리")
        XCTAssertEqual(station?.direction, -1)
    }

    // 깨짐: 순환 wrap이 없으면 인덱스 9에서 nil/크래시로 실패한다.
    func testAC18_나_성수대교_북단_900초는_성수역으로_이어진다() {
        let station = departed(origin: "seongsuBridgeNorth", elapsed: 900).reachedStation
        XCTAssertEqual(station?.id, "seongsu")
        XCTAssertEqual(station?.name, "성수역")
        XCTAssertEqual(station?.direction, 1)
    }

    // 깨짐: 진도 0에서 출발지 대신 다른 값을 내면 실패한다.
    func testAC19_진도_0초는_출발_정류장이다() {
        XCTAssertEqual(departed(elapsed: 0).reachedStation?.name, "성수역")
    }

    // 깨짐: 출발 대기 여정에서 nil을 내거나 목적지를 내면 실패한다.
    func testFR8_출발_대기_여정은_출발_정류장이다() {
        let awaiting = F.journey(originStopID: "seongsu", minutes: 25, destinationStopID: "seoulForestGate", phase: .awaitingDeparture)
        XCTAssertEqual(awaiting.reachedStation?.id, "seongsu")
    }

    // 깨짐: 도착인데 식으로 계산하면(seongsuBridgeNorth 등) 저장값 seoulForestGate와 달라 실패한다. 식과 다른 도착지 픽스처.
    func testAC24_도착_여정은_저장된_도착지를_따른다() {
        let arrived = departed(destination: "seoulForestGate", elapsed: 1500)
        XCTAssertEqual(arrived.reachedStation?.id, "seoulForestGate")
        XCTAssertEqual(arrived.reachedStation?.name, "서울숲 입구")
        let mismatched = departed(destination: "ttukseomHangangPark", elapsed: 1500)
        XCTAssertEqual(mismatched.reachedStation?.id, "ttukseomHangangPark")
    }

    // 깨짐: 카탈로그 밖 출발지에서 nil이 아니면 실패한다.
    func testBR1_카탈로그_밖_출발지_여정은_nil이다() {
        XCTAssertNil(departed(origin: "nowhere", elapsed: 300).reachedStation)
    }

    // 깨짐: records/cards/initialStation을 비우거나 journey를 안 비우거나 currentStation을 안 바꾸면 실패한다.
    func testBR1_4_종료_후보는_기록과_카드와_최초정류장을_보존하고_여정을_비우며_현재정류장만_바꾼다() {
        let initial = StationSnapshot(id: "seongsu", name: "성수역", direction: 1)
        let record = RecordSnapshot(
            id: "seed-record-1", completedAt: "2026-10-13T01:00:00Z", date: "2026-10-13", bus: "버스2014",
            tag: "독서", tagColor: "#12ABef", task: "책 한 챕터 읽기", minutes: 25, sound: "빗소리",
            from: "성수역", to: "서울숲 입구", memo: ""
        )
        let before = XCTestCase.stage(true, initial, initial)
            .issuingCard(CardSnapshot(id: F.cardID, issuedAt: F.boardedAt))
            .updating(records: RecordSection(items: [record]))
            .updating(journey: JourneySection(active: departed(elapsed: 600)))
        let target = StationSnapshot(id: "ttukseom", name: "뚝섬역", direction: 1)

        let after = before.endingActiveJourney(at: target)

        XCTAssertEqual(after.currentStation, target)
        XCTAssertEqual(after.initialStation, initial)
        XCTAssertNil(after.journey.active)
        XCTAssertEqual(after.records.items, [record])
        XCTAssertEqual(after.cards, before.cards)
        XCTAssertTrue(after.cardIssued)
    }
}
