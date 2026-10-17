import Foundation
import XCTest
@testable import FocusMate

final class RecordsAnalyticsRowTests: XCTestCase {
    private func record(_ id: String, task: String, memo: String) -> RecordSnapshot {
        RecordSnapshot(
            id: id, completedAt: "2026-10-14T12:00:00Z", date: "2026-10-14",
            bus: "버스2014", tag: "독서", tagColor: "#12ABef", task: task,
            minutes: 25, sound: "빗소리", from: "성수역", to: "서울숲 입구", memo: memo
        )
    }

    // 깨짐: Swift String canonical equality를 행ID로 사용하여 서로다른 원문기록을 한행으로 합친다.
    func testW09b_canonical동등해도_UTF16다른_기록행ID는_두개다() {
        let first = RecordsAnalyticsRow(record: record("\u{00E9}", task: "첫 할 일", memo: "첫 메모"))
        let second = RecordsAnalyticsRow(record: record("e\u{0301}", task: "둘째 할 일", memo: "둘째 메모"))

        XCTAssertEqual(Set([first.id, second.id]).count, 2)
    }

    // 깨짐: 행생성시 원문ID를정규화하거나 canonical동등한 다른기록의할일·메모로 덮는다.
    func testW09b_각기록행은_원본ID와_할일메모를_보존한다() {
        let rows = [
            RecordsAnalyticsRow(record: record("\u{00E9}", task: "첫 할 일", memo: "첫 메모")),
            RecordsAnalyticsRow(record: record("e\u{0301}", task: "둘째 할 일", memo: "둘째 메모"))
        ]

        XCTAssertEqual(rows.map { Array($0.record.id.utf16) }, [[233], [101, 769]])
        XCTAssertEqual(rows.map { $0.record.task }, ["첫 할 일", "둘째 할 일"])
        XCTAssertEqual(rows.map { $0.record.memo }, ["첫 메모", "둘째 메모"])
    }
}
