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

    // 깨짐: 진행 여정이 있는 메인에서 카드가 없거나 임시 안내가 남거나 자동으로 여행/안내 화면으로 이동한다.
    // (activeJourney 시드는 정류장 단언 금지 — 흐름 확인에만 쓴다.)
    func testSeededActiveJourneyShowsMainCardWithoutAutoNavigation() throws {
        let h = FocusMateUIHarness.launch(seed: "activeJourney")
        h.relaunch()

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let card = h.element("main.activeJourney")
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(card.label.contains("여정이 있어요"), card.label)
        XCTAssertFalse(card.label.contains("진행 중인 여정"), card.label)
        XCTAssertFalse(h.element("screen.journey").waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("screen.main").exists)
        XCTAssertTrue(try activeJourney(h) is [String: Any])
    }

    // 깨짐: 새 여정 확정이 진행 여정을 폐기하지 않거나, 폐기하며 기록을 만들거나, 시간 선택으로 가지 않는다.
    func testConfirmingNewJourneyFromMainDiscardsActiveJourneyWithoutRecord() throws {
        let h = FocusMateUIHarness.launch(seed: "activeJourney")
        h.relaunch()
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))

        h.app.buttons["open.preparation"].tap()
        let confirm = h.alertButton("main.newJourney.confirm", label: "새 여정 시작")
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()

        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        XCTAssertTrue(try activeJourney(h) is NSNull)
        let records = try XCTUnwrap(try h.snapshot()["records"] as? [String: Any])
        let items = try XCTUnwrap(records["items"] as? [Any])
        XCTAssertEqual(items.count, 0)
    }

    // 깨짐: 확정 저장이 실패했는데 시간 선택으로 이동하거나 진행 여정이 사라지거나 실패 안내가 없다.
    func testNewJourneySaveFailureKeepsMainActiveJourneyAndShowsFailure() throws {
        let h = FocusMateUIHarness.launch(seed: "activeJourney", save: "fail")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))

        h.app.buttons["open.preparation"].tap()
        let confirm = h.alertButton("main.newJourney.confirm", label: "새 여정 시작")
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()

        XCTAssertTrue(h.element("main.saveFailure").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.time").waitForExistence(timeout: 1))
        XCTAssertTrue(h.element("screen.main").exists)
        XCTAssertTrue(h.element("main.activeJourney").exists)
        XCTAssertTrue(try activeJourney(h) is [String: Any])
    }
}
