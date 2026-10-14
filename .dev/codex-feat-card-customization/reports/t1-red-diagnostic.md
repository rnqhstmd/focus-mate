# T1 AC32 원인진단 RED 작성 보고

Status: DONE_WITH_CONCERNS

## 범위와 실행 상태
새 AC32 테스트 1개만 추가했다. 기존 AC33 및 기존 helper는 바이트 동일하게 보존했다. 프로덕션 열람·수정, 다른 테스트 수정, 새 agent, commit/push 없음. 사용자 지시에 따라 테스트 실행은 부모만 수행하며 이 단계에서는 실행하지 않았다. 새 진단 테스트의 컴파일 성공·실제 RED는 아직 확인되지 않았다.

## 깨짐 명명 및 기대값
후보 탭 가로채기 또는 탭 뒤 분 변경으로 후보 선택이 해제되는 변경을 잡는다. 기존 LargeTextUITests와 같은 launchArguments(cardOnly/UUID/AccessibilityXXXL), search result 및 confirm, wheel60, reach 최대3회/isHittable, candidate2014 탭, proceed 준비 라벨 및 준비 화면 진입을 유지했다. accessibility5 검증과 최종 minutes=60/busID=2014/destination=성동구민체육센터를 유지한다. 기댓값은 리터럴이며 실제 앱 UI를 검증한다. 동작·expectation 완화 없음.

## 단계별 증거
wheel60 전후, reach 전후, candidate 탭 직전/직후 및 assertion 전에 print와 keepAlways 문자열·앱 스크린샷을 남긴다. candidate/wheel/proceed/app/모든 ScrollView frame, candidate isHittable/isSelected, wheel.value, time.minutesLabel.value, proceed.label/isEnabled, app.debugDescription을 기록한다. 기존 test.journeySelection도 optional로 관찰하며 누락 시 진단만 nil로 출력한다. 필수 UI 값/최종 여정 expectation은 그대로 유지한다. 진단용 frame은 출력에만 사용하고 스타일 assertion은 추가하지 않았다.

## 예정 실패 확인 명령 (부모 실행)
```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate -destination 'platform=iOS Simulator,id=D3BB49D7-3834-4BC9-B910-1CADD9E036E1' -derivedDataPath .build/ios -parallel-testing-enabled NO -collect-test-diagnostics never -only-testing:FocusMateUITests/SimulatorLargeTextRecoveryTests/testAC32_XXXL에서_60분_2014를_선택하면_선택값을_유지하고_준비로_진입한다 test CODE_SIGNING_ALLOWED=NO
```
실패 메시지: 미실행으로 없음. t1-impl.md가 보고한 기존 AC32 실패는 후보 탭 뒤 proceed actual="버스와 도착지를 선택하세요"이며, 새 테스트의 직접 실행 결과와 구분한다. 부모는 컴파일 오류와 실제 assertion RED를 구분하고 각 단계 attachment를 확인해야 한다. 지정 simulator ID는 t1-impl.md의 예정 명령을 그대로 참조했으며 현 환경 확인은 수행하지 않았다.

## 참조 파일 전체
- ios/FocusMateUITests/LargeTextUITests.swift
- ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift
- ios/FocusMateUITests/UITestLaunchSupport.swift
- ios/FocusMateUITests/HarnessUITests.swift
- .dev/codex-feat-card-customization/prd.md
- .dev/codex-feat-card-customization/design.md
- .dev/codex-feat-card-customization/reports/t1-impl.md
- /Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md (작업 시작 스킬; 특정 역할 디스패치는 제외 대상)
파일 목록 탐색 및 UITests 내 harness 정의 위치 검색만 추가 수행했다. 프로덕션 파일 내용은 읽지 않았다.

## 테스트 파일 전체 코드
```swift
import Foundation
import XCTest

@MainActor
final class SimulatorLargeTextRecoveryTests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testAC32_XXXL에서_60분_2014를_선택하면_선택값을_유지하고_준비로_진입한다() throws {
        // 깨짐 명명: 후보 탭을 휠이 가로채거나 탭 뒤 분 변경으로 후보 선택을
        // 해제하면 준비 라벨/준비 진입/저장된 여정 선택값 검증이 실패한다.
        let h = FocusMateUIHarness.launch(seed: "cardOnly", extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        let app = h.app
        let candidate = h.element("time.candidate.2014")
        let wheel = app.pickerWheels.firstMatch
        let proceed = h.element("time.proceed")

        // 진단은 누락된 요소를 기다리거나 assertion하지 않는다. nil도 증거로 남긴다.
        func describe(_ name: String, _ element: XCUIElement) -> String {
            guard element.exists else { return "\(name): exists=false frame=nil value=nil" }
            return "\(name): exists=true frame=\(element.frame)"
                + " isHittable=\(element.isHittable) isSelected=\(element.isSelected)"
                + " value=\(String(describing: element.value))"
                + " label=\(element.label) isEnabled=\(element.isEnabled)"
        }

        func record(_ stage: String) {
            var lines = [
                "AC32 stage=\(stage)",
                "app.frame=\(app.frame)",
                describe("candidate2014", candidate),
                describe("wheel", wheel),
                describe("time.minutesLabel", h.element("time.minutesLabel")),
                describe("proceed", proceed),
                describe("test.journeySelection (optional)", h.element("test.journeySelection"))
            ]
            let scrollViews = app.scrollViews.allElementsBoundByIndex
            if scrollViews.isEmpty { lines.append("ScrollView.frame=nil") }
            for (index, scrollView) in scrollViews.enumerated() {
                lines.append(describe("ScrollView[\(index)]", scrollView))
            }
            lines.append("accessibility debugDescription:\n\(app.debugDescription)")
            let details = lines.joined(separator: "\n")
            print(details)
            let text = XCTAttachment(string: details)
            text.name = "AC32 \(stage) UI 진단"
            text.lifetime = .keepAlways
            add(text)
            let screenshot = XCTAttachment(screenshot: app.screenshot())
            screenshot.name = "AC32 \(stage) 화면"
            screenshot.lifetime = .keepAlways
            add(screenshot)
        }

        // LargeTextUITests와 같은 isHittable 조건·최대 3회 app.swipeUp 경로.
        func reach(_ target: XCUIElement, stage: String) {
            record("\(stage) reach 전")
            var attempts = 0
            while !target.isHittable && attempts < 3 {
                app.swipeUp()
                attempts += 1
            }
            record("\(stage) reach 후 (swipes=\(attempts))")
            XCTAssertTrue(target.isHittable, "스크롤해도 닿지 않음: \(target.identifier)")
        }

        record("launch 후")
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")
        let result = h.element("search.result.seongsu:1")
        let resultExists = result.waitForExistence(timeout: timeout)
        record("search result 확인 전")
        XCTAssertTrue(resultExists)
        reach(result, stage: "search result")
        result.tap()
        let confirm = h.element("search.confirm")
        let confirmExists = confirm.waitForExistence(timeout: timeout)
        record("search confirm 확인 전")
        XCTAssertTrue(confirmExists)
        XCTAssertTrue(confirm.isHittable, "확인 버튼이 스크롤 없이 닿지 않음")
        confirm.tap()
        let timeExists = h.element("screen.time").waitForExistence(timeout: timeout)
        record("time 진입 확인 전")
        XCTAssertTrue(timeExists)

        let proceedExists = proceed.waitForExistence(timeout: timeout)
        record("proceed 초기 도달 확인 전")
        XCTAssertTrue(proceedExists)
        XCTAssertTrue(proceed.isHittable, "진행 버튼이 진입 직후 스크롤 없이 닿지 않음")
        let wheelExists = wheel.waitForExistence(timeout: timeout)
        record("wheel60 전")
        XCTAssertTrue(wheelExists, "분 휠이 없음")
        wheel.adjust(toPickerWheelValue: "60분")
        record("wheel60 후")
        let minutes = h.element("time.minutesLabel")
        let minutesExists = minutes.waitForExistence(timeout: timeout)
        record("wheel60 minutes assertion 전")
        XCTAssertTrue(minutesExists, "Missing value element: time.minutesLabel")
        XCTAssertEqual(try XCTUnwrap(minutes.value as? String), "60")

        let candidateExists = candidate.waitForExistence(timeout: timeout)
        record("candidate 존재 assertion 전")
        XCTAssertTrue(candidateExists)
        reach(candidate, stage: "candidate2014")
        record("candidate 탭 직전")
        candidate.tap()
        record("candidate 탭 직후")

        XCTAssertTrue(proceed.isHittable, "후보 선택 뒤 진행 버튼이 닿지 않음")
        XCTAssertEqual(proceed.label, "이 여정 준비하기")
        proceed.tap()
        let preparationExists = h.element("screen.preparation").waitForExistence(timeout: timeout)
        record("preparation assertion 전")
        XCTAssertTrue(preparationExists)
        let rawSelection = try h.diagnostic("test.journeySelection")
        record("journeySelection assertion 전")
        let data = try XCTUnwrap(rawSelection.data(using: .utf8))
        let selection = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        XCTAssertEqual(selection["minutes"] as? Int, 60)
        XCTAssertEqual(selection["busID"] as? String, "2014")
        XCTAssertEqual(selection["destination"] as? String, "성동구민체육센터")
    }

    func testAC33_XXXL에서_마지막_안내까지_읽고_카드를_발급할_수_있다() throws {
        // 깨짐 명명: 본문 끝의 스크롤 여유를 없애 안내가 고정 버튼에 가려지거나,
        // 발급 탭의 저장 부작용을 누락하면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "none", extraArguments: [
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ])
        XCTAssertTrue(h.element("screen.cardEntry").waitForExistence(timeout: timeout))
        XCTAssertEqual(try h.diagnostic("test.dynamicTypeSize"), "accessibility5")

        let hint = h.app.staticTexts["한 번 발급받아, 모든 몰입 여정에 사용해요."]
        let issue = h.app.buttons["집중동행카드 발급받기"]
        XCTAssertTrue(hint.waitForExistence(timeout: timeout))
        XCTAssertTrue(issue.waitForExistence(timeout: timeout))

        // 정확한 픽셀이나 여백이 아니라 안내 전체의 가시 영역 도달을 검사한다.
        var scrolls = 0
        while !isFullyReadable(hint, above: issue, in: h.app) && scrolls < 8 {
            h.app.swipeUp()
            scrolls += 1
        }
        let readable = XCTNSPredicateExpectation(
            predicate: NSPredicate { _, _ in
                self.isFullyReadable(hint, above: issue, in: h.app)
            },
            object: hint
        )
        let result = XCTWaiter.wait(for: [readable], timeout: timeout)
        let attachment = XCTAttachment(string:
            "scrolls=\(scrolls) hint=\(hint.frame) button=\(issue.frame) window=\(h.app.frame)"
        )
        attachment.name = "AC33 본문 끝 도달 프레임"
        attachment.lifetime = .keepAlways
        add(attachment)
        XCTAssertEqual(result, .completed, "마지막 안내 전체가 화면 안에서 발급 버튼 위에 도달하지 못함")
        XCTAssertTrue(issue.isEnabled)
        XCTAssertTrue(issue.isHittable, "본문 끝 도달 후 발급 버튼을 누를 수 없음")
        issue.tap()

        XCTAssertTrue(h.element("card.continueButton").waitForExistence(timeout: 8))
        let snapshot = try h.snapshot()
        XCTAssertEqual(snapshot["cardIssued"] as? Bool, true)
        let cards = try XCTUnwrap(snapshot["cards"] as? [String: Any])
        let items = try XCTUnwrap(cards["items"] as? [[String: Any]])
        XCTAssertEqual(items.count, 1)
        XCTAssertNotEqual(try h.diagnostic("test.persistedBytes"), "absent")
    }

    private func isFullyReadable(
        _ hint: XCUIElement, above button: XCUIElement, in app: XCUIApplication
    ) -> Bool {
        let hintFrame = hint.frame
        let buttonFrame = button.frame
        return !hintFrame.isEmpty && !buttonFrame.isEmpty
            && app.frame.contains(hintFrame)
            && hintFrame.maxY <= buttonFrame.minY
    }
}
```

## 다음 단계
부모가 위 focused 테스트를 실행해 RED 및 단계별 첨부물 수집 → 원인 확정 → implementer의 최소 GREEN 수리. 이 보고서는 실행 성공이나 원인 확정을 주장하지 않는다.

## 부모 직접 RED 확인
`FOCUSMATE_SIMULATOR_ID=D3BB49D7-3834-4BC9-B910-1CADD9E036E1 python3 scripts/check-ios.py test ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift` exit65. AC32 assertion 실패, AC33 PASS. 탭 전후 분 값은60 유지, 후보선택 false·진행 disabled 유지. candidate frame은 고정wheel영역과 겹침. actual원인증거는 t1-diagnostic-test.log와 xcresult첨부물.
