# T1 RED draft report

Status: DONE_WITH_CONCERNS — baseline gate 대기 중 초안. 앱 테스트 폴더 승격·명령 실행·RED 확정은 수행하지 않았다.

## 범위와 검증 상태

PreparationDraftTests 및 PreparationModelTests 초안만 작성했다. PRD AC1~13/23의 순수 값·모델 시나리오를 개별 테스트로 구분하고 확정값 현재 유효성 보강을 추가했다. T2 sound controller 및 AppModel.soundPreview는 사용하지 않았다.

컴파일/행동 실패는 아직 확인하지 않았다. 새 선언 미존재 compile RED 예정이며 부모의 baseline 종료 및 승격 지시 이후 무동작 선언에서 behavior assertion RED를 별도 확인해야 한다. 기본값·차단의 일부는 올바른 무동작 기본값에서 통과할 수 있으므로 유효 draft 생성/선택/입력/confirm 성공을 선행하는 테스트가 mutation 누락을 드러내도록 구성했다. 대표 행동 RED 후보: 독서 선택, 80/81 task, 태그 저장, configureValidPreparation의 canConfirmPreparation, confirm 전체 payload, 시간 왕복, consume/reconfirm, 세션 쓰기0 test의 성공적인 확정.

각 테스트 본문 직전에 Break 주석으로 실패시킬 잘못된 제품 변경을 명명했다. 기댓값은 수기 리터럴이며 Fixture expectedJourney는 기존 W02 테스트의 60분·2014·성수정방향·성동구민체육센터·12정류장 값을 사용했다. 기존 저장 fixture는 stage(true, station, station)를 SnapshotCodec으로 실제 임시 파일에 생성한다. real LocalSnapshotStore는 실제 read/create/write I/O를 사용하고 writeData closure 진입 즉시 count를 증가시킨 뒤 실패 환경이면 throw한다. loadIfNeeded 시 쓰기0을 먼저 검사한 후 W03 동작과 새 model 재진입 전후 쓰기0·실제 파일 byte equality를 검사한다.

## 범위 한계

AC1 제목·입력 숨김, AC2 입력 표시, AC5 실제 시트 열기, AC6/7 오류 UI, AC9 준비 복귀, AC10 실제 취소/뒤로가기·포커스는 T3 UI 확인 대상이다. T1의 TagEditorDraft 값 분리는 실제 화면 취소 이벤트 연결을 증명하지 않는다. 쓰기 실패 환경은 이미 ready한 실제 저장 파일의 writeData가 호출되면 throw하는 환경이며 기존 saveFailure 표시/복구 UI를 새로 생성하지 않는다. W03이 writeData를 호출하지 않는지 count를 검사한다.

## AC 매핑

- AC1: 새 draft 초기값 / 유효 W02 최초 준비.
- AC2: 독서 선택·자동 task 없음 / model 직접 확정 차단.
- AC3: 빈 값 / 공백·줄바꿈 각각 draft 및 model.
- AC4: 80 / 81 / surrogate pair 경계 / emoji UTF16 예산 / model 80 확정.
- AC5: 독립 editor 초기값·준비 draft 보존.
- AC6: 빈 이름 / 공백 이름 각각 실패·전체 draft 보존.
- AC7: 대소문자 / 전각·반각 각각 중복·전체 draft 보존.
- AC8: trim된 20 / 21 / 22 UTF16 emoji 이름.
- AC9: 이름·icon·color 저장 / 새 선택·task·sound 보존 / model 여정 보존.
- AC10: 독립 editor 폐기 시 draft 보존 / model 유효값 유지 (실제 UI 이벤트는 T3).
- AC11: 실제 goBack·proceed 왕복 / 시간 변경 후 getter·consume0.
- AC12: 전체 payload·trim·진행/기록0 / 1회 consume / 재confirm / tag·task·sound stale / getter 무부작용.
- AC13: 여정 없음 / 태그 없음 / 빈 task / 공백 task 각각 직접 호출 차단 / invalid consume 이후 복원해도 요청0.
- AC23: 정상 / write throw 환경 각각 세션 생성·확정·consume, 실제 bytes 동일·write0, 새 model 초기화.

## 테스트 case 목록

### PreparationDraftTests.swift (21 cases)

- `test새_준비는_태그와_할_일이_없고_bus이며_불완전하다`
- `test독서_선택은_단일_태그를_선택하고_할_일은_자동_생성하지_않는다`
- `test없는_태그_ID_선택은_초안_전체를_유지한다`
- `test빈_할_일로_바꾸면_준비가_불완전해진다`
- `test공백과_줄바꿈_할_일은_준비가_불완전하다`
- `test80_UTF16_할_일은_그대로_유지되어_확정_가능하다`
- `test81_UTF16_붙여넣기는_80단위까지만_보존한다`
- `test경계의_이모지는_surrogate_pair를_자르지_않는다`
- `test40개_이모지는_80_UTF16이며_41번째는_저장되지_않는다`
- `test할_일은_입력_공백을_보존하고_확정용_값만_trim한다`
- `test새_태그_편집_기본값은_빈_이름_독서_모래빛이고_초안은_유지된다`
- `test빈_태그_이름_저장은_empty와_초안_전체_불변을_반환한다`
- `test공백_태그_이름_저장은_empty와_초안_전체_불변을_반환한다`
- `test대소문자만_다른_태그는_중복으로_추가되지_않는다`
- `test전각과_반각_이름은_NFKC_중복으로_추가되지_않는다`
- `testtrim한_20_UTF16_태그_이름은_저장_가능하다`
- `test21_UTF16_태그_이름은_tooLong과_초안_전체_불변을_반환한다`
- `test11개_이모지_태그는_22_UTF16이므로_거부한다`
- `test유효_태그_저장은_정리한_표시이름과_메타데이터를_추가하고_선택한다`
- `test태그_편집을_취소하면_유효한_기존_초안과_태그수가_그대로다`
- `test소리_없음도_유효한_태그와_할_일이면_확정_가능하다`

### PreparationModelTests.swift (22 cases)

- `test유효_W02로_처음_진입한_준비는_초기값이고_확정할_수_없다`
- `test독서만_선택하면_할_일은_비어있고_확정_요청은_생성되지_않는다`
- `test빈_할_일로_변경한_후_직접_확정해도_전달은_0이다`
- `test공백과_줄바꿈_할_일로_변경한_후_직접_확정해도_전달은_0이다`
- `test81단위_입력은_80단위로_확정되어_한번_전달된다`
- `test새_태그_저장은_기존_할_일과_W02_여정을_유지한다`
- `test태그_편집_취소는_선택_할_일_소리_여정을_유지한다`
- `test시간_화면_왕복은_세션_태그_할_일_확정_소리를_보존한다`
- `test시간_변경으로_후보가_해제되면_getter와_소비_전달은_0이다`
- `test준비_확정은_전체_payload를_전달하고_진행_여정과_기록을_생성하지_않는다`
- `test같은_payload_확정_연타의_요청은_한번만_소비된다`
- `test소비한_뒤_다시_확정하면_새_요청을_한번_전달한다`
- `test태그_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다`
- `test할_일_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다`
- `test확정_소리_변경은_이전_확정값과_요청을_숨기고_소비를_차단한다`
- `test무효_상태에서_소비한_요청은_입력을_복원해도_되살아나지_않는다`
- `test무효_getter_읽기는_부작용없이_숨기며_소비전_입력복원은_기존요청을_유지한다`
- `test여정이_없는_직접_확정은_준비값과_요청을_생성하지_않는다`
- `test태그가_없는_직접_확정은_준비값과_요청을_생성하지_않는다`
- `test소리_없음은_유효한_준비를_차단하지_않고_none으로_전달된다`
- `test정상_저장_환경에서도_W03_쓰기0_원본동일_새모델_초안초기화다`
- `test쓰기_실패_환경에서도_W03_쓰기시도0_원본동일_새모델_초안초기화다`

## 참조 파일 전체 목록

- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-dev/references/codex-roles/red-writer.md
- /Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md
- .dev/codex-feat-preparation-tags-sound/prd.md
- .dev/codex-feat-preparation-tags-sound/design.md (공개 순수 값/AppModel API, 2차 보강, 최종 Testability 포함)
- ios/FocusMateTests/JourneyStartModelTests.swift
- ios/FocusMateTests/StorageTestSupport.swift
- .dev/codex-feat-preparation-tags-sound/draft-tests/PreparationDraftTests.swift (자체 작성 코드)
- .dev/codex-feat-preparation-tags-sound/draft-tests/PreparationModelTests.swift (자체 작성 코드)

Production source Read/Grep/Write 없음. 테스트 실행 명령 없음. 정식 RED report는 승격·실행 뒤 별도 작성.

## 테스트 코드 전문

### PreparationDraftTests.swift

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

    // Break: an editor directly mutates the preparation instead of remaining a separate value.
    func test태그_편집을_취소하면_유효한_기존_초안과_태그수가_그대로다() {
        let draft = validDraft()
        let before = draft
        var editor = TagEditorDraft()
        editor.name = "취소할 태그"
        editor.icon = .writing
        editor.color = .pink
        XCTAssertEqual(draft, before)
        XCTAssertEqual(draft.tags.count, 4)
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

### PreparationModelTests.swift

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

    // Break: discarding a tag editor changes the active draft or journey.
    @MainActor
    func test태그_편집_취소는_선택_할_일_소리_여정을_유지한다() throws {
        try withReadyModel { model, _, _, _ in
            try configureValidPreparation(model)
            model.preparation.setSound(.forest)
            let before = model.preparation
            var editor = TagEditorDraft()
            editor.name = "취소"
            editor.icon = .writing
            editor.color = .pink
            XCTAssertEqual(model.preparation, before)
            XCTAssertEqual(model.preparedJourney, Self.expectedJourney)
            XCTAssertTrue(model.confirmPreparation())
            XCTAssertEqual(try XCTUnwrap(model.consumePreparationRequest()).task, "책 읽기")
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

## 격리 검토 후 정정 (2026-10-14)

현재 초안은 PreparationDraftTests.swift **20 cases**, PreparationModelTests.swift **21 cases**, 총 **41 cases**다. 위 최초 작성 목록과 코드 전문은 변경 전 기록이며 현재 실행 후보는 draft-tests/ 두 파일이다.

제거한 2 cases:
- `test태그_편집을_취소하면_유효한_기존_초안과_태그수가_그대로다`
- `test태그_편집_취소는_선택_할_일_소리_여정을_유지한다`

두 테스트는 로컬 TagEditorDraft 값만 변경한 뒤 건드리지 않은 draft/model을 비교했다. 실제 제품 취소 이벤트를 호출하지 않아 취소 연결 누락·잘못된 commit을 검출할 수 없으므로 제거했다. 현재 초안에 pendingSound 로컬 변수 취소 case는 없다. 태그/소리 시트의 실제 취소·뒤로가기 후 기존 선택/할 일/소리/여정 보존은 T3 XCUITest에서 사용자 이벤트로 검증한다. AC10의 T1 취소 검증 매핑을 철회하고 T3로 이관한다.

순수 TagEditorDraft 초기 입력 계약, UTF16/NFKC 경계, stale confirm/consume guard, 새 모델 재실행 세션 초기화, 실제 LocalSnapshotStore write 진입 0회 및 실제 파일 bytes 불변 검증은 유지했다. 기댓값을 제품 계산 결과로 새로 만들거나 무의미한 probe를 추가하지 않았다.

참조: red-writer 역할 지침, draft-tests/PreparationDraftTests.swift, draft-tests/PreparationModelTests.swift, 이 report만 읽었다. production은 열람·검색·수정하지 않았다. baseline full 재실행이 끝나지 않은 상태이므로 앱 테스트 폴더 승격·테스트 실행·RED 확정은 수행하지 않았으며 승격 지시를 대기한다.

### missing-tag 입력 전제 보강

`test태그가_없는_직접_확정은_준비값과_요청을_생성하지_않는다`에 `XCTAssertEqual(model.preparation.task, "책 읽기")`를 추가했다. 비어 있지 않은 실제 입력 상태를 먼저 확인하여 no-op setTask가 missing-tag guard 검증을 거짓으로 통과하지 않게 한다. fresh editor 초기값 case는 이미 validDraft()를 호출하며 helper의 chooseTag 성공 assertion이 no-op 선택을 검출한다. case count는 20 + 21 = 41로 유지한다. production은 읽지 않았고 formal promotion/실행은 baseline full GREEN까지 대기한다.
