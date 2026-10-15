# T1/T2 RED report

케이스: JourneyReachTests 11건, ActiveJourneyCardContentTests 5건 (총 16)

실패 확인 명령: cd /Users/bonseung/Documents/ChatGPT/new-w07 && FOCUSMATE_SIMULATOR_ID=113C1ABE-9FC9-48F7-9CA5-60498418C2F1 python3 scripts/check-ios.py test ios/FocusMateTests/JourneyReachTests.swift ios/FocusMateTests/ActiveJourneyCardContentTests.swift

실패 메시지(요약): 컴파일 에러는 모두 미정의 심볼 — cannot find 'JourneyReach' / 'ActiveJourneyCardContent' in scope, JourneySnapshot has no member 'reachedStation', AppSnapshot has no member 'endingActiveJourney', ActiveJourneyCardContent.Kind 멤버(resumable/arrived) 추론 실패(연쇄). 픽스처 오타 등 다른 오류 없음. TEST FAILED.

가정: 버스 종류 '지선'은 설계서 예시(지선 2014) 기준; 기존 테스트에서 확인 불가. 할 일 '책 읽기', 태그 '독서'는 BoardingFixtures 기본값. 카드 accessibilityLabel은 '→'를 포함하지 않는다고 가정(낭독 라벨, 이어가기 버튼 문구와 구분).

참조한 파일: prd.md, design.md, ios/FocusMateTests/{BoardingTestDoubles,JourneyTimerTestDoubles,StorageTestSupport,JourneyTimerDisplayTests,RecordSectionTests,CardCustomizationAppModelTests}.swift(grep), 기존 프로덕션 ios/FocusMate/AppSnapshot.swift 는 grep 'func updating' 시그니처 확인용으로만 1회 조회

## 테스트 코드 전문

### JourneyReachTests.swift
```swift
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
```

### ActiveJourneyCardContentTests.swift
```swift
import Foundation
import XCTest
@testable import FocusMate

/// 메인 이어가기 카드 값 (FR-1, FR-8, FR-9). 버스 종류 "지선"은 설계서 예시("지선 2014") 기준 가정.
@MainActor
final class ActiveJourneyCardContentTests: XCTestCase {
    private typealias F = BoardingFixtures

    private func departed(elapsed: Int, paused: Bool = true) -> JourneySnapshot {
        F.journey(
            minutes: 25, busID: "2014", destinationStopID: "seoulForestGate",
            phase: .departed, elapsedSeconds: elapsed, paused: paused
        )
    }

    // 깨짐: 제목·할 일·버스·경로·버튼 구성 중 하나라도 틀리면 실패한다.
    func testAC1_일시정지_여정의_카드_필드() throws {
        let card = try XCTUnwrap(ActiveJourneyCardContent(journey: departed(elapsed: 90)))
        XCTAssertEqual(card.kind, .resumable)
        XCTAssertEqual(card.title, "잠시 멈춘 여정이 있어요.")
        XCTAssertEqual(card.task, "책 읽기")
        XCTAssertEqual(card.busText, "지선 2014")
        XCTAssertEqual(card.remainingText, "24 min 남음")
        XCTAssertEqual(card.routeText, "독서 · 서울숲 입구까지")
        XCTAssertTrue(card.showsResume)
    }

    // 깨짐: 내림/반올림을 쓰면 1·61초에서, 시·초 표기를 쓰면 문자열이 달라 실패한다.
    func testAC2_남은_시간은_올림_분으로만_표기된다() throws {
        let cases: [(elapsed: Int, text: String)] = [
            (0, "25 min 남음"), (1, "25 min 남음"), (60, "24 min 남음"), (61, "24 min 남음"), (1499, "1 min 남음"),
        ]
        for c in cases {
            let card = try XCTUnwrap(ActiveJourneyCardContent(journey: departed(elapsed: c.elapsed)), "elapsed \(c.elapsed)")
            XCTAssertEqual(card.remainingText, c.text, "elapsed \(c.elapsed)")
        }
    }

    // 깨짐: 출발 대기를 별도 처리해 남은 시간이 없거나 전체 분이 아니면 실패한다.
    func testAC23_출발_대기_여정은_전체_시간을_보이고_이어가기가_있다() throws {
        let awaiting = F.journey(minutes: 25, destinationStopID: "seoulForestGate", phase: .awaitingDeparture)
        let card = try XCTUnwrap(ActiveJourneyCardContent(journey: awaiting))
        XCTAssertEqual(card.kind, .resumable)
        XCTAssertEqual(card.remainingText, "25 min 남음")
        XCTAssertTrue(card.showsResume)
    }

    // 깨짐: 도착 여정을 resumable로 만들거나 이어가기·남은 시간을 노출하면 실패한다.
    func testAC24_도착_여정은_arrived_카드로_이어가기와_남은_시간이_없다() throws {
        let card = try XCTUnwrap(ActiveJourneyCardContent(journey: departed(elapsed: 1500)))
        XCTAssertEqual(card.kind, .arrived)
        XCTAssertEqual(card.title, "도착한 여정이 있어요")
        XCTAssertEqual(card.routeText, "독서 · 서울숲 입구까지")
        XCTAssertNil(card.remainingText)
        XCTAssertFalse(card.showsResume)
    }

    // 깨짐: 카드를 한 요소로 낭독할 라벨에 제목·할 일·버스·남은 시간·경로가 빠지면 실패한다.
    func testAC32_카드_낭독_라벨은_모든_정보를_포함한다() throws {
        let card = try XCTUnwrap(ActiveJourneyCardContent(journey: departed(elapsed: 90)))
        for part in ["잠시 멈춘 여정이 있어요.", "책 읽기", "지선 2014", "24 min 남음", "독서 · 서울숲 입구까지"] {
            XCTAssertTrue(card.accessibilityLabel.contains(part), part)
        }
        XCTAssertFalse(card.accessibilityLabel.contains("→"))
    }
}
```
