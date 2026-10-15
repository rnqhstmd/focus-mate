import CoreGraphics
import Foundation
import XCTest
@testable import FocusMate

/// 하차 저장 결과를 순서대로 돌려주고 호출 수를 센다. 결과가 소진되면 true.
@MainActor
private final class FakeJourneyAlighter: JourneyAlighting {
    private var results: [Bool]
    private(set) var calls = 0

    init(results: [Bool] = [true]) { self.results = results }

    func alightJourney() -> Bool {
        calls += 1
        return results.isEmpty ? true : results.removeFirst()
    }
}

@MainActor
final class AlightingTagControllerTests: XCTestCase {
    private static let success = "집중동행카드 인식됨, 하차했습니다"
    private static let failure = "저장하지 못했어요. 다시 눌러주세요."

    private final class FinishBox {
        var controller: BoardingTagController?
        var finishedPhases: [BoardingTagController.Phase] = []
    }

    private struct Rig {
        let controller: BoardingTagController
        let alighter: FakeJourneyAlighter
        let haptics: FakeIssuanceHaptics
        let announcer: RecordingAnnouncer
        let sleeper: SuspendingSleep   // contact / fade
        let holdSleeper: SuspendingSleep
        let box: FinishBox
    }

    // 태그 영역 (0,0,238,160), 카드 휴식 위치 (-15,300,268,168). dy -240 → 겹침 0.625 접촉.
    private func rig(results: [Bool] = [true]) -> Rig {
        let alighter = FakeJourneyAlighter(results: results)
        let haptics = FakeIssuanceHaptics(isSupported: true)
        let announcer = RecordingAnnouncer()
        let sleeper = SuspendingSleep()
        let holdSleeper = SuspendingSleep()
        let box = FinishBox()
        let controller = BoardingTagController(
            alighter: alighter, haptics: haptics, announcer: announcer,
            sleep: { await sleeper.sleep($0) },
            holdSleep: { await holdSleeper.sleep($0) },
            onFinished: { box.finishedPhases.append(box.controller?.phase ?? .ready) })
        box.controller = controller
        controller.updateLayout(
            cardRest: CGRect(x: -15, y: 300, width: 268, height: 168),
            tagArea: CGRect(x: 0, y: 0, width: 238, height: 160))
        return Rig(controller: controller, alighter: alighter, haptics: haptics, announcer: announcer,
                   sleeper: sleeper, holdSleeper: holdSleeper, box: box)
    }

    private func dragToContact(_ r: Rig) {
        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: false)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -240), reduceMotion: false)
    }

    private func reachHeld(_ r: Rig) async {
        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value
        await r.holdSleeper.untilSuspended()
    }

    // 깨짐: 터치만으로 하차를 저장하거나 탭 힌트를 켜지 않으면 실패.
    func test끌지_않고_터치만_하면_하차_저장_없이_탭_힌트가_나온다() {
        let r = rig()
        r.controller.dragEnded(translation: CGSize(width: 3, height: 2), reduceMotion: false)

        XCTAssertEqual(r.alighter.calls, 0)
        XCTAssertTrue(r.controller.showsTapHint)
        XCTAssertEqual(r.controller.phase, .ready)
    }

    // 깨짐: activate 가 접촉 대기 뒤 alightJourney 를 정확히 1회 부르지 않으면 실패.
    func test활성화하면_끌기_없이_접촉_대기_뒤_하차_저장_1회() async {
        let r = rig()
        r.controller.activate(reduceMotion: false)

        XCTAssertEqual(r.controller.phase, .contacting)
        XCTAssertEqual(r.alighter.calls, 0)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.alighter.calls, 1)
        XCTAssertEqual(r.controller.phase, .held)
    }

    // 깨짐: 접촉 대기 중 추가 접촉이 저장을 중복 호출하면 실패.
    func test인식_직후_접촉_대기_중_세_번_더_접촉해도_하차_저장은_1회() async {
        let r = rig()
        r.controller.activate(reduceMotion: false)
        r.controller.activate(reduceMotion: false)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: false)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -240), reduceMotion: false)
        r.controller.activate(reduceMotion: false)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.alighter.calls, 1)
        XCTAssertEqual(r.announcer.messages, [Self.success])
        XCTAssertEqual(r.haptics.patterns.count, 1)
    }

    // 깨짐: 실패를 failed/표시/하차 실패 낭독으로 처리하지 않거나 재시도가 하차를 다시 부르지 않으면 실패.
    func test하차_저장_실패는_failed와_실패_낭독이고_다시_활성화하면_성공_전환한다() async {
        let r = rig(results: [false, true])
        r.controller.activate(reduceMotion: false)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.controller.phase, .failed)
        XCTAssertTrue(r.controller.showsSaveFailure)
        XCTAssertEqual(r.announcer.messages, [Self.failure])

        r.controller.activate(reduceMotion: false)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.alighter.calls, 2)
        XCTAssertEqual(r.controller.phase, .held)
        XCTAssertEqual(r.announcer.messages, [Self.failure, Self.success])
    }

    // 깨짐: hold 1400 / fade 450 대기를 지키지 않거나 finished 설정 전에 onFinished 를 부르면 실패.
    func test성공_뒤_유지_1400_페이드_450이_지나면_finished로_onFinished_1회() async {
        let r = rig()
        await reachHeld(r)
        XCTAssertEqual(r.holdSleeper.requested, [.milliseconds(1400)])
        XCTAssertEqual(r.announcer.messages, [Self.success])

        r.holdSleeper.resume()
        await r.sleeper.untilSuspended()
        XCTAssertEqual(r.sleeper.requested, [.milliseconds(300), .milliseconds(450)])
        r.sleeper.resume()
        await r.controller.pendingTransition?.value

        XCTAssertEqual(r.box.finishedPhases, [.finished])
    }

    // 깨짐: 승차 문구가 바뀌거나 하차 문구가 다르면 실패.
    func test카드_태그_문구는_승차는_기존과_같고_하차는_하차_문구다() {
        XCTAssertEqual(CardTagCopy.boarding.recognizedAnnouncement, "집중동행카드 인식됨, 승차했습니다")
        XCTAssertEqual(CardTagCopy.boarding.failedAnnouncement, "승차 정보를 저장하지 못했어요. 카드를 다시 대주세요.")
        XCTAssertEqual(CardTagCopy.alighting.recognizedAnnouncement, "집중동행카드 인식됨, 하차했습니다")
        XCTAssertEqual(CardTagCopy.alighting.failedAnnouncement, "저장하지 못했어요. 다시 눌러주세요.")
    }

    // 깨짐: alightingSaved 가 false 인데 종료 판단을 하면 실패.
    func test하차_저장_전이면_모든_phase에서_종료하지_않는다() {
        let phases: [BoardingTagController.Phase] = [
            .ready, .dragging, .contacting, .held, .fading, .finished, .failed, .abandoned,
        ]
        for phase in phases {
            XCTAssertFalse(AlightingTagRecovery.shouldFinish(phase: phase, alightingSaved: false), "\(phase)")
        }
    }

    // 깨짐: 접촉·유지·페이드 중에 종료시키거나 그 외 phase 에서 복구 종료를 안 하면 실패.
    func test하차_저장_뒤에는_접촉_유지_페이드만_기다리고_나머지는_종료한다() {
        let waiting: [BoardingTagController.Phase] = [.contacting, .held, .fading]
        let finishing: [BoardingTagController.Phase] = [.ready, .dragging, .failed, .abandoned, .finished]
        for phase in waiting {
            XCTAssertFalse(AlightingTagRecovery.shouldFinish(phase: phase, alightingSaved: true), "\(phase)")
        }
        for phase in finishing {
            XCTAssertTrue(AlightingTagRecovery.shouldFinish(phase: phase, alightingSaved: true), "\(phase)")
        }
    }

    // 깨짐: 중단 후 복귀한 컨트롤러가 ready 로 안 가거나 스스로 onFinished 를 부르면 실패(복구는 화면 몫).
    func test접촉_대기_중_중단_뒤_복귀하면_저장_성공_후_ready이고_화면_복구가_종료를_판단한다() async {
        let r = rig()
        r.controller.activate(reduceMotion: false)
        await r.sleeper.untilSuspended()
        r.controller.cancelPendingTransition()
        r.controller.returnToForeground()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.alighter.calls, 1)
        XCTAssertEqual(r.controller.phase, .ready)
        XCTAssertTrue(AlightingTagRecovery.shouldFinish(phase: r.controller.phase, alightingSaved: true))
        XCTAssertEqual(r.box.finishedPhases.count, 0)
    }
}
