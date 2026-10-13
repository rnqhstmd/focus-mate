import Foundation
import XCTest

@MainActor
final class RecoveryHistoryFlowTests: XCTestCase {
    private let timeout: TimeInterval = 3

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // 깨짐 명명: 실패한 정리 이력을 잃어 두 번째 요청/취소 뒤 원본 보존 문구를 다시 표시하거나 저장물을 바꾸면 실패.
    func test실패한정리뒤_다시요청하고취소하면_이전원본보장문구를숨기고저장물을유지한다() throws {
        let app = XCUIApplication()
        app.launchArguments = [
            "--fm-ui-test-id", UUID().uuidString,
            "--fm-ui-seed", "unsupported",
            "--fm-ui-recovery", "cleanupFail",
        ]
        app.launch()

        XCTAssertTrue(element("screen.storageError", in: app).waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["기존 데이터는 변경하지 않았어요."].exists)
        let originalBytes = try diagnosticValue("test.persistedBytes", in: app)
        let initialBackups = try backups(in: app)
        XCTAssertEqual(initialBackups, [:])

        element("storage.cleanup", in: app).tap()
        XCTAssertTrue(element("storage.cleanupConfirmation", in: app).waitForExistence(timeout: timeout))
        element("storage.confirmCleanup", in: app).tap()

        XCTAssertTrue(element("storage.recoveryFailure", in: app).waitForExistence(timeout: timeout))
        let verifiedBackups = try backups(in: app)
        XCTAssertEqual(verifiedBackups.count, initialBackups.count + 1)
        XCTAssertEqual(verifiedBackups.values.first, originalBytes)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), originalBytes)

        element("storage.cleanup", in: app).tap()
        XCTAssertTrue(element("storage.cleanupConfirmation", in: app).waitForExistence(timeout: timeout))
        element("storage.cancelCleanup", in: app).tap()

        XCTAssertFalse(app.staticTexts["기존 데이터는 변경하지 않았어요."].exists)
        XCTAssertTrue(element("storage.retry", in: app).exists)
        XCTAssertTrue(element("storage.cleanup", in: app).exists)
        XCTAssertEqual(try diagnosticValue("test.persistedBytes", in: app), originalBytes)
        XCTAssertEqual(try backups(in: app), verifiedBackups)
        XCTAssertFalse(element("screen.cardEntry", in: app).exists)
    }

    private func element(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    private func diagnosticValue(_ identifier: String, in app: XCUIApplication) throws -> String {
        let diagnostic = element(identifier, in: app)
        XCTAssertTrue(diagnostic.waitForExistence(timeout: timeout), "Missing diagnostic: \(identifier)")
        return try XCTUnwrap(diagnostic.value as? String, "Diagnostic has no string value: \(identifier)")
    }

    private func backups(in app: XCUIApplication) throws -> [String: String] {
        let raw = try diagnosticValue("test.backups", in: app)
        let data = try XCTUnwrap(raw.data(using: .utf8))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: String])
    }
}
