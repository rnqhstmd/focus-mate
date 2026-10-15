import Foundation
import XCTest

/// 기록 화면(마이페이지 아래 기록) UI 테스트. recordID 규칙은 시드 규칙 "records-memo-0"~"records-memo-11"을 가정한다
/// (0이 가장 최신, 1번이 "집중 잘됨").
@MainActor
final class RecordsUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐: 기록 0건 안내 문구·요약이 달라지거나 "예시" 기록이 노출되거나 마이페이지 완료 여정 수가 0이 아니면 실패
    func testAC24_AC31_기록_0건이면_빈_안내와_0회_요약만_보이고_예시가_없다() throws {
        let h = FocusMateUIHarness.launch(seed: "ready")
        openRecords(h)
        let empty = h.element("records.empty")
        XCTAssertTrue(empty.waitForExistence(timeout: timeout), "records.empty 없음")
        XCTAssertEqual(empty.label, "첫 여행을 마치면 잔디에 색이 채워져요. 하루하루 나만의 시간을 모아보세요.")
        XCTAssertEqual(h.element("records.summary").label, "0회 여행 · 0일")
        let withExample = h.app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "예시"))
        XCTAssertEqual(withExample.count, 0)

        h.app.navigationBars.firstMatch.buttons.firstMatch.tap()
        let profile = h.element("open.profile")
        XCTAssertTrue(profile.waitForExistence(timeout: timeout), "open.profile 없음")
        profile.tap()
        let stat = h.element("profile.stat.journeys")
        XCTAssertTrue(stat.waitForExistence(timeout: timeout), "profile.stat.journeys 없음")
        let shown = stat.label + " " + ((stat.value as? String) ?? "")
        XCTAssertTrue(shown.contains("0"), "완료 여정 수 0 아님: \(shown)")
        XCTAssertFalse(shown.contains("1"), "완료 여정 수 0 아님: \(shown)")
    }

    // 깨짐: 10건 단위 더 보기 / 메모 라벨 / 저장 반영 / 200자 제한 / 실패 유지 / 재실행 유지 중 하나라도 어긋나면 실패
    func testAC20_AC26_AC29_AC30_메모_남기기_수정_제한_실패_유지() throws {
        let h = FocusMateUIHarness.launch(seed: "recordsMemo")
        openRecords(h)

        let first = try records(h)
        XCTAssertEqual(first["visibleCount"] as? Int, 10)
        XCTAssertEqual(first["hasMore"] as? Bool, true)
        h.tap("records.more")
        XCTAssertTrue(h.waitUntil { (try? self.records(h)["visibleCount"] as? Int) == 12 })
        XCTAssertFalse(h.element("records.more").exists)

        let emptyMemo = h.element("records.memo.records-memo-0")
        XCTAssertTrue(emptyMemo.waitForExistence(timeout: timeout), "records.memo.records-memo-0 없음")
        XCTAssertEqual(emptyMemo.label, "메모 남기기")
        let filledMemo = h.element("records.memo.records-memo-1")
        XCTAssertTrue(filledMemo.waitForExistence(timeout: timeout))
        XCTAssertEqual(filledMemo.label, "메모 수정")

        // 수정 저장
        filledMemo.tap()
        let field = h.app.textFields["recordMemo.field"]
        XCTAssertTrue(field.waitForExistence(timeout: timeout), "recordMemo.field 없음")
        XCTAssertEqual(field.value as? String, "집중 잘됨")
        replaceText(field, with: "다시 읽기 좋은 책")
        h.tap("recordMemo.save")
        XCTAssertTrue(h.waitUntil { !h.element("recordMemo.field").exists }, "시트가 닫히지 않음")
        let saved = try h.persistedText()
        XCTAssertTrue(saved.contains("다시 읽기 좋은 책"))
        XCTAssertFalse(saved.contains("집중 잘됨"))
        XCTAssertEqual(saved.components(separatedBy: "\"memo\":\"\"").count - 1, 11, "다른 기록 메모가 바뀜")

        // 201자 입력은 200자로 제한
        emptyMemo.tap()
        let limited = h.app.textFields["recordMemo.field"]
        XCTAssertTrue(limited.waitForExistence(timeout: timeout))
        limited.tap()
        limited.typeText(String(repeating: "가", count: 201))
        XCTAssertEqual((limited.value as? String)?.count, 200)
        XCTAssertEqual(h.element("recordMemo.counter").label, "200 / 200")
        h.tap("recordMemo.cancel")
        XCTAssertTrue(h.waitUntil { !h.element("recordMemo.field").exists })

        // 저장 실패 주입: 시트 유지, 입력 그대로, 안내 문구
        h.tap("test.records.failNextSave")
        filledMemo.tap()
        let failing = h.app.textFields["recordMemo.field"]
        XCTAssertTrue(failing.waitForExistence(timeout: timeout))
        replaceText(failing, with: "실패할 메모")
        h.tap("recordMemo.save")
        let failure = h.element("recordMemo.saveFailure")
        XCTAssertTrue(failure.waitForExistence(timeout: timeout), "saveFailure 없음")
        XCTAssertEqual(failure.label, "저장하지 못했어요. 다시 눌러주세요.")
        XCTAssertEqual(h.app.textFields["recordMemo.field"].value as? String, "실패할 메모")
        h.tap("recordMemo.cancel")

        // 재실행 후에도 수정한 메모 유지
        h.relaunch()
        openRecords(h)
        let again = h.element("records.memo.records-memo-1")
        XCTAssertTrue(again.waitForExistence(timeout: timeout))
        XCTAssertEqual(again.label, "메모 수정")
        XCTAssertTrue(try h.persistedText().contains("다시 읽기 좋은 책"))
    }

    // 깨짐: 올해에서 다음이 활성이거나, 연도 이동·요약·선택 날짜가 어긋나거나, 잔디 increment가 오늘을 넘어가면 실패
    func testAC27_연도_이동과_오늘_이후_차단() throws {
        let h = FocusMateUIHarness.launch(seed: "recordsTwoYears")
        openRecords(h)
        let next = h.element("records.year.next")
        XCTAssertTrue(next.waitForExistence(timeout: timeout))
        XCTAssertFalse(next.isEnabled)

        let (thisYear, today) = Self.todayParts()
        h.tap("records.year.previous")
        XCTAssertTrue(h.waitUntil { (try? self.records(h)["year"] as? Int) == thisYear - 1 })
        XCTAssertEqual(try records(h)["selected"] as? String, "\(thisYear - 1)-06-20")
        XCTAssertTrue(h.element("records.summary").label.hasPrefix("2회 여행 · 2일"))

        h.tap("records.year.next")
        XCTAssertTrue(h.waitUntil { (try? self.records(h)["year"] as? Int) == thisYear })
        XCTAssertEqual(try records(h)["selected"] as? String, today)

        let heatmap = h.element("records.heatmap")
        XCTAssertTrue(heatmap.waitForExistence(timeout: timeout))
        h.tap("test.records.nextDay")
        XCTAssertEqual(try records(h)["selected"] as? String, today, "오늘 이후로 이동함")
        h.tap("test.records.previousDay")
        let yesterday = Self.yesterday()
        XCTAssertTrue(h.waitUntil { (try? self.records(h)["selected"] as? String) == yesterday }, "전날로 이동하지 않음")
    }

    // MARK: - 도우미

    private func openRecords(_ h: FocusMateUIHarness) {
        let entry = h.element("open.records")
        XCTAssertTrue(entry.waitForExistence(timeout: timeout), "open.records 없음")
        entry.tap()
        XCTAssertTrue(h.element("screen.records").waitForExistence(timeout: timeout), "screen.records 없음")
    }

    private func records(_ h: FocusMateUIHarness) throws -> [String: Any] {
        let raw = try h.diagnostic("test.records")
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func replaceText(_ field: XCUIElement, with text: String) {
        field.tap()
        let current = (field.value as? String) ?? ""
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
        field.typeText(text)
    }

    private static func todayParts() -> (year: Int, today: String) {
        let c = Calendar.current.dateComponents(in: TimeZone.current, from: Date())
        return (c.year!, String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!))
    }

    private static func yesterday() -> String {
        let d = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        let c = Calendar.current.dateComponents(in: TimeZone.current, from: d)
        return String(format: "%04d-%02d-%02d", c.year!, c.month!, c.day!)
    }
}
