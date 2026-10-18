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

    // 깨짐: 미완성 상태에서 승차권 보기가 board로 이동한다.
    func testTappingDisabledConfirmDoesNotOpenBoardingPass() throws {
        let app = launchCardOnly()
        try openTimeScreenFromSearch(in: app)
        try selectSixtyMinutesBus2014(in: app)
        element("time.proceed", in: app).tap()
        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))

        element("preparation.confirm", in: app).tap()

        XCTAssertFalse(element("screen.board", in: app).waitForExistence(timeout: 1))
        XCTAssertTrue(element("screen.preparation", in: app).exists)
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

        // 준비(R07)는 시스템 내비 막대 대신 시트의 × 닫기로 돌아간다.
        element("preparation.close", in: app).tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
    }

    func testReturningFromPreparationKeepsSelectionAndItSurvivesLeavingToMainInSameRun() throws {
        let app = launchReady()
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        app.buttons["open.preparation"].tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.origin", in: app), "서울숲")
        try selectSixtyMinutesBus2014(in: app, routeID: "2014-r")
        element("time.proceed", in: app).tap()
        XCTAssertTrue(element("screen.preparation", in: app).waitForExistence(timeout: timeout))

        // 준비(R07)는 시스템 내비 막대 대신 시트의 × 닫기로 돌아간다.
        element("preparation.close", in: app).tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.minutesLabel", in: app), "60")
        XCTAssertTrue(element("time.candidate.2014-r", in: app).isSelected)

        element("time.back", in: app).tap()
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        app.buttons["open.preparation"].tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.minutesLabel", in: app), "60")
        XCTAssertTrue(element("time.candidate.2014-r", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("time.candidate.2014-r", in: app).isSelected)
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
            (button: "마이페이지", screen: "screen.profile"),
            (button: "open.preparation", screen: "screen.time"),
        ]
        for destination in destinations {
            app.buttons[destination.button].tap()
            XCTAssertTrue(element(destination.screen, in: app).waitForExistence(timeout: timeout))
            XCTAssertFalse(element("screen.initialStationEntry", in: app).exists)
            XCTAssertEqual(searchElements(in: app).count, 0)
            if destination.screen == "screen.time" { element("time.back", in: app).tap() }
            else { app.navigationBars.buttons.firstMatch.tap() }
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
        app.buttons["open.preparation"].tap()
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
        app.typeStationQuery("성수역")
        let origin = element("search.result.seongsu", in: app)
        XCTAssertTrue(origin.waitForExistence(timeout: timeout))
        origin.tap()
        element("search.confirm", in: app).tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
    }

    /// 후보 식별자는 노선 id다. 서울숲역 역방향 승강장(ready 시드)에서는 2014-r이다.
    private func selectSixtyMinutesBus2014(in app: XCUIApplication, routeID: String = "2014") throws {
        app.setJourneyMinutes(60, timeout: timeout)
        XCTAssertEqual(try value("time.minutesLabel", in: app), "60")
        let candidate = element("time.candidate.\(routeID)", in: app)
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
