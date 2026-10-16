import Foundation
import XCTest
@testable import FocusMate

@MainActor
private final class FakeArrivalProgress: ArrivalProgress {
    var isArrived = true
    private(set) var ensureCalls = 0
    func ensureArrivalSaved() -> Bool {
        ensureCalls += 1
        return true
    }
}

@MainActor
private final class FakeArrivalConfirmer: ArrivalConfirming {
    private var results: [LifecycleActionResult]
    private(set) var timerArrivedArgs: [Bool] = []
    private weak var progress: FakeArrivalProgress?
    private(set) var ensureCallsAtConfirm: [Int] = []

    init(results: [LifecycleActionResult] = [.done], progress: FakeArrivalProgress? = nil) {
        self.results = results
        self.progress = progress
    }

    func confirmArrival(timerArrived: Bool) -> LifecycleActionResult {
        timerArrivedArgs.append(timerArrived)
        ensureCallsAtConfirm.append(progress?.ensureCalls ?? -1)
        return results.isEmpty ? .done : results.removeFirst()
    }
}

@MainActor
final class ArrivalBriefingControllerTests: XCTestCase {
    private struct Rig {
        let controller: ArrivalBriefingController
        let progress: FakeArrivalProgress
        let confirmer: FakeArrivalConfirmer
        let sleeper: QueuedSleep
    }

    private func content() -> ArrivalBriefingContent {
        let journey = BoardingFixtures.journey(
            minutes: 25, busID: "2014", destinationStopID: "seoulForestGate", destinationName: "서울숲 입구",
            phase: .departed, elapsedSeconds: 1500)
        return ArrivalBriefingContent(journey: journey)
    }

    private func rig(results: [LifecycleActionResult] = [.done]) -> Rig {
        let progress = FakeArrivalProgress()
        let confirmer = FakeArrivalConfirmer(results: results, progress: progress)
        let sleeper = QueuedSleep()
        let controller = ArrivalBriefingController(
            content: content(), progress: progress, confirmer: confirmer,
            interval: .milliseconds(1700), sleep: { await sleeper.sleep($0) })
        return Rig(controller: controller, progress: progress, confirmer: confirmer, sleeper: sleeper)
    }

    private func playToEnd(_ r: Rig) async {
        let task = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 1)
        r.sleeper.resumeOldest()
        await r.sleeper.untilSuspended(count: 2)
        r.sleeper.resumeOldest()
        await task.value
    }

    // 깨짐: 문구·경로 텍스트 조립이 바뀌면 실패.
    func test도착_안내_내용은_경로_문구와_세_문장을_만든다() {
        let c = content()
        XCTAssertEqual(c.routeText, "2014 · 서울숲 입구 도착")
        XCTAssertEqual(c.sentences, ["곧 서울숲 입구에 도착합니다", "버스가 멈추면 일어나주세요", "카드를 찍고 내려주세요"])
    }

    // 깨짐: 번호·도착지 이름을 카탈로그가 아니라 저장된 여정 값에서 가져오지 않으면 실패(카탈로그 밖 id여도 만들어진다).
    func test카탈로그_밖_id여도_저장된_값으로_내용이_만들어진다() {
        let journey = BoardingFixtures.journey(
            busID: "no-such-bus", busNumber: "N37", destinationStopID: "no-such-stop", destinationName: "저장된 도착지",
            phase: .departed)
        let c = ArrivalBriefingContent(journey: journey)
        XCTAssertEqual(c.routeText, "N37 · 저장된 도착지 도착")
        XCTAssertEqual(c.sentences.first, "곧 저장된 도착지에 도착합니다")
    }

    // 깨짐: 간격이 1700ms가 아니거나 순서가 틀리거나 중간에 확인 버튼이 먼저 켜지면 실패.
    func test문장이_순서대로_나온_뒤_마지막에만_확인_버튼과_포커스가_생긴다() async {
        let r = rig()
        let task = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 1)
        XCTAssertEqual(r.controller.visibleIndex, 0)
        XCTAssertFalse(r.controller.showsConfirm)
        XCTAssertNil(r.controller.focusTarget)

        r.sleeper.resumeOldest()
        await r.sleeper.untilSuspended(count: 2)
        XCTAssertEqual(r.controller.visibleIndex, 1)
        XCTAssertFalse(r.controller.showsConfirm)

        r.sleeper.resumeOldest()
        await task.value
        XCTAssertEqual(r.controller.visibleIndex, 2)
        XCTAssertTrue(r.controller.showsConfirm)
        XCTAssertEqual(r.controller.focusTarget, .confirmButton)
        XCTAssertEqual(r.sleeper.requested, [.milliseconds(1700), .milliseconds(1700)])
    }

    // 깨짐: 동작 줄이기에서 sleep을 요청하거나 전체/확인을 즉시 켜지 않으면 실패.
    func test동작_줄이기는_대기_없이_전체_문장과_확인_버튼을_보여준다() async {
        let r = rig()
        await r.controller.begin(reduceMotion: true)
        XCTAssertTrue(r.controller.showsAll)
        XCTAssertTrue(r.controller.showsConfirm)
        XCTAssertEqual(r.controller.visibleIndex, 2)
        XCTAssertEqual(r.sleeper.requested.count, 0)
    }

    // 깨짐: reset이 index/확인 버튼을 되돌리지 않으면 실패.
    func testreset_뒤_다시_시작하면_처음부터_진행한다() async {
        let r = rig()
        await playToEnd(r)
        r.controller.reset()
        XCTAssertEqual(r.controller.visibleIndex, 0)
        XCTAssertFalse(r.controller.showsConfirm)

        let again = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 3)
        XCTAssertEqual(r.controller.visibleIndex, 0)
        XCTAssertFalse(r.controller.showsConfirm)
        r.sleeper.resumeOldest()
        await r.sleeper.untilSuspended(count: 4)
        r.sleeper.resumeOldest()
        await again.value
    }

    // 깨짐: sleep 뒤 토큰을 확인하지 않아 reset 이전 대기가 index를 올리면 실패.
    func test진행_중_reset되면_이전_begin은_더_진행하지_않는다() async {
        let r = rig()
        let old = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 1)
        r.controller.reset()

        r.sleeper.resume(at: 0)
        await old.value

        XCTAssertEqual(r.controller.visibleIndex, 0)
        XCTAssertFalse(r.controller.showsConfirm)
        XCTAssertEqual(r.sleeper.requested.count, 1)
    }

    // 깨짐: showsConfirm 가드가 없어 확인 전 confirm이 저장·확정을 부르면 실패.
    func test확인_버튼이_나오기_전_confirm은_거절되고_확정을_부르지_않는다() async {
        let r = rig()
        let task = Task { await r.controller.begin(reduceMotion: false) }
        await r.sleeper.untilSuspended(count: 1)

        let result = r.controller.confirm()

        XCTAssertEqual(result, .rejected)
        XCTAssertEqual(r.confirmer.timerArrivedArgs.count, 0)
        XCTAssertEqual(r.progress.ensureCalls, 0)

        r.sleeper.resumeOldest()
        await r.sleeper.untilSuspended(count: 2)
        r.sleeper.resumeOldest()
        await task.value
    }

    // 깨짐: ensureArrivalSaved를 안 부르거나 confirmer 뒤에 부르거나 isArrived를 넘기지 않으면 실패.
    func test확인하면_도착_저장을_먼저_보장한_뒤_확정하고_done을_돌려준다() async {
        let r = rig()
        r.progress.isArrived = false
        await playToEnd(r)

        let result = r.controller.confirm()

        XCTAssertEqual(result, .done)
        XCTAssertEqual(r.progress.ensureCalls, 1)
        XCTAssertEqual(r.confirmer.ensureCallsAtConfirm, [1])
        XCTAssertEqual(r.confirmer.timerArrivedArgs, [false])
    }

    // 깨짐: 저장 실패 때 showsSaveFailure를 켜지 않으면 실패.
    func test확정_저장_실패는_실패_표시를_켠다() async {
        let r = rig(results: [.saveFailed])
        await playToEnd(r)

        let result = r.controller.confirm()

        XCTAssertEqual(result, .saveFailed)
        XCTAssertTrue(r.controller.showsSaveFailure)
        XCTAssertTrue(r.controller.showsConfirm)
    }

    // 깨짐: 재시도에서 ensureArrivalSaved를 다시 부르지 않거나 성공 뒤 실패 표시가 남으면 실패.
    func test저장_실패_뒤_다시_확인하면_저장을_다시_보장하고_실패_표시가_사라진다() async {
        let r = rig(results: [.saveFailed, .done])
        await playToEnd(r)
        _ = r.controller.confirm()

        let retry = r.controller.confirm()

        XCTAssertEqual(retry, .done)
        XCTAssertEqual(r.progress.ensureCalls, 2)
        XCTAssertFalse(r.controller.showsSaveFailure)
    }
}
