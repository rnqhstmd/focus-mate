import Foundation
import XCTest
@testable import FocusMate

final class WidgetTimelinePlanTests: XCTestCase {
    private typealias F = WidgetFixtures

    // 깨짐:30분경계entry를누락하거나같은snapshot의저장진도를시간만큼외삽한다.
    func testW18_fresh공유본은_현재와30분stale_두entry를_제공한다() {
        let snapshot = F.snapshot()
        let entries = WidgetTimelinePlan.entries(state: .valid(snapshot), now: F.generated, timeZone: F.utc)

        XCTAssertEqual(entries, [
            WidgetTimelineValue(date: F.date("2026-10-16T12:00:00Z"), state: .valid(snapshot)),
            WidgetTimelineValue(date: F.date("2026-10-16T12:30:00Z"), state: .stale(snapshot))
        ])
    }

    // 깨짐:자정entry에서지난날분석을재계산하거나기준일과저장경과678을바꾼다.
    func testW18_30분보다빠른자정은_같은공유본을_stale로만_바꾼다() throws {
        let base = F.snapshot()
        let snapshot = WidgetSnapshot(
            version: base.version, generatedAt: F.date("2026-10-16T23:50:00Z"),
            basisDay: base.basisDay, timeZoneID: base.timeZoneID, journey: base.journey, analytics: base.analytics
        )
        let entries = WidgetTimelinePlan.entries(state: .valid(snapshot), now: F.date("2026-10-16T23:55:00Z"), timeZone: F.utc)

        XCTAssertEqual(entries, [
            WidgetTimelineValue(date: F.date("2026-10-16T23:55:00Z"), state: .valid(snapshot)),
            WidgetTimelineValue(date: F.date("2026-10-17T00:00:00Z"), state: .stale(snapshot))
        ])
        let next = try XCTUnwrap(entries.last)
        guard case .stale(let retained) = next.state else { return XCTFail("다음 entry는 stale이어야 한다") }
        XCTAssertEqual(retained.journey.elapsedSeconds, 678)
        XCTAssertEqual(retained.analytics.days.map(\.minutes), [30, 0, 30, 0, 0, 0, 0])
        XCTAssertEqual(retained.basisDay, "2026-10-16")
    }

    // 깨짐:이미stale인자료를즉시재요청하거나fresh로되살린다.
    func testW18_stale공유본은_15분뒤에도_같은값으로_stale이다() {
        let snapshot = F.snapshot()
        let entries = WidgetTimelinePlan.entries(state: .stale(snapshot), now: F.date("2026-10-16T12:30:00Z"), timeZone: F.utc)

        XCTAssertEqual(entries, [
            WidgetTimelineValue(date: F.date("2026-10-16T12:30:00Z"), state: .stale(snapshot)),
            WidgetTimelineValue(date: F.date("2026-10-16T12:45:00Z"), state: .stale(snapshot))
        ])
    }

    // 깨짐:오류상태를다음entry에서정상0으로대체하거나오류종류를잃는다.
    func testW18_오류타임라인도_두entry에서_같은오류를_유지한다() {
        let states: [WidgetReadState] = [.unavailable, .malformed, .unsupportedVersion(2)]
        for state in states {
            let entries = WidgetTimelinePlan.entries(state: state, now: F.generated, timeZone: F.utc)
            XCTAssertEqual(entries, [
                WidgetTimelineValue(date: F.date("2026-10-16T12:00:00Z"), state: state),
                WidgetTimelineValue(date: F.date("2026-10-16T12:15:00Z"), state: state)
            ])
        }
    }
}
