import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class DepartureBriefingControllerTests: XCTestCase {
    private struct Rig {
        let controller: DepartureBriefingController
        let confirmer: FakeDepartureConfirmer
        let sleeper: QueuedSleep
    }

    private func rig(results: [Bool] = [true]) -> Rig {
        let confirmer = FakeDepartureConfirmer(results: results)
        let sleeper = QueuedSleep()
        let controller = DepartureBriefingController(
            confirmer: confirmer, interval: DepartureBriefingController.interval,
            sleep: { await sleeper.sleep($0) })
        return Rig(controller: controller, confirmer: confirmer, sleeper: sleeper)
    }

    /// 안내를 끝까지 진행시켜 시작 버튼이 나온 상태로 만든다.
    private func playToEnd(_ r: Rig) async {
        let task = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 1)
        r.sleeper.resumeOldest()
        await r.sleeper.untilSuspended(count: 2)
        r.sleeper.resumeOldest()
        await task.value
    }

    // 깨짐: 문장 순서가 바뀌거나 간격이 1700ms 가 아니거나 중간에 시작 버튼이 먼저 켜지면 실패.
    func testAC17_문장이_순서대로_나온_뒤_마지막에만_시작_버튼과_포커스가_생긴다() async {
        let r = rig()
        XCTAssertEqual(DepartureBriefingController.sentences, ["문을 닫습니다", "자리에 앉아주세요", "버스 출발합니다"])

        let task = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 1)
        XCTAssertEqual(r.controller.visibleIndex, 0)
        XCTAssertFalse(r.controller.showsStart)
        XCTAssertNil(r.controller.focusTarget)

        r.sleeper.resumeOldest()
        await r.sleeper.untilSuspended(count: 2)
        XCTAssertEqual(r.controller.visibleIndex, 1)
        XCTAssertFalse(r.controller.showsStart)
        XCTAssertNil(r.controller.focusTarget)

        r.sleeper.resumeOldest()
        await task.value
        XCTAssertEqual(r.controller.visibleIndex, 2)
        XCTAssertTrue(r.controller.showsStart)
        XCTAssertEqual(r.controller.focusTarget, .startButton)
        XCTAssertEqual(r.sleeper.requested, [.milliseconds(1700), .milliseconds(1700)])
    }

    // 깨짐: 동작 줄이기에서 sleep 을 요청하거나 전체 문장/시작 버튼을 즉시 켜지 않으면 실패.
    func testAC18_동작_줄이기는_대기_없이_전체_문장과_시작_버튼을_즉시_보여준다() async {
        let r = rig()
        await r.controller.begin(reduceMotion: true)

        XCTAssertTrue(r.controller.showsAll)
        XCTAssertTrue(r.controller.showsStart)
        XCTAssertEqual(r.sleeper.requested.count, 0)
    }

    // 깨짐: 안내가 끝날 때 자동으로 confirmDeparture 를 호출하면 실패.
    func testAC19_시작을_누르지_않으면_안내가_끝나도_출발이_확정되지_않는다() async {
        let r = rig()
        await playToEnd(r)

        XCTAssertTrue(r.controller.showsStart)
        XCTAssertEqual(r.confirmer.calls, 0)
        XCTAssertFalse(r.controller.isConfirmed)
    }

    // 깨짐: 동작 줄이기 경로에서도 자동 확정하면 실패.
    func testAC19_동작_줄이기에서도_시작을_누르기_전에는_확정되지_않는다() async {
        let r = rig()
        await r.controller.begin(reduceMotion: true)

        XCTAssertEqual(r.confirmer.calls, 0)
        XCTAssertFalse(r.controller.isConfirmed)
    }

    // 깨짐: confirm 이 confirmer 를 0회·2회 부르거나 isConfirmed 를 켜지 않으면 실패.
    func testAC20_시작_버튼으로_confirm_하면_한_번_확정된다() async {
        let r = rig()
        await playToEnd(r)

        let result = r.controller.confirm()

        XCTAssertTrue(result)
        XCTAssertEqual(r.confirmer.calls, 1)
        XCTAssertTrue(r.controller.isConfirmed)
        XCTAssertFalse(r.controller.showsSaveFailure)
    }

    // 깨짐: showsStart 가드가 없어 안내 도중 confirm 이 저장을 호출하거나 true 를 돌려주면 실패.
    func testAC20_시작_버튼이_나오기_전_confirm_은_거절되고_저장하지_않는다() async {
        let r = rig()
        let task = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 1)

        let result = r.controller.confirm()

        XCTAssertFalse(result)
        XCTAssertEqual(r.confirmer.calls, 0)
        XCTAssertFalse(r.controller.isConfirmed)

        r.sleeper.resumeOldest()
        await r.sleeper.untilSuspended(count: 2)
        r.sleeper.resumeOldest()
        await task.value
    }

    // 깨짐: 실패 시 showsSaveFailure 를 켜지 않거나 시작 버튼을 숨기거나 확정 처리하면 실패.
    func testAC20_저장_실패는_오류를_표시하고_시작_버튼을_유지한다() async {
        let r = rig(results: [false])
        await playToEnd(r)

        let result = r.controller.confirm()

        XCTAssertFalse(result)
        XCTAssertTrue(r.controller.showsSaveFailure)
        XCTAssertTrue(r.controller.showsStart)
        XCTAssertFalse(r.controller.isConfirmed)
    }

    // 깨짐: 실패 뒤 재시도를 막거나 성공 후에도 실패 표시가 남으면 실패.
    func testAC20_저장_실패_뒤_다시_누르면_성공으로_확정된다() async {
        let r = rig(results: [false, true])
        await playToEnd(r)
        _ = r.controller.confirm()

        let retry = r.controller.confirm()

        XCTAssertTrue(retry)
        XCTAssertEqual(r.confirmer.calls, 2)
        XCTAssertTrue(r.controller.isConfirmed)
        XCTAssertFalse(r.controller.showsSaveFailure)
    }

    // 깨짐: reset 이 시작 버튼/포커스/index 를 되돌리지 않으면 실패.
    func testreset은_진행_상태를_처음으로_되돌린다() async {
        let r = rig()
        await playToEnd(r)

        r.controller.reset()

        XCTAssertEqual(r.controller.visibleIndex, 0)
        XCTAssertFalse(r.controller.showsStart)
        XCTAssertNil(r.controller.focusTarget)
    }

    // 깨짐: begin 이 sleep 뒤 token 을 확인하지 않아 reset 이전의 대기가 깨어나 index 를 올리면 실패.
    func testreset_뒤_이전_begin_의_대기가_풀려도_진행_상태는_바뀌지_않는다() async {
        let r = rig()
        let old = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 1)

        r.controller.reset()
        let fresh = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 2)

        r.sleeper.resume(at: 0)
        await old.value

        XCTAssertEqual(r.controller.visibleIndex, 0)
        XCTAssertFalse(r.controller.showsStart)
        XCTAssertEqual(r.sleeper.requested.count, 2)

        r.sleeper.resume(at: 1)
        await r.sleeper.untilSuspended(count: 3)
        r.sleeper.resumeOldest()
        await fresh.value
        XCTAssertEqual(r.controller.visibleIndex, 2)
        XCTAssertTrue(r.controller.showsStart)
    }
}
