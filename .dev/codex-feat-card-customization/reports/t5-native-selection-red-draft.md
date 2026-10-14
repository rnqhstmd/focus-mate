# T5 native drag/resize selection RED and tap compatibility

Status: **PARENT ASSERTION RED VERIFIED / COMPATIBILITY GUARDS APPENDED / READY FOR GREEN**

Only test13 was inserted before the existing helper section. Removing its exact inserted bytes reconstructs the complete previous file byte-for-byte, so all 12 preexisting methods, setup, helpers, and declarations are unchanged.

Before insertion SHA256: `61798b5d49842296d38d63fcd0d9055e83f5e28cb64601d6dd7866341e1840db`.
After insertion SHA256: `4e28cf3e5e1e09bbd893580b4ec2eb3c37c46095e2cd652b358c4d2fee73ef45`.

Case: `FocusMateUITests/CardCustomizationFlowTests/test13_실제드래그와_크기조절후에도_선택사진을_유지한다`.

The test imports actual valid2 images, selects landscape A and moves it to the front, physically reaches the preview, then uses a native .1s press/drag by (+24,+12). Immediately after the gesture it records JSON/frames/screenshot and asserts A stays selected, its center moves positively, width/data/dimensions remain, B remains unchanged, and persisted/saved appearance remains unchanged. It then computes the selected image lower-right handle from public preview and photo metadata, verifies the 44pt handle and (+20,0) endpoint fit in the canvas, and physically drags it. The same observations precede the immediate selection assertion and checks of growing width, fixed center/data/ratio, untouched B, order, background and persisted state. No fake setters or harness flags were added.

The four observation stages are before-drag, after-drag, before-resize, after-resize. They retain actual compact style JSON, selected ID, preview/body/save frames, gesture endpoints and screenshot. Existing fail-fast means a selection failure after drag intentionally prevents a misleading resize attempt with no selected handle; after-drag evidence still identifies that phase.

This author performed no compile/test/device/build/Git action for this case. Production source was not read or changed. Parent execution of the unchanged failing prefix is documented below; the appended compatibility tail has not yet compiled or executed.

Planned command once granted (runtime UUID intentionally pending):

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate -destination 'platform=iOS Simulator,id=<PARENT-GRANTED-UUID>' -derivedDataPath .build/ios -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO -collect-test-diagnostics never '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test13_실제드래그와_크기조절후에도_선택사진을_유지한다'
```

Oracle limits: native gestures are best effort, so displacement is directional rather than an exact coordinate oracle. This case covers the selected landscape image and in-canvas handle path; it is not all pointer, off-canvas, multitouch or accessibility paths. The parent-provided observed clear after combined drag/resize remains reported evidence, not this test's executed result.

## Directly read parent execution evidence

DEV `t5-parent-native-selection-red.log` compiled the test and records **exit65 / 1 test / 1 assertion failure / 0 unexpected**, 58.550 seconds. At t44.16 the after-drag attachment reports selected A `34AFC10D-4EB4-46DD-AC55-85779DA5712F`; drag-preservation assertions then passed. At t52.45 the after-resize attachment reports `selectedID=nil`. The only failure is original line405: `Actual photo resize must preserve selection`, nil versus A. This independently locates selection loss after the real handle resize. No earlier assertion failed. The post-resize width/data assertions occur after this fail-fast point and were not executed, so they are not claimed passing.

Only a compatibility tail was appended after every existing test13 assertion. The entire original test13 prefix remains byte-identical, so the same failing resize-selection assertion remains the genuine RED. The added tail is not claimed compiled or executed: once the resize fix allows reaching it, it must prove an actual empty (.95,.9) canvas tap clears selection and an actual overlapping-center tap selects topmost A, with draft/saved/persisted state unchanged. Geometry checks prove the empty point lies outside both photos and the overlap point lies inside both. Two additional retained observation stages identify these tap results.

Baseline manifest entry count: 20. The only changed manifest path is `ios/FocusMateUITests/CardCustomizationFlowTests.swift`; all other locked paths match. Parent should regenerate the expected UI hash before executor dispatch. Removing the complete current test13 still reconstructs original 12 methods/helpers/setup source with SHA256 `61798b5d49842296d38d63fcd0d9055e83f5e28cb64601d6dd7866341e1840db`.

Current UI SHA256: `815e2b05d59ab4a05c9a807de1a62080916700b33170a0ae6202c0469f405fd2`.
Current UI Git-blob SHA1: `ec280e0cfab403991e3f97ae2b02c99efe46d9c0`.

## Exact added compatibility bytes

```swift

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
```

## Full current appended test13

```swift
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

```
