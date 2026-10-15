import XCTest
@testable import FocusMate

final class RecordsCalendarTests: XCTestCase {
    private let today = RecordDay(year: 2026, month: 10, day: 15)

    // 깨짐: 경계(30/31/60/61/120/121) 임계값을 바꾸면 실패.
    func testAC25_잔디_5단계_경계값은_0_1_2_2_3_3_4다() {
        let levels = [0, 30, 31, 60, 61, 120, 121].map { RecordHeatLevel.level(minutes: $0) }
        XCTAssertEqual(levels, [0, 1, 2, 2, 3, 3, 4])
    }

    // 깨짐: 접근성 라벨 형식(날짜 · 횟수 · 분)을 바꾸면 실패.
    func testAC25_셀_접근성_라벨은_날짜_횟수_분_형식이다() {
        let records = [Self.record(id: "a", date: "2026-10-15", minutes: 25)]
        let cell = RecordsCalendar.cells(year: 2026, records: records, today: today)
            .first { $0.day == RecordDay(year: 2026, month: 10, day: 15) }
        XCTAssertEqual(cell?.accessibilityLabel, "10월 15일 · 1회 · 25분")
    }

    // 깨짐: 미래 날짜/오늘 플래그 계산이 틀리면 실패.
    func testAC27_셀은_미래_날과_오늘을_구분한다() {
        let cells = RecordsCalendar.cells(year: 2026, records: [], today: today)
        let future = cells.first { $0.day == RecordDay(year: 2026, month: 10, day: 16) }
        let now = cells.first { $0.day == RecordDay(year: 2026, month: 10, day: 15) }
        XCTAssertEqual(future?.isFuture, true)
        XCTAssertEqual(future?.isToday, false)
        XCTAssertEqual(now?.isToday, true)
        XCTAssertEqual(now?.isFuture, false)
    }

    // 깨짐: 12/31 기록이 다음 해로 새거나 누락되면 실패.
    func testAC28_연말_기록은_해당_날에만_속한다() {
        let late = RecordDay(year: 2027, month: 1, day: 2)
        let records = [Self.record(id: "a", date: "2026-12-31", minutes: 25)]
        XCTAssertEqual(RecordsCalendar.records(on: RecordDay(year: 2026, month: 12, day: 31), in: records).count, 1)
        XCTAssertEqual(RecordsCalendar.records(on: RecordDay(year: 2027, month: 1, day: 1), in: records).count, 0)
        XCTAssertEqual(RecordsCalendar.summary(year: 2027, records: records, today: late).count, 0)
    }

    // 깨짐: 기록 0건 문구가 바뀌면 실패.
    func testAC24_기록_0건_요약_문구는_0회_여행_0일이다() {
        let summary = RecordsCalendar.summary(year: 2026, records: [], today: today)
        XCTAssertEqual(summary.text, "0회 여행 · 0일")
    }

    // 깨짐: 횟수/일수/시간 집계나 시간 표기가 틀리면 실패.
    func testAC24_기록_2건_65분_2일_요약_문구에는_시간이_붙는다() {
        let records = [
            Self.record(id: "a", date: "2026-10-14", minutes: 40),
            Self.record(id: "b", date: "2026-10-15", minutes: 25),
        ]
        let summary = RecordsCalendar.summary(year: 2026, records: records, today: today)
        XCTAssertEqual(summary.text, "2회 여행 · 2일 · 1 h 5 min")
    }

    // 깨짐: 미래 날짜 기록을 집계에 포함하면 실패.
    func test오늘보다_뒤_날짜_기록은_집계에서_제외된다() {
        let records = [
            Self.record(id: "a", date: "2026-10-15", minutes: 25),
            Self.record(id: "b", date: "2026-10-16", minutes: 25),
        ]
        let summary = RecordsCalendar.summary(year: 2026, records: records, today: today)
        let cells = RecordsCalendar.cells(year: 2026, records: records, today: today)
        let futureCell = cells.first { $0.day == RecordDay(year: 2026, month: 10, day: 16) }
        XCTAssertEqual(summary.count, 1)
        XCTAssertEqual(futureCell?.count, 0)
    }

    // 깨짐: 존재하지 않는 날짜를 보정해 받아들이면 실패.
    func test존재하지_않는_날짜_키는_nil이고_정상_키는_왕복한다() {
        XCTAssertNil(RecordDay(key: "2026-02-30"))
        XCTAssertEqual(RecordDay(key: "2026-10-05")?.key, "2026-10-05")
    }

    // 깨짐: 기록 없는 메모 버튼 문구가 바뀌면 실패.
    func testAC30_메모가_비면_메모_남기기_있으면_메모_수정이다() {
        let empty = RecordListItemContent(record: Self.record(id: "a", date: "2026-10-15", minutes: 25, memo: ""), timeZone: TimeZone(identifier: "UTC")!)
        let filled = RecordListItemContent(record: Self.record(id: "b", date: "2026-10-15", minutes: 25, memo: "좋았다"), timeZone: TimeZone(identifier: "UTC")!)
        XCTAssertEqual(empty.memoButtonTitle, "메모 남기기")
        XCTAssertEqual(filled.memoButtonTitle, "메모 수정")
    }

    static func record(
        id: String,
        date: String,
        minutes: Int,
        completedAt: String? = nil,
        memo: String = ""
    ) -> RecordSnapshot {
        RecordSnapshot(
            id: id,
            completedAt: completedAt ?? "\(date)T01:00:00Z",
            date: date,
            bus: "버스2014",
            tag: "독서",
            tagColor: "#12ABef",
            task: "책 한 챕터 읽기",
            minutes: minutes,
            sound: "빗소리",
            from: "성수역",
            to: "서울숲 입구",
            memo: memo
        )
    }
}
