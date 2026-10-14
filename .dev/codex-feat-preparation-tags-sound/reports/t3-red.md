# T3 formal RED

Status: DONE — 테스트 승격 및 focused 행동 RED 확인 완료. 제품 GREEN 구현과 실제 화면 비교는 후속 단계.

## Scope / count

PreparationEditorUITests: 12 original case identities preserved. PreparationFlowUITests: 6 cases, 5 old flow regressions plus the replacement initial-hub behavior case. T3 focused planned total 85 = 67 existing units + 6 Flow + 12 Editor. No production source reads, searches, edits or implementation diffs. No source types are referenced; compile RED is unnecessary.

## Observable states and screenshot evidence

After behavioral assertions reach their state, XCTest keepAlways screenshot attachments retain: w03-preparation-empty, w03-preparation-filled (after confirm), w03-tag-editor (development/green/name verified before save), w03-sound-options, w03-sound-error, w03-preparation-largest (after confirm).

These are actual screen evidence for later comparison with approved design. No snapshot/style/pixel assertions were added. Attachments exist only if the verified states are reached during execution; this report does not claim the images exist or that visual comparison was completed.

Existing conditions, ready seed expected 60/bus2014/destination 성수동/12, and Flow's original forward fixture values are preserved. Only the promotion, six screenshot calls/helper, and selected editor metadata assertions before capture were added.

## Name the break

Each preserved case comment names the erroneous behavior it must reject: incorrect defaults, invalid input confirmation, missing payload, lost draft, unsaved sound changes, failure blocking preparation, unwanted automatic playback, session persistence, inaccessible controls. The initial-hub replacement must fail when the actual preparation UI is missing.

## Read references (all for this step)

- .dev/codex-feat-preparation-tags-sound/draft-tests/PreparationEditorUITests.swift
- .dev/codex-feat-preparation-tags-sound/draft-tests/PreparationFlowUITests.swift
- .dev/codex-feat-preparation-tags-sound/reports/t3-red-draft.md
- .dev/codex-feat-preparation-tags-sound/design.md (already read for isolated T2)
- .dev/codex-feat-preparation-tags-sound/prd.md (already read for isolated T2)
- gx-dev/references/codex-roles/red-writer.md (already read)
- gx-tdd/references/testing-anti-patterns.md (already read)

## Focused command and result

Started in background, session_id=75561. Log: `.dev/codex-feat-preparation-tags-sound/t3-red-behavior.log`. Completion and failure messages pending; parent may resume session to collect results. Expected existing 67 units + 5 old Flow pass, 12 Editor + modified initial Flow fail due missing actual UI. No executed RED result claimed yet.

```sh
FOCUSMATE_SIMULATOR_ID=88ABB031-C48A-4DA0-B15C-14787702E647 python3 scripts/check-ios.py test ios/FocusMateTests/PreparationDraftTests.swift ios/FocusMateTests/PreparationModelTests.swift ios/FocusMateTests/PreparationDetailsTests.swift ios/FocusMateTests/SoundPreviewControllerTests.swift ios/FocusMateTests/AudioResourceTests.swift ios/FocusMateUITests/PreparationFlowUITests.swift ios/FocusMateUITests/PreparationEditorUITests.swift > .dev/codex-feat-preparation-tags-sound/t3-red-behavior.log 2>&1
```

## Full test code

### ios/FocusMateUITests/PreparationEditorUITests.swift
```swift
import Foundation
import XCTest

@MainActor
final class PreparationEditorUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    override func setUp() { super.setUp(); continueAfterFailure = false }

    // 깨짐: 최초 준비가 태그를 자동 선택하거나 숨겨야 할 입력/활성 confirm을 노출한다.
    func testAC1_InitialHubHasNoTagOrTaskAndBusSound() throws {
        let h = try openPreparation()
        XCTAssertTrue(h.app.staticTexts["무엇을 할까요?"].exists)
        for id in ["reading", "study", "work", "rest"] { XCTAssertFalse(h.element("preparation.tag.\(id)").isSelected, id) }
        XCTAssertFalse(h.element("preparation.task").exists)
        XCTAssertFalse(h.element("preparation.confirm").isEnabled)
        XCTAssertEqual(try h.diagnostic("test.preparedPreparation"), "null")
        XCTAssertEqual(try stringValue(h.element("preparation.sound")), "버스")
        attachScreen(h.app, named: "w03-preparation-empty")
    }
    // 깨짐: 태그 선택이 할 일을 자동 입력하거나 공백 할 일을 확정한다.
    func testAC2_AC3_SelectingTagShowsEmptyTaskAndWhitespaceCannotConfirm() throws {
        let h = try openPreparation()
        tap(h.element("preparation.tag.reading"), in: h.app)
        XCTAssertTrue(h.element("preparation.tag.reading").isSelected)
        XCTAssertFalse(h.element("preparation.tag.study").isSelected)
        let field = h.element("preparation.task")
        XCTAssertTrue(field.waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("preparation.confirm").isEnabled)
        replaceText(field, in: h.app, with: "   ")
        XCTAssertFalse(h.element("preparation.confirm").isEnabled)
        XCTAssertEqual(try h.diagnostic("test.preparedPreparation"), "null")
        replaceText(field, in: h.app, with: "책 읽기")
        wait(h.element("preparation.confirm"), key: "enabled", equals: true)
    }
    // 깨짐: 81단위 입력을 허용하거나 전달 task trim/W02/태그/소리가 틀리거나 실제 여행을 만든다.
    func testAC4_AC12_TaskLimitAndTrimmedPreparationRequestPreserveJourney() throws {
        let h = try openPreparation(); try selectTask(h, text: String(repeating: "a", count: 81))
        wait(h.element("preparation.task"), key: "value", equals: String(repeating: "a", count: 80))
        tap(h.element("preparation.confirm"), in: h.app)
        XCTAssertEqual(try preparation(h)["task"] as? String, String(repeating: "a", count: 80))
        replaceText(h.element("preparation.task"), in: h.app, with: "  책 읽기  ")
        tap(h.element("preparation.confirm"), in: h.app)
        let payload = try preparation(h)
        XCTAssertEqual(payload["task"] as? String, "책 읽기")
        XCTAssertEqual(payload["sound"] as? String, "bus")
        let journey = try XCTUnwrap(payload["journey"] as? [String: Any])
        XCTAssertEqual(journey["minutes"] as? Int, 60); XCTAssertEqual(journey["busID"] as? String, "2014")
        XCTAssertEqual(journey["busNumber"] as? String, "2014")
        XCTAssertEqual(journey["destination"] as? String, "성수동"); XCTAssertEqual(journey["stops"] as? Int, 12)
        let tag = try XCTUnwrap(payload["tag"] as? [String: Any])
        XCTAssertEqual(tag["id"] as? String, "reading"); XCTAssertEqual(tag["name"] as? String, "독서")
        XCTAssertTrue(h.element("screen.preparation").exists)
        let snapshotJourney = try XCTUnwrap(try h.snapshot()["journey"] as? [String: Any])
        XCTAssertTrue(snapshotJourney["active"] is NSNull)
        attachScreen(h.app, named: "w03-preparation-filled")
    }
    // 깨짐: 빈/중복/21단위 이름이 저장되거나 오류인데 시트가 닫힌다.
    func testAC5_AC6_AC7_AC8_TagEditorDefaultsAndInvalidNamesKeepEditorOpen() throws {
        let h = try openPreparation(); tap(h.element("preparation.addTag"), in: h.app)
        let name = h.element("tagEditor.name")
        XCTAssertTrue(name.waitForExistence(timeout: timeout))
        XCTAssertTrue(h.element("tagEditor.icon.reading").isSelected)
        XCTAssertTrue(h.element("tagEditor.color.sand").isSelected)
        for invalid in ["   ", "독서", String(repeating: "x", count: 21)] {
            replaceText(name, in: h.app, with: invalid); tap(h.element("tagEditor.save"), in: h.app)
            XCTAssertTrue(h.element("tagEditor.error").waitForExistence(timeout: timeout), invalid)
            XCTAssertTrue(name.exists, invalid)
            XCTAssertFalse(h.element("preparation.task").exists, invalid)
        }
        tap(h.element("tagEditor.cancel"), in: h.app)
        wait(name, key: "exists", equals: false)
        XCTAssertFalse(h.element("preparation.task").exists)
    }
    // 깨짐: 유효 태그 저장이 추가/선택하지 않거나 아이콘/색/이름/할 일을 잃는다.
    func testAC9_NewTagPreservesTaskAndDeliversDevelopmentGreenDefinition() throws {
        let h = try openPreparation(); try selectTask(h, text: "구현하기")
        tap(h.element("preparation.addTag"), in: h.app)
        replaceText(h.element("tagEditor.name"), in: h.app, with: "  개발 시간  ")
        tap(h.element("tagEditor.icon.development"), in: h.app)
        tap(h.element("tagEditor.color.green"), in: h.app)
        XCTAssertEqual(try stringValue(h.element("tagEditor.name")), "  개발 시간  ")
        XCTAssertTrue(h.element("tagEditor.icon.development").isSelected)
        XCTAssertTrue(h.element("tagEditor.color.green").isSelected)
        attachScreen(h.app, named: "w03-tag-editor")
        tap(h.element("tagEditor.save"), in: h.app)
        wait(h.element("tagEditor.name"), key: "exists", equals: false)
        XCTAssertEqual(try stringValue(h.element("preparation.task")), "구현하기")
        let newTag = h.app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "preparation.tag.", "개발 시간")).firstMatch
        XCTAssertTrue(newTag.exists); XCTAssertTrue(newTag.isSelected)
        tap(h.element("preparation.confirm"), in: h.app)
        let tag = try XCTUnwrap(try preparation(h)["tag"] as? [String: Any])
        XCTAssertEqual(tag["name"] as? String, "개발 시간"); XCTAssertEqual(tag["icon"] as? String, "development")
        XCTAssertEqual(tag["color"] as? String, "green")
    }
    // 깨짐: 태그 취소가 추가/선택/할 일을 바꾸거나 시간 왕복이 초안을 reset한다.
    func testAC10_AC11_TagCancelAndTimeRoundTripKeepDraft() throws {
        let h = try openPreparation(); try selectTask(h, text: "유지할 일")
        let before = try h.diagnostic("test.journeySelection")
        let tags = h.app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "preparation.tag.")).count
        tap(h.element("preparation.addTag"), in: h.app)
        replaceText(h.element("tagEditor.name"), in: h.app, with: "버릴 태그")
        tap(h.element("tagEditor.cancel"), in: h.app)
        wait(h.element("tagEditor.name"), key: "exists", equals: false)
        XCTAssertEqual(h.app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "preparation.tag.")).count, tags)
        XCTAssertTrue(h.element("preparation.tag.reading").isSelected)
        h.app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        tap(h.element("time.proceed"), in: h.app)
        XCTAssertTrue(h.element("screen.preparation").waitForExistence(timeout: timeout))
        XCTAssertEqual(try stringValue(h.element("preparation.task")), "유지할 일")
        XCTAssertTrue(h.element("preparation.tag.reading").isSelected)
        XCTAssertEqual(try stringValue(h.element("preparation.sound")), "버스")
        XCTAssertEqual(try h.diagnostic("test.journeySelection"), before)
    }
    // 깨짐: 소리 선택만으로 재생하거나 취소가 확정값을 변경하거나 저장이 전달되지 않는다.
    func testAC14_AC15_AC16_FiveSoundOptionsCancelAndSaveUseSeparateValues() throws {
        let h = try openPreparation(); try selectTask(h, text: "읽기")
        tap(h.element("preparation.sound"), in: h.app)
        let titles = ["bus": "버스", "rainBus": "비 오는 버스", "subway": "지하철", "forest": "숲속", "none": "소리 없음"]
        for (id, title) in titles {
            let option = h.element("sound.option.\(id)")
            XCTAssertTrue(option.exists, id); XCTAssertEqual(option.label, title, id)
        }
        XCTAssertTrue(h.element("sound.option.bus").isSelected)
        XCTAssertEqual(h.element("sound.preview").label, "선택한 소리 미리 듣기")
        attachScreen(h.app, named: "w03-sound-options")
        tap(h.element("sound.option.forest"), in: h.app)
        waitPreview(h, phase: "stopped")
        tap(h.element("sound.cancel"), in: h.app)
        wait(h.element("sound.save"), key: "exists", equals: false)
        XCTAssertEqual(try stringValue(h.element("preparation.sound")), "버스")
        XCTAssertEqual(try stringValue(h.element("preparation.task")), "읽기")
        tap(h.element("preparation.sound"), in: h.app)
        tap(h.element("sound.option.rainBus"), in: h.app)
        XCTAssertEqual(h.element("sound.save").label, "소리 저장")
        tap(h.element("sound.save"), in: h.app)
        wait(h.element("sound.preview"), key: "exists", equals: false)
        XCTAssertEqual(try stringValue(h.element("preparation.sound")), "비 오는 버스")
        tap(h.element("preparation.confirm"), in: h.app)
        XCTAssertEqual(try preparation(h)["sound"] as? String, "rainBus")
    }
    // 깨짐: none 미리듣기가 loading/playing으로 전이하거나 none이 준비 완료를 막는다.
    func testAC19_NoneStaysSilentAndCanConfirm() throws {
        let h = try openPreparation(); try selectTask(h, text: "조용히 읽기")
        tap(h.element("preparation.sound"), in: h.app); tap(h.element("sound.option.none"), in: h.app)
        let preview = h.element("sound.preview")
        if preview.isEnabled { tap(preview, in: h.app) }
        waitPreview(h, phase: "stopped")
        XCTAssertEqual(try soundState(h)["selectedSound"] as? String, "none")
        tap(h.element("sound.save"), in: h.app)
        XCTAssertEqual(try stringValue(h.element("preparation.sound")), "소리 없음")
        tap(h.element("preparation.confirm"), in: h.app)
        XCTAssertEqual(try preparation(h)["sound"] as? String, "none")
    }
    // 깨짐: 오디오 실패가 안내/무음/선택유지를 제공하지 않거나 저장/준비를 막는다.
    func testAC20_AudioFailureStillAllowsSaveAndConfirm() throws {
        let h = try openPreparation(extra: ["--fm-ui-sound", "fail"]); try selectTask(h, text: "오류에도 읽기")
        tap(h.element("preparation.sound"), in: h.app); tap(h.element("sound.option.subway"), in: h.app)
        tap(h.element("sound.preview"), in: h.app)
        XCTAssertTrue(h.element("sound.error").waitForExistence(timeout: timeout))
        waitPreview(h, phase: "stopped")
        XCTAssertTrue(h.element("sound.option.subway").isSelected)
        XCTAssertFalse(h.element("sound.error").label.isEmpty)
        XCTAssertTrue(h.element("sound.save").isEnabled)
        attachScreen(h.app, named: "w03-sound-error")
        tap(h.element("sound.save"), in: h.app)
        wait(h.element("sound.error"), key: "exists", equals: false)
        tap(h.element("preparation.confirm"), in: h.app)
        XCTAssertEqual(try preparation(h)["sound"] as? String, "subway")
    }
    // 깨짐: 실제 preview 토글/시트 dismiss가 stop하지 않거나 재열기가 자동 재생한다.
    func testAC17_AC18_AC22_RealPreviewStartStopAndDismissReopenStayStopped() throws {
        let h = try openPreparation(); tap(h.element("preparation.sound"), in: h.app)
        tap(h.element("sound.preview"), in: h.app); waitPreview(h, phase: "playing")
        XCTAssertEqual(h.element("sound.preview").label, "미리 듣기 중지")
        XCTAssertEqual(try stringValue(h.element("sound.preview")), "playing")
        tap(h.element("sound.preview"), in: h.app); waitPreview(h, phase: "stopped")
        tap(h.element("sound.preview"), in: h.app); waitPreview(h, phase: "playing")
        tap(h.element("sound.cancel"), in: h.app)
        wait(h.element("sound.preview"), key: "exists", equals: false); waitPreview(h, phase: "stopped")
        tap(h.element("preparation.sound"), in: h.app); waitPreview(h, phase: "stopped")
        XCTAssertEqual(h.element("sound.preview").label, "선택한 소리 미리 듣기")
        XCTAssertEqual(try stringValue(h.element("sound.preview")), "stopped")
    }
    // 깨짐: 실제 최대 글자 설정을 반영하지 않거나 마지막태그/+·입력·소리저장·confirm에 닿지 못한다.
    func testAC24_AC25_MaximumTextHasNamedReachableControlsAndClosedEditorsDisappear() throws {
        let h = try openPreparation(extra: ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"])
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        XCTAssertFalse(h.element("preparation.task").exists)
        let rest = h.element("preparation.tag.rest"); tap(rest, in: h.app)
        XCTAssertEqual(rest.label, "휴식"); XCTAssertTrue(rest.isSelected)
        tap(h.element("preparation.addTag"), in: h.app)
        XCTAssertFalse(h.element("tagEditor.name").label.isEmpty)
        tap(h.element("tagEditor.cancel"), in: h.app)
        wait(h.element("tagEditor.name"), key: "exists", equals: false)
        let field = h.element("preparation.task")
        XCTAssertEqual(field.label, "할 일 한 줄"); replaceText(field, in: h.app, with: "쉬기")
        tap(h.element("preparation.sound"), in: h.app)
        tap(h.element("sound.option.forest"), in: h.app); tap(h.element("sound.save"), in: h.app)
        wait(h.element("sound.save"), key: "exists", equals: false)
        XCTAssertFalse(h.element("sound.option.forest").exists)
        let confirm = h.element("preparation.confirm")
        XCTAssertEqual(confirm.label, "승차권 보기"); XCTAssertTrue(confirm.isEnabled)
        tap(confirm, in: h.app); XCTAssertEqual(try preparation(h)["task"] as? String, "쉬기")
        attachScreen(h.app, named: "w03-preparation-largest")
    }
    // 깨짐: W03 편집/확정이 저장 bytes를 바꾸거나 세션 초안/추가태그를 재실행에 복원한다.
    func testAC23_RelaunchClearsSessionDraftAndPreservesOriginalBytes() throws {
        let h = try openPreparation(); let original = try h.diagnostic("test.persistedBytes")
        try selectTask(h, text: "세션 할 일")
        tap(h.element("preparation.addTag"), in: h.app)
        replaceText(h.element("tagEditor.name"), in: h.app, with: "세션 태그")
        tap(h.element("tagEditor.save"), in: h.app); wait(h.element("tagEditor.name"), key: "exists", equals: false)
        tap(h.element("preparation.sound"), in: h.app); tap(h.element("sound.option.forest"), in: h.app)
        tap(h.element("sound.save"), in: h.app); tap(h.element("preparation.confirm"), in: h.app)
        _ = try preparation(h)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), original)
        h.relaunch(); try enterPreparation(h)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), original)
        XCTAssertFalse(h.element("preparation.task").exists)
        XCTAssertFalse(h.element("preparation.tag.reading").isSelected)
        XCTAssertEqual(h.app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "preparation.tag.")).count, 4)
        XCTAssertEqual(try stringValue(h.element("preparation.sound")), "버스")
        XCTAssertEqual(try h.diagnostic("test.preparedPreparation"), "null")
    }

    private func attachScreen(_ app: XCUIApplication, named name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func openPreparation(extra: [String] = []) throws -> FocusMateUIHarness {
        let h = FocusMateUIHarness.launch(seed: "ready", extraArguments: extra)
        try enterPreparation(h); return h
    }
    private func enterPreparation(_ h: FocusMateUIHarness) throws {
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        h.app.buttons["여행 준비"].tap()
        let wheel = h.app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: timeout)); wheel.adjust(toPickerWheelValue: "60분")
        tap(h.element("time.candidate.2014"), in: h.app); tap(h.element("time.proceed"), in: h.app)
        XCTAssertTrue(h.element("screen.preparation").waitForExistence(timeout: timeout))
    }
    private func selectTask(_ h: FocusMateUIHarness, text: String) throws {
        tap(h.element("preparation.tag.reading"), in: h.app)
        replaceText(h.element("preparation.task"), in: h.app, with: text)
    }
    private func tap(_ target: XCUIElement, in app: XCUIApplication) {
        XCTAssertTrue(target.waitForExistence(timeout: timeout), target.identifier)
        var attempts = 0
        while !target.isHittable && attempts < 6 {
            if target.identifier.hasPrefix("preparation.tag.") || target.identifier == "preparation.addTag" {
                let tags = app.scrollViews["preparation.tags"]
                XCTAssertTrue(tags.waitForExistence(timeout: timeout)); tags.swipeLeft()
            } else if target.identifier.hasPrefix("tagEditor.icon.") || target.identifier.hasPrefix("tagEditor.color.") {
                let fields = app.scrollViews["tagEditor.fields"]
                XCTAssertTrue(fields.waitForExistence(timeout: timeout)); fields.swipeUp()
            } else { app.swipeUp() }
            attempts += 1
        }
        XCTAssertTrue(target.isHittable, "스크롤해도 닿지 않음: \(target.identifier)"); target.tap()
    }
    private func replaceText(_ field: XCUIElement, in app: XCUIApplication, with text: String) {
        tap(field, in: app)
        let old = field.value as? String ?? ""
        // 빈 TextField의 value가 placeholder인 경우 실제 입력을 지우지 않아도 delete는 무해하다.
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count) + text)
    }
    private func stringValue(_ element: XCUIElement) throws -> String {
        XCTAssertTrue(element.waitForExistence(timeout: timeout)); return try XCTUnwrap(element.value as? String)
    }
    private func wait(_ element: XCUIElement, key: String, equals value: Any) {
        let condition = XCTNSPredicateExpectation(predicate: NSPredicate { object, _ in
            guard let observed = object as? XCUIElement else { return false }
            switch key {
            case "enabled": return observed.isEnabled == (value as? Bool)
            case "exists": return observed.exists == (value as? Bool)
            case "value": return observed.value as? String == value as? String
            default: return false
            }
        }, object: element)
        XCTAssertEqual(XCTWaiter.wait(for: [condition], timeout: timeout), .completed, "\(element.identifier).\(key)")
    }
    private func object(_ raw: String) throws -> [String: Any] {
        let data = try XCTUnwrap(raw.data(using: .utf8)); return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
    private func preparation(_ h: FocusMateUIHarness) throws -> [String: Any] {
        let condition = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let raw = h.element("test.preparedPreparation").value as? String,
                  let data = raw.data(using: .utf8) else { return false }
            return (try? JSONSerialization.jsonObject(with: data)) is [String: Any]
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [condition], timeout: timeout), .completed)
        return try object(h.diagnostic("test.preparedPreparation"))
    }
    private func soundState(_ h: FocusMateUIHarness) throws -> [String: Any] { try object(h.diagnostic("test.soundPreview")) }
    private func waitPreview(_ h: FocusMateUIHarness, phase: String) {
        let condition = XCTNSPredicateExpectation(predicate: NSPredicate { _, _ in
            guard let raw = h.element("test.soundPreview").value as? String,
                  let data = raw.data(using: .utf8),
                  let state = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return false }
            return state["phase"] as? String == phase
        }, object: nil)
        XCTAssertEqual(XCTWaiter.wait(for: [condition], timeout: timeout), .completed, "preview phase \(phase)")
    }
}
```

### ios/FocusMateUITests/PreparationFlowUITests.swift
```swift
import Foundation
import XCTest

@MainActor
final class PreparationFlowUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testProceedingWithSelectedBusOpensPreparationWithSelectionAndNoActiveJourney() throws {
        let app = launchCardOnly()
        try openTimeScreenFromSearch(in: app)
        try selectSixtyMinutesBus2014(in: app)

        element("time.proceed", in: app).tap()

        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))
        let selection = try journeySelection(in: app)
        XCTAssertEqual(selection["minutes"] as? Int, 60)
        XCTAssertEqual(selection["busID"] as? String, "2014")
        XCTAssertEqual(selection["busNumber"] as? String, "2014")
        XCTAssertEqual(selection["destination"] as? String, "성동구민체육센터")
        XCTAssertEqual(selection["stops"] as? Int, 12)
        let snapshot = try snapshot(in: app)
        let journey = try XCTUnwrap(snapshot["journey"] as? [String: Any])
        XCTAssertTrue(journey["active"] is NSNull)
    }

    // 깨짐: 준비 허브가 초기 태그/할 일을 자동 선택하거나 confirm을 활성화한다.
    func testPreparationHubInitiallyHasNoSelectedTagHiddenTaskAndDisabledConfirm() throws {
        let app = launchCardOnly()
        try openTimeScreenFromSearch(in: app)
        try selectSixtyMinutesBus2014(in: app)
        element("time.proceed", in: app).tap()
        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["무엇을 할까요?"].exists)
        for id in ["reading", "study", "work", "rest"] {
            XCTAssertFalse(element("preparation.tag.\(id)", in: app).isSelected, id)
        }
        XCTAssertFalse(element("preparation.task", in: app).exists)
        XCTAssertFalse(element("preparation.confirm", in: app).isEnabled)
    }

    func testRapidDoubleTapOnProceedPushesPreparationOnlyOnce() throws {
        let app = launchCardOnly()
        try openTimeScreenFromSearch(in: app)
        try selectSixtyMinutesBus2014(in: app)

        let proceed = element("time.proceed", in: app)
        proceed.tap()
        if proceed.exists && proceed.isHittable {
            proceed.tap()
        }
        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
    }

    func testReturningFromPreparationKeepsSelectionAndItSurvivesLeavingToMainInSameRun() throws {
        let app = launchReady()
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        app.buttons["여행 준비"].tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.origin", in: app), "서울숲")
        try selectSixtyMinutesBus2014(in: app)
        element("time.proceed", in: app).tap()
        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))

        app.navigationBars.buttons.firstMatch.tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.minutesLabel", in: app), "60")
        XCTAssertTrue(element("time.candidate.2014", in: app).isSelected)

        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        app.buttons["여행 준비"].tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.minutesLabel", in: app), "60")
        XCTAssertTrue(element("time.candidate.2014", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("time.candidate.2014", in: app).isSelected)
    }

    func testRelaunchAfterSavingStationOpensMainAndNeverShowsSearchAgain() throws {
        let testID = UUID()
        let app = XCUIApplication()
        launch(app, testID: testID, seed: "cardOnly")
        try openTimeScreenFromSearch(in: app)

        app.terminate()
        launch(app, testID: testID, seed: nil)

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        XCTAssertFalse(element("screen.initialStationEntry", in: app).exists)
        XCTAssertEqual(searchElements(in: app).count, 0)

        let destinations = [
            (button: "기록", screen: "screen.records"),
            (button: "설정", screen: "screen.settings"),
            (button: "마이페이지", screen: "screen.profile"),
            (button: "여행 준비", screen: "screen.time"),
        ]
        for destination in destinations {
            app.buttons[destination.button].tap()
            XCTAssertTrue(element(destination.screen, in: app).waitForExistence(timeout: timeout))
            XCTAssertFalse(element("screen.initialStationEntry", in: app).exists)
            XCTAssertEqual(searchElements(in: app).count, 0)
            app.navigationBars.buttons.firstMatch.tap()
            XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
            XCTAssertFalse(element("screen.initialStationEntry", in: app).exists)
            XCTAssertEqual(searchElements(in: app).count, 0)
        }
    }

    func testSelectionIsNotPersistedAcrossRelaunchAndStoredBytesStayUnchanged() throws {
        let testID = UUID()
        let app = XCUIApplication()
        launch(app, testID: testID, seed: "cardOnly")
        try openTimeScreenFromSearch(in: app)
        let bytesAfterStationSave = try diagnosticValue("test.persistedBytes", in: app)
        try selectSixtyMinutesBus2014(in: app)
        element("time.proceed", in: app).tap()
        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))

        app.terminate()
        launch(app, testID: testID, seed: nil)

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        app.buttons["여행 준비"].tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.minutesLabel", in: app), "25")
        let selected = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@ AND selected == true", "time.candidate.")
        )
        XCTAssertEqual(selected.count, 0)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), bytesAfterStationSave)
    }

    // MARK: - Helpers

    private func launchCardOnly() -> XCUIApplication {
        let app = XCUIApplication()
        launch(app, testID: UUID(), seed: "cardOnly")
        return app
    }

    private func launchReady() -> XCUIApplication {
        let app = XCUIApplication()
        launch(app, testID: UUID(), seed: "ready")
        return app
    }

    private func launch(_ app: XCUIApplication, testID: UUID, seed: String?) {
        var arguments = ["--fm-ui-test-id", testID.uuidString]
        if let seed {
            arguments += ["--fm-ui-seed", seed]
        }
        app.launchArguments = arguments
        app.launch()
    }

    private func openTimeScreenFromSearch(in app: XCUIApplication) throws {
        let origin = element("search.result.seongsu:1", in: app)
        XCTAssertTrue(origin.waitForExistence(timeout: timeout))
        origin.tap()
        element("search.confirm", in: app).tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
    }

    private func selectSixtyMinutesBus2014(in app: XCUIApplication) throws {
        let wheel = app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: timeout), "분 휠이 없음")
        wheel.adjust(toPickerWheelValue: "60분")
        XCTAssertEqual(try value("time.minutesLabel", in: app), "60")
        let candidate = element("time.candidate.2014", in: app)
        XCTAssertTrue(candidate.waitForExistence(timeout: timeout))
        candidate.tap()
        XCTAssertTrue(candidate.isSelected)
    }

    private func searchElements(in app: XCUIApplication) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", "search."))
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func diagnosticValue(_ identifier: String, in app: XCUIApplication) throws -> String {
        let diagnostic = element(identifier, in: app)
        XCTAssertTrue(diagnostic.waitForExistence(timeout: timeout), "Missing diagnostic: \(identifier)")
        return try XCTUnwrap(diagnostic.value as? String, "Diagnostic has no string value: \(identifier)")
    }

    private func value(_ identifier: String, in app: XCUIApplication) throws -> String {
        let observed = element(identifier, in: app)
        XCTAssertTrue(observed.waitForExistence(timeout: timeout), "Missing value element: \(identifier)")
        return try XCTUnwrap(observed.value as? String, "Element has no string value: \(identifier)")
    }

    private func snapshot(in app: XCUIApplication) throws -> [String: Any] {
        try parseObject(try diagnosticValue("test.snapshot", in: app))
    }

    private func journeySelection(in app: XCUIApplication) throws -> [String: Any] {
        try parseObject(try diagnosticValue("test.journeySelection", in: app))
    }

    private func parseObject(_ raw: String) throws -> [String: Any] {
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
```

## 실제 focused RED 결과 (2026-10-14)

원래 session75561의 종료를 직접 확인했다. 종료 코드 **65**. 새 명령 재실행 없음.

| Suite | 실제 실행 | 실패 | 통과 |
| --- | ---: | ---: | ---: |
| AudioResourceTests | 3 | 0 | 3 |
| PreparationDetailsTests | 1 | 0 | 1 |
| PreparationDraftTests | 20 | 0 | 20 |
| PreparationModelTests | 21 | 0 | 21 |
| SoundPreviewControllerTests | 22 | 0 | 22 |
| PreparationEditorUITests | 12 | 12 | 0 |
| PreparationFlowUITests | 6 | 1 | 5 |
| 합계 | **85** | **13** | **72** |

로그는 unit67/0fail, UI18/13fail을 각 selected tests 묶음으로 기록한다. 신규 Editor12개와 수정한 Flow 초기허브1개가 실패하고 기존 Flow5개는 통과했다. build/compile 오류가 아니라 실제 UI 행동 RED다.

대표 실패 메시지:

```text
PreparationEditorUITests.swift:12: error: testAC1_InitialHubHasNoTagOrTaskAndBusSound : XCTAssertTrue failed
PreparationEditorUITests.swift:251: error: testAC9_NewTagPreservesTaskAndDeliversDevelopmentGreenDefinition : Failed to get matching snapshot: No matches found for Elements matching predicate '"preparation.tag.reading" IN identifiers'
PreparationEditorUITests.swift:251: error: testAC5_AC6_AC7_AC8_TagEditorDefaultsAndInvalidNamesKeepEditorOpen : Failed to get matching snapshot: No matches found for Elements matching predicate '"preparation.addTag" IN identifiers'
PreparationFlowUITests.swift:39: error: testPreparationHubInitiallyHasNoSelectedTagHiddenTaskAndDisabledConfirm : XCTAssertTrue failed
Executed 18 tests, with 13 failures (0 unexpected)
** TEST FAILED **
```

기대 제목/태그/소리 컨트롤이 실제 UI에 없어 실패했다. 일부 Editor 실패는 명시적 XCTAssert 문구 대신 XCUIElement snapshot 조회 실패 형태로 기록됐다. 고정 sleep/yield 또는 스타일 비교 실패가 아니다.

원본 실행 로그: `.dev/codex-feat-preparation-tags-sound/t3-red-behavior.log`.
xcresult: `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_11-42-57-+0900.xcresult`.

Editor12개 모두 screenshot 호출 이전 UI 검증에서 실패하여 지정한 6개 검증 상태의 첨부 생성 지점에 도달하지 못했다. XCTest의 일반 실패 화면과 지정한 keepAlways 상태 첨부를 구분한다. 이번 RED로 승인 디자인과 실제 화면의 시각 비교 완료를 주장하지 않는다.

추가로 참조한 파일: 실행 로그 `.dev/codex-feat-preparation-tags-sound/t3-red-behavior.log`와 결과를 기록하기 위한 본 보고서. 제품 코드 읽기/검색/수정 없음.
