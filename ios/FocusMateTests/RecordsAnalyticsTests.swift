import Foundation
import XCTest
@testable import FocusMate

final class RecordsAnalyticsTests: XCTestCase {
    private var utc: TimeZone { TimeZone(secondsFromGMT: 0)! }
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = utc
        return value
    }
    private func date(_ text: String) throws -> Date {
        try XCTUnwrap(ISO8601DateFormatter().date(from: text))
    }
    private func input(
        _ id: String, day: String = "2026-10-14", minutes: Int = 10,
        tag: String = "A", color: String = "#112233",
        completed: String = "2026-10-14T12:00:00Z",
        bus: String = "2014", from: String = "성수", to: String = "서울숲"
    ) throws -> AnalyticsRecordInput {
        AnalyticsRecordInput(
            id: id, day: day, completedAt: try date(completed), minutes: minutes,
            tag: tag, tagColor: color, bus: bus, from: from, to: to
        )
    }
    private var week: AnalyticsPeriod {
        AnalyticsPeriod(kind: .week, startDay: "2026-10-12", endDay: "2026-10-18")
    }
    private func compute(
        _ records: [AnalyticsRecordInput], period: AnalyticsPeriod? = nil,
        tag: String? = nil, instant: String = "2026-10-16T23:00:00Z",
        zone: TimeZone? = nil
    ) throws -> RecordsAnalyticsComputation {
        try RecordsAnalytics.compute(
            records: records, period: period ?? week, selectedTag: tag,
            now: date(instant), calendar: calendar, timeZone: zone ?? utc
        )
    }

    // 깨짐: 주를 일요일부터 계산하거나 7일을 벗어난다.
    func testW09b_선택수요일의_주는_월요일부터일요일이다() throws {
        let result = try RecordsAnalytics.period(kind: .week, containing: "2026-10-14", calendar: calendar)
        XCTAssertEqual(result.startDay, "2026-10-12")
        XCTAssertEqual(result.endDay, "2026-10-18")
        let report = try compute([], period: result).report
        XCTAssertEqual(report.days.count, 7)
        XCTAssertEqual(report.days.map(\.isFuture), [false, false, false, false, false, true, true])
    }

    // 깨짐: 월 길이를 고정하거나 윤년2월을28일로 처리한다.
    func testW09b_윤년과평년의_2월은29일과28일이다() throws {
        let leap = try RecordsAnalytics.period(kind: .month, containing: "2024-02-14", calendar: calendar)
        let normal = try RecordsAnalytics.period(kind: .month, containing: "2025-02-14", calendar: calendar)
        XCTAssertEqual(leap.endDay, "2024-02-29")
        XCTAssertEqual(normal.endDay, "2025-02-28")
        XCTAssertEqual(try compute([], period: leap).report.days.count, 29)
        XCTAssertEqual(try compute([], period: normal).report.days.count, 28)
    }

    // 깨짐: 연도경계를 넘는 주의 종료일을 같은 해로 만든다.
    func testW09b_연말주는_다음해일요일까지_포함한다() throws {
        let result = try RecordsAnalytics.period(kind: .week, containing: "2026-12-31", calendar: calendar)
        XCTAssertEqual(result.startDay, "2026-12-28")
        XCTAssertEqual(result.endDay, "2027-01-03")
    }

    // 깨짐: DST의23시간날을86400초로 순회하여 날짜를 중복하거나 누락한다.
    func testW09b_DST전환주도_서로다른7일을_반환한다() throws {
        var local = Calendar(identifier: .gregorian)
        let zone = try XCTUnwrap(TimeZone(identifier: "America/New_York"))
        local.timeZone = zone
        let period = try RecordsAnalytics.period(kind: .week, containing: "2026-03-08", calendar: local)
        let result = try RecordsAnalytics.compute(
            records: [], period: period, selectedTag: nil,
            now: date("2026-03-09T12:00:00Z"), calendar: local, timeZone: zone
        )
        XCTAssertEqual(result.report.days.map(\.day), ["2026-03-02", "2026-03-03", "2026-03-04", "2026-03-05", "2026-03-06", "2026-03-07", "2026-03-08"])
    }

    // 깨짐: 주입시간대를 무시하고 UTC날짜를 오늘로 쓴다.
    func testW09b_오늘은_주입서울시간대에서_다음날이다() throws {
        let result = try RecordsAnalytics.today(
            now: date("2026-10-16T23:00:00Z"), calendar: calendar,
            timeZone: XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        )
        XCTAssertEqual(result, "2026-10-17")
    }

    // 깨짐: 오늘보다 미래에 시작하는 다음주로 이동을 허용한다.
    func testW09b_미래주이동은_차단하고_이전주는_허용한다() throws {
        XCTAssertNil(try RecordsAnalytics.shift(period: week, by: 1, today: "2026-10-16", calendar: calendar))
        let previous = try XCTUnwrap(RecordsAnalytics.shift(period: week, by: -1, today: "2026-10-16", calendar: calendar))
        XCTAssertEqual(previous.startDay, "2026-10-05")
        XCTAssertEqual(previous.endDay, "2026-10-11")
    }

    // 깨짐: 완료시각을 재분류해 저장day대신 다른 날짜에 합산한다.
    func testW09b_저장day가_완료시각의_표시날짜보다_우선한다() throws {
        let record = try input("saved", day: "2026-10-12", completed: "2026-10-13T23:30:00Z")
        let result = try compute([record], zone: XCTUnwrap(TimeZone(identifier: "Asia/Seoul")))
        XCTAssertEqual(result.report.days.map(\.minutes), [10, 0, 0, 0, 0, 0, 0])
    }

    // 깨짐: 저장day가 미래이거나 completedAt이 미래인 기록을 포함한다.
    func testW09b_미래day와_미래완료시각은_각각_제외한다() throws {
        let records = try [
            input("ok", day: "2026-10-16", minutes: 10, completed: "2026-10-16T22:00:00Z"),
            input("future-day", day: "2026-10-17", minutes: 20, completed: "2026-10-16T22:00:00Z"),
            input("future-time", day: "2026-10-16", minutes: 30, completed: "2026-10-16T23:00:01Z")
        ]
        let result = try compute(records)
        XCTAssertEqual(result.report.totals.minutes, 10)
        XCTAssertEqual(result.scopedRecordIDs, ["ok"])
        let future = try XCTUnwrap(result.report.days.first { $0.day == "2026-10-17" })
        XCTAssertEqual(future.minutes, 0)
        XCTAssertTrue(future.isFuture)
    }

    // 깨짐: 빈날을 빼거나 같은날횟수/집중일수/평균을 혼동한다.
    func testW09b_60분3회2일의_주일별합계와_평균은_일치한다() throws {
        let records = try [input("a", day: "2026-10-12", minutes: 10), input("b", day: "2026-10-12", minutes: 20), input("c", minutes: 30)]
        let report = try compute(records).report
        XCTAssertEqual(report.totals, AnalyticsTotals(minutes: 60, count: 3, activeDays: 2, averageMinutes: 20))
        XCTAssertEqual(report.days.map(\.minutes), [30, 0, 30, 0, 0, 0, 0])
        XCTAssertEqual(report.days.map(\.count), [2, 0, 1, 0, 0, 0, 0])
        let month = AnalyticsPeriod(kind: .month, startDay: "2026-10-01", endDay: "2026-10-31")
        let monthReport = try compute(records, period: month).report
        XCTAssertEqual(monthReport.days.count, 31)
        XCTAssertEqual(monthReport.totals.minutes, 60)
        XCTAssertEqual(monthReport.days.map(\.minutes).reduce(0, +), 60)
    }

    // 깨짐: 평균을 버림하여10.5분을10분으로 만든다.
    func testW09b_평균10점5분은11분으로_반올림한다() throws {
        let result = try compute([input("a", minutes: 10), input("b", minutes: 11)])
        XCTAssertEqual(result.report.totals.averageMinutes, 11)
    }

    // 깨짐: 현재주비교에 이전주전체를 쓰거나 증감을 반대로 계산한다.
    func testW09b_현재주60분은_이전경과5일40분보다20분_증가다() throws {
        let records = try [input("a", minutes: 60), input("old", day: "2026-10-05", minutes: 40), input("excluded", day: "2026-10-10", minutes: 100)]
        let c = try compute(records).report.comparison
        XCTAssertEqual(c.previousStartDay, "2026-10-05")
        XCTAssertEqual(c.previousEndDay, "2026-10-09")
        XCTAssertEqual(c.currentMinutes, 60)
        XCTAssertEqual(c.previousMinutes, 40)
        XCTAssertEqual(c.deltaMinutes, 20)
        XCTAssertEqual(try XCTUnwrap(c.changePercent), 50, accuracy: 0.000001)
    }

    // 깨짐: 이전0분의 비율을 무한대나0퍼센트로 꾸민다.
    func testW09b_이전0분은_비교율없음과_현재증감을_제공한다() throws {
        let c = try compute([input("a", minutes: 30)]).report.comparison
        XCTAssertEqual(c.previousMinutes, 0)
        XCTAssertEqual(c.deltaMinutes, 30)
        XCTAssertNil(c.changePercent)
    }

    // 깨짐: 현재월31일의 이전동기간을2월밖으로 넘긴다.
    func testW09b_현재3월31일의_이전비교는_2월28일로_제한한다() throws {
        let period = AnalyticsPeriod(kind: .month, startDay: "2026-03-01", endDay: "2026-03-31")
        let result = try compute([], period: period, instant: "2026-03-31T23:00:00Z")
        XCTAssertEqual(result.report.days.count, 31)
        XCTAssertEqual(result.report.comparison.previousStartDay, "2026-02-01")
        XCTAssertEqual(result.report.comparison.previousEndDay, "2026-02-28")
    }

    // 깨짐: 연도1이전 비교기간을 만들며 정상 현재집계도 실패한다.
    func testW09b_연도1첫달은_이전비교없이_정상집계한다() throws {
        let period = AnalyticsPeriod(kind: .month, startDay: "0001-01-01", endDay: "0001-01-31")
        let result = try compute([], period: period)
        XCTAssertEqual(result.report.days.count, 31)
        XCTAssertNil(result.report.comparison.previousStartDay)
        XCTAssertNil(result.report.comparison.previousEndDay)
        XCTAssertEqual(result.report.comparison.previousMinutes, 0)
        XCTAssertNil(result.report.comparison.changePercent)
    }

    // 깨짐: 상위3만 반환해 나머지10분을 버리거나 삭제태그를 누락한다.
    func testW09b_태그40_30_20_10은_상위3과_나머지를_보존한다() throws {
        let result = try compute([input("a", minutes: 40, tag: "A"), input("b", minutes: 30, tag: "B"), input("c", minutes: 20, tag: "C"), input("d", minutes: 10, tag: "D")])
        XCTAssertEqual(result.report.totals.minutes, 100)
        XCTAssertEqual(result.report.tags.map(\.name), ["A", "B", "C", "D"])
        XCTAssertEqual(result.report.topTags.map(\.id), [.named("A"), .named("B"), .named("C"), .remainder])
        XCTAssertEqual(result.report.topTags.map(\.minutes), [40, 30, 20, 10])
        XCTAssertEqual(result.report.topTags.map(\.count), [1, 1, 1, 1])
        XCTAssertEqual(try XCTUnwrap(result.report.topTags.last).color, "#BFC6C1")
        XCTAssertEqual(try XCTUnwrap(result.report.tags.first).share, 0.4, accuracy: 0.000001)
    }

    // 깨짐: 실제이름기타를 나머지묶음과 같은 식별자로 합친다.
    func testW09b_실제기타태그와_나머지기타는_다른ID다() throws {
        let report = try compute([input("a", minutes: 40, tag: "기타"), input("b", minutes: 30, tag: "B"), input("c", minutes: 20, tag: "C"), input("d", minutes: 10, tag: "D")]).report
        XCTAssertEqual(try XCTUnwrap(report.topTags.first).id, .named("기타"))
        XCTAssertEqual(try XCTUnwrap(report.topTags.last).id, .remainder)
        XCTAssertEqual(report.topTags.map(\.minutes), [40, 30, 20, 10])
    }

    // 깨짐: 최신색을 안쓰거나 완료시각동률에서 입력뒤쪽색을 쓴다.
    func testW09b_대표색은_최신기록과_동률입력앞을_따른다() throws {
        let records = try [
            input("old", tag: "A", color: "#111111", completed: "2026-10-13T12:00:00Z"),
            input("new", tag: "A", color: "#222222", completed: "2026-10-14T12:00:00Z"),
            input("tie-first", tag: "B", color: "#333333"),
            input("tie-last", tag: "B", color: "#444444")
        ]
        let tags = try compute(records).report.tags
        XCTAssertEqual(tags.first { $0.name == "A" }?.color, "#222222")
        XCTAssertEqual(tags.first { $0.name == "B" }?.color, "#333333")
    }

    // 깨짐: 태그분동률에서 횟수와 이름순서를 무시한다.
    func testW09b_태그순위는_분_횟수_이름순이다() throws {
        let records = try [input("a", minutes: 20, tag: "C"), input("b", tag: "B"), input("c", tag: "B"), input("d", tag: "A"), input("e", tag: "A")]
        XCTAssertEqual(try compute(records).report.tags.map(\.name), ["A", "B", "C"])
    }

    // 깨짐: 기간에없는태그를 유지하여 하위분석을 거짓빈값으로 만든다.
    func testW09b_없는태그필터는_전체로_복귀한다() throws {
        let result = try compute([input("a", minutes: 20)], tag: "없음")
        XCTAssertNil(result.effectiveTag)
        XCTAssertEqual(result.scopedRecordIDs, ["a"])
        XCTAssertEqual(result.filteredDays.map(\.minutes), [0, 0, 20, 0, 0, 0, 0])
    }

    // 깨짐: 선택태그필터가 전체상단합계나 전체연속일을 좁힌다.
    func testW09b_선택태그는_하위활동만_좁히고_상단은전체다() throws {
        let records = try [input("a", day: "2026-10-12", minutes: 40, tag: "A"), input("b", day: "2026-10-13", minutes: 60, tag: "B")]
        let result = try compute(records, tag: "A")
        XCTAssertEqual(result.effectiveTag, "A")
        XCTAssertEqual(result.report.totals.minutes, 100)
        XCTAssertEqual(result.report.tags.map(\.minutes), [60, 40])
        XCTAssertEqual(result.filteredDays.map(\.minutes), [40, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(result.scopedRecordIDs, ["a"])
        XCTAssertEqual(result.insights.longestStreak, 2)
        XCTAssertEqual(result.insights.lengths.map(\.count), [0, 1, 0, 0, 0])
    }

    // 깨짐: 05/12/18시경계가 이전버킷에 속하거나 저장day시각을 사용한다.
    func testW09b_완료시각은_새벽오전오후저녁_경계를_따른다() throws {
        let records = try [input("a", minutes: 10, completed: "2026-10-14T04:59:00Z"), input("b", minutes: 20, completed: "2026-10-14T05:00:00Z"), input("c", minutes: 30, completed: "2026-10-14T12:00:00Z"), input("d", minutes: 40, completed: "2026-10-14T18:00:00Z")]
        let bands = try compute(records).insights.timeBands
        XCTAssertEqual(bands.map(\.band), [.dawn, .morning, .afternoon, .evening])
        XCTAssertEqual(bands.map(\.minutes), [10, 20, 30, 40])
        XCTAssertEqual(bands.map(\.count), [1, 1, 1, 1])
    }

    // 깨짐: 대상3회전에도 확정시간대인사이트로 안내한다.
    func testW09b_시간대대상2회는_추가기록안내_3회는_해제다() throws {
        XCTAssertTrue(try compute([input("a"), input("b")]).insights.needsMoreTimeBandRecords)
        XCTAssertFalse(try compute([input("a"), input("b"), input("c")]).insights.needsMoreTimeBandRecords)
    }

    // 깨짐: 30/60/120/240분포함경계를 잘못 정하여 누락/중복한다.
    func testW09b_길이9경계는_5버킷에_한번씩_속한다() throws {
        let records = try [30, 31, 60, 61, 120, 121, 240, 241, 360].enumerated().map { try input("length-\($0.offset)", minutes: $0.element) }
        let lengths = try compute(records).insights.lengths
        XCTAssertEqual(lengths.map(\.band), [.upTo30, .from31To60, .from61To120, .from121To240, .from241To360])
        XCTAssertEqual(lengths.map(\.count), [1, 2, 2, 2, 2])
        XCTAssertEqual(lengths.map(\.minutes), [30, 91, 181, 361, 601])
    }

    // 깨짐: 노선을버스번호만으로합치거나 횟수보다분을우선하거나 4개를반환한다.
    func testW09b_노선은_구조화키와_횟수시간순으로_상위3이다() throws {
        let records = try [input("a1", bus: "A"), input("a2", bus: "A"), input("b1", minutes: 30, bus: "B"), input("b2", bus: "B"), input("c", minutes: 20, bus: "A", to: "다른도착"), input("d", bus: "D")]
        let routes = try compute(records).insights.routes
        XCTAssertEqual(routes.map(\.bus), ["B", "A", "A"])
        XCTAssertEqual(routes.map(\.to), ["서울숲", "서울숲", "다른도착"])
        XCTAssertEqual(routes.map(\.count), [2, 2, 1])
        XCTAssertEqual(routes.map(\.minutes), [40, 20, 20])
    }

    // 깨짐: 같은날2회를 연속2일로 세거나 비연속일을 연결한다.
    func testW09b_동일날중복을제외한_최장연속은3일이다() throws {
        let records = try [input("a", day: "2026-10-12"), input("b", day: "2026-10-12"), input("c", day: "2026-10-13"), input("d", day: "2026-10-14"), input("e", day: "2026-10-16")]
        XCTAssertEqual(try compute(records).insights.longestStreak, 3)
    }

    // 깨짐: 중복ID를 조용히 합산/제거하여 부분성공을 반환한다.
    func testW09b_중복ID는_전체집계를_거절한다() throws {
        let records = try [input("same"), input("same", minutes: 20)]
        XCTAssertThrowsError(try compute(records)) { XCTAssertEqual($0 as? AnalyticsIssue, .invalidInput) }
    }

    // 깨짐: 손상날짜1건을 보정/skip하여 정상항목만 성공으로 반환한다.
    func testW09b_존재하지않는day는_전체집계를_거절한다() throws {
        let records = try [input("ok"), input("bad", day: "2026-02-30")]
        XCTAssertThrowsError(try compute(records)) { XCTAssertEqual($0 as? AnalyticsIssue, .invalidDay("2026-02-30")) }
    }

    // 깨짐:0분/361분을 버리거나 유효범위로 보정하여 성공한다.
    func testW09b_범위밖분은_전체집계를_거절한다() throws {
        for minutes in [0, 361] {
            let records = try [input("ok"), input("bad", minutes: minutes)]
            XCTAssertThrowsError(try compute(records)) { XCTAssertEqual($0 as? AnalyticsIssue, .invalidInput) }
        }
    }

    // 깨짐: 첫기록전 빈값에 비율/평균 가짜값을 넣거나 날짜를 생략한다.
    func testW09b_빈기간은_7일0과_빈태그를_제공한다() throws {
        let result = try compute([])
        XCTAssertEqual(result.report.totals, AnalyticsTotals(minutes: 0, count: 0, activeDays: 0, averageMinutes: 0))
        XCTAssertEqual(result.report.days.map(\.minutes), [0, 0, 0, 0, 0, 0, 0])
        XCTAssertEqual(result.report.tags, [])
        XCTAssertEqual(result.report.topTags, [])
        XCTAssertEqual(result.scopedRecordIDs, [])
        XCTAssertEqual(result.insights.longestStreak, 0)
    }

    // 깨짐: 앱전용원본ID·할일·메모가 위젯소비report JSON으로 유출된다.
    func testW09b_report직렬화에는_ID_할일_메모키가_없다() throws {
        let report = try compute([input("private-record-id", tag: "독서")]).report
        let data = try JSONEncoder().encode(report)
        let json = try JSONSerialization.jsonObject(with: data)
        func keys(_ object: Any) -> [String] {
            if let map = object as? [String: Any] { return Array(map.keys) + map.values.flatMap(keys) }
            if let list = object as? [Any] { return list.flatMap(keys) }
            return []
        }
        let names = Set(keys(json).map { $0.lowercased() })
        XCTAssertTrue(names.isDisjoint(with: ["recordid", "recordids", "task", "memo", "scopedrecordids"]))
        // 태그의 named/remainder 식별자 id는 승인 DTO이며 원본record id와 구분한다.
        XCTAssertFalse(String(decoding: data, as: UTF8.self).contains("private-record-id"))
    }
}
