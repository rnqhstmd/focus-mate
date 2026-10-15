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
