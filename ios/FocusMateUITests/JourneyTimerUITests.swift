import Foundation
import XCTest

/// 실제 분 타이머 UI 테스트 V1, V2, V3, V8 (모두 --fm-ui-clock manual).
@MainActor
final class JourneyTimerUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let briefingTimeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchBoardingWithManualClock() -> FocusMateUIHarness {
        FocusMateUIHarness.launch(
            seed: "ready",
            extraArguments: FocusMateUIHarness.manualClockArguments + ["--fm-ui-route", "boarding"]
        )
    }

    private func reachStartButton(_ h: FocusMateUIHarness) -> XCUIElement {
        XCTAssertTrue(h.element("screen.boarding").waitForExistence(timeout: timeout))
        h.tap("test.activateBoardingCard", timeout: timeout)
        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
        let start = h.element("journey.start")
        XCTAssertTrue(start.waitForExistence(timeout: briefingTimeout))
        return start
    }

    // MARK: V1 (AC-1, 2, 17)

    // 깨짐: 시작이 타이머를 띄우지 않거나, 남은 분을 잘못 계산하거나, 출발 완료·미일시정지·0초 저장을 하지 않는다.
    func testV1_AC1_시작을_누르면_60분_타이머가_진행_상태로_시작한다() throws {
        let h = launchBoardingWithManualClock()
        reachStartButton(h).tap()

        XCTAssertTrue(h.element("journey.timer.remaining").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "60 min")
        let active = try XCTUnwrap(try h.memoryActive())
        XCTAssertEqual(active["phase"] as? String, "departed")
        XCTAssertEqual(active["paused"] as? Bool, false)
        XCTAssertEqual(try h.memoryElapsed(), 0)
        XCTAssertTrue(h.element("journey.timer.pause").exists)
        XCTAssertFalse(h.element("journey.placeholder").exists)
    }

    // 깨짐: 시작 저장 실패인데 타이머 화면으로 넘어가거나 실패 안내가 없거나 저장값이 바뀐다.
    func testV1_AC17_시작_저장이_실패하면_타이머로_넘어가지_않고_실패_안내가_나온다() throws {
        let h = launchBoardingWithManualClock()
        let start = reachStartButton(h)

        h.failNextSave { start.tap() }

        XCTAssertTrue(h.element("journey.saveFailure").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.timer.remaining").exists)
        let active = try XCTUnwrap(try h.memoryActive())
        XCTAssertEqual(active["phase"] as? String, "awaitingDeparture")
        XCTAssertEqual(try h.memoryElapsed(), 0)
    }

    // MARK: V2 (AC-4, 5, 6, 10)

    // 깨짐: 일시정지 중 시간이 흐르거나, 일시정지·재개 버튼 노출이 반대로 되거나, 재개 후 분 계산이 어긋난다.
    func testV2_AC4_5_일시정지하면_시간이_멈추고_재개하면_다시_흐른다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        XCTAssertTrue(h.element("journey.timer.remaining").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "24 min")
        XCTAssertTrue(h.element("journey.timer.resume").exists)
        XCTAssertFalse(h.element("journey.timer.pause").exists)

        h.advance(600)
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "24 min")
        XCTAssertEqual(try h.memoryElapsed(), 90)

        h.tap("journey.timer.resume")
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.timer.resume").exists)
        h.advance(60)

        XCTAssertEqual(try h.timerDiagnostic()["elapsed"] as? Int, 150)
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, false)
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "23 min")
    }

    // 깨짐: 9초에 저장하거나 10초째에 체크포인트를 저장하지 않는다.
    func testV2_AC10_체크포인트는_10초째에_저장된다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        h.tap("journey.timer.resume")
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedElapsed(), 90)

        h.advance(1, times: 9)
        XCTAssertEqual(try h.persistedElapsed(), 90)
        XCTAssertEqual(try h.timerDiagnostic()["elapsed"] as? Int, 99)

        h.advance(1)
        XCTAssertEqual(try h.persistedElapsed(), 100)
        XCTAssertEqual(try h.persistedPaused(), false)
    }

    // 깨짐: 연타가 전환을 중복 저장하거나 경과를 이중 가산한다(쓰기 횟수는 저장 바이트 변화로 확인).
    func testV2_AC6_일시정지와_재개를_연타해도_전환은_한_번씩만_일어난다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        h.tap("journey.timer.resume")
        h.advance(1, times: 5)
        let pause = h.element("journey.timer.pause")
        XCTAssertTrue(pause.waitForExistence(timeout: timeout))

        pause.doubleTap()
        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.timer.pause").exists)
        XCTAssertEqual(try h.timerDiagnostic()["status"] as? String, "paused")
        XCTAssertEqual(try h.persistedPaused(), true)
        XCTAssertEqual(try h.persistedElapsed(), 95)
        let afterPause = try h.persistedBytes()

        h.advance(60)
        let resume = h.element("journey.timer.resume")
        resume.doubleTap()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.timer.resume").exists)
        XCTAssertEqual(try h.timerDiagnostic()["status"] as? String, "running")
        XCTAssertNotEqual(try h.persistedBytes(), afterPause)
        XCTAssertEqual(try h.persistedPaused(), false)
        XCTAssertEqual(try h.persistedElapsed(), 95)
        XCTAssertEqual(try h.timerDiagnostic()["elapsed"] as? Int, 95)
    }

    // MARK: V3 (AC-12, 13, 14, 31)

    // 깨짐: 0분 도달 시 도착 표시가 없거나 버튼이 남거나 기록이 생기거나 재실행 뒤 도착 상태가 복원되지 않는다.
    func testV3_AC12_13_31_남은_1분이_지나면_도착하고_재실행해도_도착_상태다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerNearArrival")
        h.tap("journey.timer.resume")
        h.advance(60)

        XCTAssertTrue(h.element("journey.arrived").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "0 min")
        XCTAssertFalse(h.element("journey.timer.pause").exists)
        XCTAssertFalse(h.element("journey.timer.resume").exists)
        XCTAssertEqual(try h.persistedElapsed(), 1500)
        XCTAssertEqual(try h.recordCount(), 0)

        h.advance(600)
        XCTAssertEqual(try h.persistedElapsed(), 1500)

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments + ["--fm-ui-route", "journey"])

        XCTAssertTrue(h.element("journey.arrived").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.timer.pause").exists)
        XCTAssertFalse(h.element("journey.timer.resume").exists)
        XCTAssertEqual(try h.memoryElapsed(), 1500)
        XCTAssertEqual(try h.recordCount(), 0)
    }

    // MARK: V8 (AC-9)

    private func assertStaysOnJourneyAfterSwipes(_ h: FocusMateUIHarness) throws {
        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
        XCTAssertEqual(h.app.navigationBars.buttons.count, 0)

        let edge = h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.5))
        edge.press(forDuration: 0.1, thenDragTo: h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5)))
        let center = h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        center.press(forDuration: 0.1, thenDragTo: h.app.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.5)))

        XCTAssertTrue(h.element("screen.journey").exists)
        XCTAssertFalse(h.element("screen.main").exists)
        XCTAssertEqual(h.app.navigationBars.buttons.count, 0)
        XCTAssertEqual(try h.timerDiagnostic()["path"] as? [String], ["journey"])
    }

    // 깨짐: 일시정지 화면에 뒤로가기 버튼이 보이거나 스와이프로 메인에 돌아간다.
    func testV8_AC9_일시정지_화면은_뒤로가기와_스와이프로_나갈_수_없다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        try assertStaysOnJourneyAfterSwipes(h)
    }

    // 깨짐: 진행 중 화면에 뒤로가기 버튼이 보이거나 스와이프로 메인에 돌아간다.
    func testV8_AC9_진행_중_화면은_뒤로가기와_스와이프로_나갈_수_없다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerPaused90")
        h.tap("journey.timer.resume")
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        try assertStaysOnJourneyAfterSwipes(h)
    }

    // 깨짐: 도착 화면에 뒤로가기 버튼이 보이거나 스와이프로 메인에 돌아간다.
    func testV8_AC9_도착_화면은_뒤로가기와_스와이프로_나갈_수_없다() throws {
        let h = FocusMateUIHarness.launchJourney(seed: "timerArrived")
        XCTAssertTrue(h.element("journey.arrived").waitForExistence(timeout: timeout))
        try assertStaysOnJourneyAfterSwipes(h)
    }
}
