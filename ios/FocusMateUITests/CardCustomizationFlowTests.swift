import Foundation
import XCTest

@MainActor
final class CardCustomizationFlowTests: XCTestCase {
    private let timeout: TimeInterval = 8
    private let prefix = "cardCustomization."

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func test01_저장_정체성을_유지해_열고_변경없이_닫는다() throws {
        // 깨짐 명명: 진입/무변경 종료가 재발급 또는 파일 쓰기를 수행한다.
        let h = launch()
        let snapshot = try h.snapshot()
        let bytes = try h.diagnostic("test.persistedBytes")
        try open(h)
        let state = try style(h)
        XCTAssertEqual(state.cardID, try card(snapshot)["id"] as? String)
        XCTAssertEqual(state.saved, state.draft)
        XCTAssertEqual(state.draft?.photos.count, 0)
        XCTAssertFalse(state.canUndo)
        XCTAssertTrue(control(h, "save").isEnabled)
        for color in ["standard", "slate", "blue", "mauve", "sand", "ivory"] {
            XCTAssertTrue(control(h, "color." + color).exists)
        }
        for tool in ["x", "y", "width", "forward", "backward", "delete"] {
            let element = control(h, tool)
            XCTAssertTrue(!element.exists || !element.isEnabled)
        }
        capture(h, "basic")
        try tap(h, "close")
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        XCTAssertFalse(control(h, "discard").exists)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
        XCTAssertEqual(try canonical(h.snapshot()), try canonical(snapshot))
    }

    func test02_색변경과_기본복원은_저장없이_각각_되돌릴수있다() throws {
        // 깨짐 명명: 색/복원을 즉시 저장하거나 복원을 undo 이력에서 빠뜨린다.
        let h = launch(); try open(h)
        let baseline = try style(h)
        let bytes = try h.diagnostic("test.persistedBytes")
        try tap(h, "color.sand")
        let colored = try style(h)
        XCTAssertNotEqual(colored.draft?.background, baseline.draft?.background)
        XCTAssertEqual(colored.saved, baseline.saved)
        try tap(h, "undo")
        XCTAssertEqual(try style(h).draft, baseline.draft)
        try tap(h, "color.blue")
        let blue = try style(h).draft
        try tap(h, "restoreDefault")
        XCTAssertEqual(try style(h).draft, baseline.draft)
        try tap(h, "undo")
        XCTAssertEqual(try style(h).draft, blue)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
    }

    func test03_명시적_종료에서_계속은_초안유지_버리기는_파일유지() throws {
        // 깨짐 명명: 계속이 초안을 초기화하거나 버리기가 미저장 초안을 쓴다.
        let h = launch(); try open(h)
        let baseline = try style(h).draft
        let bytes = try h.diagnostic("test.persistedBytes")
        try tap(h, "color.mauve")
        let changed = try style(h)
        try tap(h, "close")
        try confirmation(h)
        capture(h, "confirmation")
        try tapConfirmation(h, "continueEditing", label: "계속 편집")
        XCTAssertEqual(try style(h).draft, changed.draft)
        XCTAssertEqual(try style(h).canUndo, changed.canUndo)
        try tap(h, "close"); try confirmation(h)
        try tapConfirmation(h, "discard", label: "변경 버리기")
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
        try open(h)
        XCTAssertEqual(try style(h).draft, baseline)
    }

    func test04_실제_두사진을_순서대로_추가해_선택사진만_편집한다() throws {
        // 깨짐 명명: 입력 순서를 뒤집거나 선택 아닌 사진에 위치/크기/삭제를 적용한다.
        let h = launch(manifest: "valid2"); try open(h); try importFixture(h, count: 2)
        let imported = try style(h)
        let photos = try XCTUnwrap(imported.draft).photos
        try assertValid2(photos)
        for photo in photos {
            XCTAssertEqual(photo.centerX, 0.5)
            XCTAssertEqual(photo.centerY, 0.5)
            XCTAssertEqual(photo.widthFraction, 0.6) // Policy literal: initial width 60%.
        }
        XCTAssertEqual(imported.selectedPhotoID, photos[1].id)
        XCTAssertEqual(imported.saved.photos.count, 0)
        try tap(h, "color.sand")
        capture(h, "photo2selected")
        try select(h, photos[0].id)
        XCTAssertEqual(try style(h).selectedPhotoID, photos[0].id)
        try step(h, axis: "x", increase: true)
        try step(h, axis: "y", increase: false)
        let width = h.app.sliders[helperID("width")]
        try reach(width, h)
        width.adjust(toNormalizedSliderPosition: 0.5)
        let moved = try XCTUnwrap(try style(h).draft).photos
        XCTAssertEqual(moved[0].centerX, 0.55, accuracy: 0.0001)
        XCTAssertEqual(moved[0].centerY, 0.45, accuracy: 0.0001)
        // XCTest's native slider gesture is best effort; verify the user's resize outcome.
        XCTAssertTrue(moved[0].widthFraction.isFinite)
        XCTAssertTrue((0.15...2.5).contains(moved[0].widthFraction))
        XCTAssertGreaterThan(moved[0].widthFraction, photos[0].widthFraction)
        XCTAssertLessThan(moved[0].widthFraction, 2.5)
        XCTAssertEqual(moved[0].pixelWidth, 120)
        XCTAssertEqual(moved[0].pixelHeight, 80)
        XCTAssertEqual(moved[1], photos[1])
        try tap(h, "forward")
        XCTAssertEqual(try style(h).draft?.photos.map(\.id), [photos[1].id, photos[0].id])
        try tap(h, "delete")
        XCTAssertEqual(try style(h).draft?.photos.map(\.id), [photos[1].id])
        try tap(h, "undo")
        XCTAssertEqual(try style(h).draft?.photos.map(\.id), [photos[1].id, photos[0].id])
        try tap(h, "undo")
        XCTAssertEqual(try style(h).draft?.photos, moved)
    }

    func test05_카드밖_사진은_색과_저장탭을_가로채지_않고_목록에서_복귀한다() throws {
        // 깨짐 명명: 카드 밖 interaction layer가 아래 색/저장 탭을 가로챈다.
        let h = launch(manifest: "valid2"); try open(h); try importFixture(h, count: 2)
        let id = try XCTUnwrap(try style(h).selectedPhotoID)
        // Portrait + maximum width deliberately spans the controls beneath preview.
        let slider = h.app.sliders[helperID("width")]; try reach(slider, h)
        slider.adjust(toNormalizedSliderPosition: 1)
        for _ in 0..<30 { try step(h, axis: "y", increase: true) }
        do {
            let selectedID = try style(h).selectedPhotoID ?? "nil"
            let observation = XCTAttachment(string: "selectedID=\(selectedID)\nbody=\(control(h, "body").frame)\npreview=\(control(h, "preview").frame)\nyIncrease=\(control(h, "y").buttons[helperID("y.increase")].frame)\ncardStyleJSON=\(try h.diagnostic("test.cardStyleJSON"))")
            observation.name = "T5 test05 after-y-loop before-preview-scroll"
            observation.lifetime = .keepAlways; add(observation)
            print("T5 test05 after-y-loop selectedID=\(selectedID)")
        }
        let preview = control(h, "preview")
        let body = control(h, "body")
        for _ in 0..<10 {
            if preview.exists && h.app.frame.contains(preview.frame) { break }
            try scrollBody(body, contentUp: false)
        }
        do {
            let selectedID = try style(h).selectedPhotoID ?? "nil"
            let observation = XCTAttachment(string: "selectedID=\(selectedID)\nbody=\(body.frame)\npreview=\(preview.frame)\nyIncrease=\(control(h, "y").buttons[helperID("y.increase")].frame)\ncardStyleJSON=\(try h.diagnostic("test.cardStyleJSON"))")
            observation.name = "T5 test05 after-preview-scroll before-sand"
            observation.lifetime = .keepAlways; add(observation)
            print("T5 test05 after-preview-scroll selectedID=\(selectedID)")
        }
        XCTAssertTrue(h.app.frame.contains(preview.frame), "Hit-test setup must keep preview onscreen")
        let beforeColor = try style(h)
        let sand = control(h, "color.sand")
        XCTAssertTrue(sand.isHittable)
        sand.tap() // No intervening scroll that would remove the overlapping preview.
        do {
            let selectedID = try style(h).selectedPhotoID ?? "nil"
            let observation = XCTAttachment(string: "selectedID=\(selectedID)\nbody=\(body.frame)\npreview=\(preview.frame)\nyIncrease=\(control(h, "y").buttons[helperID("y.increase")].frame)\ncardStyleJSON=\(try h.diagnostic("test.cardStyleJSON"))")
            observation.name = "T5 test05 after-sand before-save"
            observation.lifetime = .keepAlways; add(observation)
            print("T5 test05 after-sand selectedID=\(selectedID)")
        }

        XCTAssertNotEqual(try style(h).draft?.background, beforeColor.draft?.background)
        let save = control(h, "save")
        XCTAssertTrue(save.isHittable)
        let expectedSaved = try XCTUnwrap(try style(h).draft)
        save.tap() // Keep the hit-test arrangement while tapping fixed footer.

        let closed = try successfulSave(h, expected: expectedSaved)
        XCTAssertEqual(closed.saved.photos.first { $0.id == id }?.centerY, 2)
        // Move fully off card at normal width, then reselect by generated ID in list.
        try open(h)
        try select(h, id)
        let reopenedSlider = h.app.sliders[helperID("width")]
        try reach(reopenedSlider, h)
        reopenedSlider.adjust(toNormalizedSliderPosition: 0.19148936) // 60% in 15...250% range.
        let undoBeforeSelection = try style(h).canUndo
        let other = try XCTUnwrap(try style(h).draft?.photos.first { $0.id != id }?.id)
        try select(h, other); try select(h, id)
        XCTAssertEqual(try style(h).canUndo, undoBeforeSelection)
        for _ in 0..<30 { try step(h, axis: "y", increase: false) }
        XCTAssertEqual(try XCTUnwrap(try style(h).draft?.photos.first { $0.id == id }).centerY,
                       0.5, accuracy: 0.0001)
    }

    func test06_수동입력중_초안조작은_잠기고_닫기와_명시적해제는_가능하다() throws {
        // 깨짐 명명: import 중 색/undo/save가 활성화되거나 close도 잠긴다.
        let h = launch(manifest: "hold", extra: ["--fm-ui-card-import-hold", "manual"])
        try open(h); try tap(h, "color.slate")
        let before = try style(h).draft
        try fixtureButton(h)
        try waitState(h) { $0.isImporting }
        for name in ["color.sand", "photoPicker", "undo", "restoreDefault", "save"] {
            XCTAssertFalse(control(h, name).isEnabled, name)
        }
        XCTAssertTrue(control(h, "close").isEnabled)
        try tap(h, "close"); try confirmation(h)
        try tapConfirmation(h, "continueEditing", label: "계속 편집")
        XCTAssertTrue(try style(h).isImporting)
        XCTAssertEqual(try style(h).draft, before)
        try release(h)
        try waitState(h) { !$0.isImporting && $0.draft?.photos.count == 1 }
        XCTAssertTrue(control(h, "save").isEnabled)
        XCTAssertTrue(control(h, "undo").isEnabled)
    }

    func test07_입력중_버린_실제gate는_재진입에_사진을_적용하지않는다() throws {
        // 깨짐 명명: discard/cancel 뒤 이전 task가 새 세션에 사진을 반영한다.
        let h = launch(manifest: "hold", extra: ["--fm-ui-card-import-hold", "manual"])
        try open(h)
        let baseline = try style(h).draft
        let bytes = try h.diagnostic("test.persistedBytes")
        try fixtureButton(h); try waitState(h) { $0.isImporting }
        try tap(h, "close"); try confirmation(h)
        try tapConfirmation(h, "discard", label: "변경 버리기")
        XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        try open(h)
        XCTAssertEqual(try style(h).draft, baseline)
        // A new batch must arm again; release its real gate, not an artificial ignore-cancel loader.
        try fixtureButton(h); try waitState(h) { $0.isImporting }; try release(h)
        try waitState(h) { !$0.isImporting && $0.draft?.photos.count == 1 }
        try tap(h, "undo")
        XCTAssertEqual(try style(h).draft, baseline)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
        // This is cancellation UI coverage, not unit proof of cancellation-ignoring late success.
    }

    func test08_먼저실패한_입력은_자리를_먹지않고_성공만_추가한다() throws {
        // 깨짐 명명: 실패가 남은 자리를 소비하거나 성공 사진도 버린다.
        let h = launch(manifest: "mixed"); try open(h)
        let bytes = try h.diagnostic("test.persistedBytes")
        try importFixture(h, count: 1)
        let photo = try XCTUnwrap(try style(h).draft?.photos.first)
        XCTAssertEqual(photo.pixelWidth, 120); XCTAssertEqual(photo.pixelHeight, 80)
        try notice(h); capture(h, "import-error")
        XCTAssertTrue(control(h, "save").isEnabled)
        XCTAssertTrue(control(h, "undo").isEnabled)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
    }

    func test09_정상7장_선택은_앞6장만_추가하고_한도를_안내한다() throws {
        // 깨짐 명명: 7장을 추가하거나 입력 뒤쪽 사진을 앞쪽 대신 추가한다.
        let h = launch(manifest: "seven"); try open(h); try importFixture(h, count: 6)
        let photos = try XCTUnwrap(try style(h).draft).photos
        XCTAssertEqual(photos.map(\.pixelWidth), [101, 102, 103, 104, 105, 106])
        XCTAssertEqual(photos.map(\.pixelHeight), [80, 80, 80, 80, 80, 80])
        try notice(h)
        XCTAssertTrue(control(h, "notice").label.contains("6") ||
                      (control(h, "notice").value as? String)?.contains("6") == true)
        XCTAssertFalse(control(h, "photoPicker").isEnabled)
        try tap(h, "undo")
        XCTAssertEqual(try style(h).draft?.photos.count, 0)
    }

    func test10_경로이탈과_없는파일은_초안과_파일을_보존한다() throws {
        // 깨짐 명명: ../escape를 읽거나 모두 실패한 batch가 history를 만든다.
        let h = launch(manifest: "invalidPaths"); try open(h)
        let baseline = try style(h)
        let bytes = try h.diagnostic("test.persistedBytes")
        try fixtureButton(h)
        try notice(h); try waitState(h) { !$0.isImporting }
        XCTAssertEqual(try style(h).draft, baseline.draft)
        XCTAssertEqual(try style(h).canUndo, baseline.canUndo)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
    }

    func test11_실제쓰기_한번실패는_초안과원본보존_재시도후_같은UUID로복원() throws {
        // 깨짐 명명: write failure가 파일을 바꾸거나 retry/relaunch가 사진 bytes/배치를 잃는다.
        let h = launch(manifest: "valid2", extra: ["--fm-ui-card-save", "fail-once"])
        let originalSnapshot = try h.snapshot()
        let bytes = try h.diagnostic("test.persistedBytes")
        try open(h); try importFixture(h, count: 2); try tap(h, "color.sand")
        let before = try style(h)
        try tap(h, "save"); try notice(h); capture(h, "save-error")
        let failed = try style(h)
        XCTAssertFalse(failed.didSave)
        XCTAssertEqual(failed.draft, before.draft)
        XCTAssertEqual(failed.selectedPhotoID, before.selectedPhotoID)
        XCTAssertEqual(failed.canUndo, before.canUndo)
        XCTAssertEqual(failed.saved, before.saved)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), bytes)
        XCTAssertTrue(control(h, "save").isEnabled)
        let expectedSaved = try XCTUnwrap(before.draft)
        try tap(h, "save")
        let saved = try successfulSave(h, expected: expectedSaved).saved
        XCTAssertNotEqual(try h.diagnostic("test.persistedBytes"), bytes)
        let updated = try h.snapshot()
        XCTAssertEqual(try card(updated)["id"] as? String, try card(originalSnapshot)["id"] as? String)
        XCTAssertEqual(try card(updated)["issuedAt"] as? String,
                       try card(originalSnapshot)["issuedAt"] as? String)
        for section in ["currentStation", "initialStation", "journey", "records"] {
            XCTAssertEqual(try canonical(updated[section]), try canonical(originalSnapshot[section]))
        }
        h.relaunch() // same random UUID; seed and fail-once OMITTED by existing harness.
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        try open(h)
        XCTAssertEqual(try style(h).saved, saved)
        XCTAssertEqual(try style(h).draft, saved)
        try assertValid2(saved.photos) // decoded metadata + SHA preserved, not fake image Data.
    }

    func test12_XXXL에서_도구와복원이_고정저장위로_도달한다() throws {
        // 깨짐 명명: 고정 footer가 스크롤 본문을 덮어 도구에 도달할 수 없다.
        let h = launch(manifest: "valid2", extra: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        try open(h)
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        capture(h, "XXXL-basic-start")
        let save = control(h, "save")
        XCTAssertTrue(save.isHittable)
        try reach(control(h, "restoreDefault"), h, above: save)
        capture(h, "XXXL-basic-end")
        try importFixture(h, count: 2)
        let body = control(h, "body")
        try scrollBody(body, contentUp: false); try scrollBody(body, contentUp: false)
        capture(h, "XXXL-photo-start")
        for name in ["x", "y", "width", "forward", "backward", "delete", "restoreDefault"] {
            try reach(control(h, name), h, above: save)
        }
        capture(h, "XXXL-photo-end")
        XCTAssertTrue(save.isHittable)
        let expectedSaved = try XCTUnwrap(try style(h).draft)
        try tap(h, "save")
        _ = try successfulSave(h, expected: expectedSaved)
        try open(h)
        XCTAssertEqual(try style(h).draft, expectedSaved)
        let reopenedSave = control(h, "save")
        try reach(control(h, "restoreDefault"), h, above: reopenedSave)
        XCTAssertTrue(reopenedSave.isHittable)
    }

    func test13_실제드래그와_크기조절후에도_선택사진을_유지한다() throws {
        // 깨짐 명명: 실제 사진 drag/resize 종료가 선택을 해제하거나 다른 사진/저장 외형을 바꾼다.
        let h = launch(manifest: "valid2")
        try open(h); try importFixture(h, count: 2)
        let initial = try style(h)
        let photos = try XCTUnwrap(initial.draft).photos
        try assertValid2(photos)
        let original = photos[0]
        let other = photos[1]
        let persisted = try h.diagnostic("test.persistedBytes")
        try select(h, original.id); try tap(h, "forward")
        XCTAssertEqual(try style(h).draft?.photos.map(\.id), [other.id, original.id])
        let preview = control(h, "preview")
        try reach(preview, h)

        func observe(_ stage: String, start: CGPoint, end: CGPoint) throws {
            let state = try style(h)
            let attachment = XCTAttachment(string:
                "selectedID=\(state.selectedPhotoID ?? "nil")\npreview=\(preview.frame)\nbody=\(control(h, "body").frame)\nsave=\(control(h, "save").frame)\nstart=\(start)\nend=\(end)\ncardStyleJSON=\(try h.diagnostic("test.cardStyleJSON"))")
            attachment.name = "T5 test13 " + stage
            attachment.lifetime = .keepAlways; add(attachment)
            print("T5 test13 \(stage) selectedID=\(state.selectedPhotoID ?? "nil")")
            capture(h, "test13 " + stage)
        }

        let initialFrame = preview.frame
        let dragStartPoint = CGPoint(x: initialFrame.minX + original.centerX * initialFrame.width,
                                     y: initialFrame.minY + original.centerY * initialFrame.height)
        let dragEndPoint = CGPoint(x: dragStartPoint.x + 24, y: dragStartPoint.y + 12)
        XCTAssertTrue(initialFrame.contains(dragStartPoint))
        XCTAssertTrue(initialFrame.contains(dragEndPoint))
        XCTAssertEqual(try style(h).selectedPhotoID, original.id)
        try observe("before-drag", start: dragStartPoint, end: dragEndPoint)
        let dragStart = preview.coordinate(withNormalizedOffset:
            CGVector(dx: original.centerX, dy: original.centerY))
        dragStart.press(forDuration: 0.1, thenDragTo: dragStart.withOffset(CGVector(dx: 24, dy: 12)))
        try observe("after-drag", start: dragStartPoint, end: dragEndPoint)
        let dragged = try style(h)
        XCTAssertEqual(dragged.selectedPhotoID, original.id, "Actual photo drag must preserve selection")
        let draggedPhotos = try XCTUnwrap(dragged.draft).photos
        let draggedPhoto = try XCTUnwrap(draggedPhotos.first { $0.id == original.id })
        XCTAssertGreaterThan(draggedPhoto.centerX, original.centerX)
        XCTAssertGreaterThan(draggedPhoto.centerY, original.centerY)
        XCTAssertEqual(draggedPhoto.widthFraction, original.widthFraction)
        XCTAssertEqual(draggedPhoto.pixelWidth, original.pixelWidth)
        XCTAssertEqual(draggedPhoto.pixelHeight, original.pixelHeight)
        XCTAssertEqual(draggedPhoto.byteCount, original.byteCount)
        XCTAssertEqual(draggedPhoto.sha256, original.sha256)
        XCTAssertEqual(draggedPhotos.first { $0.id == other.id }, other)
        XCTAssertEqual(dragged.saved, initial.saved)
        XCTAssertEqual(dragged.draft?.background, initial.draft?.background)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), persisted)

        let frame = preview.frame
        let photoWidth = frame.width * draggedPhoto.widthFraction
        let photoHeight = photoWidth * Double(draggedPhoto.pixelHeight) / Double(draggedPhoto.pixelWidth)
        let handlePoint = CGPoint(x: frame.minX + draggedPhoto.centerX * frame.width + photoWidth / 2,
                                  y: frame.minY + draggedPhoto.centerY * frame.height + photoHeight / 2)
        let resizeEndPoint = CGPoint(x: handlePoint.x + 20, y: handlePoint.y)
        XCTAssertTrue(frame.contains(CGRect(x: handlePoint.x - 22, y: handlePoint.y - 22,
                                           width: 44, height: 44)), "The real 44pt handle must fit inside the canvas")
        XCTAssertTrue(frame.contains(CGRect(x: resizeEndPoint.x - 22, y: resizeEndPoint.y - 22,
                                           width: 44, height: 44)), "Resize must remain inside the canvas")
        try observe("before-resize", start: handlePoint, end: resizeEndPoint)
        let handle = preview.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: handlePoint.x - frame.minX, dy: handlePoint.y - frame.minY))
        handle.press(forDuration: 0.1, thenDragTo: handle.withOffset(CGVector(dx: 20, dy: 0)))
        try observe("after-resize", start: handlePoint, end: resizeEndPoint)
        let resized = try style(h)
        XCTAssertEqual(resized.selectedPhotoID, original.id, "Actual photo resize must preserve selection")
        let resizedPhotos = try XCTUnwrap(resized.draft).photos
        let resizedPhoto = try XCTUnwrap(resizedPhotos.first { $0.id == original.id })
        XCTAssertGreaterThan(resizedPhoto.widthFraction, draggedPhoto.widthFraction)
        XCTAssertEqual(resizedPhoto.centerX, draggedPhoto.centerX)
        XCTAssertEqual(resizedPhoto.centerY, draggedPhoto.centerY)
        XCTAssertEqual(resizedPhoto.pixelWidth, original.pixelWidth)
        XCTAssertEqual(resizedPhoto.pixelHeight, original.pixelHeight)
        XCTAssertEqual(resizedPhoto.byteCount, original.byteCount)
        XCTAssertEqual(resizedPhoto.sha256, original.sha256)
        XCTAssertEqual(resizedPhotos.first { $0.id == other.id }, other)
        XCTAssertEqual(resized.draft?.photos.map(\.id), [other.id, original.id])
        XCTAssertEqual(resized.draft?.background, initial.draft?.background)
        XCTAssertEqual(resized.saved, initial.saved)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), persisted)

        let currentFrame = preview.frame
        func photoRect(_ photo: Photo) -> CGRect {
            let width = currentFrame.width * photo.widthFraction
            let height = width * Double(photo.pixelHeight) / Double(photo.pixelWidth)
            return CGRect(x: currentFrame.minX + photo.centerX * currentFrame.width - width / 2,
                          y: currentFrame.minY + photo.centerY * currentFrame.height - height / 2,
                          width: width, height: height)
        }
        let emptyPoint = CGPoint(x: currentFrame.minX + currentFrame.width * 0.95,
                                 y: currentFrame.minY + currentFrame.height * 0.9)
        XCTAssertFalse(photoRect(resizedPhoto).contains(emptyPoint))
        XCTAssertFalse(photoRect(other).contains(emptyPoint))
        preview.coordinate(withNormalizedOffset: CGVector(dx: 0.95, dy: 0.9)).tap()
        try observe("after-empty-tap", start: emptyPoint, end: emptyPoint)
        let cleared = try style(h)
        XCTAssertNil(cleared.selectedPhotoID, "An actual empty canvas tap must still clear selection")
        XCTAssertEqual(cleared.draft, resized.draft)
        XCTAssertEqual(cleared.saved, resized.saved)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), persisted)

        let overlapPoint = CGPoint(x: currentFrame.minX + resizedPhoto.centerX * currentFrame.width,
                                   y: currentFrame.minY + resizedPhoto.centerY * currentFrame.height)
        XCTAssertTrue(photoRect(resizedPhoto).contains(overlapPoint))
        XCTAssertTrue(photoRect(other).contains(overlapPoint), "The tap must exercise overlapping photos")
        preview.coordinate(withNormalizedOffset:
            CGVector(dx: resizedPhoto.centerX, dy: resizedPhoto.centerY)).tap()
        try observe("after-topmost-tap", start: overlapPoint, end: overlapPoint)
        let reselected = try style(h)
        XCTAssertEqual(reselected.selectedPhotoID, original.id, "An actual overlap tap must select topmost A")
        XCTAssertEqual(reselected.draft, resized.draft)
        XCTAssertEqual(reselected.saved, resized.saved)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), persisted)
    }

    // MARK: Test-only helpers. No production setters, snapshots/golden assertions or style values.
    private func launch(manifest: String? = nil, extra: [String] = []) -> FocusMateUIHarness {
        var arguments = extra
        if let manifest {
            arguments += ["--fm-ui-card-photo-manifest", "FocusMate/UITestPhotoFixtures/" + manifest + ".json"]
        }
        return FocusMateUIHarness.launch(seed: "ready", extraArguments: arguments, testID: UUID())
    }
    private func helperID(_ suffix: String) -> String { prefix + suffix }
    private func control(_ h: FocusMateUIHarness, _ suffix: String) -> XCUIElement {
        h.element(helperID(suffix))
    }
    private func open(_ h: FocusMateUIHarness) throws {
        // 시안 R01: 메인에는 기록·마이페이지만 있다. 카드 꾸미기는 마이페이지에서 연다.
        let entry = h.element("profile.customize")
        if !entry.exists {
            let profile = h.element("open.profile")
            XCTAssertTrue(profile.waitForExistence(timeout: timeout))
            profile.tap()
            XCTAssertTrue(h.element("screen.profile").waitForExistence(timeout: timeout))
        }
        XCTAssertTrue(entry.waitForExistence(timeout: timeout))
        // 큰 글자에서는 버튼이 화면 아래로 밀린다. 마이페이지는 스크롤된다.
        var swipes = 0
        while (!entry.isHittable || entry.frame.maxY > h.app.frame.maxY - 120) && swipes < 4 { h.app.swipeUp(); swipes += 1 }
        entry.tap()
        XCTAssertTrue(h.element("screen.cardCustomization").waitForExistence(timeout: timeout))
    }
    private func tap(_ h: FocusMateUIHarness, _ suffix: String) throws {
        let target = control(h, suffix); try reach(target, h); XCTAssertTrue(target.isEnabled); target.tap()
    }
    private func reach(_ target: XCUIElement, _ h: FocusMateUIHarness, above: XCUIElement? = nil) throws {
        XCTAssertTrue(target.waitForExistence(timeout: timeout))
        let body = control(h, "body")
        XCTAssertTrue(body.waitForExistence(timeout: timeout), "Missing scroll body: " + helperID("body"))
        let footer = control(h, "save")
        func visibleBody() -> CGRect {
            let viewport = body.frame.intersection(h.app.frame)
            let bottom = min(viewport.maxY, above?.frame.minY ?? footer.frame.minY)
            return CGRect(x: viewport.minX, y: viewport.minY,
                          width: viewport.width, height: max(0, bottom - viewport.minY))
        }
        func reachable() -> Bool {
            let fixedIDs = [helperID("close"), helperID("undo"),
                            "test.cardImportFixture", "test.releaseCardImport"]
            let viewport: CGRect
            if target.identifier == helperID("save") {
                viewport = h.app.frame
            } else if fixedIDs.contains(target.identifier) {
                let appFrame = h.app.frame
                viewport = CGRect(x: appFrame.minX, y: appFrame.minY,
                                  width: appFrame.width, height: footer.frame.minY - appFrame.minY)
            } else {
                viewport = visibleBody()
            }
            return target.isHittable && viewport.contains(target.frame)
        }
        // 방향이 뒤집히면(지나침) 끄는 거리를 절반으로 줄인다 — 큰 글자에서 조작이 커 보이는 창이 좁으면 같은 거리로는 오가기만 한다.
        var span: CGFloat = 0.6
        var lastUp: Bool?
        for _ in 0..<12 {
            if reachable() { break }
            let lowerBound = visibleBody().minY
            let upperBound = visibleBody().maxY
            let up: Bool
            if target.frame.maxY > upperBound {
                up = true
            } else if target.frame.minY < lowerBound {
                up = false
            } else {
                up = target.frame.midY >= body.frame.midY
            }
            if let lastUp, lastUp != up { span = max(0.15, span / 2) }
            lastUp = up
            try scrollBody(body, contentUp: up, span: span)
        }
        XCTAssertTrue(reachable(), "본문/조작 도달 실패: " + target.identifier)
    }
    private func scrollBody(_ body: XCUIElement, contentUp: Bool, span: CGFloat = 0.6) throws {
        XCTAssertTrue(body.waitForExistence(timeout: timeout))
        // 본문 ScrollView 프레임은 고정 저장 버튼(safeAreaInset) 아래까지 이어진다. 큰 글자에서 저장 영역이 커지면
        // 본문 프레임 기준 80% 지점이 저장 영역 위에 떨어져 끌어도 스크롤되지 않으므로, 저장 위 보이는 본문 안에서만 끈다.
        let save = XCUIApplication().descendants(matching: .any)[helperID("save")]
        let bottom = save.exists ? min(body.frame.maxY, save.frame.minY) : body.frame.maxY
        let height = max(1, bottom - body.frame.minY)
        func point(_ fraction: CGFloat) -> XCUICoordinate {
            body.coordinate(withNormalizedOffset: .zero)
                .withOffset(CGVector(dx: body.frame.width * 0.02, dy: height * fraction))
        }
        let start = point(contentUp ? 0.5 + span / 2 : 0.5 - span / 2)
        let end = point(contentUp ? 0.5 - span / 2 : 0.5 + span / 2)
        start.press(forDuration: 0.01, thenDragTo: end)
    }
    private func confirmation(_ h: FocusMateUIHarness) throws {
        // Container ID can be absent for native dialog. Require the contracted actual buttons.
        XCTAssertTrue(confirmationButton(h, "continueEditing", label: "계속 편집")
            .waitForExistence(timeout: timeout))
        XCTAssertTrue(confirmationButton(h, "discard", label: "변경 버리기").exists)
    }
    private func confirmationButton(
        _ h: FocusMateUIHarness,
        _ suffix: String,
        label: String
    ) -> XCUIElement {
        let alert = h.app.alerts
            .matching(NSPredicate(format: "label == %@", "변경 내용을 버릴까요?"))
            .firstMatch
        let buttons = alert.buttons
            .matching(identifier: helperID(suffix))
            .matching(NSPredicate(format: "label == %@", label))
        return buttons.firstMatch
    }
    private func tapConfirmation(
        _ h: FocusMateUIHarness,
        _ suffix: String,
        label: String
    ) throws {
        let alert = h.app.alerts
            .matching(NSPredicate(format: "label == %@", "변경 내용을 버릴까요?"))
            .firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: timeout))
        let button = confirmationButton(h, suffix, label: label)
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        XCTAssertTrue(button.isEnabled)
        XCTAssertTrue(button.isHittable)
        button.tap()
    }
    private func fixtureButton(_ h: FocusMateUIHarness) throws {
        let button = h.element("test.cardImportFixture"); try reach(button, h); button.tap()
    }
    private func release(_ h: FocusMateUIHarness) throws {
        let button = h.element("test.releaseCardImport")
        XCTAssertTrue(button.waitForExistence(timeout: timeout)); XCTAssertTrue(button.isEnabled); button.tap()
    }
    private func importFixture(_ h: FocusMateUIHarness, count: Int) throws {
        try fixtureButton(h)
        try waitState(h) { !$0.isImporting && $0.draft?.photos.count == count }
    }
    private func select(_ h: FocusMateUIHarness, _ id: String) throws {
        try tap(h, "photo." + id)
    }
    private func step(_ h: FocusMateUIHarness, axis: String, increase: Bool) throws {
        let container = control(h, axis)
        let action = increase ? "increase" : "decrease"
        let label: String
        switch (axis, increase) {
        case ("x", false): label = "가로 위치 줄이기"
        case ("x", true): label = "가로 위치 늘리기"
        case ("y", false): label = "세로 위치 줄이기"
        case ("y", true): label = "세로 위치 늘리기"
        default: XCTFail("Unsupported axis: " + axis); return
        }
        let button = container.buttons[helperID(axis + "." + action)]
        try reach(button, h)
        XCTAssertTrue(button.waitForExistence(timeout: timeout))
        XCTAssertEqual(button.label, label)
        XCTAssertTrue(button.isEnabled)
        button.tap()
    }
    private func successfulSave(_ h: FocusMateUIHarness, expected: Style) throws -> StyleState {
        let editor = h.element("screen.cardCustomization")
        let main = h.element("screen.profile")
        let savedNotice = control(h, "savedNotice")
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            !editor.exists && main.exists && savedNotice.exists
        }, object: h.app)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
        XCTAssertEqual(savedNotice.label, "카드 외형을 저장했어요.")
        let closed = try style(h)
        XCTAssertEqual(closed.saved, expected)
        XCTAssertNil(closed.draft)
        XCTAssertNil(closed.selectedPhotoID)
        XCTAssertFalse(closed.didSave)
        XCTAssertFalse(closed.canUndo)
        return closed
    }
    private func notice(_ h: FocusMateUIHarness) throws {
        let n = control(h, "notice")
        XCTAssertTrue(n.waitForExistence(timeout: timeout))
        XCTAssertFalse((n.label + ((n.value as? String) ?? "")).isEmpty)
    }
    private func waitState(_ h: FocusMateUIHarness, _ predicate: @escaping (StyleState) -> Bool) throws {
        let expectation = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let value = try? self.style(h) else { return false }
            return predicate(value)
        }, object: h.app)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }
    private func capture(_ h: FocusMateUIHarness, _ name: String) {
        let attachment = XCTAttachment(screenshot: h.app.screenshot())
        attachment.name = "T5 " + name; attachment.lifetime = .keepAlways; add(attachment)
    }
    private func card(_ snapshot: [String: Any]) throws -> [String: Any] {
        let cards = try XCTUnwrap(snapshot["cards"] as? [String: Any])
        let items = try XCTUnwrap(cards["items"] as? [[String: Any]])
        XCTAssertEqual(items.count, 1)
        return try XCTUnwrap(items.first)
    }
    private func canonical(_ value: Any?) throws -> Data {
        try JSONSerialization.data(withJSONObject: value ?? NSNull(), options: [.sortedKeys, .fragmentsAllowed])
    }
    private func style(_ h: FocusMateUIHarness) throws -> StyleState {
        try JSONDecoder().decode(StyleState.self, from: Data(h.diagnostic("test.cardStyleJSON").utf8))
    }
    private func assertValid2(_ photos: [Photo]) throws {
        XCTAssertEqual(photos.count, 2)
        XCTAssertEqual(photos.map(\.pixelWidth), [120, 80])
        XCTAssertEqual(photos.map(\.pixelHeight), [80, 120])
        XCTAssertEqual(Set(photos.map(\.id)).count, 2)
        XCTAssertNotEqual(photos[0].sha256, photos[1].sha256)
        for photo in photos {
            XCTAssertTrue((1...1_048_576).contains(photo.byteCount))
            XCTAssertNotNil(photo.sha256.range(of: "^[a-fA-F0-9]{64}$", options: .regularExpression))
        }
    }
    private struct StyleState: Decodable {
        let cardID: String
        let background: Color
        let photos: [Photo]
        let draft: Style?
        let selectedPhotoID: String?
        let isImporting: Bool
        let canUndo: Bool
        let didSave: Bool
        var saved: Style { Style(background: background, photos: photos) }
    }
    private struct Color: Decodable, Equatable { let red: Double; let green: Double; let blue: Double }
    private struct Style: Decodable, Equatable { let background: Color; let photos: [Photo] }
    private struct Photo: Decodable, Equatable {
        let id: String
        let pixelWidth: Int
        let pixelHeight: Int
        let centerX: Double
        let centerY: Double
        let widthFraction: Double
        let byteCount: Int
        let sha256: String
    }
}
