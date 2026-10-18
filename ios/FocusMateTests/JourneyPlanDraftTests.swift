import Foundation
import XCTest
@testable import FocusMate

final class JourneyPlanDraftTests: XCTestCase {
    private let catalog = BoardingFixtures.uiCatalog()

    private var origin: RouteOrigin {
        let index = catalog.stopIndex(id: "seongsu")!
        return RouteOrigin(stopIndex: index, stopID: "seongsu", name: "성수역", boundLabel: "성수동 방면")
    }

    private func draft(minutes: Int) -> JourneyPlanDraft {
        var draft = JourneyPlanDraft()
        draft.setMinutes(minutes)
        return draft
    }

    private func choose(_ d: inout JourneyPlanDraft, _ routeID: String) -> Bool {
        d.choose(routeID: routeID, origin: origin, catalog: catalog)
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
        XCTAssertTrue(choose(&d, "2014"))
        d.setMinutes(14)
        XCTAssertEqual(d.minutes, 15)
        XCTAssertEqual(d.selectedRouteID, "2014")
    }

    func test_기본_draft는_25분이고_선택이_없다() {
        let d = JourneyPlanDraft()
        XCTAssertEqual(d.minutes, 25)
        XCTAssertNil(d.selectedRouteID)
    }

    func test_기본_draft의_후보는_2014_서울숲_입구_5정류장_1건이다() {
        let result = JourneyPlanDraft().candidates(origin: origin, catalog: catalog)
        XCTAssertEqual(result.map(\.routeID), ["2014"])
        XCTAssertEqual(result.map(\.destination), ["서울숲 입구"])
        XCTAssertEqual(result.map(\.stops), [5])
    }

    func test_후보가_있고_선택이_없으면_needsSelection이며_진행할_수_없다() {
        let state = JourneyPlanDraft().proceedState(origin: origin, catalog: catalog)
        XCTAssertEqual(state, .needsSelection)
        XCTAssertEqual(state.title, "버스와 도착지를 선택하세요")
        XCTAssertFalse(state.isEnabled)
    }

    func test_17분은_후보가_없어_noCandidates이며_진행할_수_없다() {
        let d = draft(minutes: 17)
        XCTAssertEqual(d.candidates(origin: origin, catalog: catalog), [])
        let state = d.proceedState(origin: origin, catalog: catalog)
        XCTAssertEqual(state, .noCandidates)
        XCTAssertEqual(state.title, "이 시간의 도착 후보가 없어요")
        XCTAssertFalse(state.isEnabled)
    }

    func test_60분_선택_없음은_needsSelection이며_진행할_수_없다() {
        let state = draft(minutes: 60).proceedState(origin: origin, catalog: catalog)
        XCTAssertEqual(state, .needsSelection)
        XCTAssertFalse(state.isEnabled)
    }

    func test_60분에서_2014를_선택하면_성공하고_선택_후보가_2014다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(choose(&d, "2014"))
        XCTAssertEqual(d.selectedCandidate(origin: origin, catalog: catalog)?.routeID, "2014")
    }

    func test_다른_버스를_선택하면_선택이_302로_교체된다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(choose(&d, "2014"))
        XCTAssertTrue(choose(&d, "302"))
        XCTAssertEqual(d.selectedRouteID, "302")
        XCTAssertEqual(d.selectedCandidate(origin: origin, catalog: catalog)?.routeID, "302")
    }

    func test_선택된_상태의_proceedState는_ready이며_JourneySelection을_담는다() throws {
        var d = draft(minutes: 60)
        XCTAssertTrue(choose(&d, "2014"))
        let state = d.proceedState(origin: origin, catalog: catalog)
        guard case let .ready(selection) = state else { return XCTFail("ready가 아님: \(state)") }
        XCTAssertEqual(selection.originStopID, "seongsu")
        XCTAssertEqual(selection.originName, "성수역")
        XCTAssertEqual(selection.boundLabel, "성수동 방면")
        XCTAssertEqual(selection.minutes, 60)
        XCTAssertEqual(selection.busID, "2014")
        XCTAssertEqual(selection.busNumber, "2014")
        XCTAssertEqual(selection.busKind, "지선")
        XCTAssertEqual(selection.destinationStopID, "seongdongSportsCenter")
        XCTAssertEqual(selection.destination, "성동구민체육센터")
        XCTAssertEqual(selection.stops, 12)
        XCTAssertGreaterThan(selection.distanceMeters, 0)
        XCTAssertEqual(state.title, "이 여정 준비하기")
        XCTAssertTrue(state.isEnabled)
    }

    func test_노선_302를_선택하면_번호와_종류가_카탈로그_노선_값이다() throws {
        var d = draft(minutes: 60)
        XCTAssertTrue(choose(&d, "302"))
        guard case let .ready(selection) = d.proceedState(origin: origin, catalog: catalog) else {
            return XCTFail("ready가 아님")
        }
        XCTAssertEqual(selection.busID, "302")
        XCTAssertEqual(selection.busNumber, "강남02")
        XCTAssertEqual(selection.busKind, "마을")
        XCTAssertEqual(selection.stops, 8)
    }

    func test_60분에서_421_선택은_거부되고_선택이_바뀌지_않는다() {
        var d = draft(minutes: 60)
        XCTAssertFalse(choose(&d, "421"))
        XCTAssertNil(d.selectedRouteID)
        XCTAssertNil(d.selectedCandidate(origin: origin, catalog: catalog))
    }

    func test_실패한_선택은_기존_선택을_유지한다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(choose(&d, "2014"))
        XCTAssertFalse(choose(&d, "421"))
        XCTAssertEqual(d.selectedRouteID, "2014")
    }

    func test_시간이_바뀌면_선택이_해제되고_같은_값으로_되돌려도_복원되지_않는다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(choose(&d, "2014"))
        d.setMinutes(61)
        XCTAssertNil(d.selectedRouteID)
        d.setMinutes(60)
        XCTAssertNil(d.selectedRouteID)
        XCTAssertEqual(d.proceedState(origin: origin, catalog: catalog), .needsSelection)
    }

    func test_같은_버스가_새_시간에도_후보여도_시간이_바뀌면_선택이_해제된다() {
        var d = draft(minutes: 60)
        XCTAssertTrue(choose(&d, "2014"))
        d.setMinutes(120)
        XCTAssertNil(d.selectedRouteID)
    }

    func test_상태별_안내_문구와_진행_가능_여부() {
        XCTAssertEqual(ProceedState.originUnavailable.title, "출발 정류장을 확인할 수 없어요")
        XCTAssertFalse(ProceedState.originUnavailable.isEnabled)
        XCTAssertEqual(ProceedState.routeDataLoading.title, "정류장 정보를 불러오는 중이에요")
        XCTAssertFalse(ProceedState.routeDataLoading.isEnabled)
        XCTAssertEqual(ProceedState.routeDataFailed.title, "정류장 정보를 불러오지 못했어요. 앱을 다시 실행해 주세요")
        XCTAssertFalse(ProceedState.routeDataFailed.isEnabled)
    }
}
