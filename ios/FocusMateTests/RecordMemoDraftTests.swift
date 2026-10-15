import Foundation
import XCTest
@testable import FocusMate

/// 요약 시트 메모 초안 (AC-18, AC-19/BR-4).
final class RecordMemoDraftTests: XCTestCase {
    // 깨짐: 한도를 넘겨 저장하거나 카운터가 글자 수 대신 다른 값을 내면 실패.
    func testAC18_201자_입력은_200자로_잘리고_카운터는_200_나누기_200이다() {
        var draft = RecordMemoDraft()

        draft.update(String(repeating: "가", count: 201))

        XCTAssertEqual(draft.text.utf16.count, 200)
        XCTAssertEqual(draft.counterText, "200 / 200")
    }

    // 깨짐: UTF-16 경계에서 서로게이트 쌍을 쪼개거나 200단위를 넘기면 실패.
    func testAC18_이모지_경계에서_스칼라를_쪼개지_않는다() {
        var draft = RecordMemoDraft()

        draft.update(String(repeating: "가", count: 199) + "😀")

        XCTAssertEqual(draft.text, String(repeating: "가", count: 199))
        XCTAssertEqual(draft.counterText, "199 / 200")
    }

    // 깨짐: 공백만 입력을 비어있지 않다고 보거나 저장값이 공백이면 실패.
    func testAC19_공백_3칸은_blank이고_저장값은_빈문자열이다() {
        var draft = RecordMemoDraft()

        draft.update("   ")

        XCTAssertTrue(draft.isBlank)
        XCTAssertEqual(draft.savedValue, "")
    }

    // 깨짐: 저장값에서 앞뒤 공백을 제거하지 않으면 실패.
    func testBR4_저장값은_앞뒤_공백을_제거한다() {
        var draft = RecordMemoDraft()

        draft.update("  집중 잘됨  ")

        XCTAssertFalse(draft.isBlank)
        XCTAssertEqual(draft.savedValue, "집중 잘됨")
    }

    // 깨짐: update가 입력 중 trim하면 text가 달라져 실패.
    func testBR4_update는_trim하지_않고_입력_그대로_둔다() {
        var draft = RecordMemoDraft()

        draft.update("  집중 잘됨  ")

        XCTAssertEqual(draft.text, "  집중 잘됨  ")
    }
}
