import Foundation
import XCTest
@testable import FocusMate

final class RecordLifetimeSummaryTests: XCTestCase {
    private static let seoul = TimeZone(identifier: "Asia/Seoul")!

    // 깨짐 명명: 건수 대신 분 합이나 날짜별 일부만 세거나 minutes 합산을 빠뜨리면 실패.
    func testAC12_서로다른ID_세건은_건수3과_분합60을_반환한다() throws {
        let section = RecordSection(items: [
            Self.record(id: "a", date: "2026-10-11", minutes: 10),
            Self.record(id: "b", date: "2026-10-12", minutes: 20),
            Self.record(id: "c", date: "2026-10-13", minutes: 30),
        ])

        XCTAssertEqual(try section.lifetimeSummary(), RecordLifetimeSummary(count: 3, minutes: 60))
    }

    // 깨짐 명명: 집계가 내부 상태를 누적·변경해 두 번째 호출 결과가 달라지면 실패.
    func testAC12_같은입력을_두번요청해도_결과가_같다() throws {
        let section = RecordSection(items: [
            Self.record(id: "a", minutes: 25),
            Self.record(id: "b", minutes: 35),
        ])

        let first = try section.lifetimeSummary()
        let second = try section.lifetimeSummary()

        XCTAssertEqual(first, RecordLifetimeSummary(count: 2, minutes: 60))
        XCTAssertEqual(second, first)
    }

    // 깨짐 명명: 빈 섹션에서 오류를 던지거나 nil/비0 값을 반환하면 실패.
    func testAC12_기록이_0건이면_건수0_분0이다() throws {
        XCTAssertEqual(try RecordSection.empty.lifetimeSummary(), RecordLifetimeSummary(count: 0, minutes: 0))
    }

    // 깨짐 명명: 예시 완료 저장 시도가 누적 건수나 분에 반영되면 실패.
    func testAC13_예시완료_저장시도는_누적집계를_바꾸지않는다() throws {
        let before = RecordSection(items: [Self.record(id: "real", minutes: 25)])
        let summaryBefore = try before.lifetimeSummary()

        let after = try before.recordingCompletion(
            Self.input(id: "example", minutes: 40),
            outcome: .alighted,
            isExample: true,
            timeZone: Self.seoul
        )

        XCTAssertEqual(summaryBefore, RecordLifetimeSummary(count: 1, minutes: 25))
        XCTAssertEqual(try after.lifetimeSummary(), summaryBefore)
    }

    // 깨짐 명명: 유효하지 않은 1건을 건너뛰고 나머지 4건(합 100)만 합산해 반환하면 실패.
    func testAC30_저장기록_5건중_minutes0이_있으면_일부합산_대신_invalidMinutes를_던진다() {
        let section = RecordSection(items: [
            Self.record(id: "a", minutes: 25),
            Self.record(id: "b", minutes: 25),
            Self.record(id: "bad", minutes: 0),
            Self.record(id: "d", minutes: 25),
            Self.record(id: "e", minutes: 25),
        ])

        do {
            let summary = try section.lifetimeSummary()
            XCTFail("Expected invalidMinutes(0), got \(summary)")
        } catch let issue as RecordValidationIssue {
            XCTAssertEqual(issue, .invalidMinutes(0))
        } catch {
            XCTFail("Expected RecordValidationIssue.invalidMinutes(0), got \(error)")
        }
    }

    private static func input(
        id: String = "journey-001",
        completedAt: String = "2026-10-13T01:00:00Z",
        minutes: Int = 25
    ) -> RecordCompletionInput {
        RecordCompletionInput(
            id: id,
            completedAt: completedAt,
            bus: "버스2014",
            tag: "독서",
            tagColor: "#12ABef",
            task: "책 한 챕터 읽기",
            minutes: minutes,
            sound: "빗소리",
            from: "성수역",
            to: "서울숲 입구"
        )
    }

    private static func record(
        id: String = "journey-001",
        completedAt: String = "2026-10-13T01:00:00Z",
        date: String = "2026-10-13",
        minutes: Int = 25
    ) -> RecordSnapshot {
        RecordSnapshot(
            id: id,
            completedAt: completedAt,
            date: date,
            bus: "버스2014",
            tag: "독서",
            tagColor: "#12ABef",
            task: "책 한 챕터 읽기",
            minutes: minutes,
            sound: "빗소리",
            from: "성수역",
            to: "서울숲 입구",
            memo: ""
        )
    }
}
