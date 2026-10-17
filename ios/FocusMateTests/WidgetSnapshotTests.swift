import Foundation
import XCTest
@testable import FocusMate

final class WidgetSnapshotTests: XCTestCase {
    private typealias F = WidgetFixtures

    // 합계가 맞더라도 상위 세 태그를 넘는 원문 배열은 공유 계약이 아니다.
    func testW18_named태그4개는_합계가맞아도_거부한다() throws {
        try assertRejectedTags([
            named("A", 40, 1), named("B", 30, 1), named("C", 20, 1), named("D", 10, 1)
        ])
    }

    func testW18_기타단독은_거부한다() throws {
        try assertRejectedTags([remainder(100, 4)])
    }

    func testW18_기타가상위태그중간에있으면_거부한다() throws {
        try assertRejectedTags([
            named("A", 40, 1), remainder(10, 1), named("B", 30, 1), named("C", 20, 1)
        ])
    }

    func testW18_기타중복은_거부한다() throws {
        try assertRejectedTags([
            named("A", 40, 1), named("B", 30, 1), remainder(20, 1), remainder(10, 1)
        ])
    }

    func testW18_기타횟수0은_거부한다() throws {
        try assertRejectedTags([
            named("A", 40, 2), named("B", 30, 1), named("C", 20, 1), remainder(10, 0)
        ])
    }

    func testW18_named태그1부터3개는_왕복허용한다() throws {
        let cases: [[WidgetTag]] = [
            [named("A", 100, 4)],
            [named("A", 60, 2), named("B", 40, 2)],
            [named("A", 50, 2), named("B", 30, 1), named("C", 20, 1)]
        ]
        for tags in cases {
            let snapshot = structureSnapshot(tags: tags)
            XCTAssertEqual(WidgetSnapshotCodec.decode(try WidgetSnapshotCodec.encode(snapshot)), .valid(snapshot))
        }
    }

    func testW18_named3개와마지막기타는_왕복허용한다() throws {
        let snapshot = structureSnapshot(tags: [
            named("A", 40, 1), named("B", 30, 1), named("C", 20, 1), remainder(10, 1)
        ])
        XCTAssertEqual(WidgetSnapshotCodec.decode(try WidgetSnapshotCodec.encode(snapshot)), .valid(snapshot))
    }

    private func named(_ name: String, _ minutes: Int, _ count: Int) -> WidgetTag {
        WidgetTag(id: .named(name), name: name, color: "#12ABef", minutes: minutes, count: count)
    }

    private func remainder(_ minutes: Int, _ count: Int) -> WidgetTag {
        WidgetTag(id: .remainder, name: "기타", color: "#BFC6C1", minutes: minutes, count: count)
    }

    private func structureSnapshot(tags: [WidgetTag]) -> WidgetSnapshot {
        let base = F.snapshot()
        var days = base.analytics.days.map { WidgetDay(day: $0.day, minutes: 0, count: 0) }
        days[4] = WidgetDay(day: "2026-10-16", minutes: 100, count: 4)
        return WidgetSnapshot(version: 1, generatedAt: F.generated, basisDay: "2026-10-16", timeZoneID: "GMT",
                              journey: F.journey,
                              analytics: WidgetAnalytics(today: days[4], weekStart: "2026-10-12", weekEnd: "2026-10-18",
                                                         weekMinutes: 100, weekCount: 4, days: days, tags: tags))
    }

    private func assertRejectedTags(_ tags: [WidgetTag], file: StaticString = #filePath, line: UInt = #line) throws {
        let snapshot = structureSnapshot(tags: tags)
        // 생산 encoder를 우회한 입력으로 decode의 실제 검증 경계를 확인한다.
        XCTAssertEqual(WidgetSnapshotCodec.decode(try JSONEncoder().encode(snapshot)), .malformed, file: file, line: line)
        XCTAssertThrowsError(try WidgetSnapshotCodec.encode(snapshot), file: file, line: line) { error in
            XCTAssertEqual(error as? WidgetDataIssue, .invalidSnapshot, file: file, line: line)
        }
    }

    // 깨짐: 공유7일/태그/저장여정이 codec 왕복에서 사라지거나 바뀐다.
    func testW18_최소공유본은_7일과_저장여정을_왕복보존한다() throws {
        let snapshot = F.snapshot()
        let encoded = try WidgetSnapshotCodec.encode(snapshot)
        XCTAssertEqual(WidgetSnapshotCodec.decode(encoded), .valid(snapshot))
    }

    // 깨짐: codec가 원본ID목록/메모/할일/카드/전체report를 공유한다.
    func testW18_공유JSON은_최소투영만_허용한다() throws {
        let data = try WidgetSnapshotCodec.encode(F.snapshot())
        let object = try JSONSerialization.jsonObject(with: data)
        func keys(_ value: Any) -> [String] {
            if let map = value as? [String: Any] { return Array(map.keys) + map.values.flatMap(keys) }
            if let list = value as? [Any] { return list.flatMap(keys) }
            return []
        }
        XCTAssertTrue(Set(keys(object).map { $0.lowercased() }).isDisjoint(with: ["cardid", "task", "memo", "recordid", "recordids", "scopedrecordids", "report", "recent", "routes", "insights"]))
        // journeyID와 named/remainder 태그id는 승인된 최소 식별자다.
    }

    // 깨짐: version만읽어도 판별할수있는2를 malformed로 낮춘다.
    func testW18_버전2는_나머지필드없이도_미지원으로_구분한다() {
        XCTAssertEqual(WidgetSnapshotCodec.decode(Data(#"{"version":2}"#.utf8)), .unsupportedVersion(2))
    }

    // 호환 회귀. 깨짐: 분합계/날짜연속성이 어긋난 공유본을 보정하여 정상화한다.
    func testW18_합계와_날짜불일치는_malformed다() throws {
        let wrongTotal = try JSONEncoder().encode(F.snapshot(total: 61))
        XCTAssertEqual(WidgetSnapshotCodec.decode(wrongTotal), .malformed)
        var days = F.snapshot().analytics.days
        days[1] = WidgetDay(day: "2026-10-12", minutes: 0, count: 0)
        let wrongDay = try JSONEncoder().encode(F.replacingDays(days))
        XCTAssertEqual(WidgetSnapshotCodec.decode(wrongDay), .malformed)
    }

    // 깨짐: 분석0건을 이유로 진행여정을 지우거나 validEmpty를 unavailable로 바꾼다.
    func testW18_validEmpty도_정지여정을_유지한다() {
        let snapshot = F.snapshot(empty: true)
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.generated, timeZone: F.utc), .validEmpty(snapshot))
    }

    // 깨짐:30분경계가포함되거나1799초에 조기만료된다.
    func testW18_1799초는_valid_1800초는_stale이다() {
        let snapshot = F.snapshot()
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.date("2026-10-16T12:29:59Z"), timeZone: F.utc), .valid(snapshot))
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.date("2026-10-16T12:30:00Z"), timeZone: F.utc), .stale(snapshot))
    }

    // 깨짐: 날짜또는표시시간대변경후에도 오늘현재값으로 설명한다.
    func testW18_자정또는_시간대변경은_stale이다() throws {
        let snapshot = F.snapshot()
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.date("2026-10-17T00:00:00Z"), timeZone: F.utc), .stale(snapshot))
        let seoul = try XCTUnwrap(TimeZone(identifier: "Asia/Seoul"))
        XCTAssertEqual(WidgetFreshness.classify(.valid(snapshot), now: F.generated, timeZone: seoul), .stale(snapshot))
    }

    // 깨짐: 생성시각이미래인데 fresh/stale 공유정보로 허용한다.
    func testW18_미래생성시각은_malformed다() {
        XCTAssertEqual(WidgetFreshness.classify(.valid(F.snapshot()), now: F.date("2026-10-16T11:59:59Z"), timeZone: F.utc), .malformed)
    }
}
