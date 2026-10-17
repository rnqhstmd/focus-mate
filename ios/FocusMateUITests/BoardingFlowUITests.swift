import Foundation
import XCTest

@MainActor
final class BoardingFlowUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐: 메인 버튼 라벨이 '여행 시작하기'가 아니거나 식별자 open.preparation이 없다.
    func testMainTripButtonIsLabeledStartTripAndHasStableIdentifier() throws {
        let h = FocusMateUIHarness.launch(seed: "ready")
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let button = h.app.buttons["open.preparation"]
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        XCTAssertEqual(button.label, "여행 시작하기")
    }

    // 깨짐: 확정이 승차권으로 이동하지 않거나, 승차권 값/버스·분 노출 위치/탑승·뒤로 흐름/무저장이 깨진다.
    func testConfirmOpensBoardingPassWithValuesBoardsToTagScreenAndBackWritesNothing() throws {
        let h = FocusMateUIHarness.launch(seed: "ready")
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        let startBytes = try h.diagnostic("test.persistedBytes")
        h.app.buttons["open.preparation"].tap()
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        h.app.setJourneyMinutes(60, timeout: timeout)
        let bus = h.element("time.candidate.2014-r")
        XCTAssertTrue(bus.waitForExistence(timeout: timeout))
        bus.tap()
        h.element("time.proceed").tap()
        XCTAssertTrue(h.element("screen.preparation").waitForExistence(timeout: timeout))

        let tag = h.element("preparation.tag.reading")
        XCTAssertTrue(tag.waitForExistence(timeout: timeout))
        tag.tap()
        let field = h.element("preparation.task")
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        field.tap()
        field.typeText("보고서 읽기")
        let confirm = h.app.buttons["preparation.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        XCTAssertEqual(confirm.label, "승차권 보기")
        var attempts = 0
        while !confirm.isHittable && attempts < 4 { h.app.swipeUp(); attempts += 1 }
        confirm.tap()

        XCTAssertTrue(h.element("screen.board").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.diagnostic("board.origin"), "서울숲역")
        XCTAssertFalse(try h.diagnostic("board.destination").isEmpty)
        XCTAssertEqual(try h.diagnostic("board.stops"), "12개")
        XCTAssertFalse(try h.diagnostic("board.distance").isEmpty)
        XCTAssertEqual(try h.diagnostic("board.boarding"), "지금")
        let date = try h.diagnostic("board.date")
        XCTAssertNotNil(date.range(of: #"^\d{4}/\d{2}/\d{2}$"#, options: .regularExpression), date)
        XCTAssertEqual(try h.diagnostic("board.tag"), "독서")
        XCTAssertEqual(try h.diagnostic("board.task"), "보고서 읽기")

        let route = h.element("board.route")
        XCTAssertTrue(route.waitForExistence(timeout: timeout))
        XCTAssertTrue(route.label.contains("2014"), route.label)
        XCTAssertTrue(route.label.contains("60분"), route.label)
        let leaking = h.app.staticTexts.allElementsBoundByIndex.filter {
            $0.identifier != "board.route" && ($0.label.contains("2014") || $0.label.contains("60분"))
        }
        XCTAssertEqual(leaking.count, 0, leaking.map(\.label).joined(separator: ","))

        let boardBus = h.app.buttons["board.boardBus"]
        XCTAssertTrue(boardBus.waitForExistence(timeout: timeout))
        XCTAssertEqual(boardBus.label, "버스에 탑승하기")
        boardBus.tap()
        XCTAssertTrue(h.element("screen.boarding").waitForExistence(timeout: timeout))

        h.app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(h.element("screen.board").waitForExistence(timeout: timeout))
        h.app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(h.element("screen.preparation").waitForExistence(timeout: timeout))

        let journey = try XCTUnwrap(try h.snapshot()["journey"] as? [String: Any])
        XCTAssertTrue(journey["active"] is NSNull)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), startBytes)
    }

    // MARK: - U3 (AC-14, 25, 28)

    private func fillPreparation(_ h: FocusMateUIHarness, task: String, replacing old: String? = nil) {
        let field = h.element("preparation.task")
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        field.tap()
        if let old {
            field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count))
        }
        field.typeText(task)
    }

    private func confirmAndBoard(_ h: FocusMateUIHarness) {
        let confirm = h.app.buttons["preparation.confirm"]
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        var attempts = 0
        while !confirm.isHittable && attempts < 4 { h.app.swipeUp(); attempts += 1 }
        confirm.tap()
        let boardBus = h.app.buttons["board.boardBus"]
        XCTAssertTrue(boardBus.waitForExistence(timeout: timeout))
        boardBus.tap()
        XCTAssertTrue(h.element("screen.boarding").waitForExistence(timeout: timeout))
    }

    private func recognizeAndWaitHeld(_ h: FocusMateUIHarness) throws {
        let card = h.element("boarding.card")
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        let area = h.element("boarding.tagArea")
        card.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            .press(forDuration: 0.2,
                   thenDragTo: area.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)))
        let deadline = Date().addingTimeInterval(timeout)
        var phase = ""
        while Date() < deadline {
            let raw = try h.diagnostic("test.boarding")
            let obj = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(raw.utf8)) as? [String: Any])
            phase = obj["phase"] as? String ?? ""
            if phase == "held" { return }
            Thread.sleep(forTimeInterval: 0.1)
        }
        XCTAssertEqual(phase, "held")
    }

    private func activeTask(_ h: FocusMateUIHarness) throws -> String? {
        let journey = try XCTUnwrap(try h.snapshot()["journey"] as? [String: Any])
        return (journey["active"] as? [String: Any])?["task"] as? String
    }

    // 깨짐: hold 중 뒤로가 전환을 취소하지 않거나, 재인식이 여정을 중복/미교체하거나, 메인 안내가 안 뜬다.
    func testU3_인식_후_뒤로가면_전환이_취소되고_수정해_재인식하면_교체되며_메인에_안내가_뜬다() throws {
        let h = FocusMateUIHarness.launch(
            seed: "ready",
            extraArguments: ["--fm-ui-boarding-hold", "manual"]
        )
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        h.app.buttons["open.preparation"].tap()
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        h.app.setJourneyMinutes(60, timeout: timeout)
        let bus = h.element("time.candidate.2014-r")
        XCTAssertTrue(bus.waitForExistence(timeout: timeout))
        bus.tap()
        h.element("time.proceed").tap()
        XCTAssertTrue(h.element("screen.preparation").waitForExistence(timeout: timeout))
        let tag = h.element("preparation.tag.reading")
        XCTAssertTrue(tag.waitForExistence(timeout: timeout))
        tag.tap()

        let taskA = "보고서 읽기"
        let taskB = "논문 읽기"
        fillPreparation(h, task: taskA)
        confirmAndBoard(h)
        try recognizeAndWaitHeld(h)
        XCTAssertEqual(try activeTask(h), taskA)

        h.app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(h.element("screen.board").waitForExistence(timeout: timeout))
        let release = h.element("test.releaseBoardingHold")
        XCTAssertTrue(release.waitForExistence(timeout: timeout))
        release.tap()
        XCTAssertFalse(h.element("screen.journey").waitForExistence(timeout: 1))
        XCTAssertEqual(try activeTask(h), taskA)

        h.app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(h.element("screen.preparation").waitForExistence(timeout: timeout))
        fillPreparation(h, task: taskB, replacing: taskA)
        confirmAndBoard(h)
        try recognizeAndWaitHeld(h)

        let journey = try XCTUnwrap(try h.snapshot()["journey"] as? [String: Any])
        let active = try XCTUnwrap(journey["active"] as? [String: Any])
        XCTAssertEqual(active["task"] as? String, taskB)

        for expected in ["screen.board", "screen.preparation", "screen.time", "screen.main"] {
            // 시간 화면(R04)은 시스템 내비 막대 대신 패널 안 뒤로 버튼을 쓴다.
            if expected == "screen.main" { h.element("time.back").tap() }
            else { h.app.navigationBars.buttons.firstMatch.tap() }
            XCTAssertTrue(h.element(expected).waitForExistence(timeout: timeout), expected)
        }
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        XCTAssertEqual(try activeTask(h), taskB)
    }
}
