import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class JourneyAbandonControllerTests: XCTestCase {
    private func rig(_ results: [LifecycleActionResult] = [.done])
        -> (controller: JourneyAbandonController, abandoner: FakeJourneyAbandoner) {
        let abandoner = FakeJourneyAbandoner(results: results)
        return (JourneyAbandonController(abandoner: abandoner), abandoner)
    }

    // 깨짐: 일시정지 중 request가 확인창을 열지 않거나, 두 번째 request가 상태를 바꾸면 실패.
    func testAC21_확인창_요청_두_번은_하나로_취급한다() {
        let r = rig()
        r.controller.request(isPaused: true)
        XCTAssertTrue(r.controller.isConfirming)
        r.controller.cancel()
        r.controller.request(isPaused: true)
        r.controller.request(isPaused: true)
        XCTAssertTrue(r.controller.isConfirming)
        XCTAssertEqual(r.abandoner.calls, [])
    }

    // 깨짐: 일시정지가 아닐 때 확인창이 열리면 실패 (BR-6).
    func testBR6_일시정지가_아니면_확인창을_열지_않는다() {
        let r = rig()
        r.controller.request(isPaused: false)
        XCTAssertFalse(r.controller.isConfirming)
        XCTAssertNil(r.controller.focusTarget)
        XCTAssertEqual(r.abandoner.calls, [])
    }

    // 깨짐: 취소가 닫지 않거나 포기를 호출하거나 포커스를 포기 버튼으로 돌리지 않으면 실패.
    func testAC15_취소하면_닫히고_호출은_없고_포커스는_포기_버튼이다() {
        let r = rig()
        r.controller.request(isPaused: true)
        r.controller.cancel()
        XCTAssertFalse(r.controller.isConfirming)
        XCTAssertEqual(r.abandoner.calls, [])
        XCTAssertEqual(r.controller.focusTarget, .abandonButton)
        XCTAssertFalse(r.controller.hasFinished)
    }

    // 깨짐: 확정이 isPaused 인자를 그대로 넘기지 않거나 닫지 않거나 완료 표시를 안 하면 실패.
    func testAC21_확정하면_닫히고_포기를_한_번_호출하며_완료된다() {
        let r = rig([.done])
        r.controller.request(isPaused: true)
        let result = r.controller.confirm(isPaused: true)
        XCTAssertEqual(result, .done)
        XCTAssertFalse(r.controller.isConfirming)
        XCTAssertTrue(r.controller.hasFinished)
        XCTAssertNil(r.controller.focusTarget)
        XCTAssertEqual(r.abandoner.calls, [true])
    }

    // 깨짐: 완료 뒤 두 번째 확정이 abandoner를 다시 호출하면 실패.
    func testAC21_확정_두_번은_호출_한_번이다() {
        let r = rig([.done])
        r.controller.request(isPaused: true)
        r.controller.confirm(isPaused: true)
        r.controller.confirm(isPaused: true)
        XCTAssertEqual(r.abandoner.calls.count, 1)
    }

    // 깨짐: 확정이 isConfirming에 의존해 확인-후-취소 순서에서 호출이 사라지거나 포커스가 남으면 실패 (R2).
    func testAC21_확정_뒤_취소가_와도_호출은_한_번이고_포커스는_없다() {
        let r = rig([.done])
        r.controller.request(isPaused: true)
        r.controller.confirm(isPaused: true)
        r.controller.cancel()
        XCTAssertEqual(r.abandoner.calls.count, 1)
        XCTAssertNil(r.controller.focusTarget)
        XCTAssertFalse(r.controller.isConfirming)
    }

    // 깨짐: 취소가 먼저 와서 isConfirming이 꺼진 뒤 확정이 무시되거나, 완료 후 포커스가 남으면 실패 (R2).
    func testAC21_취소_뒤_확정이_와도_호출은_한_번이고_포커스는_없다() {
        let r = rig([.done])
        r.controller.request(isPaused: true)
        r.controller.cancel()
        r.controller.confirm(isPaused: true)
        XCTAssertEqual(r.abandoner.calls.count, 1)
        XCTAssertNil(r.controller.focusTarget)
        XCTAssertTrue(r.controller.hasFinished)
    }

    // 깨짐: 일시정지 아님 인자를 abandoner에 전달하지 않거나 .rejected에 표시를 띄우면 실패 (BR-6).
    func testBR6_거절되면_실패_표시_없이_인자를_그대로_전달한다() {
        let r = rig([.rejected])
        let result = r.controller.confirm(isPaused: false)
        XCTAssertEqual(result, .rejected)
        XCTAssertEqual(r.abandoner.calls, [false])
        XCTAssertFalse(r.controller.showsFailure)
        XCTAssertFalse(r.controller.hasFinished)
    }

    // 깨짐: 저장 실패에 실패 표시·포커스를 안 두거나 완료 처리해 버리면 실패.
    func testAC20_저장_실패는_실패_표시와_포기_버튼_포커스를_남긴다() {
        let r = rig([.saveFailed])
        r.controller.request(isPaused: true)
        let result = r.controller.confirm(isPaused: true)
        XCTAssertEqual(result, .saveFailed)
        XCTAssertTrue(r.controller.showsFailure)
        XCTAssertEqual(r.controller.focusTarget, .abandonButton)
        XCTAssertFalse(r.controller.hasFinished)
        XCTAssertFalse(r.controller.isConfirming)
    }

    // 깨짐: 실패 뒤 재요청이 실패 표시를 지우지 않거나 재확정이 막히면 실패.
    func testAC20_실패_뒤_다시_시도하면_성공한다() {
        let r = rig([.saveFailed, .done])
        r.controller.request(isPaused: true)
        r.controller.confirm(isPaused: true)
        r.controller.request(isPaused: true)
        XCTAssertFalse(r.controller.showsFailure)
        XCTAssertTrue(r.controller.isConfirming)
        let result = r.controller.confirm(isPaused: true)
        XCTAssertEqual(result, .done)
        XCTAssertEqual(r.abandoner.calls, [true, true])
        XCTAssertTrue(r.controller.hasFinished)
        XCTAssertNil(r.controller.focusTarget)
        XCTAssertFalse(r.controller.showsFailure)
    }

    // 깨짐: clearFailure가 실패 표시를 끄지 않으면 실패.
    func testAC20_실패_표시를_닫으면_사라진다() {
        let r = rig([.saveFailed])
        r.controller.confirm(isPaused: true)
        r.controller.clearFailure()
        XCTAssertFalse(r.controller.showsFailure)
    }

    // 깨짐: 성공 뒤 request가 다시 확인창을 열면 실패.
    func testAC21_완료_뒤_요청은_무시한다() {
        let r = rig([.done])
        r.controller.confirm(isPaused: true)
        r.controller.request(isPaused: true)
        XCTAssertFalse(r.controller.isConfirming)
    }
}
