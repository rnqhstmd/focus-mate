import Foundation
import XCTest
@testable import FocusMate

final class WidgetLinkTests: XCTestCase {
    private typealias F = WidgetFixtures
    private func url(_ target: WidgetLinkTarget = .journey(expectedID: "journey-독서")) throws -> URL {
        try XCTUnwrap(WidgetLinkCodec.makeURL(WidgetLink(issuedAt: F.generated, target: target)))
    }

    // 깨짐: 한글·구분자를포함한원본여정ID를분해하거나 다른ID로복원한다.
    func testW18_여정링크는_원본ID를_왕복한다() throws {
        let target = WidgetLinkTarget.journey(expectedID: "여정/독서?1&2")
        let value = try url(target)
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.generated), .valid(WidgetLink(issuedAt: F.generated, target: target)))
    }

    // 깨짐: 위젯주간맥락을앱월간으로바꾸거나 태그/날짜를잃는다.
    func testW18_분석링크는_날짜태그와_week종류를_보존한다() throws {
        let target = WidgetLinkTarget.analytics(day: "2026-10-14", tag: "독서", kind: .week)
        XCTAssertEqual(WidgetLinkCodec.parse(try url(target), now: F.generated), .valid(WidgetLink(issuedAt: F.generated, target: target)))
    }

    // 깨짐:24시간정각을허용하거나 만료1초전에 차단한다.
    func testW18_TTL86399초는_유효하고86400초는_만료다() throws {
        let value = try url()
        let link = WidgetLink(issuedAt: F.generated, target: .journey(expectedID: "journey-독서"))
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.date("2026-10-17T11:59:59Z")), .valid(link))
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.date("2026-10-17T12:00:00Z")), .expired)
    }

    // 호환 회귀. 깨짐: 알수없는경로를기본여정으로 해석한다.
    func testW18_알수없는경로는_invalid다() throws {
        let value = try XCTUnwrap(URL(string: "focusmate://widget/unknown?v=1&issuedAt=1792152000"))
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.generated), .invalid)
    }

    // 깨짐: 중복query값중하나를 임의선택하여 권한없는입력을 허용한다.
    func testW18_중복query는_invalid다() throws {
        var components = try XCTUnwrap(URLComponents(url: url(), resolvingAgainstBaseURL: false))
        let first = try XCTUnwrap(components.queryItems?.first)
        components.queryItems = (components.queryItems ?? []) + [first]
        XCTAssertEqual(WidgetLinkCodec.parse(try XCTUnwrap(components.url), now: F.generated), .invalid)
    }

    // 호환 회귀. 깨짐: 미래발급시각을 유효TTL로 받아들인다.
    func testW18_미래발급링크는_invalid다() throws {
        let value = try XCTUnwrap(URL(string: "focusmate://widget/analytics?v=1&issuedAt=1792152001&period=week"))
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.generated), .invalid)
    }

    // 깨짐: 링크생성때옛snapshot발급시각을현재렌더시각으로 세탁한다.
    func testW18_링크발급시각은_공유본원본시각을_유지한다() throws {
        let value = try url(.newJourney(expectedID: nil))
        let components = try XCTUnwrap(URLComponents(url: value, resolvingAgainstBaseURL: false))
        XCTAssertEqual(components.queryItems?.first { $0.name == "issuedAt" }?.value, "1792152000")
        XCTAssertEqual(WidgetLinkCodec.parse(value, now: F.date("2026-10-17T12:00:00Z")), .expired)
    }
}
