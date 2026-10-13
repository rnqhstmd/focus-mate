import Foundation
import XCTest
@testable import FocusMate

final class RecordSectionTests: XCTestCase {
    private static let seoul = TimeZone(identifier: "Asia/Seoul")!
    private static let losAngeles = TimeZone(identifier: "America/Los_Angeles")!

    // 깨짐 명명: 정상 완료를 누락하거나 입력 필드·완료 당시 로컬 날짜를 바꾸면 실패.
    func testAC1_하차성공은_모든필드와_서울완료날짜를_기록한다() throws {
        let section = try RecordSection.empty.recordingCompletion(
            Self.input(), outcome: .alighted, timeZone: Self.seoul
        )

        let record = try XCTUnwrap(section.items.first)
        XCTAssertEqual(section.items.count, 1)
        assertUTF16(record.id, "journey-001")
        assertUTF16(record.completedAt, "2026-10-13T01:00:00Z")
        assertUTF16(record.date, "2026-10-13")
        assertUTF16(record.bus, "버스2014")
        assertUTF16(record.tag, "독서")
        assertUTF16(record.tagColor, "#12ABef")
        assertUTF16(record.task, "책 한 챕터 읽기")
        XCTAssertEqual(record.minutes, 25)
        assertUTF16(record.sound, "빗소리")
        assertUTF16(record.from, "성수역")
        assertUTF16(record.to, "서울숲 입구")
        assertUTF16(record.memo, "")
    }

    // 깨짐 명명: 진행·포기·예시 입력 중 하나라도 완료 기록이나 집계에 포함하면 실패.
    func testAC2_진행_포기_예시는_기록과_집계에서_제외된다() throws {
        var section = RecordSection.empty
        section = try section.recordingCompletion(Self.input(id: "active"), outcome: .active, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: "abandoned"), outcome: .abandoned, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: "example"), outcome: .alighted, isExample: true, timeZone: Self.seoul)

        XCTAssertEqual(section.items.count, 0)
        XCTAssertEqual(try section.dailySummary(on: "2026-10-13"), RecordDaySummary(count: 0, minutes: 0))
    }

    // 깨짐 명명: 같은 원문 ID 재요청이 새 기록을 만들거나 기존 시각·분·메모를 덮으면 실패.
    func testAC3_같은ID_완료재요청은_기존기록과_메모를_유지한다() throws {
        var section = try RecordSection.empty.recordingCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul)
        section = try section.updatingMemo("첫 메모", forJourneyID: "journey-001")
        section = try section.recordingCompletion(
            Self.input(completedAt: "2026-10-13T03:00:00Z", minutes: 99),
            outcome: .alighted,
            timeZone: Self.seoul
        )

        let record = try XCTUnwrap(section.items.first)
        XCTAssertEqual(section.items.count, 1)
        assertUTF16(record.completedAt, "2026-10-13T01:00:00Z")
        XCTAssertEqual(record.minutes, 25)
        assertUTF16(record.memo, "첫 메모")
        XCTAssertEqual(try section.dailySummary(on: "2026-10-13"), RecordDaySummary(count: 1, minutes: 25))
    }

    // 깨짐 명명: trim 뒤 200 UTF-16 단위 제한 대신 Character 수를 쓰거나 다른 필드를 바꾸면 실패.
    func testAC4_메모는_trim후_200UTF16단위까지만_저장하고_다른필드를_보존한다() throws {
        let original = try RecordSection.empty.recordingCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul)
        let changed = try original.updatingMemo("  \(String(repeating: "가", count: 201))  ", forJourneyID: "journey-001")
        let before = try XCTUnwrap(original.items.first)
        let after = try XCTUnwrap(changed.items.first)

        XCTAssertEqual(after.memo.utf16.count, 200)
        assertUTF16(after.memo, String(repeating: "가", count: 200))
        XCTAssertEqual(changed.items.count, 1)
        assertSameCompletionFields(before, after)
    }

    // 깨짐 명명: UTF-16 경계에서 surrogate 절반을 저장하거나 200단위를 넘기면 실패.
    func testAC4_메모절단은_UnicodeScalar경계를_보존한다() throws {
        let section = try RecordSection.empty.recordingCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul)
        let cases = [
            (String(repeating: "가", count: 199) + "😀", String(repeating: "가", count: 199)),
            (String(repeating: "😀", count: 101), String(repeating: "😀", count: 100)),
        ]

        for item in cases {
            let memo = try XCTUnwrap(try section.updatingMemo(item.0, forJourneyID: "journey-001").items.first).memo
            XCTAssertLessThanOrEqual(memo.utf16.count, 200)
            assertUTF16(memo, item.1)
        }
    }

    // 깨짐 명명: 수정 시 공백을 보존하거나 공백만 입력을 삭제로 처리하지 않으면 실패.
    func testAC5_메모수정은_trim하고_공백만입력은_빈문자열로_삭제한다() throws {
        let original = try RecordSection.empty.recordingCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul)
        let edited = try original.updatingMemo("  수정 메모  \n", forJourneyID: "journey-001")
        let deleted = try edited.updatingMemo(" \n\t ", forJourneyID: "journey-001")

        XCTAssertEqual(edited.items.count, 1)
        assertUTF16(try XCTUnwrap(edited.items.first).memo, "수정 메모")
        XCTAssertEqual(deleted.items.count, 1)
        assertUTF16(try XCTUnwrap(deleted.items.first).memo, "")
    }

    // 깨짐 명명: 없는 ID 메모 요청이 기록을 만들거나 잘못된 오류를 반환하면 실패.
    func testAC5_연결없는ID_메모는_recordNotFound이고_기록을_만들지않는다() throws {
        let section = try RecordSection.empty.recordingCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul)

        assertRecordIssue(.recordNotFound("journey-404")) {
            _ = try section.updatingMemo("메모", forJourneyID: "journey-404")
        }
        XCTAssertEqual(section.items.count, 1)
    }

    // 깨짐 명명: 공백 ID 메모 요청을 recordNotFound로 분류하면 실패.
    func testAC5_공백ID_메모는_invalidID다() throws {
        assertRecordIssue(.invalidID) {
            _ = try RecordSection.empty.updatingMemo("메모", forJourneyID: " \n")
        }
    }

    // 깨짐 명명: 1분 또는 360분 경계를 거부하면 실패.
    func testAC6_완료시간_1분과_360분은_유효하다() throws {
        var section = RecordSection.empty
        section = try section.recordingCompletion(Self.input(id: "one", minutes: 1), outcome: .alighted, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: "max", completedAt: "2026-10-13T02:00:00Z", minutes: 360), outcome: .alighted, timeZone: Self.seoul)

        XCTAssertEqual(section.items.map(\.minutes), [360, 1])
        XCTAssertEqual(try section.dailySummary(on: "2026-10-13"), RecordDaySummary(count: 2, minutes: 361))
    }

    // 깨짐 명명: 0분 또는 361분을 기록에 추가하거나 다른 오류로 분류하면 실패.
    func testAC6_완료시간_0분과_361분은_거부된다() {
        for minutes in [0, 361] {
            assertRecordIssue(.invalidMinutes(minutes), "minutes=\(minutes)") {
                _ = try RecordSection.empty.recordingCompletion(
                    Self.input(id: "minutes-\(minutes)", minutes: minutes),
                    outcome: .alighted,
                    timeZone: Self.seoul
                )
            }
        }
    }

    // 깨짐 명명: 완료 UTC 시각을 로컬 날짜로 바꾸는 자정 경계가 한쪽으로 치우치면 실패.
    func testAC7_서울자정_직전과_직후는_서로다른날짜로_집계된다() throws {
        var section = RecordSection.empty
        section = try section.recordingCompletion(Self.input(id: "before", completedAt: "2026-10-13T14:59:59Z", minutes: 25), outcome: .alighted, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: "after", completedAt: "2026-10-13T15:00:00Z", minutes: 35), outcome: .alighted, timeZone: Self.seoul)

        XCTAssertEqual(section.items.map(\.date), ["2026-10-14", "2026-10-13"])
        XCTAssertEqual(try section.dailySummary(on: "2026-10-13"), RecordDaySummary(count: 1, minutes: 25))
        XCTAssertEqual(try section.dailySummary(on: "2026-10-14"), RecordDaySummary(count: 1, minutes: 35))
    }

    // 깨짐 명명: 완료 두 건 외 진행·포기·중복까지 합계에 넣으면 실패.
    func testAC8_같은날은_완료두건만_60분으로_합산한다() throws {
        var section = RecordSection.empty
        section = try section.recordingCompletion(Self.input(id: "first", minutes: 25), outcome: .alighted, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: "second", completedAt: "2026-10-13T03:00:00Z", minutes: 35), outcome: .alighted, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: "active", minutes: 40), outcome: .active, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: "abandoned", minutes: 50), outcome: .abandoned, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: "first", minutes: 100), outcome: .alighted, timeZone: Self.seoul)

        XCTAssertEqual(try section.dailySummary(on: "2026-10-13"), RecordDaySummary(count: 2, minutes: 60))
    }

    // 깨짐 명명: 저장 date를 현재 시간대 기준으로 다시 계산하면 LA 집계가 달라져 실패.
    func testAC9_저장된날짜는_다른시간대에서도_재계산하지않는다() throws {
        let stored = RecordSection(items: [Self.record(date: "2026-10-13")])

        let newRecord = try stored.recordingCompletion(
            Self.input(id: "la", completedAt: "2026-10-13T01:00:00Z", minutes: 10),
            outcome: .alighted,
            timeZone: Self.losAngeles
        )

        assertUTF16(try XCTUnwrap(newRecord.items.first(where: { $0.id == "journey-001" })).date, "2026-10-13")
        XCTAssertEqual(try newRecord.dailySummary(on: "2026-10-13"), RecordDaySummary(count: 1, minutes: 25))
        XCTAssertEqual(try newRecord.dailySummary(on: "2026-10-12"), RecordDaySummary(count: 1, minutes: 10))
    }

    // 깨짐 명명: 기록 없는 유효 날짜를 오류나 nil로 반환하면 실패.
    func testAC9_기록없는날짜의_합계는_0회0분이다() throws {
        XCTAssertEqual(
            try RecordSection(items: [Self.record()]).dailySummary(on: "2026-10-14"),
            RecordDaySummary(count: 0, minutes: 0)
        )
    }

    // 깨짐 명명: 시간대 변환으로 Gregorian 연도 10000이 되는데도 날짜를 저장하면 실패.
    func test완료날짜가_시간대변환후_연도10000이면_invalidDate다() {
        let plusFourteen = TimeZone(secondsFromGMT: 14 * 60 * 60)!

        assertRecordIssue(.invalidDate) {
            _ = try RecordSection.empty.recordingCompletion(
                Self.input(id: "year-overflow", completedAt: "9999-12-31T23:59:59Z"),
                outcome: .alighted,
                timeZone: plusFourteen
            )
        }
    }

    // 깨짐 명명: 분수초가 섞인 ISO 문자열 자체를 내림차순 정렬하면 whole이 fraction보다 앞서 실패.
    func testAC15_완료시각은_파싱한시각_최신순이다() throws {
        let section = RecordSection(items: [
            Self.record(id: "whole", completedAt: "2026-10-13T01:00:00Z"),
            Self.record(id: "fraction", completedAt: "2026-10-13T01:00:00.001Z"),
            Self.record(id: "older", completedAt: "2026-10-13T00:59:59Z"),
        ])

        XCTAssertEqual(section.sortedNewestFirst().items.map(\.id), ["fraction", "whole", "older"])
    }

    // 깨짐 명명: 같은 완료시각 tie를 ID나 임의 순서로 바꾸거나 신규 동시각을 앞에 두면 실패.
    func testAC15_같은완료시각은_입력순서를_안정적으로_유지한다() throws {
        let section = RecordSection(items: [
            Self.record(id: "first"),
            Self.record(id: "second"),
        ])
        let sorted = section.sortedNewestFirst()
        let appended = try sorted.recordingCompletion(Self.input(id: "third"), outcome: .alighted, timeZone: Self.seoul)

        XCTAssertEqual(sorted.items.map(\.id), ["first", "second"])
        XCTAssertEqual(appended.items.map(\.id), ["first", "second", "third"])
    }

    // 깨짐 명명: Swift 정규화 동등성을 원문 ID 중복 판정에 쓰면 두 번째 기록이 사라져 실패.
    func testID중복은_canonicalEquality가아닌_UTF16원문으로_판정한다() throws {
        let composed = "é"
        let decomposed = "e\u{301}"
        var section = RecordSection.empty
        section = try section.recordingCompletion(Self.input(id: composed), outcome: .alighted, timeZone: Self.seoul)
        section = try section.recordingCompletion(Self.input(id: decomposed, completedAt: "2026-10-13T02:00:00Z"), outcome: .alighted, timeZone: Self.seoul)

        XCTAssertEqual(section.items.count, 2)
        XCTAssertFalse(section.items[0].id.utf16.elementsEqual(section.items[1].id.utf16))
    }

    // 깨짐 명명: 파일 복원 검증이 정확히 같은 원문 ID 두 건을 허용하면 실패.
    func test검증은_정확히같은_UTF16_ID중복을_거부한다() {
        let id = "journey-001"
        assertRecordIssue(.duplicateJourneyID(id)) {
            try RecordSection(items: [Self.record(id: id), Self.record(id: id)]).validate()
        }
    }

    // 깨짐 명명: 저장 메모 201 UTF-16 단위를 읽을 때 자동 절단하거나 허용하면 실패.
    func test검증은_저장메모_201UTF16단위를_거부한다() {
        let record = Self.record(memo: String(repeating: "가", count: 201))
        assertRecordIssue(.memoTooLong) {
            try RecordSection(items: [record]).validate()
        }
    }

    // 깨짐 명명: 이월 날짜·비실제 완료시각·잘못된 색상을 정상화해 허용하면 실패.
    func test검증은_날짜_시각_색상을_엄격하게_거부한다() {
        let cases: [(RecordSnapshot, RecordValidationIssue)] = [
            (Self.record(date: "2026-02-30"), .invalidDate),
            (Self.record(completedAt: "2026-02-30T01:00:00Z"), .invalidCompletedAt),
            (Self.record(tagColor: "#12GG00"), .invalidTagColor),
        ]

        for item in cases {
            assertRecordIssue(item.1) { try RecordSection(items: [item.0]).validate() }
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
        tagColor: String = "#12ABef",
        memo: String = ""
    ) -> RecordSnapshot {
        RecordSnapshot(
            id: id,
            completedAt: completedAt,
            date: date,
            bus: "버스2014",
            tag: "독서",
            tagColor: tagColor,
            task: "책 한 챕터 읽기",
            minutes: 25,
            sound: "빗소리",
            from: "성수역",
            to: "서울숲 입구",
            memo: memo
        )
    }

    private func assertSameCompletionFields(
        _ expected: RecordSnapshot,
        _ actual: RecordSnapshot,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(actual.id.utf16.elementsEqual(expected.id.utf16), file: file, line: line)
        XCTAssertTrue(actual.completedAt.utf16.elementsEqual(expected.completedAt.utf16), file: file, line: line)
        XCTAssertTrue(actual.date.utf16.elementsEqual(expected.date.utf16), file: file, line: line)
        XCTAssertTrue(actual.bus.utf16.elementsEqual(expected.bus.utf16), file: file, line: line)
        XCTAssertTrue(actual.tag.utf16.elementsEqual(expected.tag.utf16), file: file, line: line)
        XCTAssertTrue(actual.tagColor.utf16.elementsEqual(expected.tagColor.utf16), file: file, line: line)
        XCTAssertTrue(actual.task.utf16.elementsEqual(expected.task.utf16), file: file, line: line)
        XCTAssertEqual(actual.minutes, expected.minutes, file: file, line: line)
        XCTAssertTrue(actual.sound.utf16.elementsEqual(expected.sound.utf16), file: file, line: line)
        XCTAssertTrue(actual.from.utf16.elementsEqual(expected.from.utf16), file: file, line: line)
        XCTAssertTrue(actual.to.utf16.elementsEqual(expected.to.utf16), file: file, line: line)
    }

    private func assertUTF16(
        _ actual: String,
        _ expected: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(actual.utf16.elementsEqual(expected.utf16), "actual=\(actual) expected=\(expected)", file: file, line: line)
    }

    private func assertRecordIssue(
        _ expected: RecordValidationIssue,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: () throws -> Void
    ) {
        do {
            try operation()
            XCTFail("Expected RecordValidationIssue \(expected) \(message)", file: file, line: line)
        } catch let actual as RecordValidationIssue {
            XCTAssertEqual(actual, expected, message, file: file, line: line)
        } catch {
            XCTFail("Expected RecordValidationIssue \(expected), got \(error) \(message)", file: file, line: line)
        }
    }
}
