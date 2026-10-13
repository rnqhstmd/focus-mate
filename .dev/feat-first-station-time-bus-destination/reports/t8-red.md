# T8 RED report (LargeTextUITests)

## 케이스 (2건)
1. testSearchAtLargestTextSizeLetsUserReachResultAndConfirmWithoutScrolling -- 이미 구현이 있어 통과
2. testTimeScreenAtLargestTextSizeKeepsProceedReachableAndCompletesSixtyMinuteFlow -- 실패

## 실패 확인 명령
FOCUSMATE_SIMULATOR_ID=65C4EB57-5CAD-4C4C-9FA5-1EF70EF47DEA python3 scripts/check-ios.py test ios/FocusMateUITests/LargeTextUITests.swift

## 실패 메시지
LargeTextUITests.swift:60: XCTAssertEqual failed: ("버스와 도착지를 선택하세요") is not equal to ("이 여정 준비하기")
(후보 time.candidate.2014를 reach 후 탭했으나 진행 버튼 label이 선택 상태로 바뀌지 않음. 그 앞의 진입 직후 isHittable, 휠, minutesLabel 단언은 통과.)
Executed 2 tests, 1 failure.

## 참조한 파일
ios/FocusMateUITests/TimeSelectionUITests.swift, PreparationFlowUITests.swift, FirstStationSearchUITests.swift (헬퍼 참고), 프로덕션 코드 미참조.

## 테스트 코드 전문
```swift
import Foundation
import XCTest

@MainActor
final class LargeTextUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testSearchAtLargestTextSizeLetsUserReachResultAndConfirmWithoutScrolling() throws {
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
        let station = try XCTUnwrap(try snapshot(in: app)["currentStation"] as? [String: Any])
        XCTAssertEqual(station["id"] as? String, "seongsu")
        XCTAssertEqual(station["name"] as? String, "성수역")
        XCTAssertEqual(station["direction"] as? Int, 1)
    }

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

    // MARK: - Helpers

    private func launchLargestText() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--fm-ui-test-id", UUID().uuidString,
            "--fm-ui-seed", "cardOnly",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"
        ]
        app.launch()
        return app
    }

    /// 사용자가 스크롤해서 닿는 경로. 최대 3회 위로 민다.
    private func reach(_ target: XCUIElement, in app: XCUIApplication) throws {
        var attempts = 0
        while !target.isHittable && attempts < 3 {
            app.swipeUp()
            attempts += 1
        }
        XCTAssertTrue(target.isHittable, "스크롤해도 닿지 않음: \(target.identifier)")
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
