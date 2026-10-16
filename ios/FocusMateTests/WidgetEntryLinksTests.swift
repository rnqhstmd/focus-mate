import Foundation
import XCTest
@testable import FocusMate

final class WidgetEntryLinksTests: XCTestCase {
    private typealias F = WidgetFixtures

    // 깨짐:집중위젯링크가공유여정ID를누락하거나발급시각을렌더시각으로세탁한다.
    func testW18_집중링크는_공유여정ID와_원본발급시각을_보존한다() throws {
        let snapshot = F.snapshot()
        let url = try XCTUnwrap(WidgetEntryLinks.focus(state: .stale(snapshot)))

        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.generated), .valid(WidgetLink(
            issuedAt: F.date("2026-10-16T12:00:00Z"), target: .journey(expectedID: "journey-독서")
        )))
        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.date("2026-10-17T12:00:00Z")), .expired)
    }

    // 깨짐:공유본없음을샘플여정/분석링크로꾸미거나앱열기경로를제공하지않는다.
    func testW18_오류상태의_두위젯링크는_안전기본URL이다() throws {
        let states: [WidgetReadState] = [.unavailable, .malformed, .unsupportedVersion(2)]
        for state in states {
            let focus = try XCTUnwrap(WidgetEntryLinks.focus(state: state))
            let analytics = try XCTUnwrap(WidgetEntryLinks.analytics(state: state))
            XCTAssertEqual(focus.absoluteString, "focusmate://widget")
            XCTAssertEqual(analytics.absoluteString, "focusmate://widget")
        }
    }

    // 깨짐:태그선택분석링크가위젯주간맥락이나선택날짜/태그이름을잃는다.
    func testW18_named태그분석링크는_선택날짜와_week를_전달한다() throws {
        let snapshot = F.snapshot()
        let tag = try XCTUnwrap(snapshot.analytics.tags.first)
        let url = try XCTUnwrap(WidgetEntryLinks.analytics(state: .valid(snapshot), day: "2026-10-14", tag: tag))

        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.generated), .valid(WidgetLink(
            issuedAt: F.date("2026-10-16T12:00:00Z"), target: .analytics(day: "2026-10-14", tag: "독서", kind: .week)
        )))
    }

    // 깨짐:묶음기타를실제기타태그로필터하거나기본day를현재시각으로바꾼다.
    func testW18_remainder분석링크는_이전기준일과_전체태그를_전달한다() throws {
        let remainder = WidgetTag(id: .remainder, name: "기타", color: "#BFC6C1", minutes: 10, count: 1)
        let url = try XCTUnwrap(WidgetEntryLinks.analytics(state: .stale(F.snapshot()), tag: remainder))

        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.generated), .valid(WidgetLink(
            issuedAt: F.date("2026-10-16T12:00:00Z"), target: .analytics(day: "2026-10-16", tag: nil, kind: .week)
        )))
        XCTAssertEqual(WidgetLinkCodec.parse(url, now: F.date("2026-10-17T12:00:00Z")), .expired)
    }
}
