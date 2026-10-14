# T1 기존 큰 글자 회귀 RED

Status: DONE_WITH_CONCERNS

## 실행 경계
이번 작업은 테스트 작성과 보고서 작성만 수행했다. xcodebuild/check-ios.py 및 새 테스트의 빌드·실행은 수행하지 않았다. 아래 명령은 부모가 직렬 실행할 예정이며 새 테스트의 RED/PASS는 아직 미확인이다. 프로덕션 소스 열람·검색·수정, 새 agent 호출, 커밋·푸시·삭제는 수행하지 않았다.

## 케이스 목록
- AC32: `LargeTextUITests.testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow` 그대로 재사용. XXXL, seed cardOnly, 성수역 정방향 → 60분/2014 → 준비 진입 및 minutes=60, busID="2014", destination="성동구민체육센터" 리터럴을 유지한다. 기존 테스트 수정·약화·삭제 없음.
- AC33: `SimulatorLargeTextRecoveryTests.testAC33_XXXL에서_마지막_안내까지_읽고_카드를_발급할_수_있다`. 새 UUID/seed none/XXXL로 실제 앱을 조작한다. 마지막 안내 전체가 화면 안에 있고 발급 버튼 위에 도달한 뒤 실제 발급 완료·한 장 저장을 검사한다. card.hint 존재를 가정하지 않는다. 임의 sleep·모의 없음.

## 기존 actual RED 증거
actualfailureLog=`.dev/codex-feat-card-customization/baseline-ios-test.log`
직접 읽은 baseline에서 AC32 assertion 실패 1건을 확인했다(1949행). 2014 후보 탭 후 진행 버튼 라벨 actual="버스와 도착지를 선택하세요", expected="이 여정 준비하기". 컴파일 에러가 아닌 실제 UI assertion 실패로 정상 RED다. 단위 254건/0실패(649~652행), UI 66건/1실패(4407~4410행). 디스패치는 총 3회 실패를 보고했으나 이번 허용 로그에서 직접 확인한 실패는 1회다.

```text
    t =    16.51s     Wait for app.focusmate.prototype to idle
    t =    16.51s     Find the "time.candidate.2014" Button
    t =    16.62s     Check for interrupting elements affecting "time.candidate.2014" Button
    t =    16.71s     Synthesize event
    t =    17.02s     Wait for app.focusmate.prototype to idle
    t =    17.03s Find the "time.proceed" Button
    t =    17.12s Find the "time.proceed" Button
/Users/bonseung/.codex/worktrees/w10-card-customization/new/ios/FocusMateUITests/LargeTextUITests.swift:60: error: -[FocusMateUITests.LargeTextUITests testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow] : XCTAssertEqual failed: ("버스와 도착지를 선택하세요") is not equal to ("이 여정 준비하기")
    t =    17.27s Tear Down
Test Case '-[FocusMateUITests.LargeTextUITests testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow]' failed (17.510 seconds).
Test Suite 'LargeTextUITests' failed at 2026-10-14 08:12:09.872.
	 Executed 2 tests, with 1 failure (0 unexpected) in 30.123 (30.126) seconds
```

## 깨짐 명명·counterexample·변이 점검
- AC32: 2014 후보 탭을 분 휠이 받아 선택 부작용이 누락되는 변경은 진행 라벨/준비 진입 assertion에 잡힌다. 선택 minutes를 25로 되돌리는 변경은 최종 60 assertion에, busID를 다른 버스로 바꾸는 변경은 "2014" assertion에, 도착지를 기본값/빈값으로 바꾸는 변경은 "성동구민체육센터" assertion에 잡힌다.
- AC33: 스크롤 끝 여유를 없애 마지막 안내 하단이 버튼 뒤에 남는 변경은 hint.maxY<=button.minY에 잡힌다. 안내 일부가 화면 밖에 남는 변경은 app.frame.contains(hint.frame)에 잡힌다. 발급을 비활성화하거나 탭의 발급·저장 부작용을 누락하면 isEnabled/isHittable/완료 wait/cardIssued=true/items.count=1/persistedBytes assertion에 잡힌다.
- 프레임 비교는 정확한 스타일 px/색/여백 assertion이 아니다. 계약에 명시된 본문 전체 도달·고정 버튼 비가림을 상대적 포함/순서로 검사한다. 프레임 attachment는 실패 진단용이며 전체 스냅샷 assertion이 아니다.
- AC33 처음부터 PASS이면 회귀 재현 불가/특성 고정으로 보고하고 프로덕션 수리를 요구하지 않는다. FAIL이면 접근성 트리에서 해당 staticText가 온전한 안내 요소인지와 attachment를 먼저 대조해야 한다. 프레임 검사만으로 실제 글리프 잘림이나 VoiceOver 가독성을 완전 증명하지 않는다.

## 필요 진단 가설
AC32 후보 탭이 wheel hit 영역에 전달되었을 가능성은 가설이다. 기존 로그만으로 원인 확정 불가. 필요시 별도 진단 시험에서 candidate/wheel frame, 탭 전후 minutes, 선택값, proceed 값을 attachment로 남기되 기대값·런치 인자를 변경하지 않는다. 이번에는 중복 AC32 진단 시험을 추가하지 않았다. 부모가 기존 actual RED를 직렬 재실행한 후 필요성을 판단한다.

## 부모 실행 예정 명령 (미실행)
아래 simulator ID는 baseline 명령에서 가져왔다. 부모는 실행 전 대상의 가용성을 확인한다.

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=D3BB49D7-3834-4BC9-B910-1CADD9E036E1' \
  -derivedDataPath "$PWD/.build/ios" -parallel-testing-enabled NO \
  -only-testing:FocusMateUITests/LargeTextUITests/testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow \
  -only-testing:FocusMateUITests/SimulatorLargeTextRecoveryTests \
  test CODE_SIGNING_ALLOWED=NO -collect-test-diagnostics never
```

## 테스트 코드 전문 — 새 파일
`ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift`

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

## 재사용 AC32 테스트 코드 전문 (수정 없음)
`ios/FocusMateUITests/LargeTextUITests.swift` 기존 클래스/헬퍼 그대로 사용.

```swift
    func testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow() throws {
        let app = launchLargestText()
        let result = element("search.result.seongsu:1", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        try reach(result, in: app)
        result.tap()
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        XCTAssertTrue(confirm.isHittable, "확인 버튼이 스크롤 없이 닿지 않음")
        confirm.tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))

        let proceed = element("time.proceed", in: app)
        XCTAssertTrue(proceed.waitForExistence(timeout: timeout))
        XCTAssertTrue(proceed.isHittable, "진행 버튼이 진입 직후 스크롤 없이 닿지 않음")

        let wheel = app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: timeout), "분 휠이 없음")
        wheel.adjust(toPickerWheelValue: "60분")
        XCTAssertEqual(try value("time.minutesLabel", in: app), "60")

        let candidate = element("time.candidate.2014", in: app)
        XCTAssertTrue(candidate.waitForExistence(timeout: timeout))
        try reach(candidate, in: app)
        candidate.tap()

        XCTAssertTrue(proceed.isHittable, "후보 선택 뒤 진행 버튼이 닿지 않음")
        XCTAssertEqual(proceed.label, "이 여정 준비하기")
        proceed.tap()

        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))
        let selection = try journeySelection(in: app)
        XCTAssertEqual(selection["minutes"] as? Int, 60)
        XCTAssertEqual(selection["busID"] as? String, "2014")
        XCTAssertEqual(selection["destination"] as? String, "성동구민체육센터")
    }
```

## 기존 시험 불변 확인
새 파일 작성 전후 기존 UI 시험 12개 SHA-256 일치. 새 파일만 추가했고 기존 시험은 수정하지 않았다.

```text
94acb488348a22969a21ae371a44cf7823a8081b08a484009515661226e85cc4  ios/FocusMateUITests/CardIssuanceFlowTests.swift
1e4f1b97b3f391a07b79110d8d5d75e724dfd3650df945982e93a2beae634972  ios/FocusMateUITests/CardStorageFlowTests.swift
0c384f079a86b00e0ebec64e725af82ca2dd8fecaf95f3b72a907e00c8a587f0  ios/FocusMateUITests/FirstStationSearchUITests.swift
3f4e710983c1e81c22ab1d43e7c6bbed3a1b98c2cf074f4512a668e0da4da629  ios/FocusMateUITests/HarnessUITests.swift
ed6d1fcec71ef72649cdefb74f782338a14f72e2ec7066156ad79fa810ac3485  ios/FocusMateUITests/LargeTextUITests.swift
1bed415b5b7fb3069ace326822c0066c8e8ab2a62310a52cfd57652120e4d869  ios/FocusMateUITests/Phase1FlowTests.swift
4d3e4acb78671dbe128c1180ff1fc17c88af39e37c6ab55f068844eba55afcc0  ios/FocusMateUITests/PreparationFlowUITests.swift
0c2341c5d96c1dc984ff26de5ce61603fd67053e494ad6fa9906eefd6ece8c5f  ios/FocusMateUITests/RecoveryHistoryFlowTests.swift
26d05fe321d24ec3171eeb54c4278b4b2a9720e814794a93df0452772e08933b  ios/FocusMateUITests/StationSaveFailureUITests.swift
b52f1863386a9d21d56505d7cdb0df38a8f5874d2694cd635c48f70f76a12174  ios/FocusMateUITests/StorageRecoveryFlowTests.swift
f329ed1173a7d6def136c37ca4bb148522920ff0a63d29d95eeb9248aadbfad3  ios/FocusMateUITests/TimeSelectionUITests.swift
9fecc3d0d3b78fa7b4ad651e9519e17152c604d18da471795a30d82b2dfb246e  ios/FocusMateUITests/UITestLaunchSupport.swift
```

## 참조 파일 전체 목록
- `.dev/codex-feat-card-customization/prd.md`
- `.dev/codex-feat-card-customization/design.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/frontend-testing.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.1/.claude/skills/gx-tdd/references/testing-anti-patterns.md`
- `ios/FocusMateUITests/LargeTextUITests.swift`
- `ios/FocusMateUITests/CardIssuanceFlowTests.swift`
- `ios/FocusMateUITests/UITestLaunchSupport.swift`
- `.dev/codex-feat-card-customization/baseline-ios-test.log`
- `ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift`

파일 목록 탐색: `ios/FocusMateUITests`, `.dev/codex-feat-card-customization` 경로에 rg --files를 사용했다. 해시만 읽은 나머지 기존 시험은 위 SHA-256 목록에 모두 기재했다. 문서 출력 일부는 도구에서 잘렸으며 대상 AC32/33·기존 큰 글자 회귀 계약·testability 최종 평가·프론트 규약·anti-patterns 기준을 확인했다. 소스 디렉터리 ios/FocusMate는 열람·검색하지 않았다.

## 다음 단계
부모의 focused RED 실행 → AC33 PASS/FAIL 분류 → AC32 원인 진단 → implementer의 통과 코드 작성. 이 보고서는 신규 시험의 컴파일·실행 성공이나 실패를 주장하지 않는다.

## 부모 직접 RED 검증
AC32 원본전체baseline actualASSERTFAIL(소스·테스트무변경), AC33직접실행1/1PASS(exit0). AC33은특성고정회귀이며기능수리대상에서제외. 로그t1-red-test.log, hash기준t1-test-hashes.json.
