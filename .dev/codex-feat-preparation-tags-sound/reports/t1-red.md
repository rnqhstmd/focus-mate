# T1 formal RED report

Status: DONE_WITH_CONCERNS — corrected tests promoted; focused command exited 65 at missing-declaration compilation prerequisite. Behavior RED is not yet established.

Cases: PreparationDraftTests 20 + PreparationModelTests 21 = 41.

Command (workdir /Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new):
```sh
FOCUSMATE_SIMULATOR_ID=88ABB031-C48A-4DA0-B15C-14787702E647 python3 scripts/check-ios.py test ios/FocusMateTests/PreparationDraftTests.swift ios/FocusMateTests/PreparationModelTests.swift > .dev/codex-feat-preparation-tags-sound/t1-red-compile.log 2>&1
```

Missing-declaration compilation failure is a declaration prerequisite, not behavior RED. Parent will introduce no-op declarations and verify assertion RED separately. Production source has not been read, searched, or edited. Only the two corrected test files were copied into ios/FocusMateTests.

Allowed references actually read: gx-dev/references/codex-roles/red-writer.md; draft-tests/PreparationDraftTests.swift; draft-tests/PreparationModelTests.swift; reports/t1-red-draft.md. PRD/design and JourneyStartModelTests/StorageTestSupport were allowed but not read in this isolated correction. Baseline GREEN evidence was reported by parent.

## PreparationDraftTests.swift (20 cases)

```swift
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
        XCTAssertEqual(draft.sound, .bus)
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
```

## PreparationModelTests.swift (21 cases)

```swift
import Foundation
import XCTest
@testable import FocusMate

final class PreparationModelTests: XCTestCase {
    private enum ProbeError: Error { case expected }
    private final class Probe {
        var writes = 0
        var shouldFail = false
    }
    private static let station = StationSnapshot(id: "seongsu", name: "성수역", direction: 1)
    private static let expectedJourney = JourneySelection(
        origin: StopPosition(index: 0, direction: 1), minutes: 60,
        busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12
    )

    // Break: a fresh model inherits preparation values or enables an incomplete preparation.
    @MainActor
    func test유효_W02로_처음_진입한_준비는_초기값이고_확정할_수_없다() throws {
        try withReadyModel { model, probe, _, _ in
            try enterPreparation(model)
            XCTAssertEqual(model.path, [.time, .preparation])
            XCTAssertNil(model.preparation.selectedTag)
            XCTAssertEqual(model.preparation.task, "")
            XCTAssertEqual(model.preparation.sound, .bus)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertEqual(probe.writes, 0)
        }
    }

    // Break: choosing a tag generates a task or enables confirmation without user input.
    @MainActor
    func test독서만_선택하면_할_일은_비어있고_확정_요청은_생성되지_않는다() throws {
        try withReadyModel { model, _, _, _ in
            try enterPreparation(model)
            XCTAssertTrue(model.preparation.chooseTag(id: "reading"))
            XCTAssertEqual(model.preparation.selectedTag?.name, "독서")
            XCTAssertEqual(model.preparation.task, "")
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: empty input leaves an old confirmed request usable.
    @MainActor
    func test빈_할_일로_변경한_후_직접_확정해도_전달은_0이다() throws {
        try assertInvalidTask("")
    }

    // Break: whitespace input is accepted by the AppModel confirmation boundary.
    @MainActor
    func test공백과_줄바꿈_할_일로_변경한_후_직접_확정해도_전달은_0이다() throws {
        try assertInvalidTask(" \n\t ")
    }

    // Break: the AppModel guard rejects a capped valid 80-unit task.
    @MainActor
    func test81단위_입력은_80단위로_확정되어_한번_전달된다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            model.preparation.setTask(String(repeating: "가", count: 81))
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(try XCTUnwrap(model.consumePreparationRequest()).task, String(repeating: "가", count: 80))
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: successful custom-tag save loses the W02 journey or task.
    @MainActor
    func test새_태그_저장은_기존_할_일과_W02_여정을_유지한다() throws {
        try withReadyModel { model, probe, _, _ in
            try configureValidPreparation(model)
            let tag = try model.preparation.saveTag(TagEditorDraft(name: " \n개발 메모 \t", icon: .development, color: .green)).get()
            XCTAssertEqual(model.preparation.selectedTag, tag)
            XCTAssertEqual(tag.name, "개발 메모")
            XCTAssertEqual(model.preparation.task, "책 읽기")
            XCTAssertEqual(model.preparedJourney, Self.expectedJourney)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertEqual(probe.writes, 0)
        }
    }

    // Break: returning to preparation resets the existing session draft.
    @MainActor
    func test시간_화면_왕복은_세션_태그_할_일_확정_소리를_보존한다() throws {
        try withReadyModel { model, probe, _, _ in
            try configureValidPreparation(model)
            _ = try model.preparation.saveTag(TagEditorDraft(name: "개발", icon: .development, color: .blue)).get()
            model.preparation.setSound(.rainBus)
            let before = model.preparation
            model.goBack()
            XCTAssertEqual(model.path, [.time])
            XCTAssertTrue(model.proceedToPreparation())
            XCTAssertEqual(model.preparation, before)
            XCTAssertEqual(model.preparedJourney, Self.expectedJourney)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertEqual(probe.writes, 0)
        }
    }

    // Break: changing time keeps the old W02 selection/request usable.
    @MainActor
    func test시간_변경으로_후보가_해제되면_getter와_소비_전달은_0이다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            model.goBack()
            model.journeyPlan.setMinutes(25)
            XCTAssertNil(model.journeyPlan.selectedBusID)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: confirmation omits/changes journey, tag, trimmed task, or sound; persists a journey.
    @MainActor
    func test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다() throws {
        try withReadyModel { model, probe, fileURL, bytes in
            try configureValidPreparation(model)
            let tag = try model.preparation.saveTag(TagEditorDraft(name: " \nMy Focus \t", icon: .writing, color: .pink)).get()
            model.preparation.setTask("  책 읽기  ")
            model.preparation.setSound(.subway)
            let expected = PreparedJourneyDetails(journey: Self.expectedJourney, tag: tag, task: "책 읽기", sound: .subway)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(model.confirmedPreparation, expected)
            XCTAssertEqual(model.preparationRequest, expected)
            XCTAssertEqual(model.consumePreparationRequest(), expected)
            XCTAssertEqual(model.confirmedPreparation, expected)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.snapshot?.journey.active)
            XCTAssertEqual(model.snapshot?.records.items.count, 0)
            XCTAssertEqual(probe.writes, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
        }
    }

    // Break: repeated confirm enqueues multiple identical requests or consume replays one.
    @MainActor
    func test같은_payload_확정_연타의_요청은_한번만_소비된다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.consumePreparationRequest())
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertNotNil(model.confirmedPreparation)
        }
    }

    // Break: consume permanently prevents a new explicit confirmation request.
    @MainActor
    func test소비한_뒤_다시_확정하면_새_요청을_한번_전달한다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            let first = try XCTUnwrap(model.consumePreparationRequest())
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(model.consumePreparationRequest(), first)
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertEqual(model.confirmedPreparation, first)
        }
    }

    // Break: selecting a different tag allows the old tag payload to be consumed.
    @MainActor
    func test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다() throws {
        try assertStaleMutation { model in
            XCTAssertTrue(model.preparation.chooseTag(id: "study"))
            XCTAssertEqual(model.preparation.selectedTagID, "study")
        }
    }

    // Break: entering a different nonempty task allows the old task payload to be consumed.
    @MainActor
    func test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다() throws {
        try assertStaleMutation { model in
            model.preparation.setTask("새 할 일")
            XCTAssertEqual(model.preparation.task, "새 할 일")
        }
    }

    // Break: saving a different sound allows the old sound payload to be consumed.
    @MainActor
    func test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다() throws {
        try assertStaleMutation { model in
            model.preparation.setSound(.forest)
            XCTAssertEqual(model.preparation.sound, .forest)
        }
    }

    // Break: invalid consume only hides a request and resurrects it when input is restored.
    @MainActor
    func test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            model.preparation.setTask(" \n ")
            XCTAssertNil(model.consumePreparationRequest())
            model.preparation.setTask("책 읽기")
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.consumePreparationRequest())
        }
    }

    // Break: merely reading an invalid getter destroys an otherwise unconsumed request.
    @MainActor
    func test무효_getter_읽기는_부작용없이_숨기며_소비전_입력복원은_기존요청을_유지한다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            let expected = try XCTUnwrap(model.preparationRequest)
            model.preparation.setTask("다른 할 일")
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            model.preparation.setTask("책 읽기")
            XCTAssertEqual(model.confirmedPreparation, expected)
            XCTAssertEqual(model.preparationRequest, expected)
            XCTAssertEqual(model.consumePreparationRequest(), expected)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: invalid W02 input bypasses the direct-call confirmation guard.
    @MainActor
    func test여정이_없는_직접_확정은_준비값과_요청을_생성하지_않는다() throws {
        try withReadyModel { model, _, _, _ in
            XCTAssertTrue(model.preparation.chooseTag(id: "reading"))
            model.preparation.setTask("책 읽기")
            XCTAssertTrue(model.preparation.isComplete)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: a nonempty task bypasses the missing-tag confirmation guard.
    @MainActor
    func test태그가_없는_직접_확정은_준비값과_요청을_생성하지_않는다() throws {
        try withReadyModel { model, _, _, _ in
            try enterPreparation(model)
            model.preparation.setTask("책 읽기")
            XCTAssertEqual(model.preparation.task, "책 읽기")
            XCTAssertNil(model.preparation.selectedTag)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    // Break: no sound blocks confirmation or substitutes the bus identifier.
    @MainActor
    func test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            model.preparation.setSound(.none)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(try XCTUnwrap(model.consumePreparationRequest()).sound, .none)
        }
    }

    // Break: W03 accidentally writes session input or restores it in a new AppModel.
    @MainActor
    func test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다() throws {
        try assertSessionOnly(shouldFail: false)
    }

    // Break: a write-failing store is touched by W03 or session input leaks into new models.
    @MainActor
    func test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다() throws {
        try assertSessionOnly(shouldFail: true)
    }

    @MainActor
    private func enterPreparation(_ model: AppModel) throws {
        model.open(.time)
        model.journeyPlan.setMinutes(60)
        model.journeyPlan.choose(busID: "2014", from: StopPosition(index: 0, direction: 1))
        XCTAssertTrue(model.proceedToPreparation())
        XCTAssertEqual(model.preparedJourney, Self.expectedJourney)
    }

    @MainActor
    private func configureValidPreparation(_ model: AppModel) throws {
        try enterPreparation(model)
        XCTAssertTrue(model.preparation.chooseTag(id: "reading"))
        model.preparation.setTask("책 읽기")
        XCTAssertTrue(model.canConfirmPreparation)
    }

    @MainActor
    private func assertInvalidTask(_ task: String) throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            model.preparation.setTask(task)
            XCTAssertFalse(model.canConfirmPreparation)
            XCTAssertFalse(model.confirmPreparation())
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    @MainActor
    private func assertStaleMutation(_ mutate: (AppModel) -> Void) throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.preparationRequest)
            mutate(model)
            XCTAssertTrue(model.canConfirmPreparation)
            XCTAssertNil(model.confirmedPreparation)
            XCTAssertNil(model.preparationRequest)
            XCTAssertNil(model.consumePreparationRequest())
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.consumePreparationRequest())
            XCTAssertNil(model.consumePreparationRequest())
        }
    }

    @MainActor
    private func assertSessionOnly(shouldFail: Bool) throws {
        try withReadyModel(shouldFail: shouldFail) { model, probe, fileURL, bytes in
            try configureValidPreparation(model)
            _ = try model.preparation.saveTag(TagEditorDraft(name: "세션 태그", icon: .development, color: .purple)).get()
            model.preparation.setTask("세션 할 일")
            model.preparation.setSound(.rainBus)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertNotNil(model.consumePreparationRequest())
            XCTAssertEqual(probe.writes, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
            XCTAssertEqual(try SnapshotCodec.encode(try XCTUnwrap(model.snapshot)), bytes)
            let relaunched = makeModel(fileURL: fileURL, probe: probe)
            try enterPreparation(relaunched)
            XCTAssertEqual(relaunched.preparation.tags.count, 4)
            XCTAssertFalse(relaunched.preparation.tags.contains { $0.name == "세션 태그" })
            XCTAssertNil(relaunched.preparation.selectedTag)
            XCTAssertEqual(relaunched.preparation.task, "")
            XCTAssertEqual(relaunched.preparation.sound, .bus)
            XCTAssertFalse(relaunched.canConfirmPreparation)
            XCTAssertNil(relaunched.confirmedPreparation)
            XCTAssertNil(relaunched.preparationRequest)
            XCTAssertNil(relaunched.snapshot?.journey.active)
            XCTAssertEqual(relaunched.snapshot?.records.items.count, 0)
            XCTAssertEqual(probe.writes, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
        }
    }

    @MainActor
    private func withReadyModel(shouldFail: Bool = false, _ body: (AppModel, Probe, URL, Data) throws -> Void) throws {
        try withTemporaryFile { fileURL in
            let bytes = try SnapshotCodec.encode(Self.stage(true, Self.station, Self.station))
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try bytes.write(to: fileURL, options: .atomic)
            let probe = Probe()
            probe.shouldFail = shouldFail
            let model = makeModel(fileURL: fileURL, probe: probe)
            XCTAssertEqual(model.launchState, .ready(.main))
            XCTAssertEqual(probe.writes, 0, "Fixture loading must not write; counting starts before W03 mutations.")
            try body(model, probe, fileURL, bytes)
        }
    }

    @MainActor
    private func makeModel(fileURL: URL, probe: Probe) -> AppModel {
        let store = LocalSnapshotStore(
            fileURL: fileURL,
            readData: { try Data(contentsOf: $0) },
            createDirectory: { try FileManager.default.createDirectory(at: $0, withIntermediateDirectories: true) },
            writeData: { data, url in
                probe.writes += 1
                if probe.shouldFail { throw ProbeError.expected }
                try data.write(to: url, options: .atomic)
            }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()
        return model
    }
}
```

## Focused compile result

Exit code: 65. **TEST FAILED** at compilation; no test assertions executed. Missing PreparationDraft, TagEditorDraft, TagNameIssue, PreparedJourneyDetails and AppModel.preparation declarations (with downstream contextual member errors). Classified as declaration prerequisite only. Parent must add no-op declarations then run behavior/assertion RED; no production changes made by red-writer.

Representative diagnostics:
```text
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:174:34: error: cannot find type 'PreparationDraft' in scope
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:181:60: error: cannot find type 'TagNameIssue' in scope
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:8:21: error: cannot find 'PreparationDraft' in scope
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:12:38: error: type 'Equatable' has no member 'bus'
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:18:21: error: cannot find 'PreparationDraft' in scope
```

Full log: `.dev/codex-feat-preparation-tags-sound/t1-red-compile.log`. Executed only the authorized focused command.

## 직접 assertion RED 확인

exit 65, 41 cases failed / 0 passed. 컴파일/러너 오류 아님. 선언만 있는 no-op scaffold에서 실행. 로그 t1-red-behavior.log.

/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test11개_이모지_태그는_22_UTF16이므로_거부한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:147: error: -[FocusMateTests.PreparationDraftTests test11개_이모지_태그는_22_UTF16이므로_거부한다] : XCTAssertEqual failed: ("success(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))") is not equal to ("failure(FocusMate.TagNameIssue.tooLong)")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test21_UTF16_태그_이름은_tooLong과_초안_전체_불변을_반환한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:142: error: -[FocusMateTests.PreparationDraftTests test21_UTF16_태그_이름은_tooLong과_초안_전체_불변을_반환한다] : XCTAssertEqual failed: ("success(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))") is not equal to ("failure(FocusMate.TagNameIssue.tooLong)")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test40개_이모지는_80_UTF16이며_41번째는_저장되지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:79: error: -[FocusMateTests.PreparationDraftTests test40개_이모지는_80_UTF16이며_41번째는_저장되지_않는다] : XCTAssertEqual failed: ("") is not equal to ("😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀😀")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:80: error: -[FocusMateTests.PreparationDraftTests test40개_이모지는_80_UTF16이며_41번째는_저장되지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test80_UTF16_할_일은_그대로_유지되어_확정_가능하다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:55: error: -[FocusMateTests.PreparationDraftTests test80_UTF16_할_일은_그대로_유지되어_확정_가능하다] : XCTAssertEqual failed: ("") is not equal to ("가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:56: error: -[FocusMateTests.PreparationDraftTests test80_UTF16_할_일은_그대로_유지되어_확정_가능하다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test81_UTF16_붙여넣기는_80단위까지만_보존한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:63: error: -[FocusMateTests.PreparationDraftTests test81_UTF16_붙여넣기는_80단위까지만_보존한다] : XCTAssertEqual failed: ("") is not equal to ("가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:64: error: -[FocusMateTests.PreparationDraftTests test81_UTF16_붙여넣기는_80단위까지만_보존한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests testtrim한_20_UTF16_태그_이름은_저장_가능하다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:135: error: -[FocusMateTests.PreparationDraftTests testtrim한_20_UTF16_태그_이름은_저장_가능하다] : XCTAssertEqual failed: ("") is not equal to ("가가가가가가가가가가가가가가가가가가가가")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:136: error: -[FocusMateTests.PreparationDraftTests testtrim한_20_UTF16_태그_이름은_저장_가능하다] : XCTAssertEqual failed: ("0") is not equal to ("5")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:137: error: -[FocusMateTests.PreparationDraftTests testtrim한_20_UTF16_태그_이름은_저장_가능하다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test경계의_이모지는_surrogate_pair를_자르지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:71: error: -[FocusMateTests.PreparationDraftTests test경계의_이모지는_surrogate_pair를_자르지_않는다] : XCTAssertEqual failed: ("") is not equal to ("가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가가")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:72: error: -[FocusMateTests.PreparationDraftTests test경계의_이모지는_surrogate_pair를_자르지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test공백_태그_이름_저장은_empty와_초안_전체_불변을_반환한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:110: error: -[FocusMateTests.PreparationDraftTests test공백_태그_이름_저장은_empty와_초안_전체_불변을_반환한다] : XCTAssertEqual failed: ("success(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))") is not equal to ("failure(FocusMate.TagNameIssue.empty)")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test공백과_줄바꿈_할_일은_준비가_불완전하다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test대소문자만_다른_태그는_중복으로_추가되지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:118: error: -[FocusMateTests.PreparationDraftTests test대소문자만_다른_태그는_중복으로_추가되지_않는다] : XCTAssertEqual failed: ("success(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))") is not equal to ("failure(FocusMate.TagNameIssue.duplicate)")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:19: error: -[FocusMateTests.PreparationDraftTests test독서_선택은_단일_태그를_선택하고_할_일은_자동_생성하지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:20: error: -[FocusMateTests.PreparationDraftTests test독서_선택은_단일_태그를_선택하고_할_일은_자동_생성하지_않는다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional("reading")")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:21: error: -[FocusMateTests.PreparationDraftTests test독서_선택은_단일_태그를_선택하고_할_일은_자동_생성하지_않는다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional("독서")")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test빈_태그_이름_저장은_empty와_초안_전체_불변을_반환한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:105: error: -[FocusMateTests.PreparationDraftTests test빈_태그_이름_저장은_empty와_초안_전체_불변을_반환한다] : XCTAssertEqual failed: ("success(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))") is not equal to ("failure(FocusMate.TagNameIssue.empty)")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test빈_할_일로_바꾸면_준비가_불완전해진다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:12: error: -[FocusMateTests.PreparationDraftTests test새_준비는_태그와_할_일이_없고_bus이며_불완전하다] : XCTAssertEqual failed: ("none") is not equal to ("bus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test새_태그_편집_기본값은_빈_이름_독서_모래빛이고_초안은_유지된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test소리_없음도_유효한_태그와_할_일이면_확정_가능하다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:171: error: -[FocusMateTests.PreparationDraftTests test소리_없음도_유효한_태그와_할_일이면_확정_가능하다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test없는_태그_ID_선택은_초안_전체를_유지한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:155: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertEqual failed: ("") is not equal to ("My Focus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:156: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertEqual failed: ("reading") is not equal to ("development")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:157: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertEqual failed: ("sand") is not equal to ("purple")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:158: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertEqual failed: ("0") is not equal to ("5")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:159: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:160: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:161: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertEqual failed: ("") is not equal to ("책 읽기")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:162: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertEqual failed: ("none") is not equal to ("rainBus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:163: error: -[FocusMateTests.PreparationDraftTests test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test전각과_반각_이름은_NFKC_중복으로_추가되지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:127: error: -[FocusMateTests.PreparationDraftTests test전각과_반각_이름은_NFKC_중복으로_추가되지_않는다] : XCTAssertEqual failed: ("success(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))") is not equal to ("failure(FocusMate.TagNameIssue.duplicate)")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:176: error: -[FocusMateTests.PreparationDraftTests test할_일은_입력_공백을_보존하고_확정용_값만_trim한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:87: error: -[FocusMateTests.PreparationDraftTests test할_일은_입력_공백을_보존하고_확정용_값만_trim한다] : XCTAssertEqual failed: ("") is not equal to ("
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:88: error: -[FocusMateTests.PreparationDraftTests test할_일은_입력_공백을_보존하고_확정용_값만_trim한다] : XCTAssertEqual failed: ("") is not equal to ("책 읽기")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDraftTests.swift:89: error: -[FocusMateTests.PreparationDraftTests test할_일은_입력_공백을_보존하고_확정용_값만_trim한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test81단위_입력은_80단위로_확정되어_한번_전달된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test81단위_입력은_80단위로_확정되어_한번_전달된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:67: error: -[FocusMateTests.PreparationModelTests test81단위_입력은_80단위로_확정되어_한번_전달된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:68: error: -[FocusMateTests.PreparationModelTests test81단위_입력은_80단위로_확정되어_한번_전달된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:69: error: -[FocusMateTests.PreparationModelTests test81단위_입력은_80단위로_확정되어_한번_전달된다] : XCTUnwrap failed: expected non-nil value of type "PreparedJourneyDetails"
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:69: error: -[FocusMateTests.PreparationModelTests test81단위_입력은_80단위로_확정되어_한번_전달된다] : XCTAssertEqual failed: threw error "UnwrappingOptional(errorCode: 105, errorUserInfo: ["XCTestErrorUserInfoKeyShouldIgnore": true])"
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test같은_payload_확정_연타의_요청은_한번만_소비된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test같은_payload_확정_연타의_요청은_한번만_소비된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:153: error: -[FocusMateTests.PreparationModelTests test같은_payload_확정_연타의_요청은_한번만_소비된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:154: error: -[FocusMateTests.PreparationModelTests test같은_payload_확정_연타의_요청은_한번만_소비된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:155: error: -[FocusMateTests.PreparationModelTests test같은_payload_확정_연타의_요청은_한번만_소비된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:156: error: -[FocusMateTests.PreparationModelTests test같은_payload_확정_연타의_요청은_한번만_소비된다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:158: error: -[FocusMateTests.PreparationModelTests test같은_payload_확정_연타의_요청은_한번만_소비된다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test공백과_줄바꿈_할_일로_변경한_후_직접_확정해도_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test공백과_줄바꿈_할_일로_변경한_후_직접_확정해도_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:316: error: -[FocusMateTests.PreparationModelTests test공백과_줄바꿈_할_일로_변경한_후_직접_확정해도_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:38: error: -[FocusMateTests.PreparationModelTests test독서만_선택하면_할_일은_비어있고_확정_요청은_생성되지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:39: error: -[FocusMateTests.PreparationModelTests test독서만_선택하면_할_일은_비어있고_확정_요청은_생성되지_않는다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional("독서")")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test무효_getter_읽기는_부작용없이_숨기며_소비전_입력복원은_기존요청을_유지한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test무효_getter_읽기는_부작용없이_숨기며_소비전_입력복원은_기존요청을_유지한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:227: error: -[FocusMateTests.PreparationModelTests test무효_getter_읽기는_부작용없이_숨기며_소비전_입력복원은_기존요청을_유지한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:228: error: -[FocusMateTests.PreparationModelTests test무효_getter_읽기는_부작용없이_숨기며_소비전_입력복원은_기존요청을_유지한다] : XCTUnwrap failed: expected non-nil value of type "PreparedJourneyDetails"
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:209: error: -[FocusMateTests.PreparationModelTests test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:213: error: -[FocusMateTests.PreparationModelTests test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:217: error: -[FocusMateTests.PreparationModelTests test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:218: error: -[FocusMateTests.PreparationModelTests test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test빈_할_일로_변경한_후_직접_확정해도_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test빈_할_일로_변경한_후_직접_확정해도_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:316: error: -[FocusMateTests.PreparationModelTests test빈_할_일로_변경한_후_직접_확정해도_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test새_태그_저장은_기존_할_일과_W02_여정을_유지한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test새_태그_저장은_기존_할_일과_W02_여정을_유지한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:80: error: -[FocusMateTests.PreparationModelTests test새_태그_저장은_기존_할_일과_W02_여정을_유지한다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional(FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand))")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:81: error: -[FocusMateTests.PreparationModelTests test새_태그_저장은_기존_할_일과_W02_여정을_유지한다] : XCTAssertEqual failed: ("") is not equal to ("개발 메모")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:82: error: -[FocusMateTests.PreparationModelTests test새_태그_저장은_기존_할_일과_W02_여정을_유지한다] : XCTAssertEqual failed: ("") is not equal to ("책 읽기")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:84: error: -[FocusMateTests.PreparationModelTests test새_태그_저장은_기존_할_일과_W02_여정을_유지한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:277: error: -[FocusMateTests.PreparationModelTests test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:278: error: -[FocusMateTests.PreparationModelTests test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:279: error: -[FocusMateTests.PreparationModelTests test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다] : XCTUnwrap failed: expected non-nil value of type "PreparedJourneyDetails"
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:279: error: -[FocusMateTests.PreparationModelTests test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다] : XCTAssertEqual failed: threw error "UnwrappingOptional(errorCode: 105, errorUserInfo: ["XCTestErrorUserInfoKeyShouldIgnore": true])"
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test소비한_뒤_다시_확정하면_새_요청을_한번_전달한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test소비한_뒤_다시_확정하면_새_요청을_한번_전달한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:167: error: -[FocusMateTests.PreparationModelTests test소비한_뒤_다시_확정하면_새_요청을_한번_전달한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:168: error: -[FocusMateTests.PreparationModelTests test소비한_뒤_다시_확정하면_새_요청을_한번_전달한다] : XCTUnwrap failed: expected non-nil value of type "PreparedJourneyDetails"
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test시간_변경으로_후보가_해제되면_getter와_소비_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test시간_변경으로_후보가_해제되면_getter와_소비_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:112: error: -[FocusMateTests.PreparationModelTests test시간_변경으로_후보가_해제되면_getter와_소비_전달은_0이다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test시간_화면_왕복은_세션_태그_할_일_확정_소리를_보존한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test시간_화면_왕복은_세션_태그_할_일_확정_소리를_보존한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:102: error: -[FocusMateTests.PreparationModelTests test시간_화면_왕복은_세션_태그_할_일_확정_소리를_보존한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:350: error: -[FocusMateTests.PreparationModelTests test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:351: error: -[FocusMateTests.PreparationModelTests test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:357: error: -[FocusMateTests.PreparationModelTests test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다] : XCTAssertEqual failed: ("0") is not equal to ("4")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:361: error: -[FocusMateTests.PreparationModelTests test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다] : XCTAssertEqual failed: ("none") is not equal to ("bus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:244: error: -[FocusMateTests.PreparationModelTests test여정이_없는_직접_확정은_준비값과_요청을_생성하지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:246: error: -[FocusMateTests.PreparationModelTests test여정이_없는_직접_확정은_준비값과_요청을_생성하지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:25: error: -[FocusMateTests.PreparationModelTests test유효_W02로_처음_진입한_준비는_초기값이고_확정할_수_없다] : XCTAssertEqual failed: ("none") is not equal to ("bus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:350: error: -[FocusMateTests.PreparationModelTests test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:351: error: -[FocusMateTests.PreparationModelTests test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:357: error: -[FocusMateTests.PreparationModelTests test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다] : XCTAssertEqual failed: ("0") is not equal to ("4")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:361: error: -[FocusMateTests.PreparationModelTests test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다] : XCTAssertEqual failed: ("none") is not equal to ("bus")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:134: error: -[FocusMateTests.PreparationModelTests test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:135: error: -[FocusMateTests.PreparationModelTests test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:136: error: -[FocusMateTests.PreparationModelTests test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional(FocusMate.PreparedJourneyDetails(journey: FocusMate.JourneySelection(origin: FocusMate.StopPosition(index: 0, direction: 1), minutes: 60, busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12), tag: FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand), task: "책 읽기", sound: FocusMate.JourneySound.subway))")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:137: error: -[FocusMateTests.PreparationModelTests test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional(FocusMate.PreparedJourneyDetails(journey: FocusMate.JourneySelection(origin: FocusMate.StopPosition(index: 0, direction: 1), minutes: 60, busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12), tag: FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand), task: "책 읽기", sound: FocusMate.JourneySound.subway))")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:138: error: -[FocusMateTests.PreparationModelTests test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional(FocusMate.PreparedJourneyDetails(journey: FocusMate.JourneySelection(origin: FocusMate.StopPosition(index: 0, direction: 1), minutes: 60, busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12), tag: FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand), task: "책 읽기", sound: FocusMate.JourneySound.subway))")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:139: error: -[FocusMateTests.PreparationModelTests test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional(FocusMate.PreparedJourneyDetails(journey: FocusMate.JourneySelection(origin: FocusMate.StopPosition(index: 0, direction: 1), minutes: 60, busID: "2014", busNumber: "2014", destination: "성동구민체육센터", stops: 12), tag: FocusMate.PreparationTag(id: "", name: "", icon: FocusMate.PreparationTagIcon.reading, color: FocusMate.PreparationTagColor.sand), task: "책 읽기", sound: FocusMate.JourneySound.subway))")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:330: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:331: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:181: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:182: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertEqual failed: ("nil") is not equal to ("Optional("study")")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:333: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:337: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:338: error: -[FocusMateTests.PreparationModelTests test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:261: error: -[FocusMateTests.PreparationModelTests test태그가_없는_직접_확정은_준비값과_요청을_생성하지_않는다] : XCTAssertEqual failed: ("") is not equal to ("책 읽기")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:330: error: -[FocusMateTests.PreparationModelTests test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:331: error: -[FocusMateTests.PreparationModelTests test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:191: error: -[FocusMateTests.PreparationModelTests test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertEqual failed: ("") is not equal to ("새 할 일")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:333: error: -[FocusMateTests.PreparationModelTests test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:337: error: -[FocusMateTests.PreparationModelTests test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:338: error: -[FocusMateTests.PreparationModelTests test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:307: error: -[FocusMateTests.PreparationModelTests test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:309: error: -[FocusMateTests.PreparationModelTests test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:330: error: -[FocusMateTests.PreparationModelTests test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:331: error: -[FocusMateTests.PreparationModelTests test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertNotNil failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:200: error: -[FocusMateTests.PreparationModelTests test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertEqual failed: ("none") is not equal to ("forest")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:333: error: -[FocusMateTests.PreparationModelTests test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:337: error: -[FocusMateTests.PreparationModelTests test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertTrue failed
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationModelTests.swift:338: error: -[FocusMateTests.PreparationModelTests test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다] : XCTAssertNotNil failed

## Details contract assertion RED (2026-10-14)

Promoted ONLY draft-tests/PreparationDetailsTests.swift to ios/FocusMateTests/PreparationDetailsTests.swift after parent-confirmed GREEN10 (existing 41/0). Existing tests were not edited.

Command, executed from /Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new:
```sh
FOCUSMATE_SIMULATOR_ID=88ABB031-C48A-4DA0-B15C-14787702E647 python3 scripts/check-ios.py test ios/FocusMateTests/PreparationDraftTests.swift ios/FocusMateTests/PreparationModelTests.swift ios/FocusMateTests/PreparationDetailsTests.swift > .dev/codex-feat-preparation-tags-sound/t1-details-red.log 2>&1
```

Exit 65, assertion RED established for the new case. All 42 cases executed: existing Draft 20/0 failures + Model 21/0 failures; new Details 1 case/3 assertion failures (0 unexpected). All three convenience values returned empty strings rather than the independent expected literals. No production reads/searches/edits were performed.

```text
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDetailsTests.swift:14: error: -[FocusMateTests.PreparationDetailsTests testW04_전달값은_성수_정방향_12정류장의_이름_방면_거리를_제공한다] : XCTAssertEqual failed: ("") is not equal to ("성수역")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDetailsTests.swift:15: error: -[FocusMateTests.PreparationDetailsTests testW04_전달값은_성수_정방향_12정류장의_이름_방면_거리를_제공한다] : XCTAssertEqual failed: ("") is not equal to ("성수동 방면")
/Users/bonseung/.codex/worktrees/w03-preparation-tags-sound/new/ios/FocusMateTests/PreparationDetailsTests.swift:16: error: -[FocusMateTests.PreparationDetailsTests testW04_전달값은_성수_정방향_12정류장의_이름_방면_거리를_제공한다] : XCTAssertEqual failed: ("") is not equal to ("6.6km")
```

Log: `.dev/codex-feat-preparation-tags-sound/t1-details-red.log`. Current case count: 42. Next: implement these three derived payload properties, then verify all 42 GREEN.
