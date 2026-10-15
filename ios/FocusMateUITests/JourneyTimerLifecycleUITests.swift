import Foundation
import XCTest

/// 실제 분 타이머 UI 테스트 V4, V5, V6 (모두 --fm-ui-clock manual).
@MainActor
final class JourneyTimerLifecycleUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private var journeyArguments: [String] {
        FocusMateUIHarness.manualClockArguments + ["--fm-ui-route", "journey"]
    }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func runningFrom(_ seed: String) -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launchJourney(seed: seed)
        h.tap("journey.timer.resume")
        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        return h
    }

    // MARK: V4 (AC-15, 16)

    // 깨짐: 전환 저장 실패인데 일시정지가 적용되거나 안내가 없거나 저장값이 바뀌고, 재시도로 정지되지 않는다.
    func testV4_AC15_일시정지_저장이_실패하면_계속_진행되고_안내가_나오며_다시_누르면_멈춘다() throws {
        let h = runningFrom("timerPaused90")

        h.failNextSave { h.tap("journey.timer.pause") }

        XCTAssertTrue(h.element("journey.timer.saveFailure").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("journey.timer.pause").exists)
        XCTAssertFalse(h.element("journey.timer.resume").exists)
        XCTAssertEqual(try h.persistedPaused(), false)
        XCTAssertEqual(try h.persistedElapsed(), 90)

        h.tap("journey.timer.pause")

        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedPaused(), true)
    }

    // 깨짐: 체크포인트 실패 시 자동 일시정지·경고가 없거나 시계가 계속 흐르고, 재개 성공 후 경고가 남는다.
    func testV4_AC16_체크포인트_저장이_실패하면_일시정지하고_경고하며_재개하면_경고가_사라진다() throws {
        let h = runningFrom("timerPaused90")
        h.advance(1, times: 9)

        h.failNextSave { h.advance(1) }

        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("journey.timer.saveWarning").exists)
        XCTAssertFalse(h.element("journey.timer.pause").exists)
        let frozen = try XCTUnwrap(try h.timerDiagnostic()["text"] as? String)
        h.advance(600)
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, frozen)

        h.tap("journey.timer.resume")

        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("journey.timer.saveWarning").exists)
        XCTAssertEqual(try h.persistedPaused(), false)
        XCTAssertEqual(try h.persistedElapsed(), 100)
    }

    // 깨짐: 재개 저장 실패인데 진행 상태로 바뀌거나 경고가 사라진다.
    func testV4_AC16_재개_저장도_실패하면_일시정지와_경고가_유지된다() throws {
        let h = runningFrom("timerPaused90")
        h.advance(1, times: 9)
        h.failNextSave { h.advance(1) }
        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))

        h.failNextSave { h.tap("journey.timer.resume") }

        XCTAssertTrue(h.element("journey.timer.resume").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("journey.timer.saveWarning").exists)
        XCTAssertFalse(h.element("journey.timer.pause").exists)
    }

    // MARK: V5 (AC-7, 8, 11)

    // 깨짐: 백그라운드 진입 시 저장을 안 하거나 복귀 시 흐른 600초를 반영하지 않거나 진행이 멈춘 채로 남는다.
    func testV5_AC7_백그라운드에서_600초가_지나도_복귀하면_진행_상태로_700초다() throws {
        let h = runningFrom("timerPaused90")
        h.advance(10)
        h.tap("test.clock.armForeground600")

        h.goBackground()

        XCTAssertTrue(h.element("journey.timer.pause").waitForExistence(timeout: timeout))
        // 진입 시점 (100,false) 저장은 단위 테스트 T5 AC-7이 검증한다. UI에서는 복귀 후 값만 본다.
        // 복귀 시 tick 1회로 흐른 600초가 체크포인트로 즉시 저장된다.
        XCTAssertEqual(try h.persistedElapsed(), 700)
        XCTAssertEqual(try h.persistedPaused(), false)
        XCTAssertEqual(try h.timerDiagnostic()["elapsed"] as? Int, 700)
        XCTAssertEqual(try h.timerDiagnostic()["text"] as? String, "14 min")
        XCTAssertFalse(h.element("journey.timer.resume").exists)
    }

    // 깨짐: 백그라운드 중 도착을 복귀 때 반영하지 않거나 버튼이 남거나 경과가 1500을 넘는다.
    func testV5_AC8_백그라운드_중_도착하면_복귀할_때_도착_상태가_된다() throws {
        let h = runningFrom("timerNearArrival")
        h.tap("test.clock.armForeground600")

        h.goBackground()

        XCTAssertTrue(h.element("alighting.briefing").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.persistedElapsed(), 1500)
        XCTAssertFalse(h.element("journey.timer.pause").exists)
        XCTAssertFalse(h.element("journey.timer.resume").exists)
        XCTAssertEqual(try h.recordCount(), 0)
    }

    // 깨짐: 종료 후 재실행이 메인이 아닌 곳으로 가거나, 미저장 5초·종료 중 시간이 반영되거나 paused로 복원되지 않는다.
    func testV5_AC11_종료_뒤_재실행하면_메인에서_마지막_체크포인트가_일시정지로_복원된다() throws {
        let h = runningFrom("timerPaused90")
        h.advance(10, times: 3)
        h.advance(1, times: 5)

        h.relaunch()

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("main.activeJourney").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.memoryElapsed(), 120)
        XCTAssertEqual(try h.memoryActive()?["paused"] as? Bool, true)
    }

    // MARK: V6 (AC-26) + 서울 전체 데이터 이전(AC-46)

    // 깨짐: 옛 형식(v3) 여정이 해석되어 되살아나거나, 이전 때 카드가 함께 사라지거나, 최초 정류장 화면이 열리지 않는다.
    // (옛 v3 출발 완료·출발 대기·카탈로그 밖 정류장 테스트 3건은 삭제: W16b에서 v1~v4 진행 여정은 내용을 해석하지 않고
    //  정류장·여정을 비우므로 "일시정지로 읽힘·v4 저장·출발 안내 유지·카탈로그 밖 정류장 판정"이라는 전제가 사라졌다.)
    func testV6_AC46_v3_여정은_해석되지_않고_비워지며_카드는_유지되고_최초_정류장_화면이_열린다() throws {
        let h = FocusMateUIHarness.launch(seed: "v3Departed", extraArguments: FocusMateUIHarness.manualClockArguments)

        XCTAssertTrue(h.element("screen.initialStationEntry").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.main").exists)
        XCTAssertNil(try h.memoryActive())
        XCTAssertGreaterThan(try h.cardCount(), 0)
    }

    // 깨짐: 현재 버전(v5)의 361분 손상 여정이 버려지지 않거나 카드·정류장이 함께 사라진다.
    func testV6_AC26_v5_361분_여정은_여정만_버려지고_카드는_유지된다() throws {
        let h = FocusMateUIHarness.launch(seed: "invalidMinutesJourney", extraArguments: FocusMateUIHarness.manualClockArguments)
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("main.activeJourney").exists)
        XCTAssertNil(try h.memoryActive())
        XCTAssertGreaterThan(try h.cardCount(), 0)
    }
}
