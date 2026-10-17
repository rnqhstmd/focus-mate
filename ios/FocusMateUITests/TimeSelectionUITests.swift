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

    func testTimeRulerAdjustmentSpike() throws {
        let app = try openTimeScreen()

        XCTAssertEqual(app.sliders.matching(identifier: "time.ruler").count, 1)
        let ruler = app.sliders["time.ruler"]
        XCTAssertTrue(ruler.waitForExistence(timeout: 3))
        XCTAssertEqual(ruler.value as? String, "25분")
        XCTAssertEqual(try value("time.minutesLabel", in: app), "25")

        for target in ["360", "15"] {
            let started = Date()
            app.setJourneyMinutes(Int(target)!, timeout: timeout)
            XCTAssertLessThan(Date().timeIntervalSince(started), 60, "\(target)분 물리 드래그 이동이 60초를 넘김")
            XCTAssertEqual(ruler.value as? String, "\(target)분")
            XCTAssertEqual(try value("time.minutesLabel", in: app), target)
        }

        try setMinutes(60, in: app)
        app.setJourneyMinutes(61, timeout: timeout)
        XCTAssertEqual(ruler.value as? String, "61분")
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

        app.setJourneyMinutes(61, timeout: timeout)

        // ±1분 규칙: 61분에도 60분 후보(차이 60초)가 남지만 선택은 즉시 해제된다. 대기 없이 확인한다.
        let remaining = element("time.candidate.2014", in: app)
        XCTAssertTrue(remaining.exists)
        XCTAssertFalse(remaining.isSelected)
        XCTAssertEqual(element("time.proceed", in: app).label, needsSelection)
        XCTAssertFalse(element("time.proceed", in: app).isEnabled)

        app.setJourneyMinutes(60, timeout: timeout)
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

    func testRulerBoundariesReportFifteenAndThreeSixtyMinutes() throws {
        let app = try openTimeScreen()
        let ruler = app.sliders["time.ruler"]

        app.setJourneyMinutes(15, timeout: timeout)
        app.setJourneyMinutes(15, timeout: timeout)
        XCTAssertEqual(try value("time.minutesLabel", in: app), "15")
        XCTAssertEqual(ruler.value as? String, "15분")

        app.setJourneyMinutes(360, timeout: timeout)
        app.setJourneyMinutes(360, timeout: timeout)
        XCTAssertEqual(try value("time.minutesLabel", in: app), "360")
        XCTAssertEqual(ruler.value as? String, "360분")
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
        app.setJourneyMinutes(minutes, timeout: timeout)
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
