import Foundation
import XCTest
@testable import FocusMate

final class BoardingPassContentTests: XCTestCase {
    private func content() -> BoardingPassContent {
        BoardingPassContent(details: BoardingFixtures.details)
    }

    // 깨짐: 출발지 필드를 도착지나 빈 값으로 채우면 실패
    func testAC3_출발과_도착_이름을_표시한다() {
        XCTAssertEqual(content().originName, "성수역")
        XCTAssertEqual(content().destinationName, "성동구민체육센터")
    }

    // 깨짐: 버스 문구가 종류를 빠뜨리거나 번호 대신 노선 id를 쓰면 실패
    func testAC3_버스_문구는_종류_번호_순서다() {
        let journey = JourneySelection(
            originStopID: "seongsu", originName: "성수역", boundLabel: nil, minutes: 60,
            busID: "302", busNumber: "강남02", busKind: "마을",
            destinationStopID: "ttukseom", destination: "뚝섬역", stops: 8, distanceMeters: 4_000
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        let details = PreparedJourneyDetails(journey: journey, tag: tag, task: "책 읽기", sound: .bus)

        XCTAssertEqual(BoardingPassContent(details: details).busText, "마을 강남02번 버스")
    }

    // 깨짐: 정류장 수 문구를 "12"나 "12정거장"으로 바꾸면 실패
    func testAC3_정류장_수는_12개로_표시한다() {
        XCTAssertEqual(content().stopsText, "12개")
    }

    // 깨짐: 거리 단위 앞 공백(시안 R11 "2.8 km")을 빼거나 반올림 규칙을 따로 만들면 실패
    func testAC3_거리는_준비_상세_값에_단위_공백을_둔다() {
        XCTAssertEqual(content().distanceText, "6.6 km")
        XCTAssertEqual(BoardingFixtures.details.distanceText, "6.6km")
    }

    // 깨짐: 태그/할 일 필드를 서로 바꾸거나 누락하면 실패
    func testAC3_태그와_할_일을_표시한다() {
        XCTAssertEqual(content().tagName, "독서")
        XCTAssertEqual(content().task, "책 읽기")
        XCTAssertEqual(content().taskLine, "독서 · 책 읽기")
    }

    // 깨짐: 접근성 라벨에서 번호나 여행 시간을 빼면 실패
    func testAC3_접근성_라벨에_구간_버스_번호_여행_시간이_들어_있다() {
        let label = content().routeAccessibilityLabel
        XCTAssertTrue(label.hasPrefix("성수역에서 성동구민체육센터까지, "), label)
        XCTAssertTrue(label.contains("2014번 버스"), label)
        XCTAssertTrue(label.hasSuffix(", 60분 여행"), label)
    }

    // 시안 R11(규칙 변경): 승차권 화면에 노선 배지(종류·번호)와 여행 시간을 쓴다.
    // 깨짐: 배지 값이나 "N min" 표기를 바꾸면 실패
    func testAC3_화면에_노선_배지와_여행_시간을_표시한다() {
        let c = content()
        XCTAssertEqual(c.busKind, "지선")
        XCTAssertEqual(c.busNumber, "2014")
        XCTAssertEqual(c.minutesText, "60 min")
    }
}
