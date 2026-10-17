import Foundation
import XCTest
@testable import FocusMate

final class RecordsAnalyticsAdapterTests: XCTestCase {
    private var zone: TimeZone { TimeZone(secondsFromGMT: 0)! }
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = zone
        return value
    }
    private var period: AnalyticsPeriod {
        AnalyticsPeriod(kind: .month, startDay: "2026-10-01", endDay: "2026-10-31")
    }
    private func now() throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: "2026-10-16T23:00:00Z"))
    }
    private func record(
        _ id: String, day: String = "2026-10-14",
        completed: String = "2026-10-14T12:00:00Z", memo: String = "",
        task: String = "원문 할 일", minutes: Int = 25
    ) -> RecordSnapshot {
        RecordSnapshot(
            id: id, completedAt: completed, date: day,
            bus: "버스2014", tag: "독서", tagColor: "#12ABef",
            task: task, minutes: minutes, sound: "빗소리", from: "성수역", to: "서울숲 입구", memo: memo
        )
    }
    private func content(_ section: RecordSection) throws -> RecordsAnalyticsContent {
        try RecordsAnalyticsAdapter.validatedContent(
            section: section, period: period, selectedTag: nil, now: now(), calendar: calendar, timeZone: zone
        )
    }
    private func load(_ section: RecordSection?) throws -> RecordsAnalyticsLoad {
        RecordsAnalyticsAdapter.load(
            section: section, period: period, selectedTag: nil, now: try now(), calendar: calendar, timeZone: zone
        )
    }
    private func six() -> RecordSection {
        RecordSection(items: (0..<6).map { index in
            record("r\(index)", completed: String(format: "2026-10-14T%02d:00:00Z", index + 1), memo: index < 4 ? "메모\(index)" : "")
        })
    }

    // 호환 회귀. 깨짐: nil저장구역을 정상빈기록으로 바꾸어 손실을 숨긴다.
    func testW09b_nil구역은_unavailable이다() throws {
        XCTAssertEqual(try load(nil), .unavailable)
    }

    // 깨짐: 실제 빈구역을 접근불가로 처리하거나 hasAnyEligible를true로 만든다.
    func testW09b_빈구역의_검증결과는_정상0이다() throws {
        let result = try content(.empty)
        XCTAssertEqual(result.computation.report.totals.minutes, 0)
        XCTAssertEqual(result.computation.report.totals.count, 0)
        XCTAssertFalse(result.hasAnyEligibleRecords)
        XCTAssertEqual(result.recent, [])
        XCTAssertEqual(result.memoCount, 0)
    }

    // 깨짐: load wrapper가 정상빈구역도 unavailable로 삼킨다.
    func testW09b_load는_빈구역도_available로_반환한다() throws {
        let result = try load(.empty)
        guard case .available(let value) = result else {
            XCTFail("정상 빈구역은 available이어야 한다")
            return
        }
        XCTAssertEqual(value.computation.report.totals.minutes, 0)
        XCTAssertFalse(value.hasAnyEligibleRecords)
    }

    // 호환 회귀. 깨짐: 손상메모1건을 건너뛰어 정상항목만 부분집계한다.
    func testW09b_손상1건이면_전체_unavailable이다() throws {
        let section = RecordSection(items: [record("ok"), record("bad", memo: String(repeating: "가", count: 201))])
        XCTAssertEqual(try load(section), .unavailable)
    }

    // 호환 회귀. 깨짐: 동일UTF16 ID중복을 제거하여 성공으로 돌려준다.
    func testW09b_중복ID구역은_전체_unavailable이다() throws {
        let section = RecordSection(items: [record("same"), record("same", minutes: 30)])
        XCTAssertEqual(try load(section), .unavailable)
    }

    // 깨짐: 집계 과정이 저장date나원문메모·할일·색을 바꾸거나 원본을 잃는다.
    func testW09b_집계후에도_원본기록값을_보존한다() throws {
        let original = record("original", day: "2026-10-12", memo: "저장된 메모", task: "저장된 할 일")
        let section = RecordSection(items: [original])

        let result = try content(section)

        XCTAssertEqual(section.items, [original])
        XCTAssertEqual(result.recent, [original])
        XCTAssertEqual(result.recentMemos, [original])
        XCTAssertEqual(result.computation.report.days.first { $0.day == "2026-10-12" }?.minutes, 25)
    }

    // 깨짐: 최근기록이6개모두이거나 오래된순서로 반환된다.
    func testW09b_6회중_최근5회만_최신순으로_반환한다() throws {
        let result = try content(six())
        XCTAssertEqual(result.recent.map(\.id), ["r5", "r4", "r3", "r2", "r1"])
    }

    // 깨짐: 최근5회만으로 메모수를 세거나 최신메모3개를 넘긴다.
    func testW09b_메모4회는_전체수4와_최신3개를_반환한다() throws {
        let result = try content(six())
        XCTAssertEqual(result.memoCount, 4)
        XCTAssertEqual(result.recentMemos.map(\.id), ["r3", "r2", "r1"])
        XCTAssertEqual(result.recentMemos.map(\.memo), ["메모3", "메모2", "메모1"])
    }

    // 깨짐: 동시각기록을 ID순으로 재정렬하여 입력순서를 잃는다.
    func testW09b_완료시각동률은_입력순서를_보존한다() throws {
        let result = try content(RecordSection(items: [record("z-first", memo: "첫째"), record("a-second", memo: "둘째")]))
        XCTAssertEqual(result.recent.map(\.id), ["z-first", "a-second"])
        XCTAssertEqual(result.recentMemos.map(\.memo), ["첫째", "둘째"])
    }

    // 깨짐: Swift canonical equality로 원본ID를 매칭해 서로다른기록의메모를 덮는다.
    func testW09b_canonical동등하지만_UTF16다른ID는_각원본에_매칭한다() throws {
        let section = RecordSection(items: [record("\u{00E9}", memo: "조합형"), record("e\u{301}", memo: "분해형")])
        let result = try content(section)
        XCTAssertEqual(result.recent.map { Array($0.id.utf16) }, [[233], [101, 769]])
        XCTAssertEqual(result.recentMemos.map(\.memo), ["조합형", "분해형"])
        XCTAssertEqual(result.computation.scopedRecordIDs.map { Array($0.utf16) }, [[233], [101, 769]])
        XCTAssertEqual(result.computation.report.totals.count, 2)
    }

    // 깨짐: 앱전용원문이나원본ID가 report 투영에 섞인다.
    func testW09b_report는_메모할일원본ID를_직렬화하지_않는다() throws {
        let result = try content(RecordSection(items: [record("private-record-id", memo: "민감 메모 원문", task: "민감 할 일 원문")]))
        let data = try JSONEncoder().encode(result.computation.report)
        let object = try JSONSerialization.jsonObject(with: data)
        func keys(_ value: Any) -> [String] {
            if let map = value as? [String: Any] { return Array(map.keys) + map.values.flatMap(keys) }
            if let list = value as? [Any] { return list.flatMap(keys) }
            return []
        }
        XCTAssertTrue(Set(keys(object).map { $0.lowercased() }).isDisjoint(with: ["task", "memo", "recordid", "recordids", "scopedrecordids"]))
        let text = String(decoding: data, as: UTF8.self)
        XCTAssertFalse(text.contains("private-record-id"))
        XCTAssertFalse(text.contains("민감 메모 원문"))
        XCTAssertFalse(text.contains("민감 할 일 원문"))
    }

    // 깨짐: 선택기간에0건이면 전체기록도 없다고 오판한다.
    func testW09b_기간밖과거기록이있으면_빈기간과_첫기록전을_구분한다() throws {
        let section = RecordSection(items: [record("old", day: "2026-09-01", completed: "2026-09-01T12:00:00Z")])
        let result = try content(section)
        XCTAssertTrue(result.hasAnyEligibleRecords)
        XCTAssertEqual(result.computation.report.totals.count, 0)
        XCTAssertEqual(result.recent, [])
        XCTAssertEqual(result.memoCount, 0)
    }

    // 깨짐: 미래기록을 전체적격존재나최근·메모에 포함한다.
    func testW09b_미래완료만있으면_적격기록없음이다() throws {
        let section = RecordSection(items: [record("future", day: "2026-10-16", completed: "2026-10-16T23:00:01Z", memo: "미래")])
        let result = try content(section)
        XCTAssertFalse(result.hasAnyEligibleRecords)
        XCTAssertEqual(result.recent, [])
        XCTAssertEqual(result.memoCount, 0)
        XCTAssertEqual(result.computation.report.totals.count, 0)
    }
}
