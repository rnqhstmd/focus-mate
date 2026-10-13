import Foundation
import XCTest
@testable import FocusMate

final class StationSearchStateTests: XCTestCase {
    private func reverseOptionID(_ state: StationSearchState) throws -> String {
        try XCTUnwrap(state.results.first { $0.position == StopPosition(index: 0, direction: -1) }).id
    }

    func test_초기_상태는_3건_결과이고_선택_확정이_없다() {
        let state = StationSearchState()
        XCTAssertEqual(state.results.count, 3)
        XCTAssertNil(state.selectedOption)
        XCTAssertFalse(state.canConfirm)
        XCTAssertNil(state.confirmationText)
    }

    func test_없는역_검색은_결과_0건이다() {
        var state = StationSearchState()
        state.query = "없는역"
        XCTAssertEqual(state.results.count, 0)
        XCTAssertFalse(state.canConfirm)
    }

    func test_결과가_없을_때_카탈로그_id_선택은_거부되고_확정할_수_없다() {
        var state = StationSearchState()
        state.query = "없는역"
        for option in StationCatalog.all {
            XCTAssertFalse(state.select(option.id))
        }
        XCTAssertNil(state.selectedOption)
        XCTAssertFalse(state.canConfirm)
    }

    func test_성수역_역방향_선택은_성공하고_확인_문구를_만든다() throws {
        var state = StationSearchState()
        let id = try reverseOptionID(state)
        XCTAssertTrue(state.select(id))
        XCTAssertEqual(state.confirmationText, "성수역 · 성수사거리 방면에서 출발")
        XCTAssertTrue(state.canConfirm)
        XCTAssertEqual(state.selectedOption?.position, StopPosition(index: 0, direction: -1))
    }

    func test_선택한_옵션이_검색_결과에서_빠지면_선택이_사라진다() throws {
        var state = StationSearchState()
        XCTAssertTrue(state.select(try reverseOptionID(state)))
        state.query = "서울숲"
        XCTAssertNil(state.selectedOption)
        XCTAssertFalse(state.canConfirm)
    }

    func test_현재_결과에_없는_옵션_선택은_거부되고_기존_선택을_유지한다() throws {
        var state = StationSearchState()
        state.query = "서울숲"
        let forestID = try XCTUnwrap(state.results.first { $0.position == StopPosition(index: 4, direction: 1) }).id
        XCTAssertTrue(state.select(forestID))
        let reverseID = try XCTUnwrap(StationCatalog.all.first { $0.position == StopPosition(index: 0, direction: -1) }).id
        XCTAssertFalse(state.select(reverseID))
        XCTAssertEqual(state.selectedOption?.position, StopPosition(index: 4, direction: 1))
    }
}
