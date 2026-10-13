# T6 RED 보고

## 새 파일 테스트 코드 전문: ios/FocusMateUITests/TimeSelectionUITests.swift
```swift
import Foundation
import XCTest

@MainActor
final class TimeSelectionUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let noCandidates = "이 시간의 도착 후보가 없어요"
    private let needsSelection = "버스와 도착지를 선택하세요"
    private let ready = "이 여정 준비하기"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testTimeWheelSpike() throws {
        let app = try openTimeScreen()

        XCTAssertEqual(app.pickerWheels.count, 1)
        let wheel = app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: 3))
        XCTAssertEqual(wheel.value as? String, "25분")
        XCTAssertEqual(try value("time.minutesLabel", in: app), "25")

        for target in ["360", "15"] {
            let started = Date()
            wheel.adjust(toPickerWheelValue: "\(target)분")
            XCTAssertLessThan(Date().timeIntervalSince(started), 20, "\(target)분 이동이 20초를 넘김")
            XCTAssertEqual(wheel.value as? String, "\(target)분")
            XCTAssertEqual(try value("time.minutesLabel", in: app), target)
        }

        try setMinutes(60, in: app)
        wheel.adjust(toPickerWheelValue: "61분")
        XCTAssertEqual(wheel.value as? String, "61분")
        XCTAssertEqual(try value("time.minutesLabel", in: app), "61")
    }

    func testEntryShowsDefault25MinutesWithSingleUnselectedCandidateAndDisabledProceed() throws {
        let app = try openTimeScreen()

        XCTAssertEqual(try value("time.minutesLabel", in: app), "25")
        XCTAssertEqual(try value("time.origin", in: app), "성수역")
        XCTAssertEqual(candidates(in: app).count, 1)
        let candidate = element("time.candidate.2014", in: app)
        XCTAssertTrue(candidate.waitForExistence(timeout: timeout))
        XCTAssertEqual(candidate.label, "지선 2014번, 서울숲 입구, 25분, 5정류장")
        XCTAssertFalse(candidate.isSelected)
        let proceed = element("time.proceed", in: app)
        XCTAssertEqual(proceed.label, needsSelection)
        XCTAssertFalse(proceed.isEnabled)
    }

    func testSixtyToOneTwentyMinutesShowsAllThreeCandidates() throws {
        let app = try openTimeScreen()

        try setMinutes(120, in: app)

        XCTAssertTrue(element("time.candidate.2014", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("time.candidate.302", in: app).exists)
        XCTAssertTrue(element("time.candidate.421", in: app).exists)
        XCTAssertEqual(candidates(in: app).count, 3)
    }

    func testMinutesWithoutCandidatesShowDisabledProceedThatDoesNotNavigate() throws {
        let app = try openTimeScreen()

        try setMinutes(17, in: app)

        XCTAssertEqual(candidates(in: app).count, 0)
        let proceed = element("time.proceed", in: app)
        XCTAssertEqual(proceed.label, noCandidates)
        XCTAssertFalse(proceed.isEnabled)
        proceed.tap()
        XCTAssertTrue(element("screen.time", in: app).exists)
        XCTAssertFalse(element("screen.preparation", in: app).exists)
    }

    func testProceedWithoutSelectionAsksForSelectionAndStaysOnTimeScreen() throws {
        let app = try openTimeScreen()

        try setMinutes(60, in: app)

        let proceed = element("time.proceed", in: app)
        XCTAssertEqual(proceed.label, needsSelection)
        proceed.tap()
        XCTAssertTrue(element("screen.time", in: app).exists)
        XCTAssertFalse(element("screen.preparation", in: app).exists)
    }

    func testSelectingCandidateMarksOnlyThatOneAndEnablesProceed() throws {
        let app = try openTimeScreen()
        try setMinutes(60, in: app)

        let first = element("time.candidate.2014", in: app)
        XCTAssertTrue(first.waitForExistence(timeout: timeout))
        first.tap()

        XCTAssertTrue(first.isSelected)
        XCTAssertFalse(element("time.candidate.302", in: app).isSelected)
        let proceed = element("time.proceed", in: app)
        XCTAssertEqual(proceed.label, ready)
        XCTAssertTrue(proceed.isEnabled)
    }

    func testChangingMinutesClearsSelectionImmediately() throws {
        let app = try openTimeScreen()
        try setMinutes(60, in: app)
        let first = element("time.candidate.2014", in: app)
        XCTAssertTrue(first.waitForExistence(timeout: timeout))
        first.tap()
        XCTAssertTrue(first.isSelected)

        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "61분")

        // 대기 없이 즉시 확인한다.
        XCTAssertEqual(candidates(in: app).count, 0)
        XCTAssertEqual(element("time.proceed", in: app).label, noCandidates)

        app.pickerWheels.firstMatch.adjust(toPickerWheelValue: "60분")
        let again = element("time.candidate.2014", in: app)
        XCTAssertTrue(again.waitForExistence(timeout: timeout))
        XCTAssertFalse(again.isSelected)
        XCTAssertEqual(element("time.proceed", in: app).label, needsSelection)
    }

    func testCandidateAndProceedExposeReadableAccessibilityLabels() throws {
        let app = try openTimeScreen()
        try setMinutes(60, in: app)

        let candidate = element("time.candidate.2014", in: app)
        XCTAssertTrue(candidate.waitForExistence(timeout: timeout))
        XCTAssertEqual(candidate.label, "지선 2014번, 성동구민체육센터, 60분, 12정류장")
        XCTAssertFalse(element("time.proceed", in: app).label.isEmpty)
    }

    func testWheelBoundariesReportFifteenAndThreeSixtyMinutes() throws {
        let app = try openTimeScreen()
        let wheel = app.pickerWheels.firstMatch

        wheel.adjust(toPickerWheelValue: "15분")
        wheel.adjust(toPickerWheelValue: "15분")
        XCTAssertEqual(try value("time.minutesLabel", in: app), "15")
        XCTAssertEqual(wheel.value as? String, "15분")

        wheel.adjust(toPickerWheelValue: "360분")
        wheel.adjust(toPickerWheelValue: "360분")
        XCTAssertEqual(try value("time.minutesLabel", in: app), "360")
        XCTAssertEqual(wheel.value as? String, "360분")
    }

    // MARK: - Helpers

    private func openTimeScreen() throws -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--fm-ui-test-id", UUID().uuidString, "--fm-ui-seed", "cardOnly"]
        app.launch()

        let origin = element("search.result.seongsu:1", in: app)
        XCTAssertTrue(origin.waitForExistence(timeout: timeout))
        origin.tap()
        element("search.confirm", in: app).tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        return app
    }

    private func setMinutes(_ minutes: Int, in app: XCUIApplication) throws {
        let wheel = app.pickerWheels.firstMatch
        XCTAssertTrue(wheel.waitForExistence(timeout: timeout), "분 휠이 없음")
        wheel.adjust(toPickerWheelValue: "\(minutes)분")
        XCTAssertEqual(try value("time.minutesLabel", in: app), String(minutes))
    }

    private func candidates(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "time.candidate."))
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func value(_ identifier: String, in app: XCUIApplication) throws -> String {
        let observed = element(identifier, in: app)
        XCTAssertTrue(observed.waitForExistence(timeout: timeout), "Missing value element: \(identifier)")
        return try XCTUnwrap(observed.value as? String, "Element has no string value: \(identifier)")
    }
}
```

## Phase1FlowTests.swift 변경 요약
- testDestinationRoundTripsPreserveStateAndExposeNoCompletionAction: ("여행 준비", screen.preparation) -> ("여행 준비", screen.time)
- testNoCompletionActionsBeyondNavigationButtonsInDefaultDestinations: destinations에서 "여행 준비" 행 삭제 (나머지 불변)

## 케이스 (신규 9 + 변경 2)
spike, AC-11 진입, AC-12 120분 3후보, AC-17 후보0, AC-18 미선택, AC-19 선택, AC-20 선택해제, AC-23 라벨, AC-10 경계.

## 실행 명령
FOCUSMATE_SIMULATOR_ID=65C4EB57-5CAD-4C4C-9FA5-1EF70EF47DEA python3 scripts/check-ios.py test ios/FocusMateUITests/TimeSelectionUITests.swift ios/FocusMateUITests/Phase1FlowTests.swift
결과: 19 tests, 10 failures (신규 9 전부 실패 + Phase1 1건 실패). 컴파일 성공.

## 케이스별 실패 메시지
- testTimeWheelSpike: TimeSelectionUITests.swift:19 XCTAssertEqual failed: ("0") is not equal to ("1")  (pickerWheels.count)
- testEntryShowsDefault25...: :184 Missing value element: time.minutesLabel
- testSixtyToOneTwenty / testMinutesWithoutCandidates / testProceedWithoutSelection / testSelectingCandidate / testChangingMinutesClears / testCandidateAndProceedExposeReadableLabels: :169 XCTAssertTrue failed - 분 휠이 없음
- testWheelBoundaries: :141 Failed to get matching snapshot: No matches found for Descendants matching type PickerWheel
- Phase1FlowTests.testDestinationRoundTripsPreserveStateAndExposeNoCompletionAction: Phase1FlowTests.swift:58 XCTAssertTrue failed (screen.time 미노출 -- "여행 준비" 버튼이 아직 screen.time을 열지 않음)
- Phase1FlowTests.testNoCompletionActionsBeyond...: 통과 (준비 행 제거 후 나머지 3개 목적지는 현행 앱에서 정상)
- 나머지 Phase1 7건 통과 (미변경)
참고: 신규 케이스는 모두 screen.time 진입(성수역 정방향 -> 확인)까지는 성공했고 시간 화면 요소가 없어 실패 -> 정상 RED.

## 참조한 파일
- ios/FocusMateUITests/Phase1FlowTests.swift, FirstStationSearchUITests.swift (스타일, 헬퍼), 디렉터리 목록(ls)
- 프로덕션 코드 미참조
