import Foundation
import XCTest

@MainActor
final class StationSaveFailureUITests: XCTestCase {
    private let timeout: TimeInterval = 5
    private let searchFailureMessage = "출발 정류장 저장에 실패했어요. 확인을 다시 눌러 주세요."

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testConfirmWithWriteFailureKeepsSearchScreenAndShowsSearchSaveFailure() throws {
        let app = launch(seed: "cardOnly", save: "fail")
        XCTAssertFalse(element("test.setupError", in: app).waitForExistence(timeout: 2))
        app.typeStationQuery("성수역")
        let result = element("search.result.seongsu-r", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        result.tap()
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        let bytesBefore = try diagnosticValue("test.persistedBytes", in: app)

        confirm.tap()

        let failure = element("search.saveFailure", in: app)
        XCTAssertTrue(failure.waitForExistence(timeout: timeout))
        XCTAssertEqual(failure.label, searchFailureMessage)
        XCTAssertTrue(failure.label.contains("저장에 실패했어요"))
        XCTAssertFalse(element("test.setupError", in: app).exists)
        XCTAssertTrue(element("screen.initialStationEntry", in: app).exists)
        XCTAssertFalse(element("screen.time", in: app).waitForExistence(timeout: 1))
        XCTAssertFalse(element("storage.saveFailure", in: app).exists)

        let snapshot = try snapshot(in: app)
        XCTAssertTrue(snapshot["initialStation"] is NSNull)
        XCTAssertTrue(snapshot["currentStation"] is NSNull)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), bytesBefore)
    }

    func testConfirmStaysEnabledAndRetryKeepsSameFailureState() throws {
        let app = launch(seed: "cardOnly", save: "fail")
        app.typeStationQuery("성수역")
        let result = element("search.result.seongsu-r", in: app)
        XCTAssertTrue(result.waitForExistence(timeout: timeout))
        result.tap()
        let confirm = element("search.confirm", in: app)
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        let bytesBefore = try diagnosticValue("test.persistedBytes", in: app)
        confirm.tap()
        XCTAssertTrue(element("search.saveFailure", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(confirm.isEnabled)

        confirm.tap()

        XCTAssertTrue(element("search.saveFailure", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(element("search.saveFailure", in: app).label, searchFailureMessage)
        XCTAssertTrue(element("screen.initialStationEntry", in: app).exists)
        XCTAssertFalse(element("screen.time", in: app).waitForExistence(timeout: 1))
        XCTAssertFalse(element("storage.saveFailure", in: app).exists)
        XCTAssertTrue(confirm.isEnabled)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), bytesBefore)
    }

    // 기존 동작 회귀 가드(현재 통과 가능): 메인에서는 공용 storage.saveFailure가 보인다.
    func testReadySeedWithWriteFailureShowsStorageSaveFailureOnMain() throws {
        let app = launch(seed: "ready", save: "fail")

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("storage.saveFailure", in: app).waitForExistence(timeout: timeout))
    }

    private func launch(seed: String, save: String) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "--fm-ui-test-id", UUID().uuidString,
            "--fm-ui-seed", seed,
            "--fm-ui-save", save,
        ]
        app.launch()
        return app
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func diagnosticValue(_ identifier: String, in app: XCUIApplication) throws -> String {
        let diagnostic = element(identifier, in: app)
        XCTAssertTrue(diagnostic.waitForExistence(timeout: timeout), "Missing diagnostic: \(identifier)")
        return try XCTUnwrap(diagnostic.value as? String, "Diagnostic has no string value: \(identifier)")
    }

    private func snapshot(in app: XCUIApplication) throws -> [String: Any] {
        let raw = try diagnosticValue("test.snapshot", in: app)
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
    }
}
