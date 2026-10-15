import XCTest
@testable import FocusMate

final class PreparationDetailsTests: XCTestCase {
    // Break: W04 payload derives the wrong origin name/bound or drops the journey distance.
    func testW04_전달값은_선택에서_출발이름_방면_거리를_제공한다() {
        let journey = JourneySelection(
            originStopID: "seongsu", originName: "성수역", boundLabel: "성수동 방면", minutes: 60,
            busID: "2014", busNumber: "2014", busKind: "지선",
            destinationStopID: "seongdongSportsCenter", destination: "성동구민체육센터",
            stops: 12, distanceMeters: 6_600
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        let payload = PreparedJourneyDetails(journey: journey, tag: tag, task: "책 읽기", sound: .bus)

        XCTAssertEqual(payload.originName, "성수역")
        XCTAssertEqual(payload.boundLabel, "성수동 방면")
        XCTAssertEqual(payload.distanceText, "6.6km")
    }

    // Break: 방면이 없는 출발 정류장에서 빈 문구가 생기거나 nil이 사라지면 실패.
    func testW04_방면이_없으면_boundLabel도_없다() {
        let journey = JourneySelection(
            originStopID: "x", originName: "엑스", boundLabel: nil, minutes: 60,
            busID: "r", busNumber: "1", busKind: "간선",
            destinationStopID: "y", destination: "와이", stops: 3, distanceMeters: 1_000
        )
        let tag = PreparationTag(id: "t", name: "독서", icon: .reading, color: .sand)
        let payload = PreparedJourneyDetails(journey: journey, tag: tag, task: "책 읽기", sound: .bus)

        XCTAssertNil(payload.boundLabel)
        XCTAssertEqual(payload.distanceText, "1km")
    }
}
