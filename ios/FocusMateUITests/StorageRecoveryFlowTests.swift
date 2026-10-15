import Foundation
import UIKit
import XCTest

@MainActor
final class StorageRecoveryFlowTests: XCTestCase {
    private let timeout: TimeInterval = 3

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐 명명: 오류 종류를 한 문구로 뭉개거나 복구 버튼을 누락하거나 화면 진입만으로 자동 정리하면 실패.
    func testEveryStartupFailureShowsItsCauseAndTwoExplicitRecoveryChoicesWithoutChangingBytes() throws {
        let cases = [
            (seed: "corrupt", recovery: nil, message: "저장된 데이터 형식을 읽을 수 없어요."),
            (seed: "unsupported", recovery: nil, message: "이 버전의 앱에서 열 수 없는 데이터예요."),
            (seed: "invalidState", recovery: nil, message: "저장된 데이터 내용이 현재 단계와 맞지 않아요."),
            (seed: "corrupt", recovery: "readAlways", message: "저장된 데이터를 읽을 수 없어요."),
        ]

        for item in cases {
            let app = launch(seed: item.seed, recovery: item.recovery)
            XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
            XCTAssertTrue(app.staticTexts[item.message].exists)
            XCTAssertTrue(element("storage.retry", in: app).exists)
            XCTAssertTrue(element("storage.cleanup", in: app).exists)
            let bytes = try diagnosticValue("test.persistedBytes", in: app)
            XCTAssertNotEqual(bytes, "absent")
            XCTAssertEqual(try backups(in: app), [:])
            XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), bytes)
            app.terminate()
        }
    }

    // 깨짐 명명: 실패한 재시도가 화면을 이탈하거나 원본/백업을 바꾸거나 재시도 버튼을 제거하면 실패.
    func testRetryFailureStaysRecoverableAndDoesNotChangeCorruptData() throws {
        let app = launch(seed: "corrupt", recovery: "readAlways")
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        let original = try diagnosticValue("test.persistedBytes", in: app)

        element("storage.retry", in: app).tap()

        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["저장된 데이터를 읽을 수 없어요."].exists)
        XCTAssertTrue(element("storage.retry", in: app).exists)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), original)
        XCTAssertEqual(try backups(in: app), [:])
    }

    // 깨짐 명명: readOnce 재시도가 준비된 저장 상태 대신 빈 화면으로 가거나 재시도 과정에서 원본을 다시 쓰면 실패.
    func testReadOnceRetryRestoresMainFromTheOriginalReadyBytes() throws {
        let app = launch(seed: "ready", recovery: "readOnce")
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        let original = try diagnosticValue("test.persistedBytes", in: app)

        element("storage.retry", in: app).tap()

        XCTAssertTrue(element("screen.main", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try value("main.currentStation", in: app), "서울숲")
        XCTAssertTrue(app.waitForBound("성동구민체육센터 방면"), "main.bound 값이 채워지지 않음")
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), original)
        XCTAssertEqual(try backups(in: app), [:])
    }

    // 깨짐 명명: 정리 요청이 확인 없이 즉시 삭제하거나 취소가 백업/첫 시작 전환을 수행하면 실패.
    func testCleanupCancellationReturnsToErrorAndCreatesNoBackup() throws {
        let app = launch(seed: "corrupt")
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        let original = try diagnosticValue("test.persistedBytes", in: app)

        element("storage.cleanup", in: app).tap()
        XCTAssertTrue(element("storage.cleanupConfirmation", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["카드, 여행, 기록 데이터가 초기화돼요."].exists)
        XCTAssertTrue(app.staticTexts["같은 원본을 앱 내부에 보존한 뒤 정리해요."].exists)
        element("storage.cancelCleanup", in: app).tap()

        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), original)
        XCTAssertEqual(try backups(in: app), [:])
        XCTAssertFalse(element("screen.cardEntry", in: app).exists)
    }

    // 깨짐 명명: 성공 정리가 다른 바이트를 백업하거나 활성 파일을 남기거나 재실행에서 오류를 되살리면 실패.
    func testConfirmedCleanupBacksUpExactBytesAndRelaunchesAtCardEntryForBothDecodableErrors() throws {
        for seed in ["corrupt", "unsupported"] {
            let testID = UUID()
            let app = launch(testID: testID, seed: seed)
            XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
            let original = try diagnosticValue("test.persistedBytes", in: app)

            confirmCleanup(in: app)

            XCTAssertTrue(element("screen.cardEntry", in: app).waitForExistence(timeout: timeout))
            XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), "absent")
            let savedBackups = try backups(in: app)
            XCTAssertEqual(savedBackups.count, 1)
            XCTAssertEqual(savedBackups.values.first, original)

            app.terminate()
            relaunch(app, testID: testID)
            XCTAssertTrue(element("screen.cardEntry", in: app).waitForExistence(timeout: timeout))
            XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), "absent")
            XCTAssertEqual(try backups(in: app), savedBackups)
            app.terminate()
        }
    }

    // 깨짐 명명: 읽기/백업 실패를 정리 성공으로 표시하거나 활성 원본을 지우거나 복구 선택지를 잃으면 실패.
    func testPreservationFailuresStayOnErrorAndKeepOriginalData() throws {
        for recovery in ["backupFail", "readAlways"] {
            let app = launch(seed: "corrupt", recovery: recovery)
            XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
            let original = try diagnosticValue("test.persistedBytes", in: app)

            confirmCleanup(in: app)

            XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
            XCTAssertTrue(element("storage.recoveryFailure", in: app).exists)
            XCTAssertTrue(app.staticTexts["원본을 보존하지 못해 저장 데이터 정리를 완료하지 못했어요."].exists)
            XCTAssertTrue(element("storage.retry", in: app).exists)
            XCTAssertTrue(element("storage.cleanup", in: app).exists)
            XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), original)
            XCTAssertFalse(element("screen.cardEntry", in: app).exists)
            app.terminate()
        }
    }

    // 깨짐 명명: 다른 바이트의 백업을 동일하다고 승인해 활성 원본을 삭제하거나 첫 시작으로 이동하면 실패.
    func testBackupMismatchBlocksCleanupAndPreservesTheActiveOriginal() throws {
        let app = launch(seed: "corrupt", recovery: "backupMismatch")
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        let original = try diagnosticValue("test.persistedBytes", in: app)

        confirmCleanup(in: app)

        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("storage.recoveryFailure", in: app).exists)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), original)
        let savedBackups = try backups(in: app)
        XCTAssertEqual(savedBackups.count, 1)
        XCTAssertNotEqual(savedBackups.values.first, original)
        XCTAssertFalse(element("screen.cardEntry", in: app).exists)
    }

    // 깨짐 명명: 검증 백업 뒤 정리 실패를 성공 처리하거나 정확한 백업을 버리거나 원본을 바꾸면 실패.
    func testCleanupFailureRetainsVerifiedBackupAndTheErrorScreen() throws {
        let app = launch(seed: "unsupported", recovery: "cleanupFail")
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        let original = try diagnosticValue("test.persistedBytes", in: app)

        confirmCleanup(in: app)

        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(element("storage.recoveryFailure", in: app).exists)
        XCTAssertTrue(app.staticTexts["원본을 내부에 보존했지만 저장 데이터 정리 완료를 확인하지 못했어요."].exists)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), original)
        let savedBackups = try backups(in: app)
        XCTAssertEqual(savedBackups.count, 1)
        XCTAssertEqual(savedBackups.values.first, original)
        XCTAssertFalse(element("screen.cardEntry", in: app).exists)
    }

    // 깨짐 명명: 접근성 XXXL 주입이 적용되지 않거나 ScrollView가 없거나 확인/취소 버튼이 탭 불가능하면 실패.
    func testAccessibilityExtraExtraExtraLargeCanScrollToBothConfirmationActions() throws {
        let app = launch(
            seed: "corrupt",
            extraArguments: [
                "-UIPreferredContentSizeCategoryName",
                UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue,
            ]
        )
        XCTAssertEqual(try diagnosticValue("test.dynamicTypeSize", in: app), "accessibility5")
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        element("storage.cleanup", in: app).tap()
        XCTAssertTrue(element("storage.cleanupConfirmation", in: app).waitForExistence(timeout: timeout))

        let cancel = element("storage.cancelCleanup", in: app)
        XCTAssertTrue(scrollToHittable(cancel, in: app))
        cancel.tap()
        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))

        element("storage.cleanup", in: app).tap()
        let confirm = element("storage.confirmCleanup", in: app)
        XCTAssertTrue(scrollToHittable(confirm, in: app))
        confirm.tap()
        XCTAssertTrue(element("screen.cardEntry", in: app).waitForExistence(timeout: timeout))
    }

    private func confirmCleanup(in app: XCUIApplication) {
        element("storage.cleanup", in: app).tap()
        XCTAssertTrue(element("storage.cleanupConfirmation", in: app).waitForExistence(timeout: timeout))
        element("storage.confirmCleanup", in: app).tap()
    }

    private func launch(
        testID: UUID = UUID(),
        seed: String,
        recovery: String? = nil,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        var arguments = ["--fm-ui-test-id", testID.uuidString, "--fm-ui-seed", seed]
        if let recovery {
            arguments += ["--fm-ui-recovery", recovery]
        }
        arguments += extraArguments
        app.launchArguments = arguments
        app.launch()
        return app
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

    private func backups(in app: XCUIApplication) throws -> [String: String] {
        let raw = try diagnosticValue("test.backups", in: app)
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
    }

    private func scrollToHittable(_ target: XCUIElement, in app: XCUIApplication) -> Bool {
        for _ in 0..<8 {
            if target.exists, target.isHittable { return true }
            app.swipeUp()
        }
        return target.exists && target.isHittable
    }
}
