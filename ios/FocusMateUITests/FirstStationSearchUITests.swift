import Foundation
import XCTest

@MainActor
final class FirstStationSearchUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testInitialSearchScreenShowsAllThreeResultsAndDisabledConfirm() throws {
        let app = launch()

        XCTAssertTrue(element("screen.initialStationEntry", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("search.query", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("search.result.seongsu:1", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(resultButtons(in: app).count, 3)
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.exists)
        XCTAssertFalse(confirm.isEnabled)
    }

    func testQueryNarrowsResultsByStationNameAndByDirectionName() throws {
        let app = launch()
        let query = try searchField(in: app)

        query.tap()
        query.typeText("성수")
        XCTAssertTrue(element("search.result.seongsu:1", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(resultButtons(in: app).count, 3)

        query.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 2))
        query.typeText("건대")
        XCTAssertTrue(element("search.result.seongsu:-1", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(resultButtons(in: app).count, 1)
    }

    func testQueryWithSurroundingWhitespaceStillMatchesTrimmedText() throws {
        let app = launch()
        let query = try searchField(in: app)

        query.tap()
        query.typeText("  성수사거리  ")

        XCTAssertTrue(element("search.result.seongsu:-1", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(resultButtons(in: app).count, 1)
    }

    func testNoMatchShowsEmptyMessageAndConfirmCannotSaveAnything() throws {
        let app = launch()
        let query = try searchField(in: app)
        let before = try diagnosticValue("test.persistedBytes", in: app)

        query.tap()
        query.typeText("없는역")

        let empty = element("search.empty", in: app)
        XCTAssertTrue(empty.waitForExistence(timeout: timeout))
        XCTAssertEqual(empty.label, "결과가 없어요")
        XCTAssertEqual(resultButtons(in: app).count, 0)
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.exists)
        XCTAssertFalse(confirm.isEnabled)

        confirm.tap()
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), before)
        XCTAssertTrue(element("screen.initialStationEntry", in: app).exists)
    }

    func testSelectingResultShowsConfirmationMarksSelectedAndEnablesConfirm() throws {
        let app = launch()
        let result = element("search.result.seongsu:-1", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        XCTAssertFalse(element("search.confirmation", in: app).exists)

        result.tap()

        let confirmation = element("search.confirmation", in: app)
        XCTAssertTrue(confirmation.waitForExistence(timeout: timeout))
        XCTAssertEqual(confirmation.label, "성수역 · 성수사거리 방면에서 출발")
        XCTAssertTrue(result.isSelected)
        XCTAssertTrue(element("search.confirm", in: app).isEnabled)
    }

    func testKeyboardPathSearchSelectConfirmOpensTimeScreenWithSavedStation() throws {
        let app = launch()
        let query = try searchField(in: app)

        query.tap()
        query.typeText("건대")
        let result = element("search.result.seongsu:-1", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        result.tap()
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.origin", in: app), "성수역")
        XCTAssertFalse(element("screen.initialStationEntry", in: app).exists)
        let snapshot = try snapshot(in: app)
        try assertStation(snapshot["initialStation"], id: "seongsu", name: "성수역", direction: -1)
        try assertStation(snapshot["currentStation"], id: "seongsu", name: "성수역", direction: -1)
    }

    func testBackFromTimeScreenReturnsToMain() throws {
        let app = launch()
        let result = element("search.result.seongsu:-1", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        result.tap()
        element("search.confirm", in: app).tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: timeout))
        backButton.tap()

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
    }

    private func launch() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--fm-ui-test-id", UUID().uuidString, "--fm-ui-seed", "cardOnly"]
        app.launch()
        return app
    }

    private func searchField(in app: XCUIApplication) throws -> XCUIElement {
        let field = element("search.query", in: app)
        XCTAssertTrue(field.waitForExistence(timeout: timeout), "Missing search field")
        return field
    }

    private func resultButtons(in app: XCUIApplication) -> XCUIElementQuery {
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "search.result."))
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
        let raw = try diagnosticValue("test.snapshot", in: app)
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }

    private func assertStation(
        _ rawStation: Any?,
        id: String,
        name: String,
        direction: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let station = try XCTUnwrap(rawStation as? [String: Any], file: file, line: line)
        XCTAssertEqual(station["id"] as? String, id, file: file, line: line)
        XCTAssertEqual(station["name"] as? String, name, file: file, line: line)
        XCTAssertEqual(station["direction"] as? Int, direction, file: file, line: line)
    }
}
