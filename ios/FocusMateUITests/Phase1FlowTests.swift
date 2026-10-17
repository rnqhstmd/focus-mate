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

    func testReadyStateOpensMainWithSavedCurrentStationAndBound() throws {
        let app = launch(seed: "ready")

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("main.currentStation", in: app), "서울숲")
        XCTAssertTrue(app.waitForBound("성동구민체육센터 방면"), "main.bound 값이 채워지지 않음")

        let snapshot = try snapshot(in: app)
        try assertStation(snapshot["initialStation"], id: "seongsu", name: "성수")
        try assertStation(snapshot["currentStation"], id: "seoulForest-r", name: "서울숲")
    }

    func testDestinationRoundTripsPreserveStateAndExposeNoCompletionAction() throws {
        let app = launch(seed: "ready")
        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))

        let initialSnapshot = try diagnosticValue("test.snapshot", in: app)
        let initialBytes = try diagnosticValue("test.persistedBytes", in: app)
        // 시안 R01: 메인 도구는 기록·마이페이지 2개다. 설정은 마이페이지 안에서 연다(ProfileUITests).
        let destinations = [
            (button: "open.preparation", screen: "screen.time"),
            (button: "기록", screen: "screen.records"),
            (button: "마이페이지", screen: "screen.profile"),
        ]

        for destination in destinations {
            app.buttons[destination.button].tap()
            XCTAssertTrue(element(destination.screen, in: app).waitForExistence(timeout: timeout))
            XCTAssertEqual(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "완료")).count, 0)
            XCTAssertEqual(try diagnosticValue("test.snapshot", in: app), initialSnapshot)
            XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), initialBytes)

            // 시간 화면(R04)은 시스템 내비 막대 대신 패널 안 뒤로 버튼을 쓴다.
            let backButton = destination.screen == "screen.time"
                ? element("time.back", in: app) : app.navigationBars.buttons.firstMatch
            XCTAssertTrue(backButton.waitForExistence(timeout: timeout))
            backButton.tap()
            XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
            XCTAssertEqual(try value("main.currentStation", in: app), "서울숲")
            XCTAssertTrue(app.waitForBound("성동구민체육센터 방면"), "main.bound 값이 채워지지 않음")
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
        XCTAssertTrue(app.waitForBound("성동구민체육센터 방면"), "main.bound 값이 채워지지 않음")
        let restored = try snapshot(in: app)
        XCTAssertEqual(restored["cardIssued"] as? Bool, true)
        try assertStation(restored["initialStation"], id: "seongsu", name: "성수")
        try assertStation(restored["currentStation"], id: "seoulForest-r", name: "서울숲")
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
        XCTAssertTrue(app.waitForBound("성동구민체육센터 방면"), "main.bound 값이 채워지지 않음")
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

        // 기록은 W09a에서 실제 화면(연도 이동·잔디·목록)이 되어 진입·복귀만 확인한다.
        // 설정은 시안 R01에서 메인 도구가 아니라 마이페이지 안에서 연다.
        let destinations = [
            (button: "기록", screen: "screen.records", placeholder: false),
            (button: "profile.settings", screen: "screen.settings", placeholder: true),
        ]

        for destination in destinations {
            if destination.button == "profile.settings" {
                app.buttons["마이페이지"].tap()
                XCTAssertTrue(element("screen.profile", in: app).waitForExistence(timeout: timeout))
                let settings = element("profile.settings", in: app)
                XCTAssertTrue(settings.waitForExistence(timeout: timeout))
                var swipes = 0
                while !settings.isHittable && swipes < 3 { app.swipeUp(); swipes += 1 }
                settings.tap()
            } else {
                app.buttons[destination.button].tap()
            }
            XCTAssertTrue(element(destination.screen, in: app).waitForExistence(timeout: timeout))

            let navigationBar = app.navigationBars.firstMatch
            XCTAssertTrue(navigationBar.waitForExistence(timeout: timeout))
            XCTAssertEqual(navigationBar.buttons.count, 1)
            if destination.placeholder {
                XCTAssertEqual(app.buttons.count, navigationBar.buttons.count)
            }

            let backButton = navigationBar.buttons.firstMatch
            XCTAssertTrue(backButton.exists)
            backButton.tap()
            if destination.button == "profile.settings" {
                XCTAssertTrue(element("screen.profile", in: app).waitForExistence(timeout: timeout))
                app.navigationBars.buttons.firstMatch.tap()
            }
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
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        let station = try XCTUnwrap(rawStation as? [String: Any], file: file, line: line)
        XCTAssertEqual(station["id"] as? String, id, file: file, line: line)
        XCTAssertEqual(station["name"] as? String, name, file: file, line: line)
        XCTAssertNil(station["direction"], file: file, line: line)
    }

    private func jsonData(_ object: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }
}
