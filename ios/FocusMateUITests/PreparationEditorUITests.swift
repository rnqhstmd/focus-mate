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
        XCTAssertTrue(h.element("screen.board").waitForExistence(timeout: timeout))
        XCTAssertEqual(try preparation(h)["task"] as? String, String(repeating: "a", count: 80))
        h.app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(h.element("screen.preparation").waitForExistence(timeout: timeout))
        replaceText(h.element("preparation.task"), in: h.app, with: "  책 읽기  ")
        tap(h.element("preparation.confirm"), in: h.app)
        XCTAssertTrue(h.element("screen.board").waitForExistence(timeout: timeout))
        let payload = try preparation(h)
        XCTAssertEqual(payload["task"] as? String, "책 읽기")
        XCTAssertEqual(payload["sound"] as? String, "bus")
        let journey = try XCTUnwrap(payload["journey"] as? [String: Any])
        XCTAssertEqual(journey["minutes"] as? Int, 60); XCTAssertEqual(journey["busID"] as? String, "2014-r")
        XCTAssertEqual(journey["busNumber"] as? String, "2014")
        XCTAssertEqual(journey["destination"] as? String, "성수동"); XCTAssertEqual(journey["stops"] as? Int, 12)
        let tag = try XCTUnwrap(payload["tag"] as? [String: Any])
        XCTAssertEqual(tag["id"] as? String, "reading"); XCTAssertEqual(tag["name"] as? String, "독서")
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
        h.app.buttons["open.preparation"].tap()
        h.app.setJourneyMinutes(60, timeout: timeout)
        tap(h.element("time.candidate.2014-r"), in: h.app); tap(h.element("time.proceed"), in: h.app)
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
