import CoreGraphics
import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class BoardingTagControllerTests: XCTestCase {
    private static let success = "집중동행카드 인식됨, 승차했습니다"
    private static let failure = "승차 정보를 저장하지 못했어요. 카드를 다시 대주세요."

    /// onFinished 호출 시점의 phase 를 담는 상자.
    private final class FinishBox {
        var controller: BoardingTagController?
        var finishedPhases: [BoardingTagController.Phase] = []
    }

    private struct Rig {
        let controller: BoardingTagController
        let boarder: FakeJourneyBoarder
        let haptics: FakeIssuanceHaptics
        let announcer: RecordingAnnouncer
        let sleeper: SuspendingSleep   // contact / fade
        let holdSleeper: SuspendingSleep
        let box: FinishBox
    }

    // 시안 R27 기하: 태그 영역 (0,0,149,76), 카드 휴식 위치 (-60.5,260,270,158).
    // dy -240 → 카드 위쪽 20, 겹침 149x56/149x76 = 0.737 접촉, dy -150 → 위쪽 110, 겹침 없음 미접촉.
    // 위로 최대 -260, 아래로 +20, 좌우 ±26.
    private func rig(results: [Bool] = [true]) -> Rig {
        let boarder = FakeJourneyBoarder(results: results)
        let haptics = FakeIssuanceHaptics(isSupported: true)
        let announcer = RecordingAnnouncer()
        let sleeper = SuspendingSleep()
        let holdSleeper = SuspendingSleep()
        let box = FinishBox()
        let controller = BoardingTagController(
            boarder: boarder, haptics: haptics, announcer: announcer,
            sleep: { await sleeper.sleep($0) },
            holdSleep: { await holdSleeper.sleep($0) },
            onFinished: { box.finishedPhases.append(box.controller?.phase ?? .ready) })
        box.controller = controller
        controller.updateLayout(
            cardRest: CGRect(x: -60.5, y: 260, width: 270, height: 158),
            tagArea: CGRect(x: 0, y: 0, width: 149, height: 76))
        return Rig(controller: controller, boarder: boarder, haptics: haptics, announcer: announcer,
                   sleeper: sleeper, holdSleeper: holdSleeper, box: box)
    }

    /// 작은 이동으로 dragging 에 들어간 뒤 접촉 위치까지 끌어 인식시킨다.
    private func dragToContact(_ r: Rig, reduceMotion: Bool = false) {
        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: reduceMotion)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -240), reduceMotion: reduceMotion)
    }

    /// 인식 → contact resume → 저장 완료 → held (hold 수면 정지) 까지 진행한다.
    private func reachHeld(_ r: Rig) async {
        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value
        await r.holdSleeper.untilSuspended()
    }

    // 깨짐: dragChanged 가 접촉을 판정하지 않거나 햅틱을 안 울리거나 offset 을 clamp 하지 않으면 실패.
    func testAC6_놓기_전_dragChanged만으로_접촉하면_contacting_햅틱_1_offset_clamp() {
        let r = rig()
        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: false)
        r.controller.dragChanged(translation: CGSize(width: 100, height: -240), reduceMotion: false)

        XCTAssertEqual(r.controller.phase, .contacting)
        XCTAssertEqual(r.haptics.patterns, [IssuanceHapticPattern.boardingContact])
        XCTAssertEqual(r.controller.cardOffset, CGSize(width: 26, height: -240))
    }

    // 깨짐: dragEnded 가 인식하거나 원위치로 되돌리지 않으면 실패.
    func testAC6_불변식_dragEnded는_임계를_넘어도_인식하지_않고_원위치로_돌린다() {
        let r = rig()
        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: false)
        r.controller.dragEnded(translation: CGSize(width: 0, height: -240), reduceMotion: false)

        XCTAssertEqual(r.controller.phase, .ready)
        XCTAssertEqual(r.controller.cardOffset, .zero)
        XCTAssertEqual(r.haptics.patterns.count, 0)
        XCTAssertEqual(r.boarder.calls, 0)
    }

    // 깨짐: 30% 미만에서 놓았는데 ready 로 안 돌아가거나 저장·햅틱이 발생하면 실패.
    func testAC7_30퍼센트_미만에서_놓으면_원위치_ready_저장_없음() {
        let r = rig()
        r.controller.dragChanged(translation: CGSize(width: 0, height: -150), reduceMotion: false)
        XCTAssertEqual(r.controller.phase, .dragging)
        r.controller.dragEnded(translation: CGSize(width: 0, height: -150), reduceMotion: false)

        XCTAssertEqual(r.controller.phase, .ready)
        XCTAssertEqual(r.controller.cardOffset, .zero)
        XCTAssertEqual(r.boarder.calls, 0)
        XCTAssertEqual(r.haptics.patterns.count, 0)
    }

    // 깨짐: x/y clamp 를 적용하지 않거나 순서 갱신(마지막 값 기준)을 안 하면 실패.
    func testAC8_dragChanged_순서대로_cardOffset이_clamp된다() {
        let r = rig()
        r.controller.dragChanged(translation: CGSize(width: 0, height: -100), reduceMotion: false)
        XCTAssertEqual(r.controller.cardOffset, CGSize(width: 0, height: -100))
        r.controller.dragChanged(translation: CGSize(width: 100, height: -100), reduceMotion: false)
        XCTAssertEqual(r.controller.cardOffset, CGSize(width: 26, height: -100))
        r.controller.dragChanged(translation: CGSize(width: -100, height: 90), reduceMotion: false)
        XCTAssertEqual(r.controller.cardOffset, CGSize(width: -26, height: 20))
        XCTAssertEqual(r.controller.phase, .dragging)
    }

    // 깨짐: 탭 판정(tapSlop 미만)을 안 하거나 저장하거나 힌트를 안 켜면 실패.
    func testAC9_tapSlop_미만으로_놓으면_바운스_1_힌트_저장_없음() {
        let r = rig()
        r.controller.dragEnded(translation: CGSize(width: 3, height: 2), reduceMotion: false)

        XCTAssertEqual(r.controller.tapBounceCount, 1)
        XCTAssertTrue(r.controller.showsTapHint)
        XCTAssertEqual(r.controller.phase, .ready)
        XCTAssertEqual(r.boarder.calls, 0)
    }

    // 깨짐: activate 가 activationOffset(0,-214.8)으로 두지 않거나 낭독을 1회가 아니게 하면 실패.
    // h = 0.3*76 + 8 = 30.8 → 카드 위쪽 45.2 → offset y = 45.2-260 = -214.8, 중심 정렬이라 x 0.
    func testAC10_activate는_활성_위치로_옮기고_낭독_1회_저장_1회() async {
        let r = rig()
        r.controller.activate(reduceMotion: false)

        XCTAssertEqual(r.controller.cardOffset.width, 0, accuracy: 0.001)
        XCTAssertEqual(r.controller.cardOffset.height, -214.8, accuracy: 0.001)
        XCTAssertEqual(r.controller.phase, .contacting)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.announcer.messages, [Self.success])
        XCTAssertEqual(r.boarder.calls, 1)
    }

    // 깨짐: contact 대기가 300ms 가 아니거나 저장을 즉시 하거나 held 로 안 가거나 onFinished 를 일찍 부르면 실패.
    func testAC11_접촉_300ms_뒤_저장_1회_held_onFinished_없음() async {
        let r = rig()
        dragToContact(r)
        await r.sleeper.untilSuspended()
        XCTAssertEqual(r.sleeper.requested, [.milliseconds(300)])
        XCTAssertEqual(r.boarder.calls, 0)

        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.boarder.calls, 1)
        XCTAssertEqual(r.controller.phase, .held)
        XCTAssertEqual(r.box.finishedPhases.count, 0)
    }

    // 깨짐: held 에서 입력을 다시 인식하면 저장·햅틱·낭독이 늘어 실패.
    func testAC12_held에서_drag_activate_dragEnded는_무시된다() async {
        let r = rig()
        await reachHeld(r)
        let offset = r.controller.cardOffset

        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: false)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -240), reduceMotion: false)
        r.controller.activate(reduceMotion: false)
        r.controller.dragEnded(translation: CGSize(width: 0, height: -240), reduceMotion: false)

        XCTAssertEqual(r.boarder.calls, 1)
        XCTAssertEqual(r.haptics.patterns.count, 1)
        XCTAssertEqual(r.announcer.messages.count, 1)
        XCTAssertEqual(r.controller.phase, .held)
        XCTAssertEqual(r.controller.cardOffset, offset)
    }

    // 깨짐: hold→fading→finished 순서가 틀리거나 onFinished 를 finished 설정 전에 부르면 실패.
    func testAC13_hold_fade_뒤_finished_상태로_onFinished_1회() async {
        let r = rig()
        await reachHeld(r)
        XCTAssertEqual(r.holdSleeper.requested, [.milliseconds(1400)])

        r.holdSleeper.resume()
        await r.sleeper.untilSuspended()
        XCTAssertEqual(r.controller.phase, .fading)
        XCTAssertEqual(r.sleeper.requested, [.milliseconds(300), .milliseconds(450)])

        r.sleeper.resume()
        await r.controller.pendingTransition?.value

        XCTAssertEqual(r.box.finishedPhases, [.finished])
    }

    // 깨짐: contacting 중 취소가 저장을 막거나 hold 를 예약하거나 abandoned 가 아니면 실패.
    func testAC14_contacting_중_취소해도_저장은_수행되고_abandoned_hold_없음() async {
        let r = rig()
        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.controller.cancelPendingTransition()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.boarder.calls, 1)
        XCTAssertEqual(r.announcer.messages, [Self.success])
        XCTAssertEqual(r.controller.phase, .abandoned)
        XCTAssertEqual(r.holdSleeper.requested.count, 0)
        XCTAssertNil(r.controller.pendingTransition)
        XCTAssertEqual(r.box.finishedPhases.count, 0)
    }

    // 깨짐: held 취소 뒤에도 hold 가 끝나 fading/onFinished 로 가면 실패.
    func testAC15_held_중_취소하면_hold가_끝나도_onFinished_없음() async {
        let r = rig()
        await reachHeld(r)
        r.controller.cancelPendingTransition()
        XCTAssertEqual(r.controller.phase, .abandoned)
        r.holdSleeper.resume()
        await r.controller.pendingTransition?.value

        XCTAssertEqual(r.box.finishedPhases.count, 0)
        XCTAssertEqual(r.controller.phase, .abandoned)
    }

    // 깨짐: fading 취소 뒤 fade 가 끝나 onFinished 를 부르면 실패.
    func testAC15_fading_중_취소하면_fade가_끝나도_onFinished_없음() async {
        let r = rig()
        await reachHeld(r)
        r.holdSleeper.resume()
        await r.sleeper.untilSuspended()
        XCTAssertEqual(r.controller.phase, .fading)
        r.controller.cancelPendingTransition()
        r.sleeper.resume()
        await r.controller.pendingTransition?.value

        XCTAssertEqual(r.box.finishedPhases.count, 0)
        XCTAssertEqual(r.controller.phase, .abandoned)
    }

    // 깨짐: dragging 중 취소가 원위치 ready 로 되돌리지 않거나 저장하면 실패.
    func testAC16_dragging_중_취소하면_원위치_ready_저장_없음() {
        let r = rig()
        r.controller.dragChanged(translation: CGSize(width: 0, height: -100), reduceMotion: false)
        XCTAssertEqual(r.controller.phase, .dragging)
        r.controller.cancelPendingTransition()

        XCTAssertEqual(r.controller.phase, .ready)
        XCTAssertEqual(r.controller.cardOffset, .zero)
        XCTAssertEqual(r.boarder.calls, 0)
        XCTAssertNil(r.controller.pendingSave)
    }

    // 깨짐: abandoned 에서 입력을 받아 재인식하면 저장·햅틱이 늘어 실패.
    func testAC16_abandoned에서_drag와_activate는_무시된다() async {
        let r = rig()
        await reachHeld(r)
        r.controller.cancelPendingTransition()

        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: false)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -240), reduceMotion: false)
        r.controller.activate(reduceMotion: false)

        XCTAssertEqual(r.controller.phase, .abandoned)
        XCTAssertEqual(r.boarder.calls, 1)
        XCTAssertEqual(r.haptics.patterns.count, 1)
    }

    // 깨짐: returnToForeground 가 abandoned 를 ready/LCD ready/offset zero 로 복원하지 않으면 실패.
    func testAC16_복귀하면_abandoned가_ready로_돌아가고_다시_태그하면_교체_저장() async {
        let r = rig()
        await reachHeld(r)
        r.controller.cancelPendingTransition()
        r.controller.returnToForeground()

        XCTAssertEqual(r.controller.phase, .ready)
        XCTAssertEqual(r.controller.cardOffset, .zero)
        XCTAssertEqual(r.controller.lcd, .ready)
        XCTAssertFalse(r.controller.isRecognized)

        r.controller.activate(reduceMotion: false)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value
        XCTAssertEqual(r.boarder.calls, 2)
    }

    // 깨짐: contacting 취소 + 복귀 뒤 저장이 성공해도 ready 로 안 돌아가면 실패.
    func testAC16_contacting_취소_뒤_복귀하면_저장_성공_즉시_ready() async {
        let r = rig()
        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.controller.cancelPendingTransition()
        r.controller.returnToForeground()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.boarder.calls, 1)
        XCTAssertEqual(r.controller.phase, .ready)
        XCTAssertEqual(r.controller.cardOffset, .zero)
        XCTAssertEqual(r.holdSleeper.requested.count, 0)
    }

    // 깨짐: 실패 시 failed/표시/offset zero/실패 낭독이 아니거나 재시도가 안 되면 실패.
    func testAC21_저장_실패는_failed_실패_낭독이고_다시_태그하면_성공한다() async {
        let r = rig(results: [false, true])
        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.controller.phase, .failed)
        XCTAssertTrue(r.controller.showsSaveFailure)
        XCTAssertEqual(r.controller.cardOffset, .zero)
        XCTAssertEqual(r.announcer.messages, [Self.failure])

        r.controller.activate(reduceMotion: false)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.boarder.calls, 2)
        XCTAssertEqual(r.controller.phase, .held)
        XCTAssertEqual(r.announcer.messages, [Self.failure, Self.success])
    }

    // 깨짐: contacting 취소 뒤 실패를 무시하고 abandoned 로 가거나 hold 를 예약하면 실패.
    func testAC21_contacting_중_취소_뒤_저장_실패는_failed_hold_없음() async {
        let r = rig(results: [false])
        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.controller.cancelPendingTransition()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.controller.phase, .failed)
        XCTAssertEqual(r.announcer.messages, [Self.failure])
        XCTAssertEqual(r.holdSleeper.requested.count, 0)
    }

    // 깨짐: 동작 줄이기에서 햅틱을 울리거나 300/450 을 대기하거나 hold 1400 을 생략하거나 낭독이 늦으면 실패.
    func testAC22_동작_줄이기는_햅틱_없고_300_450_대기_없이_hold_1400만_대기한다() async {
        let r = rig()
        dragToContact(r, reduceMotion: true)
        await r.controller.pendingSave?.value
        await r.holdSleeper.untilSuspended()

        XCTAssertEqual(r.haptics.patterns.count, 0)
        XCTAssertEqual(r.announcer.messages, [Self.success])
        XCTAssertEqual(r.boarder.calls, 1)
        XCTAssertEqual(r.holdSleeper.requested, [.milliseconds(1400)])

        r.holdSleeper.resume()
        await r.controller.pendingTransition?.value

        XCTAssertEqual(r.sleeper.requested.count, 0)
        XCTAssertEqual(r.box.finishedPhases, [.finished])
    }

    // MARK: 리뷰 R1 — 실패 뒤 같은 동작 재인식 금지

    // 깨짐: failed 뒤 손가락을 떼지 않은 채 이어지는 dragChanged 가 다시 접촉을 인식하면 저장·낭독·햅틱이 늘어 실패.
    func testR1_저장_실패_뒤_같은_동작의_dragChanged는_다시_인식하지_않는다() async {
        let r = rig(results: [false, true])
        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value
        XCTAssertEqual(r.controller.phase, .failed)

        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: false)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -240), reduceMotion: false)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -250), reduceMotion: false)
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.boarder.calls, 1)
        XCTAssertEqual(r.announcer.messages, [Self.failure])
        XCTAssertEqual(r.haptics.patterns.count, 1)
        XCTAssertEqual(r.sleeper.requested.count, 1)
    }

    // 깨짐: 동작 줄이기에서도 같은 동작의 dragChanged 로 저장이 반복되면 실패.
    func testR1_동작_줄이기에서도_저장_실패_뒤_같은_동작은_다시_인식하지_않는다() async {
        let r = rig(results: [false, true])
        dragToContact(r, reduceMotion: true)
        await r.controller.pendingSave?.value
        XCTAssertEqual(r.controller.phase, .failed)

        r.controller.dragChanged(translation: CGSize(width: 0, height: -20), reduceMotion: true)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -240), reduceMotion: true)
        r.controller.dragChanged(translation: CGSize(width: 0, height: -250), reduceMotion: true)
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.boarder.calls, 1)
        XCTAssertEqual(r.announcer.messages, [Self.failure])
        XCTAssertEqual(r.haptics.patterns.count, 0)
    }

    // 깨짐: dragEnded 뒤의 새 동작까지 막아 재시도가 영영 안 되면 실패.
    func testR1_손을_뗀_뒤_새_동작에서는_실패_후에도_다시_태그할_수_있다() async {
        let r = rig(results: [false, true])
        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value
        XCTAssertEqual(r.controller.phase, .failed)
        r.controller.dragEnded(translation: CGSize(width: 0, height: -240), reduceMotion: false)

        dragToContact(r)
        await r.sleeper.untilSuspended()
        r.sleeper.resume()
        await r.controller.pendingSave?.value

        XCTAssertEqual(r.boarder.calls, 2)
        XCTAssertEqual(r.controller.phase, .held)
    }
}
