import XCTest
@testable import FocusMate

final class PreparationDetailsTests: XCTestCase {
    // Break: W04 payload derives the wrong origin/direction or drops the journey distance.
    func testW04_전달값은_성수_정방향_12정류장의_이름_방면_거리를_제공한다() {
        let journey = JourneySelection(
            origin: StopPosition(index: 0, direction: 1), minutes: 60,
            busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12
        )
        let tag = PreparationTag(id: "reading-fixture", name: "독서", icon: .reading, color: .sand)
        let payload = PreparedJourneyDetails(journey: journey, tag: tag, task: "책 읽기", sound: .bus)

        XCTAssertEqual(payload.originName, "성수역")
        XCTAssertEqual(payload.boundLabel, "성수동 방면")
        XCTAssertEqual(payload.distanceText, "6.6km")
    }
}
