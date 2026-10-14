# Legacy VoiceOver 추가 시험 계획

Status: DONE_WITH_CONCERNS — 작성 완료, 빌드·런·실제 VoiceOver 검증 미확인.

W10 GREEN과 독립된 HEAD `5b7af0f` 복사 프로젝트용 시험이다. HEAD/복사 동등성은 이 작성 작업에서 재검증하지 않았다. 제품 기능 RED가 아니므로 실제 시험 PASS를 허용하며, 실패를 만들기 위한 제품 변경은 없다. 기존 파일 수정, 제품 소스 열람, commit/push, agent 호출, xcodebuild 및 UI 시험 실행은 하지 않았다.

## 실행 조건과 판정

부모 실행 담당자가 복사 프로젝트의 `LegacyVoiceOverProbeTests` 네 케이스만 iOS 27 Simulator `F226C28A-81D5-4708-B939-81B605AC748E`에서 실행한다. iOS 27 availability를 클래스에 명시했고 skip은 없다. 전용 기기 지정·실제 runner 연결은 부모 책임이며 다른 런타임 결과를 이 검증으로 대체하지 않는다.

`XCUIDevice.shared.voiceOverService` enable/isEnabled/currentSpeech/moveForward/moveBackward/disable을 사용한다. nonoptional Output.utterance 전체를 stage 이름과 함께 print와 keepAlways attachment로 남긴다. 빈 speech, API 오류, 목표 탐색/자동 포커스 시간 초과는 실패다. label과 DEBUG 진단은 실제 speech로 출력하지 않는다. 매 시험 reset, enable 후 defer disable, tearDown 재해제로 안전 해제를 시도한다. 해제 오류도 실패로 남긴다.

수동 탐색은 호출당 moveForward 최대 50회. 자동 전환 포커스 검증은 currentSpeech만 최대 8초 poll하며 탐색으로 포커스를 이동시키지 않는다. 역할 suffix와 새로운 영문 장식 이름은 추측하지 않는다. focus 목표를 actual speech에서 찾은 후 대상 element.doubleTap으로 두 번 탭 gesture를 보낸다. 일반 tap은 W02의 VoiceOver 활성화 전 준비 단계에만 쓴다.

## AC 매핑과 관찰 근거 예정

| 시험 | 매핑 | 실제 관찰과 실패 조건 |
|---|---|---|
| W01 발급 | 기존 발급 AC-19M 접근성·완료 포커스 | none seed → actual `집중동행카드 발급받기` focus → doubleTap → continueButton 존재 → 탐색 없이 actual `출발지 선택하기` 포커스. 전·후방 각각 최대 50회 speech 탐색에 카드 존재를 요구하고 독립 `IC`/`비접촉` utterance 노출을 거절. 카드 전체 label 반복 횟수는 중복 판단에 쓰지 않음. 출발지 이동/여정 준비는 실행하지 않음. |
| W02 1분 증가 | 시간 휠 실제 VoiceOver adjustable 동작 | cardOnly → 성수 정방향 결과/search.confirm → time 25분. 후보의 알려진 `2014`/`정류장` 문구를 제외하고 actual 25분 focus를 찾는다. wheel.swipeUp 1회 뒤 minutes 진단 26, wheel 값 26분, actual currentSpeech 26분을 모두 요구한다. gesture 환경 오류도 기대 1분 동작 FAIL이며 adjust 대체 없음. |
| W13 확인/취소 | W13 AC-4·BR-1 및 제목/안내 focus | corrupt 원본 base64 캡처 → cleanup actual focus/activation → 확인 제목/안내 actual 자동 focus → 취소 actual focus/doubleTap → 오류 제목/안내 actual 자동 focus. persistedBytes 정확히 동일, 백업 {} 및 첫 시작 미전환. |
| W13 backupFail | W13 AC-6 및 실패 focus | 기존 시험의 `--fm-ui-recovery backupFail` 재사용. actual cleanup·확인 제목/안내·확인 동작 focus·실패 안내 전문을 단계별로 보존. 실패 안내 actual 자동 focus, 원본 동일, 오류 화면 유지·첫 시작 미전환을 요구. |

## 추가 필요사항과 한계

- 빌드/런 증거, assertion 결과, 실제 speech 및 xcresult attachment는 부모 실행 이후에만 생긴다. 현재 결과는 검증 PASS가 아니다.
- 확인 제목/오류 제목은 기존 identifier가 staticText일 때 label을 탐색 목표 매핑에만 사용한다. 아니면 기존 테스트에 명시된 한국어 안내로 제한한다. 런에서 다른 제목으로 실제 포커스가 가는데 매핑이 부족하면 interface/context 보강을 보고해야 하며 임의 문구를 추가하지 않는다.
- VoiceOver wheel 25분과 후보의 25분을 구분할 때 기존 후보 문구만 제외한다. SDK service는 speech 기반이므로 런의 전문에서 wheel focus를 재확인한다.
- 장식 검사는 알려진 `IC`/`비접촉` 문구의 독립 노출을 검사하며 카드 전체 요소에 포함된 문구는 독립 요소로 오판하지 않는다. 새로운 영문 장식 낭독을 추측해 판정하지 않는다. 동일 speech 3회 연속이면 탐색 방향의 경계 후보로 종료한다. 실제 traversal이 전체 카드 영역을 포함했는지는 부모가 attachment를 확인해야 한다. API 경계 오류를 성공으로 삼키지 않는다.
- enable 또는 화면 전환 중 빈 currentSpeech가 반환되면 실패한다. 일반 XCUI label/announcer 문자열로 대체하지 않는다.
- 정적 parse를 실행하더라도 구문 증거일 뿐 SDK typecheck, build 또는 실제 런 증거가 아니다.

## 참조한 파일

- voiceover-probe/ios/FocusMateUITests/UITestLaunchSupport.swift
- voiceover-probe/ios/FocusMateUITests/CardIssuanceFlowTests.swift
- voiceover-probe/ios/FocusMateUITests/TimeSelectionUITests.swift
- voiceover-probe/ios/FocusMateUITests/StorageRecoveryFlowTests.swift
- reports/voiceover-api-notes.md (부모가 기록한 SDK 타입검사 exit 0; actual speech 증거 없음)
- .dev/codex-feat-card-customization/design.md
- /Users/bonseung/.codex/worktrees/2da6/new/.dev/codex-feat-storage-error-recovery/design.md
- .dev/codex-feat-card-customization/voiceover-sdk-probe.swift (제품 코드 아님)
- 설치 SDK XCUIAutomation.framework/Headers/{XCUIVoiceOverService,XCUIElement,XCUIDevice}.h
- /Users/bonseung/.codex/memories/MEMORY.md: W13 과거 검증에서 VoiceOver 별도 gate였다는 맥락만 확인. 실제 목표/판정 근거는 지정 설계·기존 시험·SDK다.
- /Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md: 사용자 지정 격리 범위 우선 확인.

## 작성 후 정적 확인

`swiftc -frontend -parse .dev/codex-feat-card-customization/voiceover-probe/ios/FocusMateUITests/LegacyVoiceOverProbeTests.swift` → exit 0, 출력 없음. 신규 파일의 구문만 확인했다. SDK 타입검사·앱 빌드·UI 런은 실행하지 않았다.

보고서 코드 전문과 신규 파일의 문자열 동일성, 시험 4개, XCTSkip 및 adjust 호출 없음도 확인했다. 이것은 런/동작 검증 증거가 아니다.

## 전체 신규 테스트 코드

```swift
import Foundation
import XCTest

@MainActor
@available(iOS 27.0, *)
final class LegacyVoiceOverProbeTests: XCTestCase {
    private let timeout: TimeInterval = 8
    private var service: XCUIVoiceOverService { XCUIDevice.shared.voiceOverService }

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    override func tearDown() {
        disableVoiceOver()
        super.tearDown()
    }

    func testW01IssuanceMovesActualFocusToContinueAndHidesIndependentDecorations() throws {
        // 깨짐 명명: 완료 포커스 이동 누락 또는 IC/비접촉 장식의 독립 접근성 노출.
        try resetVoiceOver()
        let h = FocusMateUIHarness.launch(seed: "none")
        XCTAssertTrue(h.element("card.issueButton").waitForExistence(timeout: timeout))
        try withVoiceOver {
            try findSpeech(containing: ["집중동행카드 발급받기"], stage: "W01.issue.focus")
            try activateFocused(h.element("card.issueButton"), containing: ["집중동행카드 발급받기"], stage: "W01.issue.activate")
            XCTAssertTrue(h.element("card.continueButton").waitForExistence(timeout: timeout))
            // 탐색으로 원하는 포커스를 만들어 내지 않는다. currentSpeech만 poll한다.
            try pollCurrentSpeech(containing: ["출발지 선택하기"], stage: "W01.completed.automaticFocus")
            let utterances = try scanBothDirections(stage: "W01.issued.navigation")
            XCTAssertTrue(utterances.contains { $0.contains("집중동행카드") }, "카드가 실제 탐색에 포함되어야 장식 비노출을 평가할 수 있다")
            let independentDecoration = utterances.filter {
                !$0.contains("집중동행카드") && ($0.contains("IC") || $0.contains("비접촉"))
            }
            XCTAssertTrue(independentDecoration.isEmpty, "독립 장식 actual speech: \(independentDecoration)")
            // 단일 카드 전체 요소의 반복 speech 횟수는 중복 카드로 판정하지 않는다.
            XCTAssertFalse(h.element("screen.initialStationEntry").exists)
        }
    }

    func testW02ActualVoiceOverAdjustableSwipeIncrementsTwentyFiveByOne() throws {
        // 깨짐 명명: 조절 가능 gesture 누락 또는 한 번의 증가가 1분이 아닌 경우.
        try resetVoiceOver()
        let h = FocusMateUIHarness.launch(seed: "cardOnly")
        let origin = h.element("search.result.seongsu:1")
        XCTAssertTrue(origin.waitForExistence(timeout: timeout))
        origin.tap() // VoiceOver를 켜기 전 기존 W02 진입 helper와 같은 준비 경로.
        h.element("search.confirm").tap()
        XCTAssertTrue(h.element("screen.time").waitForExistence(timeout: timeout))
        let wheel = h.app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: timeout))
        XCTAssertEqual(wheel.value as? String, "25분")
        XCTAssertEqual(try h.diagnostic("time.minutesLabel"), "25")
        try withVoiceOver {
            // 기존 후보 label에도 25분이 있으므로 알려진 후보 문구를 제외한다.
            try findSpeech(containing: ["25분"], excluding: ["2014", "정류장"], stage: "W02.wheel.focus25")
            try requireCurrentSpeech(containing: ["25분"], excluding: ["2014", "정류장"], stage: "W02.wheel.beforeSwipe")
            wheel.swipeUp() // 실제 VO adjustable gesture. adjust(toPickerWheelValue:) 대체 금지.
            let changed = XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "value == %@", "26"),
                object: h.element("time.minutesLabel")
            )
            let result = XCTWaiter.wait(for: [changed], timeout: timeout)
            _ = try currentSpeech(stage: "W02.wheel.afterSwipe.actualSpeech")
            XCTAssertEqual(result, .completed, "VO swipeUp 한 번의 기대 동작은 25→26분. gesture 환경 실패도 FAIL로 보존한다")
            XCTAssertEqual(try h.diagnostic("time.minutesLabel"), "26")
            XCTAssertEqual(wheel.value as? String, "26분")
            try pollCurrentSpeech(containing: ["26분"], excluding: ["2014", "정류장"], stage: "W02.wheel.focus26")
        }
    }

    func testW13CleanupConfirmationAndCancellationMoveActualFocusAndPreserveBytes() throws {
        // 깨짐 명명: 확인/취소 제목·안내 포커스 누락 또는 취소가 원본을 변경함.
        try resetVoiceOver()
        let h = FocusMateUIHarness.launch(seed: "corrupt")
        XCTAssertTrue(h.element("screen.storageError").waitForExistence(timeout: timeout))
        let original = try h.diagnostic("test.persistedBytes")
        XCTAssertNotEqual(original, "absent")
        let cleanup = h.element("storage.cleanup")
        let cleanupTarget = try mappedButtonLabel(cleanup)
        let errorTargets = mappedTextTargets(h.element("storage.error"), fallback: ["저장된 데이터 형식을 읽을 수 없어요."])
        try withVoiceOver {
            try findSpeech(containing: [cleanupTarget], stage: "W13.cleanup.focus")
            try activateFocused(cleanup, containing: [cleanupTarget], stage: "W13.cleanup.activate")
            let confirmation = h.element("storage.cleanupConfirmation")
            XCTAssertTrue(confirmation.waitForExistence(timeout: timeout))
            let confirmationTargets = mappedTextTargets(confirmation, fallback: [
                "카드, 여행, 기록 데이터가 초기화돼요.",
                "같은 원본을 앱 내부에 보존한 뒤 정리해요."
            ])
            try pollCurrentSpeech(containing: confirmationTargets, stage: "W13.confirmation.automaticFocus")
            let cancel = h.element("storage.cancelCleanup")
            try findSpeech(containing: ["취소"], stage: "W13.cancel.focus")
            try activateFocused(cancel, containing: ["취소"], stage: "W13.cancel.activate")
            XCTAssertTrue(h.element("storage.cleanup").waitForExistence(timeout: timeout))
            XCTAssertFalse(confirmation.exists)
            try pollCurrentSpeech(containing: errorTargets, stage: "W13.cancelled.errorAutomaticFocus")
            XCTAssertEqual(try h.diagnostic("test.persistedBytes"), original)
            XCTAssertEqual(try h.diagnostic("test.backups"), "{}")
            XCTAssertFalse(h.element("screen.cardEntry").exists)
        }
    }

    func testW13BackupFailureMovesActualFocusToFailureAndPreservesBytes() throws {
        // 깨짐 명명: backupFail 후 실패 안내 포커스 누락 또는 성공으로 전환/원본 삭제.
        try resetVoiceOver()
        let h = FocusMateUIHarness.launch(seed: "corrupt", extraArguments: ["--fm-ui-recovery", "backupFail"])
        XCTAssertTrue(h.element("screen.storageError").waitForExistence(timeout: timeout))
        let original = try h.diagnostic("test.persistedBytes")
        XCTAssertNotEqual(original, "absent")
        let cleanup = h.element("storage.cleanup")
        let cleanupTarget = try mappedButtonLabel(cleanup)
        try withVoiceOver {
            try findSpeech(containing: [cleanupTarget], stage: "W13.backupFail.cleanupFocus")
            try activateFocused(cleanup, containing: [cleanupTarget], stage: "W13.backupFail.cleanupActivate")
            let confirmation = h.element("storage.cleanupConfirmation")
            XCTAssertTrue(confirmation.waitForExistence(timeout: timeout))
            try pollCurrentSpeech(containing: mappedTextTargets(confirmation, fallback: [
                "카드, 여행, 기록 데이터가 초기화돼요.",
                "같은 원본을 앱 내부에 보존한 뒤 정리해요."
            ]), stage: "W13.backupFail.confirmationAutomaticFocus")
            try findSpeech(containing: ["원본 보존 후 정리"], stage: "W13.backupFail.confirmActionFocus")
            try activateFocused(h.element("storage.confirmCleanup"), containing: ["원본 보존 후 정리"], stage: "W13.backupFail.confirmActivate")
            XCTAssertTrue(h.element("storage.recoveryFailure").waitForExistence(timeout: timeout))
            try pollCurrentSpeech(containing: ["원본을 보존하지 못해 저장 데이터 정리를 완료하지 못했어요."], stage: "W13.backupFail.failureAutomaticFocus")
            XCTAssertEqual(try h.diagnostic("test.persistedBytes"), original)
            XCTAssertTrue(h.element("screen.storageError").exists)
            XCTAssertFalse(h.element("screen.cardEntry").exists)
        }
    }

    private func resetVoiceOver() throws {
        if service.isEnabled { try service.disable() }
        XCTAssertFalse(service.isEnabled)
    }

    private func withVoiceOver(_ operation: () throws -> Void) throws {
        defer { disableVoiceOver() }
        try service.enable()
        XCTAssertTrue(service.isEnabled, "VoiceOver service enable 실패")
        _ = try currentSpeech(stage: "service.enabled.actualFocus")
        try operation()
    }

    private func disableVoiceOver() {
        do {
            if service.isEnabled { try service.disable() }
            XCTAssertFalse(service.isEnabled, "VoiceOver 안전 해제 실패")
        } catch {
            XCTFail("VoiceOver disable 오류: \(error)")
        }
    }

    @discardableResult
    private func record(_ output: XCUIVoiceOverService.Output, stage: String) throws -> String {
        let utterance = output.utterance
        let evidence = "[actual VoiceOver][\(stage)] \(utterance)"
        print(evidence)
        let attachment = XCTAttachment(string: evidence)
        attachment.name = stage
        attachment.lifetime = .keepAlways
        add(attachment)
        guard !utterance.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            XCTFail("실제 focus/speech 없음: \(stage)")
            throw ProbeFailure.missingSpeech
        }
        return utterance
    }

    private func currentSpeech(stage: String) throws -> String {
        try record(service.currentSpeech(), stage: stage)
    }

    private func matches(_ speech: String, targets: [String], excluding: [String]) -> Bool {
        targets.contains { speech.contains($0) } && !excluding.contains { speech.contains($0) }
    }

    private func findSpeech(containing targets: [String], excluding: [String] = [], stage: String) throws {
        var speech = try currentSpeech(stage: "\(stage).current")
        if matches(speech, targets: targets, excluding: excluding) { return }
        for step in 1...50 {
            speech = try record(service.moveForward(), stage: "\(stage).forward.\(step)")
            if matches(speech, targets: targets, excluding: excluding) { return }
        }
        XCTFail("50회 actual VO 탐색 내 목표 없음: \(targets)")
        throw ProbeFailure.targetNotFound
    }

    private func requireCurrentSpeech(containing targets: [String], excluding: [String] = [], stage: String) throws {
        let speech = try currentSpeech(stage: stage)
        guard matches(speech, targets: targets, excluding: excluding) else {
            XCTFail("활성화/gesture 직전 actual focus 불일치: \(speech), 목표: \(targets)")
            throw ProbeFailure.targetNotFound
        }
    }

    private func activateFocused(_ element: XCUIElement, containing targets: [String], stage: String) throws {
        try requireCurrentSpeech(containing: targets, stage: "\(stage).beforeDoubleTap")
        XCTAssertTrue(element.exists)
        element.doubleTap() // 일반 tap은 사용하지 않는다. 실제 두 번 탭으로 현재 VO focus 활성화.
        _ = try currentSpeech(stage: "\(stage).afterDoubleTap")
    }

    private func pollCurrentSpeech(containing targets: [String], excluding: [String] = [], stage: String) throws {
        let deadline = Date().addingTimeInterval(timeout)
        var sample = 0
        repeat {
            sample += 1
            let speech = try currentSpeech(stage: "\(stage).poll.\(sample)")
            if matches(speech, targets: targets, excluding: excluding) { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        } while Date() < deadline
        XCTFail("자동 포커스가 제목/안내 목표로 이동하지 않음: \(targets)")
        throw ProbeFailure.targetNotFound
    }

    private func scanBothDirections(stage: String) throws -> [String] {
        var utterances = [try currentSpeech(stage: "\(stage).start")]
        // 같은 speech가 반복돼도 곧바로 카드 중복으로 판단하지 않는다.
        for forward in [true, false] {
            var repeated = 0
            var previous = utterances.last!
            for step in 1...50 {
                let output = try forward ? service.moveForward() : service.moveBackward()
                let speech = try record(output, stage: "\(stage).\(forward ? "forward" : "backward").\(step)")
                utterances.append(speech)
                repeated = speech == previous ? repeated + 1 : 0
                previous = speech
                if repeated >= 3 { break }
            }
        }
        return utterances
    }

    private func mappedButtonLabel(_ element: XCUIElement) throws -> String {
        XCTAssertTrue(element.waitForExistence(timeout: timeout))
        let label = element.label
        guard !label.isEmpty else {
            XCTFail("설계서 인터페이스 불충분: storage.cleanup 목표 한국어 label 없음")
            throw ProbeFailure.missingTargetMapping
        }
        // label은 탐색 목표 매핑에만 사용한다. actual speech 증거로 기록하지 않는다.
        return label
    }

    private func mappedTextTargets(_ element: XCUIElement, fallback: [String]) -> [String] {
        // 제목 identifier가 실제 staticText일 때만 목표 label을 추가한다.
        // 컨테이너 전체 label/버튼 label을 제목 자동 포커스의 근거로 사용하지 않는다.
        if element.exists, element.elementType == .staticText, !element.label.isEmpty {
            return fallback + [element.label]
        }
        return fallback
    }

    private enum ProbeFailure: Error {
        case missingSpeech, targetNotFound, missingTargetMapping
    }
}
```


## 2026-10-14 — 실제 VoiceOver 목표 식별 수리 (append)

Status: NEEDS_CONTEXT — 테스트 locator 수리 및 관찰 장치 작성 완료. 수정 후 빌드·타입검사·실제 실행은 부모 담당이며 아직 재실행 미확인이다. 프로덕션 버그 확정 또는 검증 PASS가 아니다. 제품 소스 열람·수정 0, 새 agent·commit·push·빌드·UI 실행 없음.

### 기존 실제 실행 증거와 목표 식별 실수

`voiceover-native-test.log`의 네 시험 및 raw speech는 그대로 보존했다. 기존 실행은 4 tests / 2 PASS / 2 FAIL (2378–2382행)이다.

- W01 PASS (1983행): 완료 자동 포커스는 `출발지 선택하기 버튼` (1942행), 카드 탐색은 `집중동행카드   이미지` (1954행). 독립 장식 비노출 검사는 기존대로 보존했다.
- W02 FAIL (2096행): 최초 `25분` 부분일치가 정적 시간 label의 전문 `25분 25` (2046행)에 멈췄다. swipe 직전 (2048행)과 이후 (2092행)도 같은 speech였고 25→26 대기가 실패했다 (2094행). 실제 휠 focus에서 조절한 증거가 아니므로 이 결과만으로 제품 조절 기능 버그를 확정할 수 없다.
- W13 backupFail PASS (2197행): 확인 자동 focus `저장 데이터 정리 머리말` (2164행), 실패 자동 focus `원본을 보존하지 못해 저장 데이터 정리를 완료하지 못했어요.` (2188행). 이 시험은 변경하지 않았다.
- W13 cancel FAIL (2376행): 취소 뒤 실제 자동 focus는 `저장된 상태 확인 머리말` (2296–2372행)이었으나 기존 목표 배열은 원인 안내 본문만 포함했다 (2374행). 제목/안내 중 하나라는 계약의 제목 목표 매핑이 누락된 시험 오류다.

### 수정 범위와 부모 인계

수정 파일은 `voiceover-probe/ios/FocusMateUITests/LegacyVoiceOverProbeTests.swift` 하나다. 이 보고서는 append만 했다.

W02는 전용 `findWheelSpeech`에서 `25분 25` **전체 문자열 동일**만 배제하고 `2014`/`정류장` 제외를 유지한다. 이후 실제 후보 speech 전문을 기존 record(print + keepAlways attachment)와 unverifiedWheelCandidate stage로 남기며, current + 최대 50회 forward의 fullNavigationTrace attachment를 성공/실패/오류 반환 시 보존한다. 단순히 정적 label이 아닌 25분 후보라는 사실만으로 휠로 판정하지 않는다.

기존 로그는 정적 label에서 탐색을 멈춰 실제 휠의 역할/전문을 제공하지 않는다. 따라서 English/Korean roleWord를 추가하지 않았고 `observedWheelSpeech`는 nil이다. 부모에게 요청: 네 시험을 재실행하여 W02 fullNavigationTrace/후보 전문을 제공하고 어느 후보가 실제 adjustable wheel인지 확인해 달라. 근거가 확보되면 케이스의 `observedWheelSpeech`에 관찰·확인한 전문을 매핑한다. 현재는 근거 없는 후보에서 swipe를 수행하지 않고 NEEDS_CONTEXT failure로 중단한다. 후보 자체가 없거나 service 탐색 오류라면 그 trace/오류도 제공해야 한다. 실패·skip을 PASS로 바꾸지 않았다.

휠 전문이 확인되어 진행할 때에는 swipe 직전 currentSpeech가 식별된 전문과 동일해야 한다. 원래 `wheel.swipeUp()` 1회 바로 뒤 `service.isEnabled` assertion을 추가했다. 기존 25→26 완료 대기, minutes 진단 26, wheel 값 26분, 실제 currentSpeech 26분 assertion을 모두 유지했다. adjust 대체, 방향/범위 변경, 결과 약화는 없다.

W13 cancel은 진입 시 `app.staticTexts`에서 label이 정확히 `저장된 상태 확인`인 실제 제목 요소의 존재와 label을 먼저 assertion하고 오류 목표에 추가한다. 컨테이너 전체 label은 제목 근거로 쓰지 않는다. 취소 후 기존 currentSpeech poll만으로 제목/안내 중 하나의 자동 포커스를 확인하며 수동 navigation을 삽입하지 않았다. 확인 화면 및 원본/백업/첫 시작 미전환 assertion도 유지했다. 제목 요소의 실제 매핑 성공은 부모 재실행 전까지 미확인이다.

### 이 작성 단계의 확인과 참조 목록

정적 텍스트 비교만 수행했다: 네 시험 유지, W01/W13 backupFail 코드 및 기존 requireCurrentSpeech 이후 helper 동일, W02 기존 증가 assertion/gesture 유지. Swift 구문 parse·SDK 타입검사·build·UI 실행은 수행하지 않았다. 기존 로그 SHA256: `4935181bb4861b1b7abfda7a9dcbea786ece2b812c5e2a44763d3740e0077239`.

이번 작업에서 읽은 파일:

- `voiceover-probe/ios/FocusMateUITests/LegacyVoiceOverProbeTests.swift`
- `reports/voiceover-test-plan.md` (기존 보고서와 기록된 테스트 코드)
- `voiceover-native-test.log` (실제 speech·시험 결과·실패 행만 검색)
- `/Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md`
- `/Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/systematic-debugging/SKILL.md`

파일 목록 검색은 지정 `.dev/codex-feat-card-customization` 내 시험/보고서/log 위치 확인에만 사용했다. 원본 W10 및 복사 프로젝트 제품 소스는 읽거나 수정하지 않았다.


## 2026-10-14 — W02 관측 휠 전문 locator 갱신 (append)

부모가 전달한 fresh run `voiceover-native-recheck.log`의 `forward15` 관측값을 `observedWheelSpeech`에 매핑했다. 실제 adjustable wheel의 정확한 전문은 다음과 같다.

> 25분 선택기 항목 조절 가능 총 346개 중 11번째 값을 조절하려면 한 손가락으로 쓸어올리거나 쓸어내리십시오.

출처는 부모의 이번 작업 지시이며, 이 작성 단계에서 해당 로그를 직접 읽거나 실행 결과를 재검증하지 않았다. 앞선 nil/NEEDS_CONTEXT 기록은 이 관측 전문 매핑으로 갱신된다. `findWheelSpeech`가 실제 휠 전문을 정확히 선택할 수 있도록 locator 값만 변경했다.

`wheel.swipeUp()` 1회, 제스처 직전 실제 focus 동일성, 제스처 뒤 VoiceOver 활성 상태, 25→26 대기, minutes 진단 26, wheel 값 26분 및 실제 VoiceOver 26분 assertion은 그대로 보존했다. adjust로 대체하거나 assertion을 약화하지 않았다. 실제 swipeUp에 의한 25→26 변경은 여전히 미검증이며 PASS를 주장하지 않는다. 기존 실행 종료 후 부모가 W02를 재실행한다.

수정은 지정 테스트 파일과 이 보고서 append뿐이다. 프로덕션 코드 열람·수정, 빌드·테스트 실행, agent 호출, commit은 하지 않았다. 작성 후 텍스트 비교로 지정 주석/locator 2줄 외 테스트 내용이 동일함을 확인했다. 참조 파일은 지정 테스트 파일, 이 보고서 및 `using-superpowers/SKILL.md`뿐이다.

## 부모 실제 focused 검증
W02 observed-wheel locator 실행에서 actual swipeUp25→26/currentSpeech26 PASS1/1(exit0), voiceover-wheel-actual.log. W13 취소 자동 포커스는 별도 focused1/1 PASS(exit0), voiceover-cancel-focused.log. 초기4tests의 W01/W13backupFAIL안내2PASS와 합쳐 4가지 이전기능 모두 실제 VO 통과 증거를 확보했다. 전체동시재실행 안정성/Release화면/W10최종 VO는 별도게이트.
