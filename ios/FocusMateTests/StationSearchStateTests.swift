import Foundation
import XCTest
@testable import FocusMate

final class StationSearchStateTests: XCTestCase {
    private func catalog() throws -> RouteCatalog { try RouteCatalogFixture.acceptance() }

    // 깨짐: 빈 입력에서 결과를 내거나 선택·확정이 가능하면 실패한다.
    func test_초기_상태는_안내_상태이고_선택_확정이_없다() throws {
        let catalog = try catalog()
        let state = StationSearchState()

        XCTAssertEqual(state.result(in: catalog), .prompt)
        XCTAssertNil(state.selectedOption(in: catalog))
        XCTAssertFalse(state.canConfirm(in: catalog))
    }

    // 깨짐: 결과가 없을 때 카탈로그 id 선택을 허용하면 실패한다.
    func test_없는이름_검색은_빈결과이고_카탈로그_id_선택은_거부된다() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "없는이름"

        XCTAssertEqual(state.result(in: catalog), .empty)
        for id in ["S1", "S1b", "S2", "S9"] {
            XCTAssertFalse(state.select(id, in: catalog))
        }
        XCTAssertNil(state.selectedOption(in: catalog))
        XCTAssertFalse(state.canConfirm(in: catalog))
    }

    func testSelectedPreviewKeepsStationDirection() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "알파"

        XCTAssertTrue(state.select("S1", in: catalog))

        XCTAssertEqual(state.selectedOption(in: catalog)?.boundLabel, "베타 방면")
        XCTAssertTrue(state.canConfirm(in: catalog))
        XCTAssertEqual(state.selectedOption(in: catalog)?.id, "S1")
    }

    func testStationWithoutDirectionCanStillBeConfirmed() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "알파센터"

        XCTAssertTrue(state.select("S9", in: catalog))

        XCTAssertNil(state.selectedOption(in: catalog)?.boundLabel)
        XCTAssertTrue(state.canConfirm(in: catalog))
    }

    // 깨짐: 검색어가 바뀌어 결과에서 빠진 선택을 유지하면 실패한다.
    func test_선택한_옵션이_검색_결과에서_빠지면_선택이_사라진다() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "알파"
        XCTAssertTrue(state.select("S1", in: catalog))

        state.query = "베타"

        XCTAssertNil(state.selectedOption(in: catalog))
        XCTAssertFalse(state.canConfirm(in: catalog))
    }

    func testEditingQueryClearsPreviewEvenWhenTheSameResultStillMatches() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "알파"
        XCTAssertTrue(state.select("S1", in: catalog))

        state.query = "알파 "

        XCTAssertNil(state.selectedID)
        XCTAssertFalse(state.canConfirm(in: catalog))
        state.query = "알파"
        XCTAssertNil(state.selectedOption(in: catalog))
    }

    func testReselectReturnsToTheSameSearchResultsAndAnotherOriginCanBeChosen() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "알파"
        let results = state.result(in: catalog)
        XCTAssertTrue(state.select("S1", from: results))

        state.clearSelection()

        XCTAssertEqual(state.query, "알파")
        XCTAssertEqual(state.result(in: catalog), results)
        XCTAssertFalse(state.canConfirm(in: catalog))
        XCTAssertTrue(state.select("S1b", from: results))
        XCTAssertEqual(state.selectedOption(in: catalog)?.id, "S1b")
    }

    func testPreviewServingBusNumbersComeOnlyFromSelectedStopVisits() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "알파"
        XCTAssertTrue(state.select("S1", in: catalog))
        let station = try XCTUnwrap(state.selectedOption(in: catalog))
        let expected = catalog.visits(stopIndex: station.stopIndex).map { catalog.routes[$0.route].number }

        XCTAssertFalse(expected.isEmpty)
        let buses = station.servingBusNumbers(in: catalog)
        XCTAssertEqual(Set(buses), Set(expected))
        XCTAssertEqual(buses.count, Set(buses).count)
        state.query = "알파센터"
        XCTAssertTrue(state.select("S9", in: catalog))
        XCTAssertEqual(state.selectedOption(in: catalog)?.servingBusNumbers(in: catalog), [])
    }

    // 깨짐: 현재 결과 밖 id 선택을 받아들이거나 기존 선택을 지우면 실패한다.
    func test_현재_결과에_없는_옵션_선택은_거부되고_기존_선택을_유지한다() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "베타"
        XCTAssertTrue(state.select("S2", in: catalog))

        XCTAssertFalse(state.select("S1", in: catalog))

        XCTAssertEqual(state.selectedOption(in: catalog)?.id, "S2")
    }
}
