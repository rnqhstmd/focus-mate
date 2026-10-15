import Foundation
import XCTest
@testable import FocusMate

/// 하차 계산 (AC-10, BR-2, BR-3, AC-28/BR-5). 25분 버스2014, 성수역 출발, 도착지 서울숲 입구.
@MainActor
final class AlightingSnapshotTests: XCTestCase {
    private typealias F = BoardingFixtures

    private static let seoul = TimeZone(identifier: "Asia/Seoul")!
    private static let utc = TimeZone(identifier: "UTC")!

    private static func date(_ iso: String) -> Date {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: iso)!
    }

    private func journey(elapsed: Int, id: String = "journey-1") -> JourneySnapshot {
        F.journey(
            id: id, originStopID: "seongsu", direction: 1, minutes: 25, busID: "2014",
            destinationStopID: "seoulForestGate", task: "논문", phase: .departed, elapsedSeconds: elapsed, paused: true
        )
    }

    private let completedAt = AlightingSnapshotTests.date("2026-10-13T09:25:00.500Z")

    // 깨짐: 기록 필드 매핑(분·태그·할 일·from/to·색상·날짜·시각 형식) 중 하나라도 틀리면 실패.
    func testAC10_하차하면_기록이_1건_생기고_모든필드가_채워진다() throws {
        let before = F.snapshot(active: journey(elapsed: 1500))

        let result = try before.alightingActiveJourney(completedAt: completedAt, timeZone: Self.seoul)

        XCTAssertEqual(result.snapshot.records.items.count, 1)
        let record = try XCTUnwrap(result.snapshot.records.items.first)
        XCTAssertEqual(record.id, "journey-1")
        XCTAssertEqual(record.minutes, 25)
        XCTAssertEqual(record.tag, "독서")
        XCTAssertEqual(record.task, "논문")
        XCTAssertEqual(record.from, "성수역")
        XCTAssertEqual(record.to, "서울숲 입구")
        XCTAssertEqual(record.memo, "")
        XCTAssertEqual(record.date, "2026-10-13")
        XCTAssertEqual(record.tagColor, "#d7b378")
        XCTAssertEqual(record.bus, "2014")
        XCTAssertEqual(record.completedAt, "2026-10-13T09:25:00.500Z")
        XCTAssertEqual(record.completedAt.utf16.count, 24)
        XCTAssertEqual(result.record.id, "journey-1")
    }

    // 깨짐: 현재 정류장을 도착지로 옮기지 않거나 진행 여정을 비우지 않으면 실패.
    func testAC10_하차하면_현재정류장이_도착지가_되고_진행여정이_없다() throws {
        let before = F.snapshot(active: journey(elapsed: 1500))

        let after = try before.alightingActiveJourney(completedAt: completedAt, timeZone: Self.seoul).snapshot

        XCTAssertEqual(after.currentStation, StationSnapshot(id: "seoulForestGate", name: "서울숲 입구", direction: 1))
        XCTAssertNil(after.journey.active)
    }

    // 깨짐: 도착 검사를 빼면 throw 대신 성공해 실패.
    func testBR3_미도착_여정은_notArrived를_던진다() {
        let before = F.snapshot(active: journey(elapsed: 600))

        XCTAssertThrowsError(try before.alightingActiveJourney(completedAt: completedAt, timeZone: Self.seoul)) {
            XCTAssertEqual($0 as? AlightingIssue, .notArrived)
        }
    }

    // 깨짐: 진행 여정이 없을 때 다른 오류를 던지거나 성공하면 실패.
    func testBR3_진행여정이_없으면_noActiveJourney를_던진다() {
        let before = F.snapshot(active: nil)

        XCTAssertThrowsError(try before.alightingActiveJourney(completedAt: completedAt, timeZone: Self.seoul)) {
            XCTAssertEqual($0 as? AlightingIssue, .noActiveJourney)
        }
    }

    // 깨짐: 같은 id 기록을 또 만들거나 기존 기록을 덮으면, 또는 여정을 종료하지 않으면 실패.
    func testBR2_같은_여정id_기록이_있으면_1건을_유지하고_여정은_종료된다() throws {
        let existing = RecordSnapshot(
            id: "journey-1", completedAt: "2026-10-13T09:20:00Z", date: "2026-10-13", bus: "버스2014",
            tag: "독서", tagColor: "#d7b378", task: "논문", minutes: 25, sound: "버스",
            from: "성수역", to: "서울숲 입구", memo: "먼저 쓴 메모"
        )
        let before = F.snapshot(active: journey(elapsed: 1500)).updating(records: RecordSection(items: [existing]))

        let after = try before.alightingActiveJourney(completedAt: completedAt, timeZone: Self.seoul).snapshot

        XCTAssertEqual(after.records.items, [existing])
        XCTAssertNil(after.journey.active)
    }

    // 깨짐: UTC 날짜나 다음날 날짜를 쓰면(Seoul 23:50 = 14:50Z) 실패.
    func testAC28_서울_12월31일_2350_하차는_같은날짜로_기록된다() throws {
        let at = Self.date("2026-12-31T23:50:00.000+09:00")
        let before = F.snapshot(active: journey(elapsed: 1500))

        let record = try XCTUnwrap(before.alightingActiveJourney(completedAt: at, timeZone: Self.seoul).snapshot.records.items.first)

        XCTAssertEqual(record.date, "2026-12-31")
    }

    // 깨짐: 주입 시간대를 무시하고 고정 시간대를 쓰면 실패(같은 순간이 Seoul 1/1, UTC 12/31).
    func testAC28_주입한_시간대의_날짜로_기록된다() throws {
        let at = Self.date("2027-01-01T00:30:00.000+09:00")
        let before = F.snapshot(active: journey(elapsed: 1500))

        let seoulRecord = try XCTUnwrap(before.alightingActiveJourney(completedAt: at, timeZone: Self.seoul).snapshot.records.items.first)
        let utcRecord = try XCTUnwrap(before.alightingActiveJourney(completedAt: at, timeZone: Self.utc).snapshot.records.items.first)

        XCTAssertEqual(seoulRecord.date, "2027-01-01")
        XCTAssertEqual(utcRecord.date, "2026-12-31")
    }
}
