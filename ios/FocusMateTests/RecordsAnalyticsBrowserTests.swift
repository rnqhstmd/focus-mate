import Foundation
import XCTest
@testable import FocusMate

final class RecordsAnalyticsBrowserTests: XCTestCase {
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        return value
    }
    private var tags: [AnalyticsTagTotal] {
        [AnalyticsTagTotal(id: .named("독서"), name: "독서", color: "#12ABef", minutes: 25, count: 1, share: 1)]
    }

    // 깨짐: 선택일대신 오늘이나월초를 초기anchor로 쓴다.
    func testW09b_10월14일진입은_해당월과_anchor를_보존한다() throws {
        let browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        XCTAssertEqual(browser.period, AnalyticsPeriod(kind: .month, startDay: "2026-10-01", endDay: "2026-10-31"))
        XCTAssertEqual(browser.anchorDay, "2026-10-14")
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 월초를기준으로 주전환하여10-14가없는주를고르거나 태그를유지한다.
    func testW09b_월주왕복은_선택일anchor를_유지하고_태그를_해제한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        try browser.setKind(.week, calendar: calendar)
        XCTAssertEqual(browser.period, AnalyticsPeriod(kind: .week, startDay: "2026-10-12", endDay: "2026-10-18"))
        XCTAssertEqual(browser.anchorDay, "2026-10-14")
        XCTAssertNil(browser.selectedTag)
        try browser.setKind(.month, calendar: calendar)
        XCTAssertEqual(browser.period.startDay, "2026-10-01")
        XCTAssertEqual(browser.anchorDay, "2026-10-14")
    }

    // 깨짐: 거부된 미래이동이 태그·anchor·기간 중 일부를 바꾼다.
    func testW09b_미래주이동거부는_전체상태를_보존한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        try browser.setKind(.week, calendar: calendar)
        browser.selectTag("독서", available: tags)
        let before = browser
        XCTAssertFalse(try browser.move(by: 1, today: "2026-10-16", calendar: calendar))
        XCTAssertEqual(browser, before)
        XCTAssertEqual(browser.selectedTag, "독서")
    }

    // 깨짐: 기간이동후기존anchor/태그를유지하여 다음종류전환이 이전기간으로돌아간다.
    func testW09b_이전주이동은_새기간시작anchor와_태그해제를_적용한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        try browser.setKind(.week, calendar: calendar)
        browser.selectTag("독서", available: tags)
        XCTAssertTrue(try browser.move(by: -1, today: "2026-10-16", calendar: calendar))
        XCTAssertEqual(browser.period.startDay, "2026-10-05")
        XCTAssertEqual(browser.period.endDay, "2026-10-11")
        XCTAssertEqual(browser.anchorDay, "2026-10-05")
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 오늘복귀가 최초선택일로돌아가거나 기간종류/태그를잘못바꾼다.
    func testW09b_오늘복귀는_현재종류의_오늘기간과_anchor로_돌아간다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-09-14", calendar: calendar)
        try browser.setKind(.week, calendar: calendar)
        browser.selectTag("독서", available: tags)
        try browser.returnToToday(today: "2026-10-16", calendar: calendar)
        XCTAssertEqual(browser.period, AnalyticsPeriod(kind: .week, startDay: "2026-10-12", endDay: "2026-10-18"))
        XCTAssertEqual(browser.anchorDay, "2026-10-16")
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 같은태그재선택이 해제되지않거나 첫선택이 무시된다.
    func testW09b_같은태그_재선택은_전체로_토글한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        XCTAssertEqual(browser.selectedTag, "독서")
        browser.selectTag("독서", available: tags)
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 없는태그를선택상태로남겨 하위분석을거짓빈값으로만든다.
    func testW09b_없는태그선택은_전체로_복귀한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        browser.selectTag("없는태그", available: tags)
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 갱신후사라진태그를 선택상태로 유지한다.
    func testW09b_reconcile은_삭제된선택태그를_해제한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        browser.reconcileTags(available: [])
        XCTAssertNil(browser.selectedTag)
    }

    // 깨짐: 기록갱신때 존재하는선택태그까지 무조건해제한다.
    func testW09b_reconcile은_아직존재하는태그선택을_유지한다() throws {
        var browser = try RecordsAnalyticsBrowser(selectedDay: "2026-10-14", calendar: calendar)
        browser.selectTag("독서", available: tags)
        browser.reconcileTags(available: tags)
        XCTAssertEqual(browser.selectedTag, "독서")
    }
}
