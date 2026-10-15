import Foundation
import XCTest

@MainActor
final class Phase1FlowTests: XCTestCase {
    private let timeout: TimeInterval = 3

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    func testNoSavedDataOpensCardEntryWithoutCreatingAFile() throws {
        let app = launch(seed: "none")

        XCTAssertTrue(element("screen.cardEntry", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), "absent")
    }

    func testCardOnlyOpensInitialStationEntryAndPublishesSnapshotSchema() throws {
        let app = launch(seed: "cardOnly")

        XCTAssertTrue(element("screen.initialStationEntry", in: app).waitForExistence(timeout: timeout))
        let snapshot = try snapshot(in: app)
        XCTAssertEqual(snapshot["cardIssued"] as? Bool, true)
        XCTAssertTrue(snapshot["initialStation"] is NSNull)
        XCTAssertTrue(snapshot["currentStation"] is NSNull)
        XCTAssertNotEqual(try diagnosticValue("test.persistedBytes", in: app), "absent")
    }

    func testReadyStateOpensMainWithSavedCurrentStationAndDirection() throws {
        let app = launch(seed: "ready")

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("main.currentStation", in: app), "서울숲")
        XCTAssertEqual(try value("main.direction", in: app), "역방향")

        let snapshot = try snapshot(in: app)
        try assertStation(snapshot["initialStation"], id: "seongsu", name: "성수", direction: 1)
        try assertStation(snapshot["currentStation"], id: "seoulForest", name: "서울숲", direction: -1)
    }

    func testDestinationRoundTripsPreserveStateAndExposeNoCompletionAction() throws {
        let app = launch(seed: "ready")
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))

        let initialSnapshot = try diagnosticValue("test.snapshot", in: app)
        let initialBytes = try diagnosticValue("test.persistedBytes", in: app)
        let destinations = [
            (button: "open.preparation", screen: "screen.time"),
            (button: "기록", screen: "screen.records"),
            (button: "설정", screen: "screen.settings"),
            (button: "마이페이지", screen: "screen.profile"),
        ]

        for destination in destinations {
            app.buttons[destination.button].tap()
            XCTAssertTrue(element(destination.screen, in: app).waitForExistence(timeout: timeout))
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "완료")).count, 0)
            XCTAssertEqual(try diagnosticValue("test.snapshot", in: app), initialSnapshot)
            XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), initialBytes)

            let backButton = app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: timeout))
            backButton.tap()
            XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
            XCTAssertEqual(try value("main.currentStation", in: app), "서울숲")
            XCTAssertEqual(try value("main.direction", in: app), "역방향")
        }
    }

    func testReadyStateRestoresAfterTerminationWithoutReseeding() throws {
        let testID = UUID()
        let app = launch(testID: testID, seed: "ready")
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        let before = try snapshot(in: app)

        app.terminate()
        relaunch(app, testID: testID)

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("main.currentStation", in: app), "서울숲")
        XCTAssertEqual(try value("main.direction", in: app), "역방향")
        let restored = try snapshot(in: app)
        XCTAssertEqual(restored["cardIssued"] as? Bool, true)
        try assertStation(restored["initialStation"], id: "seongsu", name: "성수", direction: 1)
        try assertStation(restored["currentStation"], id: "seoulForest", name: "서울숲", direction: -1)
        XCTAssertEqual(try jsonData(restored), try jsonData(before))
    }

    func testCorruptDataReportsErrorAndPreservesExactBytesAcrossRelaunch() throws {
        let testID = UUID()
        let app = launch(testID: testID, seed: "corrupt")
        let expectedBytes = Data("{broken".utf8).base64EncodedString()

        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["저장된 데이터 형식을 읽을 수 없어요."].exists)
        XCTAssertTrue(app.staticTexts["기존 데이터는 변경하지 않았어요."].exists)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), expectedBytes)

        app.terminate()
        relaunch(app, testID: testID)
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), expectedBytes)
    }

    func testUnsupportedDataReportsErrorAndPreservesExactBytesAcrossRelaunch() throws {
        let testID = UUID()
        let app = launch(testID: testID, seed: "unsupported")
        let expectedBytes = Data(#"{"version":999,"state":null}"#.utf8).base64EncodedString()

        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["이 버전의 앱에서 열 수 없는 데이터예요."].exists)
        XCTAssertTrue(app.staticTexts["기존 데이터는 변경하지 않았어요."].exists)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), expectedBytes)

        app.terminate()
        relaunch(app, testID: testID)
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), expectedBytes)
    }

    func testFailedSaveKeepsReadySnapshotAndBytesThenRestoresNormally() throws {
        let testID = UUID()
        let app = launch(testID: testID, seed: "ready")
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        let readySnapshot = try diagnosticValue("test.snapshot", in: app)
        let readyBytes = try diagnosticValue("test.persistedBytes", in: app)

        app.terminate()
        launch(app, testID: testID, save: "fail")

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("storage.saveFailure", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["저장에 실패했어요. 변경 내용의 재실행 복원을 보장할 수 없어요."].exists)
        XCTAssertEqual(try diagnosticValue("test.snapshot", in: app), readySnapshot)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), readyBytes)

        app.terminate()
        relaunch(app, testID: testID)
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try diagnosticValue("test.snapshot", in: app), readySnapshot)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), readyBytes)
        XCTAssertEqual(try value("main.currentStation", in: app), "서울숲")
        XCTAssertEqual(try value("main.direction", in: app), "역방향")
    }

    func testMalformedTestIDReportsSetupErrorAndStaysLoading() {
        let app = XCUIApplication()
        app.launchArguments = ["--fm-ui-test-id", "not-a-uuid"]
        app.launch()

        XCTAssertTrue(element("test.setupError", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("screen.loading", in: app).exists)
        XCTAssertFalse(element("screen.cardEntry", in: app).exists)
        XCTAssertFalse(element("screen.initialStationEntry", in: app).exists)
        XCTAssertFalse(element("screen.main", in: app).exists)
        XCTAssertFalse(element("screen.storageError", in: app).exists)
    }

    func testNoCompletionActionsBeyondNavigationButtonsInDefaultDestinations() {
        let app = launch(seed: "ready")
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))

        let destinations = [
            (button: "기록", screen: "screen.records"),
            (button: "설정", screen: "screen.settings"),
        ]

        for destination in destinations {
            app.buttons[destination.button].tap()
            XCTAssertTrue(element(destination.screen, in: app).waitForExistence(timeout: timeout))

            let navigationBar = app.navigationBars.firstMatch
            XCTAssertTrue(navigationBar.waitForExistence(timeout: timeout))
            XCTAssertEqual(navigationBar.buttons.count, 1)
            XCTAssertEqual(app.buttons.count, navigationBar.buttons.count)

            let backButton = navigationBar.buttons.firstMatch
            XCTAssertTrue(backButton.exists)
            backButton.tap()
            XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        }
    }

    private func launch(testID: UUID = UUID(), seed: String) -> XCUIApplication {
        let app = XCUIApplication()
        launch(app, testID: testID, seed: seed)
        return app
    }

    private func launch(
        _ app: XCUIApplication,
        testID: UUID,
        seed: String? = nil,
        save: String? = nil
    ) {
        var arguments = ["--fm-ui-test-id", testID.uuidString]
        if let seed {
            arguments += ["--fm-ui-seed", seed]
        }
        if let save {
            arguments += ["--fm-ui-save", save]
        }
        app.launchArguments = arguments
        app.launch()
    }

    private func relaunch(_ app: XCUIApplication, testID: UUID) {
        app.launchArguments = ["--fm-ui-test-id", testID.uuidString]
        app.launch()
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

    private func jsonData(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}
