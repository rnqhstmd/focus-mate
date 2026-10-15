import Foundation
import XCTest

/// W07 이어가기 → 타이머 화면 연결 (AC-3, 4, 5, 23, 29, 30, 32 이어가기 낭독).
/// 현재 정류장 등을 단언하지 않는 흐름 위주라 lifePaused90 / lifeAwaiting 시드를 쓴다.
@MainActor
final class JourneyResumeUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let resumeAnnouncement = "이전 여정을 남은 시간부터 이어갑니다."

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func resumeFromMain(_ h: FocusMateUIHarness) {
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "main.resumeJourney 없음")
        resume.tap()
    }

    private func launchResumed(_ seed: String = "lifePaused90") -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launchLifecycle(seed: seed)
        resumeFromMain(h)
        return h
    }

    private func lines(_ h: FocusMateUIHarness, equalTo text: String) throws -> Int {
        try h.diagnostic("test.announcements").components(separatedBy: "\n").filter { $0 == text }.count
    }

    // MARK: AC-3

    // 깨짐: 이어가기가 여행 화면으로 가지 않거나 path가 [journey]가 아니다.
    func testAC3_이어가기는_여행_화면으로_가고_경로는_journey_하나다() throws {
        let h = launchResumed()

        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.timerDiagnostic()["path"] as? [String], ["journey"])
    }

    // 깨짐: 이어가기 직후 일시정지 상태로 열리거나 남은 시간이 24 min이 아니다.
    func testAC3_이어가기_직후는_진행_중이고_남은_시간은_24분이다() throws {
        let h = launchResumed()

        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.timer.resume").exists)
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "24 min")
    }

    // 깨짐: 이어가기 직후 시계가 돌지 않아 60초 뒤에도 24 min이다.
    func testAC3_이어가기_뒤_시계를_60초_진행하면_23분이다() throws {
        let h = launchResumed()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))

        h.advance(60)

        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "23 min")
    }

    // 깨짐: 이어가기가 저장을 하지 않거나 두 번 한다.
    func testAC3_이어가기는_저장_쓰기를_정확히_1회_한다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let before = try h.writeAttempts()

        resumeFromMain(h)
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.writeAttempts(), before + 1)
    }

    // MARK: AC-4

    // 깨짐: 이어가기 직후 저장값이 (90, paused=false)가 아니다.
    func testAC4_이어가기_직후_저장값은_경과_90이고_일시정지가_아니다() throws {
        let h = launchResumed()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.persistedElapsed(), 90)
        XCTAssertEqual(try h.persistedPaused(), false)
    }

    // 깨짐: 60초 진행 뒤 일시정지가 150초·paused=true를 저장하지 않는다.
    func testAC4_60초_진행_뒤_일시정지하면_저장값은_150이고_paused다() throws {
        let h = launchResumed()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        h.advance(60)

        h.tap("journey.timer.pause")

        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedElapsed(), 150)
        XCTAssertEqual(try h.persistedPaused(), true)
    }

    // 깨짐: 일시정지에서 재개·포기 버튼이 함께 보이지 않는다.
    func testAC4_일시정지하면_재개와_포기_버튼이_보인다() throws {
        let h = launchResumed()
        h.tap("journey.timer.pause")

        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("journey.abandon").exists)
    }

    // MARK: AC-5

    // 깨짐: 이어가기 연타가 여행 화면을 두 번 쌓는다.
    func testAC5_이어가기를_연타해도_여행_화면은_1개다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))

        resume.doubleTap()

        XCTAssertTrue(h.element("screen.journey").waitForExistence(timeout: timeout))
        XCTAssertEqual(h.app.descendants(matching: .any).matching(identifier: "screen.journey").count, 1)
        XCTAssertEqual(try h.timerDiagnostic()["path"] as? [String], ["journey"])
    }

    // 깨짐: 이어가기 연타가 저장을 두 번 한다.
    func testAC5_이어가기를_연타해도_저장_쓰기는_1회다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        let resume = h.app.buttons["main.resumeJourney"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        let before = try h.writeAttempts()

        resume.doubleTap()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))

        XCTAssertEqual(try h.writeAttempts(), before + 1)
    }

    // MARK: AC-23

    // 깨짐: 출발 대기 여정을 이어가면 저장을 하거나 출발 안내가 아닌 화면이 열린다.
    func testAC23_출발_대기_이어가기는_출발_안내를_보이고_쓰기가_없다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifeAwaiting")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let before = try h.writeAttempts()

        resumeFromMain(h)

        XCTAssertTrue(h.element("journey.briefing").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.writeAttempts(), before)
    }

    // 깨짐: 출발 안내 단계에 남은 시간이나 포기 버튼이 나온다.
    func testAC23_출발_대기_이어가기_화면에는_남은_시간과_포기_버튼이_없다() throws {
        let h = launchResumed("lifeAwaiting")
        XCTAssertTrue(h.element("journey.briefing").waitForExistence(timeout: timeout))

        XCTAssertFalse(h.element("journey.timer.remaining").exists)
        XCTAssertFalse(h.element("journey.abandon").exists)
    }

    // MARK: AC-29

    // 깨짐: 5초 진행 뒤 종료하면 체크포인트(10초 단위) 이전 값 90이 아닌 값으로 복원되거나 일시정지로 복원되지 않는다.
    func testAC29_이어가기_5초_뒤_종료하고_다시_열면_카드가_있고_일시정지로_복원된다() throws {
        let h = launchResumed()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        h.advance(1, times: 5)

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        let elapsed = try XCTUnwrap(try h.memoryElapsed())
        XCTAssertTrue((90..<100).contains(elapsed), "경과 \(elapsed)")
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
    }

    // MARK: AC-30

    // 깨짐: 백그라운드 600초가 반영되지 않아 690이 아니거나 진행 상태가 풀린다.
    func testAC30_백그라운드에서_600초가_지나도_복귀하면_진행_상태로_690초다() throws {
        let h = launchResumed()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedElapsed(), 90)
        XCTAssertEqual(try h.persistedPaused(), false)
        h.tap("test.clock.armForeground600")

        h.goBackground()

        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.timerDiagnostic()["elapsed"] as? Int, 690)
    }

    // 깨짐: 복귀 뒤 종료·재실행하면 일시정지로 복원되지 않거나 경과가 690을 넘는다.
    func testAC30_복귀_뒤_종료하고_다시_열면_일시정지이고_경과는_690_이하다() throws {
        let h = launchResumed()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        h.tap("test.clock.armForeground600")
        h.goBackground()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))

        h.relaunch(extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
        let elapsed = try XCTUnwrap(try h.memoryElapsed())
        XCTAssertLessThanOrEqual(elapsed, 690)
    }

    // MARK: AC-32 (이어가기 낭독)

    // 깨짐: 이어가기로 열려도 낭독이 없거나 두 번 나간다.
    func testAC32_이어가기로_열리면_이어가기_낭독이_정확히_1회_나간다() throws {
        let h = FocusMateUIHarness.launchLifecycle(seed: "lifePaused90")
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        XCTAssertEqual(try lines(h, equalTo: resumeAnnouncement), 0)

        resumeFromMain(h)
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))

        XCTAssertEqual(try lines(h, equalTo: resumeAnnouncement), 1)
    }

    // 깨짐: 낭독 문구가 화면 텍스트로도 그려진다(FR-2: 화면 문구 아님).
    func testAC32_이어가기_낭독_문구는_화면에_글자로_나오지_않는다() throws {
        let h = launchResumed()
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))

        // test.announcements(DEBUG 진단 요소)의 value도 문구와 같을 수 있어 label 기준 + 진단 identifier 제외로 판정한다.
        let onScreen = h.app.staticTexts.matching(
            NSPredicate(format: "label == %@ AND NOT (identifier BEGINSWITH 'test.')", resumeAnnouncement))
        XCTAssertEqual(onScreen.count, 0)
    }
}
