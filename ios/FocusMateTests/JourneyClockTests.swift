import Foundation
import XCTest
@testable import FocusMate

/// 단조 시계·틱 (T2). 벽시계가 아니라 주입 가능한 시계와 틱으로 시간 경과를 제어한다.
@MainActor
final class JourneyClockTests: XCTestCase {
    private final class Counter {
        var value = 0
    }

    // MARK: ManualJourneyClock

    // 깨짐: advance가 now를 증가시키지 않으면(예: 빈 구현) 실패한다.
    func test_수동_시계는_advance만큼_now가_증가한다() {
        let clock = ManualJourneyClock()
        XCTAssertEqual(clock.now, .zero)

        clock.advance(by: .seconds(60))
        clock.advance(by: .seconds(5), notify: false)

        XCTAssertEqual(clock.now, .seconds(65))
    }

    // 깨짐: advance가 틱을 부르지 않거나 두 번 부르면 실패한다.
    func test_수동_시계는_ticking_중_advance마다_onTick을_정확히_1회_부른다() {
        let clock = ManualJourneyClock()
        let ticks = Counter()
        clock.start { ticks.value += 1 }

        clock.advance(by: .seconds(1))

        XCTAssertEqual(ticks.value, 1)
        XCTAssertTrue(clock.isTicking)
    }

    // 깨짐: notify 플래그를 무시하고 항상 틱을 부르면 실패한다.
    func test_수동_시계는_notify_false면_onTick을_부르지_않는다() {
        let clock = ManualJourneyClock()
        let ticks = Counter()
        clock.start { ticks.value += 1 }

        clock.advance(by: .seconds(30), notify: false)

        XCTAssertEqual(ticks.value, 0)
        XCTAssertEqual(clock.now, .seconds(30))
    }

    // 깨짐: start가 구독을 교체하지 않고 이전 콜백을 유지하면 실패한다.
    func test_수동_시계는_start_재호출_시_이전_콜백을_부르지_않는다() {
        let clock = ManualJourneyClock()
        let first = Counter()
        let second = Counter()
        clock.start { first.value += 1 }
        clock.start { second.value += 1 }

        clock.advance(by: .seconds(1))

        XCTAssertEqual(first.value, 0)
        XCTAssertEqual(second.value, 1)
    }

    // 깨짐: stop이 isTicking을 내리지 않거나 콜백을 계속 부르면 실패한다.
    func test_수동_시계는_stop_후_isTicking이_false이고_콜백이_없다() {
        let clock = ManualJourneyClock()
        let ticks = Counter()
        clock.start { ticks.value += 1 }
        clock.stop()

        clock.advance(by: .seconds(1))

        XCTAssertFalse(clock.isTicking)
        XCTAssertEqual(ticks.value, 0)
        XCTAssertEqual(clock.now, .seconds(1))
    }

    // 깨짐: apply가 arm한 양을 반영하지 않거나 onTick을 부르면 실패한다.
    func test_수동_시계는_arm한_포그라운드_진행을_apply에서_반영하고_틱은_부르지_않는다() {
        let clock = ManualJourneyClock()
        let ticks = Counter()
        clock.start { ticks.value += 1 }

        clock.armForegroundAdvance(by: .seconds(90))
        XCTAssertEqual(clock.now, .zero, "arm만으로는 시간이 흐르지 않는다")
        clock.applyArmedForegroundAdvance()

        XCTAssertEqual(clock.now, .seconds(90))
        XCTAssertEqual(ticks.value, 0)
    }

    // 깨짐: apply 후 arm을 해제하지 않아 두 번째 apply가 또 시간을 올리면 실패한다.
    func test_수동_시계는_arm한_진행을_1회만_적용한다() {
        let clock = ManualJourneyClock()
        clock.armForegroundAdvance(by: .seconds(90))

        clock.applyArmedForegroundAdvance()
        clock.applyArmedForegroundAdvance()

        XCTAssertEqual(clock.now, .seconds(90))
    }

    // MARK: TaskJourneyTicker

    private func settle() async {
        for _ in 0..<5 { await Task.yield() }
    }

    // 깨짐: sleep 1회 완료에 onTick을 부르지 않거나 두 번 부르면 실패한다.
    func test_틱커는_sleep_1회_진행마다_onTick을_1회_부른다() async {
        let sleeper = QueuedSleep()
        let ticker = TaskJourneyTicker(sleep: { await sleeper.sleep($0) })
        let ticks = Counter()
        ticker.start { ticks.value += 1 }
        await sleeper.untilSuspended(count: 1)
        XCTAssertEqual(ticks.value, 0, "sleep이 끝나기 전에는 틱이 없다")

        sleeper.resume(at: 0)
        await sleeper.untilSuspended(count: 2)

        XCTAssertEqual(ticks.value, 1)
        XCTAssertTrue(ticker.isTicking)
        ticker.stop()
    }

    // 깨짐: 루프가 한 번만 돌고 끝나면 실패한다.
    func test_틱커는_3회_진행하면_onTick을_3회_부른다() async {
        let sleeper = QueuedSleep()
        let ticker = TaskJourneyTicker(sleep: { await sleeper.sleep($0) })
        let ticks = Counter()
        ticker.start { ticks.value += 1 }

        for position in 0..<3 {
            await sleeper.untilSuspended(count: position + 1)
            sleeper.resume(at: position)
        }
        await sleeper.untilSuspended(count: 4)

        XCTAssertEqual(ticks.value, 3)
        ticker.stop()
    }

    // 깨짐: stop이 루프를 cancel하지 않거나 cancel 확인 없이 onTick을 부르면 실패한다.
    func test_틱커는_stop_후_sleep이_끝나도_onTick을_부르지_않는다() async {
        let sleeper = QueuedSleep()
        let ticker = TaskJourneyTicker(sleep: { await sleeper.sleep($0) })
        let ticks = Counter()
        ticker.start { ticks.value += 1 }
        await sleeper.untilSuspended(count: 1)

        ticker.stop()
        sleeper.resume(at: 0)
        await settle()

        XCTAssertEqual(ticks.value, 0)
        XCTAssertFalse(ticker.isTicking)
    }

    // 깨짐: start가 이전 루프를 cancel하지 않으면 이전 콜백이 불려 실패한다.
    func test_틱커는_start_재호출_시_이전_루프를_cancel한다() async {
        let sleeper = QueuedSleep()
        let ticker = TaskJourneyTicker(sleep: { await sleeper.sleep($0) })
        let first = Counter()
        let second = Counter()
        ticker.start { first.value += 1 }
        await sleeper.untilSuspended(count: 1)
        let firstLoop = ticker.loop

        ticker.start { second.value += 1 }
        await sleeper.untilSuspended(count: 2)
        XCTAssertEqual(firstLoop?.isCancelled, true)

        sleeper.resume(at: 0)
        sleeper.resume(at: 1)
        await sleeper.untilSuspended(count: 3)

        XCTAssertEqual(first.value, 0)
        XCTAssertEqual(second.value, 1)
        ticker.stop()
    }

    // MARK: ContinuousJourneyClock

    // 깨짐: 단조가 아닌 시계(감소 가능)를 쓰면 실패한다.
    func test_연속_시계는_두_번_읽은_now가_감소하지_않는다() {
        let clock = ContinuousJourneyClock()

        let first = clock.now
        let second = clock.now

        XCTAssertGreaterThanOrEqual(second, first)
    }
}
