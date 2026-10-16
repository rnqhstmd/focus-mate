import Foundation
import XCTest

@MainActor
final class TimeSelectionUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let noCandidates = "이 시간에 맞는 버스가 없어요"
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

        // ±1분 규칙: 61분에도 60분 후보(차이 60초)가 남지만 선택은 즉시 해제된다. 대기 없이 확인한다.
        let remaining = element("time.candidate.2014", in: app)
        XCTAssertTrue(remaining.exists)
        XCTAssertFalse(remaining.isSelected)
        XCTAssertEqual(element("time.proceed", in: app).label, needsSelection)
        XCTAssertFalse(element("time.proceed", in: app).isEnabled)

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

        app.typeStationQuery("성수역")

        let origin = element("search.result.seongsu", in: app)
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
