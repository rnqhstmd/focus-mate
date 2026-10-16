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
        XCTAssertNil(state.confirmationText(in: catalog))
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

    // 깨짐: 방면을 확인 문구에 넣지 않거나 구분자가 다르면 실패한다.
    func test_방면이_있는_정류장을_선택하면_확인_문구에_방면이_붙는다() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "알파"

        XCTAssertTrue(state.select("S1", in: catalog))

        XCTAssertEqual(state.confirmationText(in: catalog), "알파 · 베타 방면에서 출발")
        XCTAssertTrue(state.canConfirm(in: catalog))
        XCTAssertEqual(state.selectedOption(in: catalog)?.id, "S1")
    }

    // 깨짐: 방면이 없는데 구분자나 빈 방면 문구가 남으면 실패한다.
    func test_방면이_없는_정류장의_확인_문구는_이름만_쓴다() throws {
        let catalog = try catalog()
        var state = StationSearchState()
        state.query = "알파센터"

        XCTAssertTrue(state.select("S9", in: catalog))

        XCTAssertEqual(state.confirmationText(in: catalog), "알파센터에서 출발")
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
        XCTAssertNil(state.confirmationText(in: catalog))
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
