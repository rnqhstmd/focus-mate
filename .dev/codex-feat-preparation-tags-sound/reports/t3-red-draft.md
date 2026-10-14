# T3 RED draft — DONE_WITH_CONCERNS

승격·실행 대기. 앱 테스트폴더 쓰기/프로덕션 Read·Grep·Write/실행 없음. 새 PreparationEditorUITests 12케이스와 PreparationFlowUITests 복제본의 placeholder 1케이스만 교체했다. 복제본의 교체 구간 이전/이후 원문 동일성은 Python 문자열 assert로 확인했다(테스트 실행 아님).

## Case AC mapping and name-the-break

- testAC1_InitialHubHasNoTagOrTaskAndBusSound
- testAC2_AC3_SelectingTagShowsEmptyTaskAndWhitespaceCannotConfirm
- testAC4_AC12_TaskLimitAndTrimmedPreparationRequestPreserveJourney
- testAC5_AC6_AC7_AC8_TagEditorDefaultsAndInvalidNamesKeepEditorOpen
- testAC9_NewTagPreservesTaskAndDeliversDevelopmentGreenDefinition
- testAC10_AC11_TagCancelAndTimeRoundTripKeepDraft
- testAC14_AC15_AC16_FiveSoundOptionsCancelAndSaveUseSeparateValues
- testAC19_NoneStaysSilentAndCanConfirm
- testAC20_AudioFailureStillAllowsSaveAndConfirm
- testAC17_AC18_AC22_RealPreviewStartStopAndDismissReopenStayStopped
- testAC24_AC25_MaximumTextHasNamedReachableControlsAndClosedEditorsDisappear
- testAC23_RelaunchClearsSessionDraftAndPreservesOriginalBytes

각 메서드 앞 깨짐 주석이 잘못된 초기값·태그/입력 guard·payload·시트 취소/저장·오디오 상태전이·원본저장 부작용·접근성 미노출·큰글자 도달성의 mutation을 명명한다.

- initial: AC1/24; selection/whitespace: AC2/3; 80단위 및 trimJSON: AC4/12/13.
- invalid editor: AC5/6/7/8 (공백, 독서 중복, 21단위 각각 표시); successful editor: AC9 (development/green/trim/기존task).
- cancel/time roundtrip: AC10/11; five options/cancel-save: AC14/15/16.
- none: AC19; injected factory fail: AC20; real preview start-stop-dismiss-reopen: AC17/18/22.
- maximum text/names/closed editors: AC24/25; session relaunch and byte equality: AC23.
- old factory stale result races/fade duration/loops/nooverlap는 T2 단위 gate 테스트, 이 UI 세트는 실제 wiring과 접근성 결과를 검증한다.

## Determinism and runner gate

FocusMateUIHarness ready seed→여행 준비→60분→2014→time.proceed 표준 진입. W02 JSON 예상값은 60/2014/2014/성수동/12 리터럴이다. XCTNSPredicateExpectation과 waitForExistence는 실제 조건을 기다리고 timeout만 실패 상한으로 사용. 고정 sleep/Task.yield/스타일·픽셀 assert 없음. 최대글자는 실제 시스템 인자와 test.dynamicTypeSize accessibility5로 확인. fake VoiceOver/reduceMotion flags 없음.

실패 확인 명령/메시지: 실행 금지로 미실행. 부모 승격 지시 후 focused 러너로 compile 및 행동 RED 확인 필요. PASS/RED 주장 없음. 실제 AV 재생 UI 테스트는 simulator audio 환경에서 실행해 확인해야 한다. text replacement는 기존 value 길이만큼 delete 후 입력하며, 실행 결과에 따라 iOS TextField 커서/placeholder 처리 보강이 필요할 수 있다.

실제 VoiceOver 포커스 복귀, 실제 시스템 동작 줄이기, 실기기 청취, 웹 시각 검토는 이 자동 세트로 완료 주장하지 않는다.

## All read references

- gx-dev/references/codex-roles/red-writer.md (같은 격리 역할의 이전 T2에서 읽음)
- gx-tdd/references/testing-anti-patterns.md (이전 T2에서 읽음)
- gx-tdd/references/frontend-testing.md (이번 T3)
- .dev/codex-feat-preparation-tags-sound/prd.md (이전 T2)
- .dev/codex-feat-preparation-tags-sound/design.md (이전 T2 및 이번 UI 테스트 환경 계약)
- ios/FocusMateUITests/PreparationFlowUITests.swift
- ios/FocusMateUITests/UITestLaunchSupport.swift
- ios/FocusMateUITests/LargeTextUITests.swift
- ios/FocusMateUITests/TimeSelectionUITests.swift
- 이번 두 UI 초안 (자체 수정/원문 보존 확인)

## Named scrolling containers

부모의 design 보강 계약: preparation.tags / tagEditor.fields. 가로 태그/+ 도달은 app.scrollViews["preparation.tags"].swipeLeft(), 편집 아이콘/색 도달은 app.scrollViews["tagEditor.fields"].swipeUp()로 실제 container를 조작한다. 구조 index fallback 없음. task TextField도 tap helper의 도달 경로를 사용한다.

## Independent ready fixture correction before promotion

부모가 전달한 검증 fixture metadata만 사용했다: ready seed의 currentStation은 seoulForest index 4, direction -1이고 route는 9정류장이다. 60분 bus2014의 12정류장 이동 결과 destination index 1인 성수동을 손으로 도출한 예상값으로 사용한다. 이전 Editor 테스트가 seongsu-forward fixture의 성동구민체육센터를 사용하던 오류를 수정했다. 기존 PreparationFlowUITests 복제본의 forward fixture 예상값은 변경하지 않았다. Editor의 confirm.label assert는 실제 1건뿐이므로 삭제할 중복이 없었다. 프로덕션 열람/테스트 실행 없음.

## Full test sources

### .dev/codex-feat-preparation-tags-sound/draft-tests/PreparationEditorUITests.swift

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

### .dev/codex-feat-preparation-tags-sound/draft-tests/PreparationFlowUITests.swift

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
