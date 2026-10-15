import Foundation
import XCTest
@testable import FocusMate

/// 타이머 컨트롤러 (T5). 시계·틱·저장·낭독을 모두 주입해 동기적으로 검증한다.
@MainActor
final class JourneyTimerControllerTests: XCTestCase {
    private static let pausedAnnouncement = "일시정지됨"
    private static let resumedAnnouncement = "재개됨"
    private static let warningAnnouncement = "진도를 저장하지 못해 멈췄어요. 재개를 눌러주세요."

    private struct Rig {
        let controller: JourneyTimerController
        let clock: ManualJourneyClock
        let saver: FakeProgressSaver
        let announcer: RecordingAnnouncer
    }

    /// 기본 여정은 25분(1500초)이다.
    private func makeRig(
        minutes: Int = 25,
        elapsed: Int = 0,
        paused: Bool = false,
        autoStart: Bool = true,
        results: [Bool] = [],
        ticker: ((ManualJourneyClock) -> JourneyTicker)? = nil
    ) -> Rig {
        let clock = ManualJourneyClock()
        let saver = FakeProgressSaver(results: results)
        let announcer = RecordingAnnouncer()
        let journey = BoardingFixtures.journey(minutes: minutes, phase: .departed, elapsedSeconds: elapsed, paused: paused)
        let controller = JourneyTimerController(
            journey: journey, autoStart: autoStart, saver: saver, clock: clock,
            ticker: ticker?(clock) ?? clock, announcer: announcer
        )
        return Rig(controller: controller, clock: clock, saver: saver, announcer: announcer)
    }

    private func running(minutes: Int = 25, elapsed: Int = 0, results: [Bool] = []) -> Rig {
        let rig = makeRig(minutes: minutes, elapsed: elapsed, results: results)
        rig.controller.appear()
        return rig
    }

    private func pausedRig(elapsed: Int, results: [Bool] = []) -> Rig {
        let rig = makeRig(elapsed: elapsed, paused: true, autoStart: false, results: results)
        rig.controller.appear()
        return rig
    }

    private func assertWrites(
        _ saver: FakeProgressSaver, _ expected: [(Int, Bool)],
        file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(saver.writes.map(\.elapsed), expected.map(\.0), file: file, line: line)
        XCTAssertEqual(saver.writes.map(\.paused), expected.map(\.1), file: file, line: line)
    }

    // MARK: AC-3 도착

    // 깨짐: 도착 판정이나 (total, true) 저장이 빠지거나, 도착 뒤 조작이 쓰기를 일으키면 실패한다.
    func testAC3_총시간이_지나면_도착_저장_1회_후_어떤_조작도_쓰기를_늘리지_않는다() {
        let rig = running(minutes: 360)

        rig.clock.advance(by: .seconds(21600))
        XCTAssertEqual(rig.controller.status, .arrived)
        assertWrites(rig.saver, [(21600, true)])

        rig.controller.appear()
        rig.controller.tick()
        rig.controller.pause()
        rig.controller.resume()
        rig.controller.enterBackground()
        rig.controller.returnToForeground()
        rig.controller.leave()
        assertWrites(rig.saver, [(21600, true)])
    }

    // MARK: AC-4 / 5 / 6 일시정지·재개

    // 깨짐: pause가 (elapsed, true)를 저장하지 않거나 ticker를 멈추지 않거나 일시정지 중에도 시간이 흐르면 실패한다.
    func testAC4_일시정지는_90초_진도를_저장하고_멈춘_동안_시간이_흐르지_않는다() {
        let rig = running(elapsed: 90)

        rig.controller.pause()
        rig.clock.advance(by: .seconds(300))

        assertWrites(rig.saver, [(90, true)])
        XCTAssertEqual(rig.controller.remainingMinutes, 24)
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertFalse(rig.clock.isTicking)
    }

    // 깨짐: resume이 (90,false)를 저장하지 않거나 재개 후 체크포인트 기준이 어긋나면 실패한다.
    func testAC5_재개는_90초에서_이어지고_60초_뒤_체크포인트를_저장한다() {
        let rig = pausedRig(elapsed: 90)

        rig.controller.resume()
        rig.clock.advance(by: .seconds(60))

        assertWrites(rig.saver, [(90, false), (150, false)])
        XCTAssertEqual(rig.controller.remainingMinutes, 23)
        XCTAssertEqual(rig.controller.status, .running)
    }

    // 깨짐: 중복 pause/resume이 추가 쓰기를 일으키거나 일시정지 구간이 진도에 더해지면 실패한다.
    func testAC6_중복_일시정지와_재개는_무시되고_진도는_running_구간만_증가한다() {
        let rig = running()

        rig.controller.pause()
        rig.controller.pause()
        rig.clock.advance(by: .seconds(5))
        rig.controller.resume()
        rig.controller.resume()
        rig.clock.advance(by: .seconds(5))

        assertWrites(rig.saver, [(0, true), (0, false)])
        XCTAssertEqual(rig.controller.elapsedSeconds, 5)
    }

    // MARK: AC-7 / 8 백그라운드

    // 깨짐: 백그라운드 즉시 저장이나 복귀 시 tick이 빠지거나, ticker를 멈추면 실패한다.
    func testAC7_백그라운드_저장_후_복귀하면_흐른_시간을_반영해_계속_달린다() {
        let rig = running(elapsed: 100)

        rig.controller.enterBackground()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.returnToForeground()

        assertWrites(rig.saver, [(100, false), (700, false)])
        XCTAssertEqual(rig.controller.status, .running)
        XCTAssertEqual(rig.controller.remainingMinutes, 14)
        XCTAssertTrue(rig.clock.isTicking)
    }

    // 깨짐: 백그라운드 중 총시간을 넘겼는데 복귀 시 도착 처리를 하지 않거나 중복 저장하면 실패한다.
    func testAC8_백그라운드_중_총시간을_넘기면_복귀_시_도착_저장_1회() {
        let rig = running(elapsed: 1400)

        rig.controller.enterBackground()
        rig.clock.advance(by: .seconds(600), notify: false)
        rig.controller.returnToForeground()

        assertWrites(rig.saver, [(1400, false), (1500, true)])
        XCTAssertEqual(rig.controller.status, .arrived)
    }

    // 깨짐: paused 상태에서 백그라운드/복귀가 저장하거나 자동 재개하면 실패한다.
    func testAC8_일시정지_상태의_백그라운드_복귀는_쓰기_없이_상태를_유지한다() {
        let rig = pausedRig(elapsed: 90)

        rig.controller.enterBackground()
        rig.controller.returnToForeground()

        XCTAssertTrue(rig.saver.writes.isEmpty)
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertEqual(rig.controller.elapsedSeconds, 90)
    }

    // MARK: AC-10 체크포인트

    // 깨짐: 체크포인트 간격이 10초보다 짧으면 9초에 쓰기가 생기고, 길면 10초에 쓰기가 없다.
    func testAC10_9초까지는_쓰지_않고_10초째에_체크포인트를_저장한다() {
        let rig = running()

        for _ in 1...9 { rig.clock.advance(by: .seconds(1)) }
        XCTAssertTrue(rig.saver.writes.isEmpty)

        rig.clock.advance(by: .seconds(1))
        assertWrites(rig.saver, [(10, false)])
    }

    // 깨짐: 재개 저장이 lastSavedElapsed를 갱신하지 않아(0 기준) 9초째에 체크포인트가 생기면 실패한다.
    func testLastSaved_재개_저장_성공이_체크포인트_기준을_갱신한다() {
        let rig = pausedRig(elapsed: 90)

        rig.controller.resume()
        for _ in 1...9 { rig.clock.advance(by: .seconds(1)) }
        assertWrites(rig.saver, [(90, false)])

        rig.clock.advance(by: .seconds(1))
        assertWrites(rig.saver, [(90, false), (100, false)])
    }

    // MARK: AC-12 / 13 / 14 도착 경계

    // 깨짐: 1440초+60초에서 도착(1500,true) 저장이 없거나 남은 분이 0이 아니면 실패한다.
    func testAC12_1440초에서_60초_지나면_도착하고_0분이다() {
        let rig = running(elapsed: 1440)

        rig.clock.advance(by: .seconds(60))

        assertWrites(rig.saver, [(1500, true)])
        XCTAssertEqual(rig.controller.remainingMinutes, 0)
        XCTAssertEqual(rig.controller.status, .arrived)
    }

    // 깨짐: 이미 도착한 여정에서 ticker를 시작하거나 appear가 저장하면 실패한다.
    func testAC13_이미_도착한_여정은_ticker를_켜지_않고_appear해도_쓰지_않는다() {
        let rig = makeRig(elapsed: 1500)

        rig.controller.appear()

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertFalse(rig.clock.isTicking)
        XCTAssertTrue(rig.saver.writes.isEmpty)
    }

    // 깨짐: 소수 초를 반올림해 1499.5초에 도착 처리하거나, 틱 사이 도달을 백그라운드가 놓치면 실패한다.
    func testAC14_백그라운드_진입에서_총시간_도달을_감지하면_도착_저장_1회() {
        let rig = running(elapsed: 1499)

        rig.clock.advance(by: .milliseconds(500), notify: false)
        rig.clock.advance(by: .milliseconds(600), notify: false)
        rig.controller.enterBackground()
        rig.controller.tick()
        rig.controller.returnToForeground()

        assertWrites(rig.saver, [(1500, true)])
        XCTAssertEqual(rig.controller.elapsedSeconds, 1500)
        XCTAssertEqual(rig.controller.status, .arrived)
    }

    // 깨짐: elapsed를 올림/반올림하면 1499.5초에 "0 min"+arrived가 된다.
    func testAC14_경계_1499점5초는_1분이고_아직_running이다() {
        let rig = running(elapsed: 1499)

        rig.clock.advance(by: .milliseconds(500), notify: false)
        rig.controller.tick()

        XCTAssertEqual(rig.controller.remainingMinutes, 1)
        XCTAssertEqual(rig.controller.status, .running)
        XCTAssertTrue(rig.saver.writes.isEmpty)
    }

    // 깨짐: arrived에서 resume/pause가 저장하거나 상태를 바꾸면 실패한다.
    func testAC14_도착_상태에서_재개와_일시정지는_무시된다() {
        let rig = running(elapsed: 1500)
        rig.clock.advance(by: .seconds(1))
        let before = rig.saver.writes.count

        rig.controller.resume()
        rig.controller.pause()

        XCTAssertEqual(rig.saver.writes.count, before)
        XCTAssertEqual(rig.controller.status, .arrived)
    }

    // MARK: AC-15 / 16 저장 실패

    // 깨짐: 일시정지 저장 실패에도 멈추거나 실패 표시를 안 하면, 또는 재시도 성공 후 표시가 남으면 실패한다.
    func testAC15_일시정지_저장_실패는_달리는_채로_실패를_표시하고_재시도로_해제된다() {
        let rig = running(results: [false, true])

        rig.controller.pause()
        XCTAssertEqual(rig.controller.status, .running)
        XCTAssertTrue(rig.controller.showsTransitionFailure)

        rig.clock.advance(by: .seconds(5))
        XCTAssertEqual(rig.controller.elapsedSeconds, 5)

        rig.controller.pause()
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertFalse(rig.controller.showsTransitionFailure)
        assertWrites(rig.saver, [(0, true), (5, true)])
    }

    // 깨짐: 체크포인트 실패 시 일시정지·경고·1회 낭독이 없거나, 멈춘 뒤에도 시간이 흐르거나, 재개가 경고를 못 지우면 실패한다.
    func testAC16_체크포인트_실패는_멈추고_경고를_1회_낭독하며_재개로_해제된다() {
        let rig = running(results: [false, true])

        rig.clock.advance(by: .seconds(10))
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertTrue(rig.controller.showsSaveWarning)
        XCTAssertEqual(rig.announcer.messages, [Self.warningAnnouncement])

        rig.clock.advance(by: .seconds(60))
        XCTAssertEqual(rig.controller.remainingMinutes, 25)

        rig.controller.resume()
        XCTAssertEqual(rig.controller.status, .running)
        XCTAssertFalse(rig.controller.showsSaveWarning)
        assertWrites(rig.saver, [(10, false), (10, false)])
    }

    // 깨짐: 경고 중 재개 실패 때 경고를 끄거나 전환 실패 표시를 켜면 실패한다.
    func testAC16_경고_중_재개가_실패하면_경고를_유지하고_전환_실패는_켜지_않는다() {
        let rig = running(results: [false, false])

        rig.clock.advance(by: .seconds(10))
        rig.controller.resume()

        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertTrue(rig.controller.showsSaveWarning)
        XCTAssertFalse(rig.controller.showsTransitionFailure)
    }

    // 깨짐: 백그라운드 저장 실패를 무시하고 달리면, 또는 재개가 재시도하지 않으면 실패한다.
    func testBg실패_백그라운드_저장_실패는_멈추고_경고하며_재개가_재시도한다() {
        let rig = running(elapsed: 50, results: [false])

        rig.controller.enterBackground()
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertTrue(rig.controller.showsSaveWarning)

        rig.controller.resume()
        XCTAssertEqual(rig.controller.status, .running)
        assertWrites(rig.saver, [(50, false), (50, false)])
    }

    // 깨짐: 도착 저장 실패 후 appear 재시도가 없거나, 성공 뒤에도 계속 재시도하면 실패한다.
    func testAppear재시도_도착_저장_실패는_경고하고_appear에서_1회_재시도한다() {
        let rig = running(elapsed: 1440, results: [false, true])

        rig.clock.advance(by: .seconds(60))
        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertTrue(rig.controller.showsSaveWarning)

        rig.controller.appear()
        rig.controller.appear()
        rig.controller.enterBackground()

        assertWrites(rig.saver, [(1500, true), (1500, true)])
    }

    // 깨짐: 백그라운드 진입에서 도착 저장을 재시도하지 않으면 실패한다.
    func testBg재시도_도착_저장_실패는_백그라운드_진입에서_재시도한다() {
        let rig = running(elapsed: 1440, results: [false, true])

        rig.clock.advance(by: .seconds(60))
        rig.controller.enterBackground()
        rig.controller.enterBackground()

        assertWrites(rig.saver, [(1500, true), (1500, true)])
    }

    // MARK: MUST-A / MUST-B

    // 깨짐: 저장된 paused=false만 보고 자동 시작하면(앵커 설정·ticker 시작) 실패한다.
    func testMUSTA_autoStart_false면_paused_false여도_멈춘_채_시작한다() {
        let rig = makeRig(elapsed: 30, paused: false, autoStart: false)

        rig.controller.appear()
        rig.clock.advance(by: .seconds(5))

        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertFalse(rig.clock.isTicking)
        XCTAssertEqual(rig.controller.elapsedSeconds, 30)
        XCTAssertTrue(rig.saver.writes.isEmpty)
    }

    // 깨짐: autoStart를 무시하고 항상 paused로 시작하면 실패한다.
    func testMUSTA_autoStart_true면_running으로_시작한다() {
        let rig = makeRig(autoStart: true)

        rig.controller.appear()

        XCTAssertEqual(rig.controller.status, .running)
        XCTAssertTrue(rig.clock.isTicking)
    }

    // 깨짐: appear가 앵커를 다시 잡으면 진도가 되돌아가고(15가 아님), ticker를 매번 재시작하면 start가 3회가 된다.
    func testMUSTB_appear를_반복해도_앵커와_ticker가_유지된다() {
        var counting: CountingTicker?
        let rig = makeRig(ticker: { clock in
            let c = CountingTicker(base: clock)
            counting = c
            return c
        })

        rig.controller.appear()
        rig.clock.advance(by: .seconds(5))
        rig.controller.appear()
        rig.clock.advance(by: .seconds(5))
        rig.controller.appear()
        rig.clock.advance(by: .seconds(5))

        XCTAssertEqual(rig.controller.elapsedSeconds, 15)
        XCTAssertEqual(counting?.startCount, 1)
    }

    // MARK: AC-28 / 32 / leave / 수명

    // 깨짐: 낭독 문구가 다르거나 전환마다 낭독하지 않거나, 시간 변화까지 낭독하면 실패한다.
    func testAC28_일시정지와_재개만_순서대로_낭독한다() {
        let rig = running()

        rig.controller.pause()
        rig.controller.resume()
        rig.clock.advance(by: .seconds(60))

        XCTAssertEqual(rig.announcer.messages, [Self.pausedAnnouncement, Self.resumedAnnouncement])
    }

    // 깨짐: 진도를 clock.now 차이로 계산하지 않고 틱 횟수로 세면 60초 1회 틱에서 1만 증가한다.
    func testAC32_60초가_한_번에_흐르면_진도는_60초_증가한다() {
        let rig = running()

        rig.clock.advance(by: .seconds(60))

        XCTAssertEqual(rig.controller.elapsedSeconds, 60)
        XCTAssertEqual(rig.controller.remainingMinutes, 24)
    }

    // 깨짐: leave가 (elapsed, true) 저장·정지를 하지 않거나 낭독하면 실패한다.
    func testLeave_이탈은_진도를_일시정지로_저장하고_멈추며_낭독하지_않는다() {
        let rig = running(elapsed: 30)

        rig.controller.leave()

        assertWrites(rig.saver, [(30, true)])
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertFalse(rig.clock.isTicking)
        XCTAssertTrue(rig.announcer.messages.isEmpty)
    }

    // 깨짐: 컨트롤러가 ticker 콜백에 강하게 잡혀 해제되지 않거나 해제 후에도 ticker가 돌면 실패한다.
    func testLifetime_컨트롤러를_해제하면_약참조가_비고_ticker가_멈춘다() {
        let clock = ManualJourneyClock()
        var controller: JourneyTimerController? = JourneyTimerController(
            journey: BoardingFixtures.journey(phase: .departed), autoStart: true,
            saver: FakeProgressSaver(), clock: clock, ticker: clock, announcer: RecordingAnnouncer()
        )
        weak var weakController = controller
        controller?.appear()
        XCTAssertTrue(clock.isTicking)

        controller = nil

        XCTAssertNil(weakController)
        XCTAssertFalse(clock.isTicking)
    }

    // MARK: R1 재현 (리뷰 지적)

    // 깨짐: 재개 저장 실패에서 일시정지 유지·실패 표시가 없거나, 재시도 성공 후 표시가 남거나 쓰기가 누락된다.
    func testR1_일시정지_상태의_재개_저장_실패는_멈춘_채_실패를_표시하고_재시도로_해제된다() {
        let rig = pausedRig(elapsed: 90, results: [false, true])

        rig.controller.resume()
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertTrue(rig.controller.showsTransitionFailure)
        assertWrites(rig.saver, [(90, false)])

        rig.controller.resume()
        XCTAssertEqual(rig.controller.status, .running)
        XCTAssertFalse(rig.controller.showsTransitionFailure)
        assertWrites(rig.saver, [(90, false), (90, false)])
    }

    // 깨짐: 총시간 도달 직후의 pause가 도착 처리 대신 일시정지로 저장하거나 "일시정지됨"을 낭독한다.
    func testR1_이미_총시간에_도달한_running에서_pause하면_도착으로_저장하고_낭독하지_않는다() {
        let rig = running(elapsed: 1490)

        rig.clock.advance(by: .seconds(20), notify: false)
        rig.controller.pause()

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertEqual(rig.saver.writes.last?.elapsed, 1500)
        XCTAssertEqual(rig.saver.writes.last?.paused, true)
        XCTAssertFalse(rig.announcer.messages.contains(Self.pausedAnnouncement))
    }

    // 깨짐: 체크포인트 실패 후 재개한 뒤 체크포인트 기준이 갱신되지 않아 9초 안에 쓰거나 10초째에 쓰지 않는다.
    func testR1_체크포인트_실패_후_재개하면_재개_시점부터_10초째에_다시_저장한다() {
        let rig = running(results: [false, true, true])

        rig.clock.advance(by: .seconds(10))
        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertTrue(rig.controller.showsSaveWarning)
        rig.controller.resume()
        XCTAssertEqual(rig.controller.status, .running)
        assertWrites(rig.saver, [(10, false), (10, false)])

        for _ in 0..<9 { rig.clock.advance(by: .seconds(1)) }
        assertWrites(rig.saver, [(10, false), (10, false)])

        rig.clock.advance(by: .seconds(1))
        assertWrites(rig.saver, [(10, false), (10, false), (20, false)])
    }

    // MARK: 리뷰 fix 라운드 1 재현

    // 깨짐: 도착 시 전환 실패 안내를 지우지 않으면 arrived인데 showsTransitionFailure가 true로 남는다.
    func testRV3_전환_실패_후_도착하면_전환_실패_안내가_사라진다() {
        let rig = running(elapsed: 1440, results: [false])

        rig.controller.pause()
        XCTAssertTrue(rig.controller.showsTransitionFailure)

        rig.clock.advance(by: .seconds(60))

        XCTAssertEqual(rig.controller.status, .arrived)
        XCTAssertFalse(rig.controller.showsTransitionFailure)
    }

    // 깨짐: 체크포인트 실패로 멈출 때 전환 실패 안내를 지우지 않으면 경고와 안내가 동시에 true가 된다.
    func testRV3_전환_실패_후_체크포인트_실패로_멈추면_저장_경고만_남는다() {
        let rig = running(results: [false, false])

        rig.controller.pause()
        XCTAssertTrue(rig.controller.showsTransitionFailure)

        rig.clock.advance(by: .seconds(10))

        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertTrue(rig.controller.showsSaveWarning)
        XCTAssertFalse(rig.controller.showsTransitionFailure)
    }
}
