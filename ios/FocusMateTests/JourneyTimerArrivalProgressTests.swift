import Foundation
import XCTest
@testable import FocusMate

/// JourneyTimerController 의 ArrivalProgress 채택 검증.
@MainActor
final class JourneyTimerArrivalProgressTests: XCTestCase {
    private struct Rig {
        let controller: JourneyTimerController
        let clock: ManualJourneyClock
        let saver: FakeProgressSaver
    }

    private func makeRig(elapsed: Int, paused: Bool = false, autoStart: Bool = true, results: [Bool] = []) -> Rig {
        let clock = ManualJourneyClock()
        let saver = FakeProgressSaver(results: results)
        let journey = BoardingFixtures.journey(minutes: 25, phase: .departed, elapsedSeconds: elapsed, paused: paused)
        let controller = JourneyTimerController(
            journey: journey, autoStart: autoStart, saver: saver, clock: clock,
            ticker: clock, announcer: RecordingAnnouncer())
        return Rig(controller: controller, clock: clock, saver: saver)
    }

    // 깨짐: isArrived가 status == .arrived 와 연결되지 않으면 실패.
    func test총_시간까지_경과한_타이머는_도착_상태다() {
        let r = makeRig(elapsed: 1500, autoStart: false)
        r.controller.appear()
        let progress: ArrivalProgress = r.controller
        XCTAssertTrue(progress.isArrived)
    }

    // 깨짐: 항상 true를 돌려주면 실패.
    func test진행_중인_타이머는_도착_상태가_아니다() {
        let r = makeRig(elapsed: 100)
        r.controller.appear()
        let progress: ArrivalProgress = r.controller
        XCTAssertFalse(progress.isArrived)
    }

    // 깨짐: 미도착인데 저장을 시도하면 실패.
    func test도착_전에는_ensureArrivalSaved가_저장을_시도하지_않는다() {
        let r = makeRig(elapsed: 100)
        r.controller.appear()
        let before = r.saver.writes.count

        _ = r.controller.ensureArrivalSaved()

        XCTAssertEqual(r.saver.writes.count, before)
    }

    // 깨짐: 재시도 저장이 (총 시간, paused true)가 아니거나 성공 값을 돌려주지 않으면 실패.
    func test도착_저장이_실패했으면_ensureArrivalSaved가_한_번_더_저장하고_성공을_돌려준다() {
        let r = makeRig(elapsed: 1499, results: [false])
        r.controller.appear()
        r.clock.advance(by: .seconds(1))
        XCTAssertEqual(r.controller.status, .arrived)
        XCTAssertEqual(r.saver.writes.map(\.elapsed), [1500])

        let saved = r.controller.ensureArrivalSaved()

        XCTAssertTrue(saved)
        XCTAssertEqual(r.saver.writes.map(\.elapsed), [1500, 1500])
        XCTAssertEqual(r.saver.writes.map(\.paused), [true, true])
    }

    // 깨짐: 이미 저장 성공인데 또 저장하면 실패.
    func test이미_저장_성공한_도착은_ensureArrivalSaved가_추가_저장_없이_true다() {
        let r = makeRig(elapsed: 1499, results: [true])
        r.controller.appear()
        r.clock.advance(by: .seconds(1))
        XCTAssertEqual(r.saver.writes.count, 1)

        let saved = r.controller.ensureArrivalSaved()

        XCTAssertTrue(saved)
        XCTAssertEqual(r.saver.writes.count, 1)
    }
}
