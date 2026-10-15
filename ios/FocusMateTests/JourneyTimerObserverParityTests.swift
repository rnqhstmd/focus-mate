import Foundation
import XCTest
@testable import FocusMate

/// 옵저버(게이트웨이) 연결이 진도 계산을 바꾸지 않고, 알림은 정해진 시점에만 나가는지 검증한다.
@MainActor
final class JourneyTimerObserverParityTests: XCTestCase {
    private struct Notice: Equatable {
        let status: JourneyTimerController.Status
        let remaining: Int
    }

    private final class RecordingObserver: JourneyTimerObserving {
        private(set) var notices: [Notice] = []

        func timerDidChange(status: JourneyTimerController.Status, remainingSeconds: Int) {
            notices.append(Notice(status: status, remaining: remainingSeconds))
        }
    }

    private struct Rig {
        let controller: JourneyTimerController
        let clock: ManualJourneyClock
        let saver: FakeProgressSaver
        let observer: RecordingObserver?
    }

    private func makeRig(observed: Bool, results: [Bool] = []) -> Rig {
        let clock = ManualJourneyClock()
        let saver = FakeProgressSaver(results: results)
        let observer: RecordingObserver? = observed ? RecordingObserver() : nil
        let journey = BoardingFixtures.journey(minutes: 60, busID: "421", phase: .departed)
        let controller = JourneyTimerController(
            journey: journey, autoStart: true, saver: saver, clock: clock,
            ticker: clock, announcer: RecordingAnnouncer(), observer: observer
        )
        return Rig(controller: controller, clock: clock, saver: saver, observer: observer)
    }

    private func assertSameState(_ a: Rig, _ b: Rig, step: String, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertEqual(a.controller.status, b.controller.status, "status @\(step)", file: file, line: line)
        XCTAssertEqual(a.controller.elapsedSeconds, b.controller.elapsedSeconds, "elapsed @\(step)", file: file, line: line)
        XCTAssertEqual(a.controller.remainingSeconds, b.controller.remainingSeconds, "remaining @\(step)", file: file, line: line)
        XCTAssertEqual(a.saver.writes.map(\.elapsed), b.saver.writes.map(\.elapsed), "writes.elapsed @\(step)", file: file, line: line)
        XCTAssertEqual(a.saver.writes.map(\.paused), b.saver.writes.map(\.paused), "writes.paused @\(step)", file: file, line: line)
    }

    // 깨짐: 옵저버 연결 여부에 따라 status·경과·남은 시간·저장 요청이 한 단계라도 달라지면 실패한다.
    func testV15_AC28_옵저버_연결_여부와_무관하게_매_단계_진도와_저장이_같다() {
        let withObserver = makeRig(observed: true)
        let without = makeRig(observed: false)
        let both = [withObserver, without]

        both.forEach { $0.controller.appear() }
        assertSameState(withObserver, without, step: "appear")

        both.forEach { $0.clock.advance(by: .seconds(600)) }
        assertSameState(withObserver, without, step: "600초 진행")

        both.forEach { $0.controller.pause() }
        assertSameState(withObserver, without, step: "pause")

        both.forEach { $0.clock.advance(by: .seconds(100), notify: false) }
        assertSameState(withObserver, without, step: "정지 중 시간 경과")

        both.forEach { $0.controller.resume() }
        assertSameState(withObserver, without, step: "resume")

        both.forEach { $0.clock.advance(by: .seconds(3000)) }
        assertSameState(withObserver, without, step: "도착")
        XCTAssertEqual(withObserver.controller.status, .arrived)
    }

    // 깨짐: appear/pause/resume/도착 끝에서 (status, 남은 초) 알림이 빠지거나 값이 틀리면 실패한다.
    func testV15_AC28_옵저버는_appear_pause_resume_도착_끝에서_상태와_남은초를_받는다() {
        let rig = makeRig(observed: true)
        let observer = rig.observer!

        rig.controller.appear()
        XCTAssertEqual(observer.notices, [Notice(status: .running, remaining: 3600)])

        rig.clock.advance(by: .seconds(600))
        rig.controller.pause()
        XCTAssertEqual(observer.notices.last, Notice(status: .paused, remaining: 3000))

        rig.controller.resume()
        XCTAssertEqual(observer.notices.last, Notice(status: .running, remaining: 3000))

        rig.clock.advance(by: .seconds(3000))
        XCTAssertEqual(observer.notices, [
            Notice(status: .running, remaining: 3600),
            Notice(status: .paused, remaining: 3000),
            Notice(status: .running, remaining: 3000),
            Notice(status: .arrived, remaining: 0)
        ])
    }

    // 깨짐: tick이나 체크포인트 저장마다 알림을 보내면(알림 폭주) 실패한다.
    func testV15_AC28_tick과_체크포인트_저장만으로는_알림이_늘지_않는다() {
        let rig = makeRig(observed: true)
        rig.controller.appear()
        let afterAppear = rig.observer!.notices.count

        rig.clock.advance(by: .seconds(120))

        XCTAssertFalse(rig.saver.writes.isEmpty, "체크포인트 저장이 일어났어야 전제가 성립한다")
        XCTAssertEqual(rig.controller.status, .running)
        XCTAssertEqual(rig.observer!.notices.count, afterAppear)
    }

    // 깨짐: 저장 실패 정지 끝에서 알림을 보내지 않으면 실패한다.
    func testV15_AC28_저장_실패로_멈추면_일시정지_알림을_보낸다() {
        let rig = makeRig(observed: true, results: [false])
        rig.controller.appear()

        rig.clock.advance(by: .seconds(600))

        XCTAssertEqual(rig.controller.status, .paused)
        XCTAssertEqual(rig.observer!.notices.last?.status, .paused)
    }
}
