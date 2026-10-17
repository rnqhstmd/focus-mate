import Foundation
import XCTest
@testable import FocusMate

/// 카탈로그 기반 여정 계획 초안. multi 카탈로그: r-100(간선, 25분 A→D, 1800m), r-200(지선, A→D 직행 25분, 3000m), r-300(후보 불가).
final class JourneyPlanDraftCatalogTests: XCTestCase {
    private typealias F = W16bFixtures

    private func origin(boundLabel: String? = "비 방면") -> RouteOrigin {
        RouteOrigin(stopIndex: 0, stopID: "A", name: "에이", boundLabel: boundLabel)
    }

    // MARK: 분 / 선택 해제

    // 깨짐: 기본 분이 25가 아니거나 선택이 있으면 실패한다.
    func testInitialDraftIsTwentyFiveMinutesWithoutSelection() {
        let draft = JourneyPlanDraft()
        XCTAssertEqual(draft.minutes, 25)
        XCTAssertNil(draft.selectedRouteID)
    }

    // 깨짐: 분이 바뀌어도 선택을 유지하면 실패한다 (AC-24).
    func testChangingMinutesClearsSelection() throws {
        let catalog = try F.multi()
        var draft = JourneyPlanDraft()
        XCTAssertTrue(draft.choose(routeID: "r-100", origin: origin(), catalog: catalog))
        draft.setMinutes(30)
        XCTAssertEqual(draft.minutes, 30)
        XCTAssertNil(draft.selectedRouteID)
    }

    // 깨짐: clamp 결과가 같은데 선택을 지우면 실패한다.
    func testClampedNoOpKeepsSelection() throws {
        let catalog = try F.multi()
        var draft = JourneyPlanDraft()
        let o = origin()
        XCTAssertTrue(draft.choose(routeID: "r-100", origin: o, catalog: catalog))
        draft.setMinutes(25)
        XCTAssertEqual(draft.selectedRouteID, "r-100")
        draft.setMinutes(361)
        XCTAssertEqual(draft.minutes, 360)
        XCTAssertNil(draft.selectedRouteID)
    }

    // MARK: candidates

    // 깨짐: 후보가 출발 정류장·분에 맞는 노선만(r-300 제외) 차이 같으면 번호 순으로 나오지 않으면 실패한다.
    func testCandidatesAreRoutesThatFitTheMinutes() throws {
        let result = JourneyPlanDraft().candidates(origin: origin(), catalog: try F.multi())
        XCTAssertEqual(result.map(\.id), ["r-100", "r-200"])
        XCTAssertEqual(result.map(\.busNumber), ["100", "200"])
        XCTAssertEqual(result.map(\.destination), ["디", "디"])
        XCTAssertEqual(result.map(\.stops), [3, 1])
    }

    // 깨짐: 분에 맞는 노선이 없는데 빈 배열이 아니면 실패한다.
    func testCandidatesAreEmptyWhenNothingFits() throws {
        var draft = JourneyPlanDraft()
        draft.setMinutes(15)
        XCTAssertEqual(draft.candidates(origin: origin(), catalog: try F.multi()), [])
    }

    // MARK: choose / selectedCandidate

    // 깨짐: 후보인 노선을 고를 수 없으면 실패한다.
    func testChooseCandidateSucceedsAndSelects() throws {
        let catalog = try F.multi()
        var draft = JourneyPlanDraft()
        XCTAssertTrue(draft.choose(routeID: "r-200", origin: origin(), catalog: catalog))
        XCTAssertEqual(draft.selectedRouteID, "r-200")
        XCTAssertEqual(draft.selectedCandidate(origin: origin(), catalog: catalog)?.busNumber, "200")
    }

    // 깨짐: 후보가 아닌 노선(r-300)이나 없는 노선 선택을 허용하면 실패한다 (기존 선택은 유지).
    func testChooseNonCandidateIsRejectedAndKeepsPreviousSelection() throws {
        let catalog = try F.multi()
        var draft = JourneyPlanDraft()
        XCTAssertTrue(draft.choose(routeID: "r-100", origin: origin(), catalog: catalog))
        XCTAssertFalse(draft.choose(routeID: "r-300", origin: origin(), catalog: catalog))
        XCTAssertFalse(draft.choose(routeID: "nope", origin: origin(), catalog: catalog))
        XCTAssertEqual(draft.selectedRouteID, "r-100")
    }

    // 깨짐: 선택이 없는데 selectedCandidate가 값을 돌려주면 실패한다.
    func testSelectedCandidateIsNilWithoutSelection() throws {
        XCTAssertNil(JourneyPlanDraft().selectedCandidate(origin: origin(), catalog: try F.multi()))
    }

    // 깨짐: 선택된 노선이 후보에서 빠지면(카탈로그 교체) selectedCandidate가 nil이 아니면 실패한다.
    func testSelectedCandidateIsNilWhenRouteNoLongerCandidate() throws {
        var draft = JourneyPlanDraft()
        XCTAssertTrue(draft.choose(routeID: "r-100", origin: origin(), catalog: try F.multi()))
        XCTAssertNil(draft.selectedCandidate(origin: origin(), catalog: try F.withoutRoute100()))
    }

    // MARK: proceedState

    // 깨짐: 후보가 있는데 선택 전 상태가 needsSelection이 아니면 실패한다.
    func testProceedStateNeedsSelectionWhenCandidatesExist() throws {
        let state = JourneyPlanDraft().proceedState(origin: origin(), catalog: try F.multi())
        XCTAssertEqual(state, .needsSelection)
        XCTAssertEqual(state.title, "버스와 도착지를 선택하세요")
    }

    // 깨짐: 후보가 없는데 noCandidates와 새 문구가 아니면 실패한다.
    func testProceedStateNoCandidatesTitle() throws {
        var draft = JourneyPlanDraft()
        draft.setMinutes(15)
        let state = draft.proceedState(origin: origin(), catalog: try F.multi())
        XCTAssertEqual(state, .noCandidates)
        XCTAssertEqual(state.title, "이 시간의 도착 후보가 없어요")
    }

    // 깨짐: ready가 후보의 값(버스 종류·번호·도착·거리·방면)으로 JourneySelection을 만들지 않으면 실패한다.
    func testProceedStateReadyBuildsSelectionFromCandidate() throws {
        let catalog = try F.multi()
        var draft = JourneyPlanDraft()
        XCTAssertTrue(draft.choose(routeID: "r-100", origin: origin(), catalog: catalog))
        let state = draft.proceedState(origin: origin(), catalog: catalog)
        let expected = JourneySelection(
            originStopID: "A", originName: "에이", boundLabel: "비 방면", minutes: 25,
            busID: "r-100", busNumber: "100", busKind: "간선",
            destinationStopID: "D", destination: "디", stops: 3, distanceMeters: 1800
        )
        XCTAssertEqual(state, .ready(expected))
        XCTAssertEqual(state.title, "이 여정 준비하기")
    }

    // 깨짐: 지선 노선을 골랐는데 busKind/거리를 다른 노선 값으로 채우면 실패한다.
    func testProceedStateReadyForSecondRouteUsesItsOwnValues() throws {
        let catalog = try F.multi()
        var draft = JourneyPlanDraft()
        XCTAssertTrue(draft.choose(routeID: "r-200", origin: origin(boundLabel: nil), catalog: catalog))
        guard case let .ready(selection) = draft.proceedState(origin: origin(boundLabel: nil), catalog: catalog) else {
            return XCTFail("ready가 아님")
        }
        XCTAssertEqual(selection.busID, "r-200")
        XCTAssertEqual(selection.busNumber, "200")
        XCTAssertEqual(selection.busKind, "지선")
        XCTAssertEqual(selection.stops, 1)
        XCTAssertEqual(selection.distanceMeters, 3000)
        XCTAssertNil(selection.boundLabel)
    }

    // 깨짐: 로딩·실패 문구가 명세와 다르면 실패한다.
    func testRouteDataStatesHaveTitles() {
        XCTAssertEqual(ProceedState.routeDataLoading.title, "정류장 정보를 불러오는 중이에요")
        XCTAssertEqual(ProceedState.routeDataFailed.title, "정류장 정보를 불러오지 못했어요. 앱을 다시 실행해 주세요")
        XCTAssertEqual(ProceedState.originUnavailable.title, "출발 정류장을 확인할 수 없어요")
    }

    // MARK: PreparedJourneyDetails / 거리 문구

    // 깨짐: 0.1km 반올림(50m 경계)·정수 km 규칙이 RouteCandidate와 다르면 실패한다.
    func testDistanceTextFromMeters() {
        XCTAssertEqual(RouteCandidates.distanceText(meters: 1800), "1.8km")
        XCTAssertEqual(RouteCandidates.distanceText(meters: 3000), "3km")
        XCTAssertEqual(RouteCandidates.distanceText(meters: 1449), "1.4km")
        XCTAssertEqual(RouteCandidates.distanceText(meters: 1450), "1.5km")
    }

    // 깨짐: 후보의 distanceText와 정적 함수 결과가 달라지면 실패한다.
    func testCandidateDistanceTextMatchesStaticFunction() throws {
        let result = JourneyPlanDraft().candidates(origin: origin(), catalog: try F.multi())
        XCTAssertEqual(result.map(\.distanceText), ["1.8km", "3km"])
    }
}
