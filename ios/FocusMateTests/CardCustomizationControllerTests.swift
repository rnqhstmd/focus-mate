import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class CardCustomizationControllerTests: XCTestCase {
    private let a = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let b = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let c = UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
    private let unknown = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
    private let blue = CardColor(red: 0.1, green: 0.2, blue: 0.8)
    // Independent RGB literal, exercised through restore + undo, never a constant-only test.
    private var defaultStyle: CardStyle {
        CardStyle(background: CardColor(red: 18.0 / 255, green: 20.0 / 255, blue: 22.0 / 255), photos: [])
    }
    private func photo(_ id: UUID, x: Double = 0.5, y: Double = 0.5,
                       width: Double = 0.6) -> CardPhoto {
        CardPhotoTestFixtures.photo(id: id, x: x, y: y, fraction: width)
    }
    private func style(_ photos: [CardPhoto]) -> CardStyle {
        CardStyle(background: blue, photos: photos)
    }
    private struct Rig {
        let controller: CardCustomizationController
        let saver: DraftCardSaver
    }
    private func rig(_ initial: CardStyle? = nil,
                     processor: any CardPhotoProcessing = DraftPhotoProcessor()) -> Rig {
        let saver = DraftCardSaver()
        let ids = DraftIDs()
        let card = CardSnapshot(id: "FM-01234567", issuedAt: Date(timeIntervalSince1970: 1_791_882_000),
                                style: initial ?? defaultStyle)
        return Rig(controller: CardCustomizationController(card: card, saver: saver,
                    processor: processor, makeID: { ids.make() }), saver: saver)
    }
    private func input(_ byte: UInt8) -> CardPhotoInput {
        CardPhotoInput(load: { Data([byte]) })
    }
    private func sixPhotos() -> [CardPhoto] {
        (1...6).map { photo(UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", $0))!) }
    }

    // AC 03,04,26; Given: 저장 외형과 고정 ID의 카드; When: 편집 후 명시적 저장; Then: 초안은 저장 외형에서 시작하며 saver는 원래 ID와 편집 외형을 받는다.
    // 깨짐 명명: 초안을 기본값으로 대체하거나 저장 ID를 새로 생성.
    func testInitialDraftCopiesSavedStyleAndSaveUsesOriginalCardID() {
        let initial = style([photo(a)])
        let r = rig(initial)
        XCTAssertEqual(r.controller.draft, initial)
        r.controller.setBackground(CardColor(red: 0.7, green: 0.3, blue: 0.2))
        let expected = CardStyle(background: CardColor(red: 0.7, green: 0.3, blue: 0.2), photos: [photo(a)])
        XCTAssertTrue(r.controller.save())
        XCTAssertEqual(r.saver.calls.count, 1)
        XCTAssertEqual(r.saver.calls.first?.cardID, "FM-01234567")
        XCTAssertEqual(r.saver.calls.first?.style, expected)
    }

    // AC 03; Given: 기본색 사진0장; When: 사용자색 선택; Then: 초안 색만 바뀌고 저장 호출 없음.
    // 깨짐 명명: setBackground에서 saver 호출 또는 색 무시.
    func testBackgroundChoiceChangesDraftWithoutSaving() {
        let r = rig()
        r.controller.setBackground(blue)
        XCTAssertEqual(r.controller.draft.background, blue)
        XCTAssertTrue(r.controller.hasChanges)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 03; Given: 변경 없는 초안; When: 범위 밖 또는 비유한 RGB 적용; Then: 초안과 history 유지.
    // 깨짐 명명: RGB 유효성 검사 제거.
    func testInvalidRGBIsWholeNoOp() {
        let r = rig()
        for color in [CardColor(red: -0.1, green: 0, blue: 0), CardColor(red: 1.1, green: 0, blue: 0), CardColor(red: .nan, green: 0, blue: 0)] {
            r.controller.setBackground(color)
            XCTAssertEqual(r.controller.draft, defaultStyle)
            XCTAssertFalse(r.controller.canUndo)
        }
    }

    // AC 04; Given: 사진0장; When: 사진 읽기 성공; Then: 새 사진 중심과 너비가 초기값이며 이동 가능.
    // 깨짐 명명: 초기 배치가 0 또는 이동 메서드가 no-op.
    func testImportCreatesEditablePhotoWithLiteralInitialPlacement() async {
        let r = rig()
        await r.controller.importPhotos([input(1)])
        XCTAssertEqual(r.controller.draft.photos.count, 1)
        let importedID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        XCTAssertEqual(r.controller.draft.photos.first?.id, importedID)
        XCTAssertEqual(r.controller.draft.photos.first?.centerX, 0.5)
        XCTAssertEqual(r.controller.draft.photos.first?.centerY, 0.5)
        XCTAssertEqual(r.controller.draft.photos.first?.widthFraction, 0.6)
        r.controller.selectPhoto(importedID)
        r.controller.setPlacement(photoID: importedID, centerX: 0.2, centerY: 0.3, widthFraction: 0.8)
        XCTAssertEqual(r.controller.selectedPhotoID, importedID)
        XCTAssertEqual(r.controller.draft.photos.first?.centerX, 0.2)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 06; Given: 6장; When: 추가 요청; Then: loader0회 maximumPhotos.
    // 깨짐 명명: 6장 가드 뒤에 loader 호출.
    func testFullCardRejectsImportBeforeLoader() async {
        let r = rig(style(sixPhotos()))
        let loader = DraftLoadCounter()
        await r.controller.importPhotos([loader.input(Data([1]))])
        XCTAssertEqual(loader.calls, 0)
        XCTAssertEqual(r.controller.draft.photos.count, 6)
        XCTAssertEqual(r.controller.notice, .maximumPhotos)
        XCTAssertFalse(r.controller.canAddPhotos)
        XCTAssertFalse(r.controller.canUndo)
    }

    // AC 07; Given: 5장; When: 정상3장 선택; Then: 첫1장만 추가하고 나머지 loader 미호출.
    // 깨짐 명명: 만석 이후 입력 처리 또는 omittedCount 오계산.
    func testOverflowProcessesOnlyRemainingSlots() async {
        let r = rig(style(Array(sixPhotos().prefix(5))))
        let loader = DraftLoadCounter()
        await r.controller.importPhotos([loader.input(Data([7])), loader.input(Data([8])), loader.input(Data([9]))])
        XCTAssertEqual(loader.calls, 1)
        XCTAssertEqual(r.controller.draft.photos.count, 6)
        XCTAssertEqual(r.controller.draft.photos.last?.data, Data([7]))
        XCTAssertEqual(r.controller.notice, .partialImport(failures: [], omittedCount: 2))
    }

    // AC 07,09; Given: 5장; When: 실패 다음 성공 다음 미처리 입력; Then: 성공이 마지막 자리를 쓰고 실패 생략 안내.
    // 깨짐 명명: 실패를 자리 소비로 계산.
    func testFailureDoesNotConsumeRemainingSlot() async {
        let r = rig(style(Array(sixPhotos().prefix(5))))
        let loader = DraftLoadCounter()
        await r.controller.importPhotos([loader.input(nil), loader.input(Data([7])), loader.input(Data([8]))])
        XCTAssertEqual(loader.calls, 2)
        XCTAssertEqual(r.controller.draft.photos.count, 6)
        XCTAssertEqual(r.controller.draft.photos.last?.data, Data([7]))
        XCTAssertEqual(r.controller.notice, .partialImport(failures: [.unreadable], omittedCount: 1))
    }

    // AC 08; Given: 2장 이력 없음; When: 빈 선택; Then: 외형과 history 유지.
    // 깨짐 명명: 빈 선택이 history를 추가.
    func testEmptyPickerCancellationPreservesDraftWithoutHistory() async {
        let initial = style([photo(a), photo(b)])
        let r = rig(initial)
        await r.controller.importPhotos([])
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.isImporting)
    }

    // AC 08,10; Given: 실패 안내 있는 세션; When: 빈 선택; Then: notice 유지.
    // 깨짐 명명: 빈 배열 분기가 notice 초기화.
    func testEmptyInputKeepsExistingFailureNotice() async {
        let r = rig()
        await r.controller.importPhotos([CardPhotoInput(load: { nil })])
        await r.controller.importPhotos([])
        XCTAssertEqual(r.controller.notice, .importFailed([.unreadable]))
    }

    // AC 09,15; Given: 기존1장; When: 정상 실패 정상 입력; Then: 성공 순서 보존하고 undo1회로 전체 batch 제거.
    // 깨짐 명명: 성공마다 history를 만들거나 순서를 역전.
    func testPartialSuccessIsOneUndoBatch() async {
        let initial = style([photo(a)])
        let r = rig(initial)
        await r.controller.importPhotos([input(2), input(90), input(3)])
        XCTAssertEqual(r.controller.draft.photos.map(\.data), [Data([1]), Data([2]), Data([3])])
        XCTAssertEqual(r.controller.notice, .partialImport(failures: [.encodingFailed], omittedCount: 0))
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertFalse(r.controller.canUndo)
    }

    // AC 09; Given: 부분 성공 안내; When: 색 편집 후 저장; Then: 입력 잠금 해제되고 저장 허용.
    // 깨짐 명명: 실패 후 isImporting 해제 누락.
    func testPartialFailureAllowsEditingAndSave() async {
        let r = rig(style([photo(a)]))
        await r.controller.importPhotos([input(2), input(90)])
        XCTAssertFalse(r.controller.isImporting)
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        XCTAssertEqual(r.controller.draft.background, CardColor(red: 0.9, green: 0.8, blue: 0.7))
        XCTAssertTrue(r.controller.save())
    }

    // AC 10; Given: 색 변경 이력; When: processor실패 둘; Then: 외형 이력 유지 실패 선택순 안내.
    // 깨짐 명명: 실패 batch가 history를 지우거나 오류 순서 역전.
    func testAllFailuresKeepPreviousHistoryAndFailureOrder() async {
        let r = rig()
        r.controller.setBackground(blue)
        let edited = r.controller.draft
        await r.controller.importPhotos([input(91), input(90)])
        XCTAssertEqual(r.controller.draft, edited)
        XCTAssertEqual(r.controller.notice, .importFailed([.unsupportedAspectRatio, .encodingFailed]))
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, defaultStyle)
        XCTAssertFalse(r.controller.canUndo)
    }

    // AC 10; Given: 활성 세션; When: nil 일반오류 cancellation 입력; Then: 세 실패 unreadable 후 재입력 가능.
    // 깨짐 명명: loader 오류를 삼키거나 cancellation을 세션 폐기로 처리.
    func testLoaderNilThrowAndActiveCancellationAreUnreadable() async {
        let r = rig()
        await r.controller.importPhotos([
            CardPhotoInput(load: { nil }),
            CardPhotoInput(load: { throw CardPhotoProcessingIssue.encodingFailed }),
            CardPhotoInput(load: { throw CancellationError() })
        ])
        XCTAssertEqual(r.controller.notice, .importFailed([.unreadable, .unreadable, .unreadable]))
        XCTAssertEqual(r.controller.draft, defaultStyle)
        XCTAssertFalse(r.controller.canUndo)
        await r.controller.importPhotos([input(1)])
        XCTAssertEqual(r.controller.draft.photos.count, 1)
        XCTAssertNil(r.controller.notice)
    }

    // AC 11; Given: 서로 다른 배치의2장; When: 한장 배치 변경; Then: 선택 대상 배치만 변경 치수와 나머지 보존.
    // 깨짐 명명: 모든 사진에 배치 적용 또는 치수 변경.
    func testPlacementChangesOnlyTargetAndKeepsAspect() {
        let initial = style([photo(a), photo(b, x: 0.9, y: 0.1, width: 0.3)])
        let r = rig(initial)
        r.controller.selectPhoto(a)
        r.controller.setPlacement(photoID: a, centerX: 0.2, centerY: 0.7, widthFraction: 1.2)
        XCTAssertEqual(r.controller.draft.photos[0], photo(a, x: 0.2, y: 0.7, width: 1.2))
        XCTAssertEqual(r.controller.draft.photos[1], photo(b, x: 0.9, y: 0.1, width: 0.3))
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 11; Given: 한장; When: 범위 밖 배치; Then: 각축 너비 clamp.
    // 깨짐 명명: clamp 하한 또는 상한 오설정.
    func testPlacementClampsMinimum() {
        let r = rig(style([photo(a)]))
        r.controller.setPlacement(photoID: a, centerX: -2, centerY: -3, widthFraction: 0.01)
        XCTAssertEqual(r.controller.draft.photos[0], photo(a, x: -1, y: -1, width: 0.15))
        r.controller.undo()
        XCTAssertEqual(r.controller.draft.photos[0], photo(a))
    }

    // AC 11; Given: 한장; When: 범위 밖 배치; Then: 각축 너비 clamp.
    // 깨짐 명명: clamp 하한 또는 상한 오설정.
    func testPlacementClampsMaximum() {
        let r = rig(style([photo(a)]))
        r.controller.setPlacement(photoID: a, centerX: 3, centerY: 4, widthFraction: 3)
        XCTAssertEqual(r.controller.draft.photos[0], photo(a, x: 2, y: 2, width: 2.5))
        r.controller.undo()
        XCTAssertEqual(r.controller.draft.photos[0], photo(a))
    }

    // AC 11; Given: 정상 배치; When: 한 필드만 비유한 다른 필드는 정상 변경; Then: 전체 no-op history없음.
    // 깨짐 명명: finite 필드만 부분 적용.
    func testNonFinitePlacementRejectsWholeOperation() {
        let initial = style([photo(a)])
        let r = rig(initial)
        for values in [(Double.nan, 0.2, 0.9), (0.2, Double.infinity, 0.9), (0.2, 0.3, -Double.infinity)] {
            r.controller.setPlacement(photoID: a, centerX: values.0, centerY: values.1, widthFraction: values.2)
            XCTAssertEqual(r.controller.draft, initial)
            XCTAssertFalse(r.controller.canUndo)
        }
    }

    // AC 13; Given: A B C; When: B를 한단계 이동; Then: 순서만 변경.
    // 깨짐 명명: 앞뒤 방향 반전 또는 끝으로 이동.
    func testLayerMovesOneStepForward() {
        let r = rig(style([photo(a), photo(b), photo(c)]))
        r.controller.selectPhoto(b)
        r.controller.moveLayer(photoID: b, direction: .forward)
        XCTAssertEqual(r.controller.draft.photos.map(\.id), [a, c, b])
        XCTAssertEqual(r.controller.draft.photos.first(where: { $0.id == b }), photo(b))
    }

    // AC 13; Given: A B C; When: B를 한단계 이동; Then: 순서만 변경.
    // 깨짐 명명: 앞뒤 방향 반전 또는 끝으로 이동.
    func testLayerMovesOneStepBackward() {
        let r = rig(style([photo(a), photo(b), photo(c)]))
        r.controller.selectPhoto(b)
        r.controller.moveLayer(photoID: b, direction: .backward)
        XCTAssertEqual(r.controller.draft.photos.map(\.id), [b, a, c])
        XCTAssertEqual(r.controller.draft.photos.first(where: { $0.id == b }), photo(b))
    }

    // AC 13,16; Given: A B C; When: 맨앞 forward 맨뒤 backward; Then: 외형 이력 유지.
    // 깨짐 명명: 끝단 이동이 history 생성.
    func testLayerEndsDoNotCreateHistory() {
        let initial = style([photo(a), photo(b), photo(c)])
        let r = rig(initial)
        r.controller.moveLayer(photoID: c, direction: .forward)
        r.controller.moveLayer(photoID: a, direction: .backward)
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertFalse(r.controller.canUndo)
    }

    // AC 14,15; Given: 6장; When: 선택 사진 삭제 후 undo; Then: 해당사진만 제거 슬롯 재개 undo복원.
    // 깨짐 명명: 다른 사진 삭제 또는 undo에서 원본 배치 손실.
    func testDeleteReopensSlotAndUndoRestoresExactPhoto() {
        let initial = style(sixPhotos())
        let r = rig(initial)
        r.controller.selectPhoto(b)
        r.controller.deletePhoto(b)
        XCTAssertEqual(r.controller.draft.photos.map(\.id), [a, c,
            UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000006")!])
        XCTAssertTrue(r.controller.canAddPhotos)
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, initial)
    }

    // AC 15; Given: 기존1장; When: 추가 색 이동 크기 순서 삭제를 수행 후 역 undo; Then: 매번 직전 외형 복원 저장0회.
    // 깨짐 명명: 한 변이 history 누락.
    func testUndoReversesEachMutationWithoutSaving() async {
        let initial = style([photo(a)])
        let r = rig(initial)
        await r.controller.importPhotos([input(2)])
        let added = r.controller.draft
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        let colored = r.controller.draft
        r.controller.setPlacement(photoID: a, centerX: 0.2, centerY: 0.3, widthFraction: 0.6)
        let moved = r.controller.draft
        r.controller.setPlacement(photoID: a, centerX: 0.2, centerY: 0.3, widthFraction: 1.2)
        let sized = r.controller.draft
        r.controller.moveLayer(photoID: a, direction: .forward)
        let layered = r.controller.draft
        r.controller.deletePhoto(a)
        for expected in [layered, sized, moved, colored, added, initial] {
            r.controller.undo()
            XCTAssertEqual(r.controller.draft, expected)
        }
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 15; Given: 추가 사진 선택; When: 추가 undo; Then: 선택nil.
    // 깨짐 명명: undo후 존재하지 않는 선택 유지.
    func testUndoRemovedSelectedPhotoClearsSelection() async {
        let r = rig()
        await r.controller.importPhotos([input(1)])
        r.controller.selectPhoto(UUID(uuidString: "00000000-0000-0000-0000-000000000101")!)
        r.controller.undo()
        XCTAssertNil(r.controller.selectedPhotoID)
    }

    // AC 16; Given: 서로 다른 색 변경21회; When: undo20회; Then: 첫 변경 0.01 남고 더 undo불가.
    // 깨짐 명명: history 21개 유지 또는 19개만 유지.
    func testUndoRetainsLiteralFirstChangeAfterTwentyUndos() {
        let r = rig()
        for step in 1...21 {
            r.controller.setBackground(CardColor(red: Double(step) / 100, green: 0.3, blue: 0.4))
        }
        for _ in 0..<20 { r.controller.undo() }
        XCTAssertEqual(r.controller.draft.background, CardColor(red: 0.01, green: 0.3, blue: 0.4))
        XCTAssertFalse(r.controller.canUndo)
        r.controller.undo()
        XCTAssertEqual(r.controller.draft.background, CardColor(red: 0.01, green: 0.3, blue: 0.4))
    }

    // AC 16; Given: 기존1장과 한 색 변경; When: 선택 해제 재선택 같은색 같은배치; Then: undo1회로 baseline.
    // 깨짐 명명: 선택이나 동일값에 history 생성.
    func testSelectionAndEqualValuesDoNotConsumeHistory() {
        let initial = style([photo(a)])
        let r = rig(initial)
        let chosen = CardColor(red: 0.6, green: 0.7, blue: 0.8)
        r.controller.setBackground(chosen)
        r.controller.selectPhoto(a)
        r.controller.selectPhoto(nil)
        r.controller.selectPhoto(a)
        r.controller.setBackground(chosen)
        r.controller.setPlacement(photoID: a, centerX: 0.5, centerY: 0.5, widthFraction: 0.6)
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertFalse(r.controller.canUndo)
    }

    // AC 11,13,14,16; Given: 알려진 사진 선택; When: 없는ID 선택 변경 삭제 순서; Then: 선택 초안 이력 유지.
    // 깨짐 명명: unknownID 선택 허용 또는 변경 생성.
    func testUnknownIDsAreNoOpsIncludingSelection() {
        let initial = style([photo(a)])
        let r = rig(initial)
        r.controller.selectPhoto(a)
        r.controller.selectPhoto(unknown)
        r.controller.setPlacement(photoID: unknown, centerX: 1, centerY: 1, widthFraction: 1)
        r.controller.moveLayer(photoID: unknown, direction: .forward)
        r.controller.deletePhoto(unknown)
        XCTAssertEqual(r.controller.selectedPhotoID, a)
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertFalse(r.controller.canUndo)
    }

    // AC 17; Given: 다른색 사진3장; When: 기본복원 후 undo; Then: literal기본색0장 복원 전 외형 undo.
    // 깨짐 명명: 복원이 사진만 지우거나 history 누락.
    func testRestoreDefaultCanBeUndoneAsOneMutation() {
        let initial = style([photo(a), photo(b), photo(c)])
        let r = rig(initial)
        r.controller.restoreDefault()
        XCTAssertEqual(r.controller.draft, defaultStyle)
        XCTAssertTrue(r.saver.calls.isEmpty)
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertFalse(r.controller.canUndo)
    }

    // AC 16,17; Given: 기본 초안; When: 기본복원; Then: history없음.
    // 깨짐 명명: 동일기본 복원이 history 생성.
    func testRestoringAlreadyDefaultIsNoOp() {
        let r = rig()
        r.controller.restoreDefault()
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.hasChanges)
    }

    // AC 19; Given: 변경없음; When: 종료; Then: dismiss 저장0회.
    // 깨짐 명명: 모든 종료에 확인 반환.
    func testPristineExitDismissesWithoutSaving() {
        let r = rig(style([photo(a)]))
        XCTAssertEqual(r.controller.requestExit(), .dismiss)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 20; Given: 미저장색 변경; When: 종료확인 계속편집; Then: 초안과 history 유지.
    // 깨짐 명명: continue에서 baseline복원.
    func testContinueEditingPreservesUnsavedDraftAndHistory() {
        let r = rig()
        r.controller.setBackground(blue)
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        r.controller.continueEditing()
        XCTAssertEqual(r.controller.draft.background, blue)
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, defaultStyle)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 21; Given: 미저장변경 선택 실패안내; When: 버리기; Then: baseline와 비활성 초기상태.
    // 깨짐 명명: discard가 draft selection notice history 잔존.
    func testDiscardRestoresBaselineAndClearsSessionState() async {
        let initial = style([photo(a)])
        let r = rig(initial)
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        r.controller.selectPhoto(a)
        await r.controller.importPhotos([input(90)])
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        r.controller.discard()
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.selectedPhotoID)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.hasChanges)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertFalse(r.controller.isSaving)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 21,22; Given: 버린 세션; When: 모든변경 import save 호출; Then: draft selection notice유지 savefalse 경계0회.
    // 깨짐 명명: 한 메서드의 비활성 가드 누락.
    func testInactiveSessionRejectsAllDefinedMutationMethods() async {
        let initial = style([photo(a), photo(b)])
        let r = rig(initial)
        func assertInactive(file: StaticString = #filePath, line: UInt = #line) {
            XCTAssertEqual(r.controller.draft, initial, file: file, line: line)
            XCTAssertNil(r.controller.selectedPhotoID, file: file, line: line)
            XCTAssertNil(r.controller.notice, file: file, line: line)
            XCTAssertFalse(r.controller.canUndo, file: file, line: line)
            XCTAssertFalse(r.controller.didSave, file: file, line: line)
            XCTAssertFalse(r.controller.isImporting, file: file, line: line)
            XCTAssertFalse(r.controller.isSaving, file: file, line: line)
            XCTAssertTrue(r.saver.calls.isEmpty, file: file, line: line)
        }
        r.controller.discard()
        assertInactive()
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        assertInactive()
        r.controller.selectPhoto(a)
        assertInactive()
        r.controller.selectPhoto(nil)
        assertInactive()
        r.controller.setPlacement(photoID: a, centerX: 1, centerY: 1, widthFraction: 1)
        assertInactive()
        r.controller.moveLayer(photoID: a, direction: .forward)
        assertInactive()
        r.controller.deletePhoto(a)
        assertInactive()
        r.controller.restoreDefault()
        assertInactive()
        r.controller.undo()
        assertInactive()
        r.controller.continueEditing()
        assertInactive()
        r.controller.discard()
        let loader = DraftLoadCounter()
        await r.controller.importPhotos([loader.input(Data([2]))])
        XCTAssertFalse(r.controller.save())
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.selectedPhotoID)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertEqual(loader.calls, 0)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 19,21; Given: 버려 비활성인 세션; When: 종료를 다시 요청; Then: 상태 변경 없이 dismiss.
    // 깨짐 명명: 비활성 requestExit가 confirmDiscard를 반환하거나 세션 상태를 다시 활성화.
    func testInactiveRequestExitDismissesWithoutStateChanges() {
        let initial = style([photo(a), photo(b)])
        let r = rig(initial)
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        r.controller.selectPhoto(a)
        r.controller.discard()

        XCTAssertEqual(r.controller.requestExit(), .dismiss)
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.selectedPhotoID)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.hasChanges)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertFalse(r.controller.isSaving)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 23; Given: loader 대기 중 기존 2장과 색 변경 이력; When: 변경재입력저장선택종료 요청; Then: 변경잠금 선택 종료확인 허용.
    // 깨짐 명명: import 잠금 가드 누락 또는 선택/종료까지 차단.
    func testImportBlocksMutationsReimportAndSaveButAllowsSelectionAndExit() async {
        let initial = style([photo(a), photo(b)])
        let r = rig(initial)
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        let expected = CardStyle(background: CardColor(red: 0.9, green: 0.8, blue: 0.7), photos: [photo(a), photo(b)])
        let gate = DraftGate<Data?>()
        let task = Task { await r.controller.importPhotos([CardPhotoInput(load: { try await gate.run() })]) }
        await gate.waitForStart()
        XCTAssertTrue(r.controller.isImporting)
        r.controller.setBackground(CardColor(red: 0.2, green: 0.4, blue: 0.6))
        XCTAssertEqual(r.controller.draft, expected)
        r.controller.setPlacement(photoID: a, centerX: 1, centerY: 1, widthFraction: 1)
        XCTAssertEqual(r.controller.draft, expected)
        r.controller.moveLayer(photoID: a, direction: .forward)
        XCTAssertEqual(r.controller.draft, expected)
        r.controller.deletePhoto(a)
        XCTAssertEqual(r.controller.draft, expected)
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, expected)
        r.controller.restoreDefault()
        XCTAssertEqual(r.controller.draft, expected)
        let loader = DraftLoadCounter()
        await r.controller.importPhotos([loader.input(Data([3]))])
        XCTAssertFalse(r.controller.save())
        r.controller.selectPhoto(b)
        XCTAssertEqual(r.controller.selectedPhotoID, b)
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        XCTAssertEqual(r.controller.draft, expected)
        XCTAssertTrue(r.controller.canUndo)
        XCTAssertEqual(loader.calls, 0)
        XCTAssertTrue(r.saver.calls.isEmpty)
        await gate.release(.success(Data([2])))
        await task.value
        XCTAssertFalse(r.controller.isImporting)
        r.controller.setBackground(CardColor(red: 0.2, green: 0.4, blue: 0.6))
        XCTAssertEqual(r.controller.draft.background, CardColor(red: 0.2, green: 0.4, blue: 0.6))
        XCTAssertTrue(r.controller.save())
    }

    // AC 20,21,22; Given: import중 종료확인; When: 확인 중 입력완료 후 Continue; Then: 완료draft유지.
    // 깨짐 명명: dialog에서 입력취소 또는 완료후 버리기 baseline불복원.
    func testCompletionDuringConfirmationThenContinue() async {
        let initial = style([photo(a)])
        let r = rig(initial)
        let gate = DraftGate<Data?>()
        let task = Task { await r.controller.importPhotos([CardPhotoInput(load: { try await gate.run() })]) }
        await gate.waitForStart()
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        await gate.release(.success(Data([2])))
        await task.value
        XCTAssertEqual(r.controller.draft.photos.count, 2)
        r.controller.continueEditing()
        XCTAssertEqual(r.controller.draft.photos.map(\.data), [Data([1]), Data([2])])
        XCTAssertTrue(r.controller.canUndo)
    }

    // AC 20,21,22; Given: import중 종료확인; When: 확인 중 입력완료 후 Discard; Then: baseline복원.
    // 깨짐 명명: dialog에서 입력취소 또는 완료후 버리기 baseline불복원.
    func testCompletionDuringConfirmationThenDiscard() async {
        let initial = style([photo(a)])
        let r = rig(initial)
        let gate = DraftGate<Data?>()
        let task = Task { await r.controller.importPhotos([CardPhotoInput(load: { try await gate.run() })]) }
        await gate.waitForStart()
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        await gate.release(.success(Data([2])))
        await task.value
        XCTAssertEqual(r.controller.draft.photos.count, 2)
        r.controller.discard()
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertFalse(r.controller.canUndo)
    }

    // AC 22; Given: await중; When: 버린 뒤 늦은 Success; Then: 결과 notice defer상태가 세션 재활성화하지 않음.
    // 깨짐 명명: await 뒤 generation 검사 또는 defer 보호 누락.
    func testDiscardIgnoresLateLoaderSuccess() async {
        let initial = style([photo(a)])
        let gate = DraftGate<Data?>()
        let r = rig(initial)
        let task = Task { await r.controller.importPhotos([CardPhotoInput(load: { try await gate.run() })]) }
        await gate.waitForStart()
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        r.controller.discard()
        XCTAssertFalse(r.controller.isImporting)
        await gate.release(.success(Data([2])))
        await task.value
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.save())
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 22; Given: await중; When: 버린 뒤 늦은 Error; Then: 결과 notice defer상태가 세션 재활성화하지 않음.
    // 깨짐 명명: await 뒤 generation 검사 또는 defer 보호 누락.
    func testDiscardIgnoresLateLoaderError() async {
        let initial = style([photo(a)])
        let gate = DraftGate<Data?>()
        let r = rig(initial)
        let task = Task { await r.controller.importPhotos([CardPhotoInput(load: { try await gate.run() })]) }
        await gate.waitForStart()
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        r.controller.discard()
        XCTAssertFalse(r.controller.isImporting)
        await gate.release(.failure(CardPhotoProcessingIssue.encodingFailed))
        await task.value
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.save())
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 22; Given: await중; When: 버린 뒤 늦은 Cancellation; Then: 결과 notice defer상태가 세션 재활성화하지 않음.
    // 깨짐 명명: await 뒤 generation 검사 또는 defer 보호 누락.
    func testDiscardIgnoresLateLoaderCancellation() async {
        let initial = style([photo(a)])
        let gate = DraftGate<Data?>()
        let r = rig(initial)
        let task = Task { await r.controller.importPhotos([CardPhotoInput(load: { try await gate.run() })]) }
        await gate.waitForStart()
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        r.controller.discard()
        XCTAssertFalse(r.controller.isImporting)
        await gate.release(.failure(CancellationError()))
        await task.value
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.save())
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 22; Given: await중; When: 버린 뒤 늦은 Success; Then: 결과 notice defer상태가 세션 재활성화하지 않음.
    // 깨짐 명명: await 뒤 generation 검사 또는 defer 보호 누락.
    func testDiscardIgnoresLateProcessorSuccess() async {
        let initial = style([photo(a)])
        let gate = DraftGate<ProcessedCardPhoto>()
        let r = rig(initial, processor: DraftHeldProcessor(gate: gate))
        let task = Task { await r.controller.importPhotos([input(2)]) }
        await gate.waitForStart()
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        r.controller.discard()
        XCTAssertFalse(r.controller.isImporting)
        await gate.release(.success(ProcessedCardPhoto(data: Data([2]), pixelWidth: 40, pixelHeight: 20)))
        await task.value
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.save())
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 22; Given: await중; When: 버린 뒤 늦은 Error; Then: 결과 notice defer상태가 세션 재활성화하지 않음.
    // 깨짐 명명: await 뒤 generation 검사 또는 defer 보호 누락.
    func testDiscardIgnoresLateProcessorError() async {
        let initial = style([photo(a)])
        let gate = DraftGate<ProcessedCardPhoto>()
        let r = rig(initial, processor: DraftHeldProcessor(gate: gate))
        let task = Task { await r.controller.importPhotos([input(2)]) }
        await gate.waitForStart()
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        r.controller.discard()
        XCTAssertFalse(r.controller.isImporting)
        await gate.release(.failure(CardPhotoProcessingIssue.encodingFailed))
        await task.value
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.save())
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 22; Given: await중; When: 버린 뒤 늦은 Cancellation; Then: 결과 notice defer상태가 세션 재활성화하지 않음.
    // 깨짐 명명: await 뒤 generation 검사 또는 defer 보호 누락.
    func testDiscardIgnoresLateProcessorCancellation() async {
        let initial = style([photo(a)])
        let gate = DraftGate<ProcessedCardPhoto>()
        let r = rig(initial, processor: DraftHeldProcessor(gate: gate))
        let task = Task { await r.controller.importPhotos([input(2)]) }
        await gate.waitForStart()
        XCTAssertEqual(r.controller.requestExit(), .confirmDiscard)
        r.controller.discard()
        XCTAssertFalse(r.controller.isImporting)
        await gate.release(.failure(CancellationError()))
        await task.value
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.isImporting)
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.save())
        XCTAssertTrue(r.saver.calls.isEmpty)
    }

    // AC 26; Given: 변경 draft와 선택; When: saverfalse; Then: 명시적오류 또는 fallback 안내 draft 이력 선택 유지.
    // 깨짐 명명: 실패를 성공처리 또는 실패에서 draft/history 초기화.
    func testSaveFailureFallbackKeepsDraftSelectionAndHistory() {
        let initial = style([photo(a)])
        let r = rig(initial)
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        r.controller.selectPhoto(a)
        let edited = r.controller.draft
        r.saver.result = false
        r.saver.saveFailure = nil
        XCTAssertFalse(r.controller.save())
        XCTAssertEqual(r.controller.notice, .saveFailed(.writeFailed))
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.isSaving)
        XCTAssertEqual(r.controller.draft, edited)
        XCTAssertEqual(r.controller.selectedPhotoID, a)
        XCTAssertTrue(r.controller.canUndo)
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, initial)
    }

    // AC 26; Given: 변경 draft와 선택; When: saverfalse; Then: 명시적오류 또는 fallback 안내 draft 이력 선택 유지.
    // 깨짐 명명: 실패를 성공처리 또는 실패에서 draft/history 초기화.
    func testSaveFailureExplicitKeepsDraftSelectionAndHistory() {
        let initial = style([photo(a)])
        let r = rig(initial)
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        r.controller.selectPhoto(a)
        let edited = r.controller.draft
        r.saver.result = false
        r.saver.saveFailure = .notReady
        XCTAssertFalse(r.controller.save())
        XCTAssertEqual(r.controller.notice, .saveFailed(.notReady))
        XCTAssertFalse(r.controller.didSave)
        XCTAssertFalse(r.controller.isSaving)
        XCTAssertEqual(r.controller.draft, edited)
        XCTAssertEqual(r.controller.selectedPhotoID, a)
        XCTAssertTrue(r.controller.canUndo)
        r.controller.undo()
        XCTAssertEqual(r.controller.draft, initial)
    }

    // AC 23,26; Given: 변경 초안과 동기 saver callback; When: 저장 callback 안에서 다시 저장; Then: 저장잠금이 보이고 중첩저장 차단, 외부저장만 성공.
    // 깨짐 명명: isSaving을 saver 호출 뒤 설정하거나 callback 재진입 save를 허용해 saver를 두 번 호출.
    func testSynchronousSaverCallbackObservesSavingLockAndBlocksReentrantSave() {
        let r = rig()
        let editedColor = CardColor(red: 0.9, green: 0.8, blue: 0.7)
        let expected = CardStyle(background: editedColor, photos: [])
        r.controller.setBackground(editedColor)
        var callbackCount = 0
        var observedIsSaving: Bool?
        var nestedSaveResult: Bool?
        var callsDuringCallback: Int?
        r.saver.onSave = { [weak controller = r.controller, weak saver = r.saver] in
            guard let controller, let saver else { return }
            callbackCount += 1
            observedIsSaving = controller.isSaving
            saver.onSave = nil
            nestedSaveResult = controller.save()
            callsDuringCallback = saver.calls.count
        }

        XCTAssertTrue(r.controller.save())
        r.saver.onSave = nil

        XCTAssertEqual(callbackCount, 1)
        XCTAssertEqual(observedIsSaving, true)
        XCTAssertEqual(nestedSaveResult, false)
        XCTAssertEqual(callsDuringCallback, 1)
        XCTAssertEqual(r.saver.calls.count, 1)
        XCTAssertEqual(r.saver.calls.first?.cardID, "FM-01234567")
        XCTAssertEqual(r.saver.calls.first?.style, expected)
        XCTAssertEqual(r.controller.draft, expected)
        XCTAssertTrue(r.controller.didSave)
        XCTAssertFalse(r.controller.isSaving)
        XCTAssertFalse(r.controller.hasChanges)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertNil(r.controller.notice)
    }

    // AC 26; Given: 저장 실패한 변경; When: 재시도 성공 후 새 변경과 버리기; Then: 성공 안내상태 historyclear 새 baseline 유지.
    // 깨짐 명명: 성공 baseline갱신 또는 history/notice 초기화 누락.
    func testRetrySuccessUpdatesBaselineClearsHistoryAndNotice() {
        let r = rig()
        r.controller.setBackground(blue)
        r.saver.result = false
        XCTAssertFalse(r.controller.save())
        r.saver.result = true
        XCTAssertTrue(r.controller.save())
        XCTAssertTrue(r.controller.didSave)
        XCTAssertNil(r.controller.notice)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertFalse(r.controller.hasChanges)
        XCTAssertEqual(r.controller.requestExit(), .dismiss)
        r.controller.setBackground(CardColor(red: 0.9, green: 0.8, blue: 0.7))
        r.controller.discard()
        XCTAssertEqual(r.controller.draft.background, blue)
        XCTAssertEqual(r.saver.calls.count, 2)
    }

    // AC 04,16; Given: 기존 사진 선택; When: select(nil); Then: 선택 해제만 발생하고 초안/history 유지.
    // 깨짐 명명: nil 선택을 무시하거나 선택 해제에 history 생성.
    func testDeselectClearsOnlySelection() {
        let initial = style([photo(a)])
        let r = rig(initial)
        r.controller.selectPhoto(a)
        XCTAssertEqual(r.controller.selectedPhotoID, a)
        r.controller.selectPhoto(nil)
        XCTAssertNil(r.controller.selectedPhotoID)
        XCTAssertEqual(r.controller.draft, initial)
        XCTAssertFalse(r.controller.canUndo)
        XCTAssertTrue(r.saver.calls.isEmpty)
    }
}
