import XCTest
@testable import FocusMate

final class RecordsBrowserTests: XCTestCase {
    private let today = RecordDay(year: 2026, month: 10, day: 15)

    private func manyRecords(_ n: Int) -> [RecordSnapshot] {
        (0..<n).map { i in
            RecordsCalendarTests.record(
                id: "r\(i)",
                date: "2026-10-15",
                minutes: 10,
                completedAt: String(format: "2026-10-15T%02d:00:00Z", i)
            )
        }
    }

    // 깨짐: 페이지 크기/더보기 증가량/hasMore 판정이 틀리면 실패.
    func testAC26_25건은_10_20_25로_늘고_hasMore는_true_true_false다() {
        let records = manyRecords(25)
        var browser = RecordsBrowser(today: today)
        var counts = [browser.visibleRecords(in: records).count]
        var more = [browser.hasMore(in: records)]
        browser.showMore()
        counts.append(browser.visibleRecords(in: records).count)
        more.append(browser.hasMore(in: records))
        browser.showMore()
        counts.append(browser.visibleRecords(in: records).count)
        more.append(browser.hasMore(in: records))
        XCTAssertEqual(counts, [10, 20, 25])
        XCTAssertEqual(more, [true, true, false])
    }

    // 깨짐: 정렬이 최신순이 아니면 실패.
    func testAC26_보이는_기록은_최신_완료시각_순이다() {
        let records = manyRecords(3)
        let browser = RecordsBrowser(today: today)
        XCTAssertEqual(browser.visibleRecords(in: records).map(\.id), ["r2", "r1", "r0"])
    }

    // 깨짐: 다른 날 선택 시 listLimit 리셋을 빼먹으면 실패.
    func testAC26_다른_날을_선택하면_목록_개수가_10으로_리셋된다() {
        let records = manyRecords(25)
        var browser = RecordsBrowser(today: today)
        browser.showMore()
        browser.select(RecordDay(year: 2026, month: 10, day: 14))
        browser.select(today)
        XCTAssertEqual(browser.visibleRecords(in: records).count, 10)
    }

    private var yearRecords: [RecordSnapshot] {
        [
            RecordsCalendarTests.record(id: "a", date: "2026-05-01", minutes: 25),
            RecordsCalendarTests.record(id: "b", date: "2025-03-10", minutes: 25),
            RecordsCalendarTests.record(id: "c", date: "2025-06-20", minutes: 25),
        ]
    }

    // 깨짐: 이동한 해에서 가장 최근 기록일을 고르지 않으면 실패.
    func testAC27_이전_해로_이동하면_그_해_가장_최근_기록일이_선택된다() {
        var browser = RecordsBrowser(today: today)
        browser.moveYear(by: -1, records: yearRecords)
        XCTAssertEqual(browser.year, 2025)
        XCTAssertEqual(browser.selectedDay, RecordDay(year: 2025, month: 6, day: 20))
        let summary = RecordsCalendar.summary(year: 2025, records: yearRecords, today: today)
        XCTAssertEqual(summary.count, 2)
        XCTAssertEqual(summary.days, 2)
    }

    // 깨짐: 기록 없는 해의 기본 선택일(1월 1일)이 바뀌면 실패.
    func testAC27_기록_없는_해로_이동하면_1월_1일이_선택된다() {
        var browser = RecordsBrowser(today: today)
        browser.moveYear(by: -1, records: yearRecords)
        browser.moveYear(by: -1, records: yearRecords)
        XCTAssertEqual(browser.year, 2024)
        XCTAssertEqual(browser.selectedDay, RecordDay(year: 2024, month: 1, day: 1))
    }

    // 깨짐: 올해 복귀 시 오늘 대신 다른 날을 고르면 실패.
    func testAC27_올해로_돌아오면_오늘이_선택된다() {
        var browser = RecordsBrowser(today: today)
        browser.moveYear(by: -1, records: yearRecords)
        browser.moveYear(by: 1, records: yearRecords)
        XCTAssertEqual(browser.year, 2026)
        XCTAssertEqual(browser.selectedDay, today)
    }

    // 깨짐: 미래 연도 이동 허용 판정이 틀리면 실패.
    func testAC27_다음_해_이동은_올해에서_불가_작년에서_가능하다() {
        var browser = RecordsBrowser(today: today)
        XCTAssertFalse(browser.canGoNextYear)
        browser.moveYear(by: -1, records: yearRecords)
        XCTAssertTrue(browser.canGoNextYear)
    }

    // 깨짐: 미래 날 선택을 허용하거나 선택일이 바뀌면 실패.
    func testAC27_미래_날_선택은_거부되고_선택일은_그대로다() {
        var browser = RecordsBrowser(today: today)
        let accepted = browser.select(RecordDay(year: 2026, month: 10, day: 16))
        XCTAssertFalse(accepted)
        XCTAssertEqual(browser.selectedDay, today)
    }

    // 깨짐: 기록 0건 빈 상태 분기가 틀리면 실패.
    func testAC24_기록이_0건이면_noRecords다() {
        let browser = RecordsBrowser(today: today)
        XCTAssertEqual(browser.emptyState(records: []), .noRecords)
    }

    // 깨짐: 선택일만 빈 경우를 noRecords로 오판하면 실패.
    func testAC24_기록은_있고_선택일만_비면_noRecordsOnDay다() {
        let records = [RecordsCalendarTests.record(id: "a", date: "2026-10-01", minutes: 25)]
        let browser = RecordsBrowser(today: today)
        XCTAssertEqual(browser.emptyState(records: records), .noRecordsOnDay)
    }

    // 깨짐: 미래 이동 거부를 빼먹으면 실패.
    func test오늘에서_다음_날로_이동은_거부된다() {
        var browser = RecordsBrowser(today: today)
        XCTAssertFalse(browser.stepDay(by: 1))
        XCTAssertEqual(browser.selectedDay, today)
    }

    // 깨짐: 전날 이동 또는 listLimit 리셋이 빠지면 실패.
    func test전날로_이동하면_선택일이_바뀌고_목록_개수가_리셋된다() {
        let records = (0..<25).map {
            RecordsCalendarTests.record(id: "r\($0)", date: "2026-10-14", minutes: 10,
                                        completedAt: String(format: "2026-10-14T%02d:00:00Z", $0))
        }
        var browser = RecordsBrowser(today: today)
        browser.showMore()
        XCTAssertTrue(browser.stepDay(by: -1))
        XCTAssertEqual(browser.selectedDay, RecordDay(year: 2026, month: 10, day: 14))
        XCTAssertEqual(browser.visibleRecords(in: records).count, 10)
    }

    // 깨짐: 선택 연도 밖으로 넘어가는 이동을 허용하면 실패.
    func test1월_1일에서_전날_이동은_거부된다() {
        var browser = RecordsBrowser(today: today)
        let jan1 = RecordDay(year: 2026, month: 1, day: 1)
        browser.select(jan1)
        XCTAssertFalse(browser.stepDay(by: -1))
        XCTAssertEqual(browser.selectedDay, jan1)
    }
}
