import CoreGraphics
import Foundation
import XCTest
@testable import FocusMate

final class BoardingPassContentTests: XCTestCase {
    private let utc = TimeZone(identifier: "UTC")!
    private let seoul = TimeZone(identifier: "Asia/Seoul")!

    private func content(timeZone: TimeZone? = nil) -> BoardingPassContent {
        BoardingPassContent(details: BoardingFixtures.details, now: BoardingFixtures.boardedAt, timeZone: timeZone ?? utc)
    }

    private func details(destination: String) -> PreparedJourneyDetails {
        let journey = JourneySelection(
            origin: StopPosition(index: 0, direction: 1), minutes: 60,
            busID: "2014", busNumber: "2014", destination: destination, stops: 12
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        return PreparedJourneyDetails(journey: journey, tag: tag, task: "책 읽기", sound: .bus)
    }

    private func fontSize(destination: String) -> CGFloat {
        BoardingPassContent(details: details(destination: destination), now: BoardingFixtures.boardedAt, timeZone: utc).stationFontSize
    }

    // 깨짐: 출발지 필드를 도착지나 빈 값으로 채우면 실패
    func testAC3_출발과_도착_이름을_표시한다() {
        XCTAssertEqual(content().originName, "성수역")
        XCTAssertEqual(content().destinationName, "성동구민체육센터")
    }

    // 깨짐: 정류장 수 문구를 "12"나 "12정거장"으로 바꾸면 실패
    func testAC3_정류장_수는_12개로_표시한다() {
        XCTAssertEqual(content().stopsText, "12개")
    }

    // 깨짐: 거리를 별도 포맷으로 새로 계산하면 기존 표기(6.6km)와 달라져 실패
    func testAC3_거리는_준비_상세와_같은_표기를_쓴다() {
        XCTAssertEqual(content().distanceText, "6.6km")
        XCTAssertEqual(content().distanceText, BoardingFixtures.details.distanceText)
    }

    // 깨짐: 승차 시각 문구를 시각 표기로 바꾸면 실패
    func testAC3_승차는_지금으로_표시한다() {
        XCTAssertEqual(content().boardingText, "지금")
    }

    // 깨짐: 날짜 포맷을 yyyy-MM-dd 등으로 바꾸면 실패
    func testAC3_날짜는_슬래시_형식으로_표시한다() {
        XCTAssertEqual(content().dateText, "2026/10/13")
    }

    // 깨짐: 타임존을 무시하면 UTC 15:00(날짜 경계 넘김) 입력에서 서울은 다음 날이어야 하므로 실패
    func testAC3_날짜는_주어진_타임존_기준이다() {
        let late = Date(timeIntervalSince1970: 1_791_882_000 + 15 * 3600) // 2026-10-14T00:00:00Z
        let inUTC = BoardingPassContent(details: BoardingFixtures.details, now: late, timeZone: utc)
        let inSeoul = BoardingPassContent(details: BoardingFixtures.details, now: late, timeZone: seoul)
        XCTAssertEqual(inUTC.dateText, "2026/10/14")
        XCTAssertEqual(inSeoul.dateText, "2026/10/14")
        let early = Date(timeIntervalSince1970: 1_791_882_000 + 10 * 3600) // 2026-10-13T19:00:00Z = 서울 10/14 04:00
        XCTAssertEqual(BoardingPassContent(details: BoardingFixtures.details, now: early, timeZone: utc).dateText, "2026/10/13")
        XCTAssertEqual(BoardingPassContent(details: BoardingFixtures.details, now: early, timeZone: seoul).dateText, "2026/10/14")
    }

    // 깨짐: 태그/할 일 필드를 서로 바꾸거나 누락하면 실패
    func testAC3_태그와_할_일을_표시한다() {
        XCTAssertEqual(content().tagName, "독서")
        XCTAssertEqual(content().task, "책 읽기")
    }

    // 깨짐: 접근성 라벨에서 번호나 여행 시간을 빼면 실패
    func testAC3_접근성_라벨에_구간_버스_번호_여행_시간이_들어_있다() {
        let label = content().routeAccessibilityLabel
        XCTAssertTrue(label.hasPrefix("성수역에서 성동구민체육센터까지, "), label)
        XCTAssertTrue(label.contains("2014번 버스"), label)
        XCTAssertTrue(label.hasSuffix(", 60분 여행"), label)
    }

    // 깨짐: 화면 필드에 버스 번호나 여행 시간을 노출하면 실패
    func testAC3_화면_필드에는_버스_번호와_여행_시간이_없다() {
        let c = content()
        let screenFields = [c.originName, c.destinationName, c.stopsText, c.distanceText, c.boardingText, c.dateText, c.tagName, c.task]
        for field in screenFields {
            XCTAssertFalse(field.contains("2014"), field)
            XCTAssertFalse(field.contains("60분"), field)
        }
    }

    // 깨짐: 4자 경계를 < 4로 바꾸면 실패 ("성수역" 출발 3자, 도착 4자)
    func testAC3_긴_이름이_4자_이하면_글꼴은_28이다() {
        XCTAssertEqual(fontSize(destination: "왕십리역"), 28, accuracy: 0.001)
    }

    // 깨짐: 5자가 28 구간에 남으면 실패
    func testAC3_긴_이름이_5자면_글꼴은_24다() {
        XCTAssertEqual(fontSize(destination: "서울숲공원역"), 24, accuracy: 0.001) // 6자
        XCTAssertEqual(fontSize(destination: "서울숲공원"), 24, accuracy: 0.001) // 5자
    }

    // 깨짐: 7자가 24 구간에 남거나 9자 경계를 < 9로 바꾸면 실패
    func testAC3_긴_이름이_7자에서_9자면_글꼴은_20이다() {
        XCTAssertEqual(fontSize(destination: "서울숲공원앞역"), 20, accuracy: 0.001) // 7자
        XCTAssertEqual(fontSize(destination: "서울숲공원앞정류장"), 20, accuracy: 0.001) // 9자
    }

    // 깨짐: 10자 이상에서 20 이하로 계속 줄이지 않거나 하한을 17이 아닌 값으로 두면 실패
    func testAC3_긴_이름이_10자_이상이면_글꼴은_17이다() {
        XCTAssertEqual(fontSize(destination: "서울숲공원앞정류장입구"), 17, accuracy: 0.001) // 11자
        XCTAssertEqual(fontSize(destination: "서울숲공원앞정류장입"), 17, accuracy: 0.001) // 10자
    }

    // 깨짐: 도착지만 보고 크기를 정하면(출발지가 더 긴 경우) 실패하나, 출발 "성수역"은 3자라 도착이 짧을 때 출발 기준 28을 확인
    func testAC3_두_이름_중_짧은_쪽이_아니라_긴_쪽으로_정한다() {
        XCTAssertEqual(fontSize(destination: "숲"), 28, accuracy: 0.001) // 출발 3자, 도착 1자 → 긴 쪽 3자
    }
}
