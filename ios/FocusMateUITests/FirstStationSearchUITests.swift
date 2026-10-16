import Foundation
import XCTest

@MainActor
final class FirstStationSearchUITests: XCTestCase {
    private let timeout: TimeInterval = 5

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐(AC-6): 검색어가 비어 있는데 결과를 나열하거나 안내 문구가 사라진다.
    func testInitialSearchScreenShowsPromptWithoutResultsAndDisabledConfirm() throws {
        let app = launch()

        XCTAssertTrue(element("screen.initialStationEntry", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("search.query", in: app).waitForExistence(timeout: timeout))
        let prompt = element("search.prompt", in: app)
        XCTAssertTrue(prompt.waitForExistence(timeout: timeout))
        XCTAssertEqual(prompt.label, "정류장 이름이나 번호를 입력하세요")
        XCTAssertEqual(resultButtons(in: app).count, 0)
        XCTAssertFalse(element("search.resetNotice", in: app).exists)
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.exists)
        XCTAssertFalse(confirm.isEnabled)
    }

    // 깨짐: 이름 부분 일치 검색이 좁혀지지 않거나 같은 이름의 양방향 승강장이 하나로 합쳐진다.
    // 픽스처: "성수"가 들어간 정류장 4곳 x 양방향 = 8건, "성수역"은 2건(seongsu, seongsu-r).
    func testQueryNarrowsResultsFromPartialNameToFullName() throws {
        let app = launch()
        let query = try searchField(in: app)

        query.tap()
        query.typeText("성수")
        XCTAssertTrue(element("search.result.seongsu", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(resultButtons(in: app).count, 8)

        query.typeText("역")
        XCTAssertTrue(element("search.result.seongsu-r", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(resultButtons(in: app).count, 2)
    }

    func testQueryWithSurroundingWhitespaceStillMatchesTrimmedText() throws {
        let app = launch()
        let query = try searchField(in: app)

        query.tap()
        query.typeText("  성수사거리  ")

        XCTAssertTrue(element("search.result.seongsuIntersection-r", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(resultButtons(in: app).count, 2)
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
        let query = try searchField(in: app)
        query.tap()
        query.typeText("성수역")
        let result = element("search.result.seongsu-r", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        XCTAssertEqual(result.label, "성수역, 성수사거리 방면")
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
        query.typeText("성수역")
        let result = element("search.result.seongsu-r", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        result.tap()
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()

        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("time.origin", in: app), "성수역")
        XCTAssertFalse(element("screen.initialStationEntry", in: app).exists)
        let snapshot = try snapshot(in: app)
        try assertStation(snapshot["initialStation"], id: "seongsu-r", name: "성수역")
        try assertStation(snapshot["currentStation"], id: "seongsu-r", name: "성수역")
    }

    func testBackFromTimeScreenReturnsToMain() throws {
        let app = launch()
        let query = try searchField(in: app)
        query.tap()
        query.typeText("성수역")
        let result = element("search.result.seongsu-r", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        result.tap()
        element("search.confirm", in: app).tap()
        XCTAssertTrue(element("screen.time", in: app).waitForExistence(timeout: timeout))

        let backButton = app.navigationBars.buttons.firstMatch
        XCTAssertTrue(backButton.waitForExistence(timeout: timeout))
        backButton.tap()

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
    }

    // 깨짐(AC-12): 번호가 없는 정류장 행에 빈 번호가 붙거나 낭독 문구가 "이름, 방면"이 아니게 된다.
    func testStopWithoutNumberReadsOnlyNameAndBound() throws {
        let app = launch()
        let query = try searchField(in: app)

        query.tap()
        query.typeText("무번호")

        let result = element("search.result.S11", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        XCTAssertEqual(resultButtons(in: app).count, 1)
        XCTAssertEqual(result.label, "무번호정류장, 델타 방면")
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let station = try XCTUnwrap(rawStation as? [String: Any], file: file, line: line)
        XCTAssertEqual(station["id"] as? String, id, file: file, line: line)
        XCTAssertEqual(station["name"] as? String, name, file: file, line: line)
        XCTAssertNil(station["direction"], file: file, line: line)
    }
}
