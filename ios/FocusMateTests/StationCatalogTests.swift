import Foundation
import XCTest
@testable import FocusMate

final class StationCatalogTests: XCTestCase {
    private let seongsuForward = StationSnapshot(id: "seongsu", name: "성수역", direction: 1)
    private let seongsuReverse = StationSnapshot(id: "seongsu", name: "성수역", direction: -1)
    private let seoulForest = StationSnapshot(id: "seoulForest", name: "서울숲역", direction: 1)

    private func snapshots(_ query: String) -> [StationSnapshot] {
        StationCatalog.search(query).map(\.snapshot)
    }

    func test_서울숲_검색은_성수역_정방향과_서울숲역_2건을_반환한다() {
        let result = snapshots("서울숲")
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result.contains(seongsuForward))
        XCTAssertTrue(result.contains(seoulForest))
    }

    func test_건대_검색은_성수역_역방향_1건을_반환한다() {
        XCTAssertEqual(snapshots("건대"), [seongsuReverse])
    }

    func test_성수_검색은_3건_전부를_반환한다() {
        let result = snapshots("성수")
        XCTAssertEqual(result.count, 3)
        XCTAssertTrue(result.contains(seongsuForward))
        XCTAssertTrue(result.contains(seongsuReverse))
        XCTAssertTrue(result.contains(seoulForest))
    }

    func test_앞뒤_공백이_있는_방면_문구_검색은_trim되어_역방향_1건을_반환한다() {
        XCTAssertEqual(snapshots("  성수사거리  "), [seongsuReverse])
        XCTAssertEqual(snapshots("  성수사거리  "), snapshots("성수사거리"))
    }

    func test_공백만_있는_검색어는_전체_3건을_반환한다() {
        XCTAssertEqual(StationCatalog.search("   ").count, 3)
    }

    func test_빈_검색어는_전체_3건을_반환한다() {
        XCTAssertEqual(StationCatalog.search("").count, 3)
    }

    func test_카탈로그는_3건이며_순서가_성수역_정방향_성수역_역방향_서울숲역이다() {
        XCTAssertEqual(StationCatalog.all.map(\.snapshot), [seongsuForward, seongsuReverse, seoulForest])
    }

    func test_성수역_역방향_옵션의_snapshot은_id_seongsu_이름_성수역_방향_음수1이다() {
        let option = StationCatalog.all.first { $0.position == StopPosition(index: 0, direction: -1) }
        XCTAssertEqual(option?.snapshot, StationSnapshot(id: "seongsu", name: "성수역", direction: -1))
    }

    func test_옵션의_방면_문구는_다음_정류장_이름을_사용한다() {
        let labels = StationCatalog.all.map(\.boundLabel)
        XCTAssertEqual(labels, ["성수동 방면", "성수사거리 방면", "서울숲 입구 방면"])
    }

    func test_position_of는_id로_찾고_direction은_저장값을_유지한다() {
        let snapshot = StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1)
        XCTAssertEqual(RouteStops.position(of: snapshot), StopPosition(index: 4, direction: -1))
    }

    func test_position_of는_알_수_없는_id면_nil을_반환한다() {
        let snapshot = StationSnapshot(id: "unknown", name: "없음", direction: 1)
        XCTAssertNil(RouteStops.position(of: snapshot))
    }

    func test_wrap은_음수와_9이상_오프셋을_순환시킨다() {
        XCTAssertEqual(RouteStops.wrap(-1), 8)
        XCTAssertEqual(RouteStops.wrap(9), 0)
        XCTAssertEqual(RouteStops.wrap(72), 0)
    }

    func test_역방향_성수역의_boundLabel은_성수사거리_방면이다() {
        XCTAssertEqual(RouteStops.boundLabel(from: StopPosition(index: 0, direction: -1)), "성수사거리 방면")
    }
}
