import Foundation
import XCTest

@MainActor
final class ActiveJourneyMainUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func activeJourney(_ h: FocusMateUIHarness) throws -> Any? {
        let journey = try XCTUnwrap(try h.snapshot()["journey"] as? [String: Any])
        return journey["active"]
    }

    // 깨짐: 진행 여정이 있는 메인에서 안내가 없거나 자동으로 여행/안내 화면으로 이동한다.
    func testSeededActiveJourneyShowsMainNoticeWithoutAutoNavigation() throws {
        let h = FocusMateUIHarness.launch(seed: "activeJourney")
        h.relaunch()

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let notice = h.element("main.activeJourney")
        XCTAssertTrue(notice.waitForExistence(timeout: timeout))
        XCTAssertTrue(notice.label.contains("진행 중인 여정"), notice.label)
        XCTAssertFalse(h.element("screen.journey").waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("screen.main").exists)
        XCTAssertTrue(try activeJourney(h) is [String: Any])
    }

    // 깨짐: 새 여행 시작이 진행 여정을 폐기하지 않거나, 폐기하며 기록을 만든다.
    func testStartingTripFromMainDiscardsActiveJourneyWithoutRecord() throws {
        let h = FocusMateUIHarness.launch(seed: "activeJourney")
        h.relaunch()
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))

        h.app.buttons["open.preparation"].tap()

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertTrue(try activeJourney(h) is NSNull)
        let records = try XCTUnwrap(try h.snapshot()["records"] as? [String: Any])
        let items = try XCTUnwrap(records["items"] as? [Any])
        XCTAssertEqual(items.count, 0)
    }

    // 깨짐: 폐기 저장이 실패했는데 시간 선택으로 이동하거나 진행 여정이 사라진다.
    func testDiscardSaveFailureKeepsMainAndActiveJourney() throws {
        let h = FocusMateUIHarness.launch(seed: "activeJourney", save: "fail")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))

        h.app.buttons["open.preparation"].tap()

        XCTAssertFalse(h.element("screen.time").waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("screen.main").exists)
        XCTAssertTrue(h.element("main.activeJourney").exists)
        XCTAssertTrue(try activeJourney(h) is [String: Any])
    }
}
