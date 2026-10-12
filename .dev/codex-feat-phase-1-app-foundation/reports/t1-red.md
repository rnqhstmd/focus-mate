# T1 RED 보고서 — Phase 1 앱 루트·저장·화면 연결

## 깨짐 명명

- 저장 유무와 카드/최초/현재 정류장 상태를 같은 화면으로 라우팅하면 진입 분기 테스트가 실패한다.
- 기본 화면 왕복이 snapshot 또는 저장 바이트를 바꾸거나 후속 완료 동작을 노출하면 왕복 테스트가 실패한다.
- 종료 후 seed 없이 같은 UUID를 불러오지 못하면 복원 테스트가 실패한다.
- 손상·미지원 원본을 덮어쓰거나 오류를 숨기면 원본 보존 테스트가 실패한다.
- 저장 실패 뒤 candidate를 현재/영속 상태에 남기거나 성공처럼 보이면 저장 실패 테스트가 실패한다.

## 테스트 코드 전문

```swift
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
            (button: "여행 준비", screen: "screen.preparation"),
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
```

## 작성 사례

1. 새 UUID와 `none` seed: 카드 진입점과 파일 `absent`.
2. `cardOnly`: 최초 정류장 진입점과 공개 snapshot schema.
3. `ready`: 메인의 현재 서울숲/역방향, 최초 성수와 구분.
4. 네 destination 왕복: snapshot/bytes 불변, 메인 복귀, 완료 버튼 부재.
5. `ready` 종료 후 같은 UUID/no-seed 재실행 복원.
6. corrupt 정확 바이트·오류·재실행 원본 보존.
7. unsupported 정확 바이트·오류·재실행 원본 보존.
8. save fail: ready snapshot/bytes 불변, 실패 안내, 정상 재실행 복원.

## 실패 확인

- 명령: `FOCUSMATE_SIMULATOR_ID=529B88AF-5286-43EA-938A-4233F6B226CD FOCUSMATE_DERIVED_DATA=/tmp/focusmate-phase1-derived python3 scripts/check-ios.py test ios/FocusMateUITests/Phase1FlowTests.swift > /tmp/focusmate-t1-red-agent.log 2>&1`
- 빌드/테스트 로딩 성공. XCTest suite가 8개를 실행했고 8개 모두 예상 공개 UI 요소 부재 assertion으로 실패했다.
- suite 요약: `Executed 8 tests, with 8 failures (0 unexpected) in 74.384 seconds`.
- 명령 프로세스는 동일 simulator/DerivedData 상위 재실행과 겹친 뒤 exit 241로 반환됐다. 기대한 단독 실행의 exit 65는 이 실행에서 확보하지 못했으므로 상위의 독립 재실행으로 확인해야 한다. suite 자체는 compiler/runner/environment 오류 없이 8개 assertion 실패까지 완료됐다.

## 개별 실패

- `testCardOnlyOpensInitialStationEntryAndPublishesSnapshotSchema` — line 23, `XCTAssertTrue failed` (`screen.initialStationEntry`).
- `testCorruptDataReportsErrorAndPreservesExactBytesAcrossRelaunch` — line 96, `XCTAssertTrue failed` (`screen.storageError`).
- `testDestinationRoundTripsPreserveStateAndExposeNoCompletionAction` — line 45, `XCTAssertTrue failed` (`screen.main`).
- `testFailedSaveKeepsReadySnapshotAndBytesThenRestoresNormally` — line 126, `XCTAssertTrue failed` (`screen.main`).
- `testNoSavedDataOpensCardEntryWithoutCreatingAFile` — line 16, `XCTAssertTrue failed` (`screen.cardEntry`).
- `testReadyStateOpensMainWithSavedCurrentStationAndDirection` — line 34, `XCTAssertTrue failed` (`screen.main`).
- `testReadyStateRestoresAfterTerminationWithoutReseeding` — line 75, `XCTAssertTrue failed` (`screen.main`).
- `testUnsupportedDataReportsErrorAndPreservesExactBytesAcrossRelaunch` — line 112, `XCTAssertTrue failed` (`screen.storageError`).

## 실패 분류

정상 RED. 테스트 파일은 컴파일됐고 실제 앱이 실행됐으며, 현재 빈 앱에 공개 Phase 1 UI 계약이 없어 각 테스트의 첫 관찰 assertion이 실패했다. 모의 UI, production 타입 import, style/좌표/계층 snapshot 검증은 사용하지 않았다.

## 참조한 파일

- `/Users/bonseung/Documents/ChatGPT/new/.dev/codex-feat-phase-1-app-foundation/rgr-task1.md`
- `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateUITests/HarnessUITests.swift`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-tdd/references/testing-anti-patterns.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-tdd/references/frontend-testing.md`
- `/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateUITests/Phase1FlowTests.swift`

## 상위 직접 RED 검증

중복 실행은 부모가 SIGTERM으로 종료하여 exit241이었다. 같은 명령을 직렬로 다시 실행했고 verbose failure diagnostics 수집만 never로 설정했다. /tmp/focusmate-t1-red-final.log: Executed8tests/8assertionfailures/0unexpected, xcodebuild exit65. 실제8케이스 모두실패, compiler/runner오류없음. 참조파일목록에nativeproduction없음을확인했다.
