import Foundation
import XCTest
@testable import FocusMate

final class PreparationDraftTests: XCTestCase {
    // Break: initialization selects a tag, supplies a task, or changes the default sound.
    func test새_준비는_태그와_할_일이_없고_bus이며_불완전하다() {
        let draft = PreparationDraft()
        XCTAssertNil(draft.selectedTag)
        XCTAssertNil(draft.selectedTagID)
        XCTAssertEqual(draft.task, "")
        XCTAssertEqual(draft.sound, .none)
        XCTAssertFalse(draft.isComplete)
    }

    // Break: choosing an existing tag is ignored or fills a suggested task.
    func test독서_선택은_단일_태그를_선택하고_할_일은_자동_생성하지_않는다() {
        var draft = PreparationDraft()
        XCTAssertTrue(draft.chooseTag(id: "reading"))
        XCTAssertEqual(draft.selectedTagID, "reading")
        XCTAssertEqual(draft.selectedTag?.name, "독서")
        XCTAssertEqual(draft.task, "")
        XCTAssertFalse(draft.isComplete)
    }

    // Break: an unknown ID destroys the valid selected tag or other draft fields.
    func test없는_태그_ID_선택은_초안_전체를_유지한다() {
        var draft = validDraft()
        draft.setSound(.forest)
        let before = draft
        XCTAssertFalse(draft.chooseTag(id: "missing"))
        XCTAssertEqual(draft, before)
    }

    // Break: an empty task is treated as complete after a valid task was entered.
    func test빈_할_일로_바꾸면_준비가_불완전해진다() {
        var draft = validDraft()
        draft.setTask("")
        XCTAssertFalse(draft.isComplete)
        XCTAssertEqual(draft.trimmedTask, "")
    }

    // Break: whitespace is accepted as a meaningful task.
    func test공백과_줄바꿈_할_일은_준비가_불완전하다() {
        var draft = validDraft()
        draft.setTask(" \n\t ")
        XCTAssertFalse(draft.isComplete)
        XCTAssertEqual(draft.trimmedTask, "")
    }

    // Break: the task cap rejects the valid 80-unit boundary.
    func test80_UTF16_할_일은_그대로_유지되어_확정_가능하다() {
        var draft = validDraft()
        draft.setTask(String(repeating: "가", count: 80))
        XCTAssertEqual(draft.task, String(repeating: "가", count: 80))
        XCTAssertTrue(draft.isComplete)
    }

    // Break: the input cap admits the 81st UTF-16 unit.
    func test81_UTF16_붙여넣기는_80단위까지만_보존한다() {
        var draft = validDraft()
        draft.setTask(String(repeating: "가", count: 81))
        XCTAssertEqual(draft.task, String(repeating: "가", count: 80))
        XCTAssertTrue(draft.isComplete)
    }

    // Break: truncation splits a surrogate pair at the 80-unit boundary.
    func test경계의_이모지는_surrogate_pair를_자르지_않는다() {
        var draft = validDraft()
        draft.setTask(String(repeating: "가", count: 79) + "😀끝")
        XCTAssertEqual(draft.task, String(repeating: "가", count: 79))
        XCTAssertTrue(draft.isComplete)
    }

    // Break: the cap counts Unicode scalars rather than UTF-16 units.
    func test40개_이모지는_80_UTF16이며_41번째는_저장되지_않는다() {
        var draft = validDraft()
        draft.setTask(String(repeating: "😀", count: 41))
        XCTAssertEqual(draft.task, String(repeating: "😀", count: 40))
        XCTAssertTrue(draft.isComplete)
    }

    // Break: editing prematurely trims the input or confirmation fails to trim it.
    func test할_일은_입력_공백을_보존하고_확정용_값만_trim한다() {
        var draft = validDraft()
        draft.setTask(" \n책 읽기 \t")
        XCTAssertEqual(draft.task, " \n책 읽기 \t")
        XCTAssertEqual(draft.trimmedTask, "책 읽기")
        XCTAssertTrue(draft.isComplete)
    }

    // Break: opening a fresh editor inherits previous values or mutates preparation.
    func test새_태그_편집_기본값은_빈_이름_독서_모래빛이고_초안은_유지된다() {
        let draft = validDraft()
        let before = draft
        let editor = TagEditorDraft()
        XCTAssertEqual(editor.name, "")
        XCTAssertEqual(editor.icon, .reading)
        XCTAssertEqual(editor.color, .sand)
        XCTAssertEqual(draft, before)
    }

    // Break: an empty name appends/selects a tag or alters any draft value.
    func test빈_태그_이름_저장은_empty와_초안_전체_불변을_반환한다() {
        assertRejectedName("", issue: .empty)
    }

    // Break: whitespace-only names bypass trim validation.
    func test공백_태그_이름_저장은_empty와_초안_전체_불변을_반환한다() {
        assertRejectedName(" \n\t ", issue: .empty)
    }

    // Break: duplicate comparison ignores case normalization.
    func test대소문자만_다른_태그는_중복으로_추가되지_않는다() throws {
        var draft = validDraft()
        _ = try draft.saveTag(TagEditorDraft(name: "Focus", icon: .study, color: .blue)).get()
        let before = draft
        XCTAssertEqual(draft.saveTag(TagEditorDraft(name: "fOcUs")), .failure(.duplicate))
        XCTAssertEqual(draft, before)
    }

    // Break: duplicate comparison ignores NFKC full-width normalization.
    func test전각과_반각_이름은_NFKC_중복으로_추가되지_않는다() throws {
        var draft = validDraft()
        _ = try draft.saveTag(TagEditorDraft(name: "Focus", icon: .study, color: .blue)).get()
        let before = draft
        XCTAssertEqual(draft.saveTag(TagEditorDraft(name: "Ｆｏｃｕｓ")), .failure(.duplicate))
        XCTAssertEqual(draft, before)
    }

    // Break: trimming occurs after the length check instead of before it.
    func testtrim한_20_UTF16_태그_이름은_저장_가능하다() throws {
        var draft = validDraft()
        let tag = try draft.saveTag(TagEditorDraft(name: " \n" + String(repeating: "가", count: 20) + " \n")).get()
        XCTAssertEqual(tag.name, String(repeating: "가", count: 20))
        XCTAssertEqual(draft.tags.count, 5)
        XCTAssertEqual(draft.selectedTag, tag)
    }

    // Break: 21-unit tag names bypass the maximum.
    func test21_UTF16_태그_이름은_tooLong과_초안_전체_불변을_반환한다() {
        assertRejectedName(String(repeating: "가", count: 21), issue: .tooLong)
    }

    // Break: tag validation counts characters instead of UTF-16 units.
    func test11개_이모지_태그는_22_UTF16이므로_거부한다() {
        assertRejectedName(String(repeating: "😀", count: 11), issue: .tooLong)
    }

    // Break: saving discards metadata, fails to select the new tag, or erases task/sound.
    func test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다() throws {
        var draft = validDraft()
        draft.setSound(.rainBus)
        let tag = try draft.saveTag(TagEditorDraft(name: " \nMy Focus \t", icon: .development, color: .purple)).get()
        XCTAssertEqual(tag.name, "My Focus")
        XCTAssertEqual(tag.icon, .development)
        XCTAssertEqual(tag.color, .purple)
        XCTAssertEqual(draft.tags.count, 5)
        XCTAssertEqual(draft.tags.last, tag)
        XCTAssertEqual(draft.selectedTag, tag)
        XCTAssertEqual(draft.task, "책 읽기")
        XCTAssertEqual(draft.sound, .rainBus)
        XCTAssertTrue(draft.isComplete)
    }

    // Break: no sound incorrectly blocks a valid preparation.
    func test소리_없음도_유효한_태그와_할_일이면_확정_가능하다() {
        var draft = validDraft()
        draft.setSound(.none)
        XCTAssertEqual(draft.sound, .none)
        XCTAssertTrue(draft.isComplete)
    }

    private func validDraft() -> PreparationDraft {
        var draft = PreparationDraft()
        XCTAssertTrue(draft.chooseTag(id: "reading"))
        draft.setTask("책 읽기")
        return draft
    }

    private func assertRejectedName(_ name: String, issue: TagNameIssue, file: StaticString = #filePath, line: UInt = #line) {
        var draft = validDraft()
        draft.setSound(.forest)
        let before = draft
        XCTAssertEqual(draft.saveTag(TagEditorDraft(name: name, icon: .writing, color: .pink)), .failure(issue), file: file, line: line)
        XCTAssertEqual(draft, before, file: file, line: line)
    }
}
