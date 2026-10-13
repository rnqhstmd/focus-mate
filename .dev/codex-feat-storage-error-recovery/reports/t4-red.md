# T4 RED author report

## Status

- Status: DONE
- Role: RED author only
- Production source read: no
- Production source written: no
- Tests executed: no (task override explicitly prohibited test execution)
- Expected RED boundary: `AppModel.hasAttemptedCleanup` is a required new API. Until the root declaration bridge exists, the unit target may fail to compile at those references. After the bridge, the assertions break implementations that erase valid cleanup-attempt history, record guarded confirms, or restore the old UI guarantee after a destructive attempt.

## Test files and hashes

- `ios/FocusMateTests/RecoveryHistoryTests.swift`
  - SHA-256: `d556b0648fd230039df8a359fa736f91959ddaec19722f9c6e2afae5c8ccb43e`
- `ios/FocusMateUITests/RecoveryHistoryFlowTests.swift`
  - SHA-256: `0c2341c5d96c1dc984ff26de5ce61603fd67053e494ad6fa9906eefd6ece8c5f`

## Why these tests break

1. The first unit test catches a missing/false-reset `hasAttemptedCleanup`, incorrect success after deletion verification becomes unreadable, loss or corruption of the exact backup, failure to clear the stale recovery failure on a new request, and history reset by request/cancel/failed retry.
2. The second unit test catches guarded confirms that mark an attempt or perform read/remove/backup work while loading, ready, or failed without a valid confirmation request.
3. The UI test catches reappearance of the old blanket “original unchanged” guarantee after a cleanup attempt that already created a verified backup and crossed the deletion boundary. It also catches mutation of the active bytes or verified backup during the second request/cancel and navigation to card entry.

## Failure confirmation

- Command: not run by explicit task override.
- Failure message: not captured by explicit task override.
- Expected initial failure: missing `AppModel.hasAttemptedCleanup` member until the root declaration bridge; otherwise behavioral assertion failures in the history/UI behavior above.

## Full test text: `ios/FocusMateTests/RecoveryHistoryTests.swift`

```swift
import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class RecoveryHistoryTests: XCTestCase {
    private static let backupUUID = UUID(uuidString: "12345678-90AB-CDEF-1234-567890ABCDEF")!
    private static let corruptBytes = Data("bad".utf8)

    // 깨짐 명명: 유효한 정리 확인 이력을 실패 결과나 다음 request/cancel/retry가 false로 되돌리면 실패.
    func test정리시도이력은_삭제후확인실패와_다음복구동작뒤에도유지된다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL)
            var didRemoveActiveFile = false
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { url in
                    if url == fileURL, didRemoveActiveFile {
                        throw CocoaError(.fileReadNoPermission)
                    }
                    return try Data(contentsOf: url)
                },
                backupID: { Self.backupUUID },
                removeData: { url in
                    try FileManager.default.removeItem(at: url)
                    didRemoveActiveFile = true
                }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertTrue(model.hasAttemptedCleanup)
            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertEqual(model.recoveryFailure, .cleanupFailed)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
            XCTAssertEqual(try Data(contentsOf: self.backupURL(for: fileURL)), Self.corruptBytes)

            model.requestCleanup()
            XCTAssertNil(model.recoveryFailure)
            XCTAssertTrue(model.hasAttemptedCleanup)
            model.cancelCleanup()
            XCTAssertFalse(model.isCleanupConfirmationPresented)
            XCTAssertTrue(model.hasAttemptedCleanup)

            model.retryLoad()
            XCTAssertEqual(model.launchState, .failed(.unreadable))
            XCTAssertTrue(model.hasAttemptedCleanup)
            XCTAssertEqual(try Data(contentsOf: self.backupURL(for: fileURL)), Self.corruptBytes)
        }
    }

    // 깨짐 명명: loading, ready 또는 failed 상태의 확인 없는 confirm이 정리 시도로 기록되거나 파일/백업을 바꾸면 실패.
    func test확인요청없는_loading_ready_failed_정리가드는_시도이력과파일을바꾸지않는다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL)
            var removeCalls = 0
            var readCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { url in
                    readCalls += 1
                    return try Data(contentsOf: url)
                },
                backupID: { Self.backupUUID },
                removeData: { _ in removeCalls += 1 }
            )
            let model = AppModel(store: store)

            XCTAssertFalse(model.hasAttemptedCleanup)
            XCTAssertEqual(model.launchState, .loading)
            XCTAssertFalse(model.confirmCleanup())
            XCTAssertFalse(model.hasAttemptedCleanup)
            XCTAssertEqual(readCalls, 0)

            model.loadIfNeeded()
            XCTAssertEqual(model.launchState, .failed(.corrupt))
            let readsAfterLoad = readCalls
            XCTAssertFalse(model.confirmCleanup())

            XCTAssertFalse(model.hasAttemptedCleanup)
            XCTAssertEqual(readCalls, readsAfterLoad)
            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.backupURL(for: fileURL).path))
        }

        try withTemporaryFile { fileURL in
            var readCalls = 0
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { _ in
                    readCalls += 1
                    throw CocoaError(.fileReadNoSuchFile)
                },
                backupID: { Self.backupUUID },
                removeData: { _ in removeCalls += 1 }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            XCTAssertEqual(model.launchState, .ready(.cardEntry))
            let readsAfterLoad = readCalls

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertFalse(model.hasAttemptedCleanup)
            XCTAssertEqual(readCalls, readsAfterLoad)
            XCTAssertEqual(removeCalls, 0)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.backupURL(for: fileURL).path))
        }
    }

    private func backupURL(for fileURL: URL) -> URL {
        fileURL.deletingLastPathComponent()
            .appendingPathComponent("app-state.recovery-\(Self.backupUUID.uuidString).backup")
    }

    private func seed(_ fileURL: URL) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try Self.corruptBytes.write(to: fileURL)
    }
}
```

## Full test text: `ios/FocusMateUITests/RecoveryHistoryFlowTests.swift`

```swift
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
```

## Referenced files

- `ios/FocusMateTests/StorageTestSupport.swift`
- `ios/FocusMateTests/StorageRecoveryTests.swift`
- `ios/FocusMateTests/AppRecoveryTests.swift`
- `ios/FocusMateUITests/StorageRecoveryFlowTests.swift`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-red/SKILL.md`

The skill-referenced `gx-dev/references/codex-runtime.md` path was absent and could not be read. No production file, diff, review, or previous-chat artifact was read.

## Next step

Root implementer adds the declaration bridge and the minimum production behavior, then runs the focused unit/UI RED verification.
