import Foundation
import XCTest
@testable import FocusMate

final class JourneyPlanDraftTests: XCTestCase {
    private let origin = StopPosition(index: 0, direction: 1)

    private func draft(minutes: Int) -> JourneyPlanDraft {
        var draft = JourneyPlanDraft()
        draft.setMinutes(minutes)
        return draft
    }

    func test_setMinutes는_14를_15로_361을_360으로_맞춘다() {
        var low = JourneyPlanDraft()
        low.setMinutes(14)
        XCTAssertEqual(low.minutes, 15)
        var high = JourneyPlanDraft()
        high.setMinutes(361)
        XCTAssertEqual(high.minutes, 360)
    }

    func test_setMinutes는_경계값_15와_360을_허용한다() {
        XCTAssertEqual(draft(minutes: 15).minutes, 15)
        XCTAssertEqual(draft(minutes: 360).minutes, 360)
    }

    func test_clamp로_값이_그대로면_선택이_유지된다() {
        var d = draft(minutes: 15)
        XCTAssertTrue(d.choose(busID: "2014", from: origin))
        d.setMinutes(14)
        XCTAssertEqual(d.minutes, 15)
        XCTAssertEqual(d.selectedBusID, "2014")
    }

    func test_기본_draft는_25분이고_선택이_없다() {
        let d = JourneyPlanDraft()
        XCTAssertEqual(d.minutes, 25)
        XCTAssertNil(d.selectedBusID)
    }

    func test_기본_draft의_후보는_2014_서울숲_입구_5정류장_1건이다() {
        let result = JourneyPlanDraft().candidates(from: origin)
        XCTAssertEqual(result.map(\.bus.id), ["2014"])
        XCTAssertEqual(result.map(\.destination), ["서울숲 입구"])
        XCTAssertEqual(result.map(\.stops), [5])
    }

    func test_후보가_있고_선택이_없으면_needsSelection이며_진행할_수_없다() {
        let state = JourneyPlanDraft().proceedState(from: origin)
        XCTAssertEqual(state, .needsSelection)
        XCTAssertEqual(state.title, "버스와 도착지를 선택하세요")
        XCTAssertFalse(state.isEnabled)
    }

    func test_17분은_후보가_없어_noCandidates이며_진행할_수_없다() {
        let d = draft(minutes: 17)
        XCTAssertEqual(d.candidates(from: origin), [])
        let state = d.proceedState(from: origin)
        XCTAssertEqual(state, .noCandidates)
        XCTAssertEqual(state.title, "이 시간의 도착 후보가 없어요")
        XCTAssertFalse(state.isEnabled)
    }

    func test_60분_선택_없음은_needsSelection이며_진행할_수_없다() {
        let state = draft(minutes: 60).proceedState(from: origin)
        XCTAssertEqual(state, .needsSelection)
        XCTAssertFalse(state.isEnabled)
    }

    func test_60분에서_2014를_선택하면_성공하고_선택_후보가_2014다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(d.choose(busID: "2014", from: origin))
        XCTAssertEqual(d.selectedCandidate(from: origin)?.bus.id, "2014")
    }

    func test_다른_버스를_선택하면_선택이_302로_교체된다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(d.choose(busID: "2014", from: origin))
        XCTAssertTrue(d.choose(busID: "302", from: origin))
        XCTAssertEqual(d.selectedBusID, "302")
        XCTAssertEqual(d.selectedCandidate(from: origin)?.bus.id, "302")
    }

    func test_선택된_상태의_proceedState는_ready이며_JourneySelection을_담는다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(d.choose(busID: "2014", from: origin))
        let state = d.proceedState(from: origin)
        XCTAssertEqual(state, .ready(JourneySelection(
            origin: StopPosition(index: 0, direction: 1),
            minutes: 60,
            busID: "2014",
            busNumber: "2014",
            destination: "성동구민체육센터",
            stops: 12
        )))
        XCTAssertEqual(state.title, "이 여정 준비하기")
        XCTAssertTrue(state.isEnabled)
    }

    func test_60분에서_421_선택은_거부되고_선택이_바뀌지_않는다() {
        var d = draft(minutes: 60)
        XCTAssertFalse(d.choose(busID: "421", from: origin))
        XCTAssertNil(d.selectedBusID)
        XCTAssertNil(d.selectedCandidate(from: origin))
    }

    func test_실패한_선택은_기존_선택을_유지한다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(d.choose(busID: "2014", from: origin))
        XCTAssertFalse(d.choose(busID: "421", from: origin))
        XCTAssertEqual(d.selectedBusID, "2014")
    }

    func test_시간이_바뀌면_선택이_해제되고_같은_값으로_되돌려도_복원되지_않는다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(d.choose(busID: "2014", from: origin))
        d.setMinutes(61)
        XCTAssertNil(d.selectedBusID)
        XCTAssertEqual(d.proceedState(from: origin), .noCandidates)
        d.setMinutes(60)
        XCTAssertNil(d.selectedBusID)
        XCTAssertEqual(d.proceedState(from: origin), .needsSelection)
    }

    func test_같은_버스가_새_시간에도_후보여도_시간이_바뀌면_선택이_해제된다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(d.choose(busID: "2014", from: origin))
        d.setMinutes(120)
        XCTAssertNil(d.selectedBusID)
    }

    func test_originUnavailable은_안내_문구를_가지며_진행할_수_없다() {
        XCTAssertEqual(ProceedState.originUnavailable.title, "출발 정류장을 확인할 수 없어요")
        XCTAssertFalse(ProceedState.originUnavailable.isEnabled)
    }
}
