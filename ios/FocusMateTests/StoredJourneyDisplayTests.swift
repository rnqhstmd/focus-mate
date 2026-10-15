import Foundation
import XCTest
@testable import FocusMate

/// 표시 문자열이 카탈로그가 아니라 저장 필드(busKind, busNumber, destinationName)에서 온다.
/// 저장 필드는 "간선"/"100"/"옛 디"이고 카탈로그와 무관하게 non-failable로 만들어진다.
final class StoredJourneyDisplayTests: XCTestCase {
    private typealias F = W16bFixtures

    // 깨짐: 완료 기록 입력이 저장 필드(버스 번호·출발·도착 이름)에서 오지 않으면 실패한다.
    func testRecordCompletionInputComesFromStoredFields() {
        let journey = F.journey(originName: "저장 출발", busNumber: "N37", destinationName: "저장 도착", elapsedSeconds: 1500)

        // 2026-10-13T01:00:00Z
        let input = RecordCompletionInput(alighting: journey, completedAt: Date(timeIntervalSince1970: 1_791_853_200))

        XCTAssertEqual(input.id, "journey-1")
        XCTAssertEqual(input.completedAt, "2026-10-13T01:00:00.000Z")
        XCTAssertEqual(input.bus, "N37")
        XCTAssertEqual(input.from, "저장 출발")
        XCTAssertEqual(input.to, "저장 도착")
        XCTAssertEqual(input.minutes, 25)
        XCTAssertEqual(input.task, "책 읽기")
        XCTAssertEqual(input.tag, "독서")
    }

    // 깨짐: 카드 버스 문구가 "종류 번호" 저장 필드 조합이 아니면 실패한다.
    func testActiveJourneyCardShowsStoredBusAndDestination() {
        let card = ActiveJourneyCardContent(journey: F.journey(elapsedSeconds: 600))

        XCTAssertEqual(card.busText, "간선 100")
        XCTAssertTrue(card.routeText.contains("옛 디"), card.routeText)
        XCTAssertEqual(card.task, "책 읽기")
        XCTAssertEqual(card.kind, .resumable)
        XCTAssertEqual(card.remainingText, "15 min 남음")
    }

    // 깨짐: 도착 카드가 저장 도착 이름을 경로에 쓰지 않으면 실패한다.
    func testArrivedCardShowsStoredDestination() {
        let card = ActiveJourneyCardContent(journey: F.journey(elapsedSeconds: 1500))

        XCTAssertEqual(card.kind, .arrived)
        XCTAssertTrue(card.routeText.contains("옛 디"), card.routeText)
    }

    // 깨짐: 도착 안내 문구가 "번호 · 도착지 도착"이 아니면 실패한다.
    func testArrivalBriefingRouteTextUsesStoredFields() {
        let content = ArrivalBriefingContent(journey: F.journey(elapsedSeconds: 1500))

        XCTAssertEqual(content.routeText, "100 · 옛 디 도착")
    }

    // 깨짐: Live Activity 속성이 저장 필드를 쓰지 않으면 실패한다 (비옵셔널 반환).
    func testLiveActivityAttributesUseStoredFields() {
        let attributes = JourneyLiveActivityPolicy.attributes(for: F.journey(elapsedSeconds: 600))

        XCTAssertEqual(attributes.journeyID, "journey-1")
        XCTAssertEqual(attributes.busNumber, "100")
        XCTAssertEqual(attributes.busKind, "간선")
        XCTAssertEqual(attributes.destinationName, "옛 디")
    }

    // 깨짐: 알 수 없는 버스·도착 id여도 속성이 만들어져야 한다 (카탈로그를 보지 않음).
    func testLiveActivityAttributesDoNotDependOnCatalogIds() {
        let attributes = JourneyLiveActivityPolicy.attributes(
            for: F.journey(busID: "gone-bus", destinationStopID: "gone-dest", elapsedSeconds: 600)
        )

        XCTAssertEqual(attributes.busNumber, "100")
        XCTAssertEqual(attributes.destinationName, "옛 디")
    }
}
