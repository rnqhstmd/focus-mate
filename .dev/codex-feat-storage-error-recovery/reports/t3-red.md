# T3 RED — UI + DEBUG bootstrap

## Status

DONE_WITH_CONCERNS

- 신규 테스트: 16건 (RecoveryBootstrapTests 7, StorageRecoveryFlowTests 9).
- 컴파일: 성공. 신규 API를 테스트가 직접 참조해 생기는 컴파일 RED는 없음.
- focused 실행: exit 65, 기능 미구현에 따른 runtime RED 확인.
- 단위: 7건 모두 실패, 22 assertion/runtime failures (2 unexpected). 현재 bootstrap이 invalidState/recovery 옵션을 구현하지 않아 invalidArguments, 정상 정리 폴백, 읽기 오류 미주입, unknown 옵션 수용으로 실패.
- UI: 복구 버튼/진단 미구현으로 storage.retry, storage.cleanup, test.backups를 찾지 못하는 실제 RED 확인. 최종 재실행 중 iOS UI test runner unexpected exit/restart가 발생해 안정적인 최종 executed 합계는 얻지 못했지만 failing summary에는 UI 9건 전부가 기록됨.
- 범위 준수: production ios/FocusMate/** 본문은 읽거나 수정하지 않음. 컴파일러/테스트 러너만 production을 사용함.

### 후속 큰 글자 입력 보강 (미실행)

- 근거: 하드코딩한 full-English category 문자열은 UIKit의 실제 raw value와 다를 수 있어 시스템 입력 적용을 보장하지 못함.
- 변경: `import UIKit` 후 `UIContentSizeCategory.accessibilityExtraExtraExtraLarge.rawValue`를 launch argument로 사용.
- 적용 확인: 버튼 탐색 전 DEBUG 진단 `test.dynamicTypeSize == "accessibility5"`를 assert. 글꼴 px/style 검증이 아니라 주입한 시스템 선호가 SUT에 적용된 전제 확인.
- 실행: 부모의 진행 중 T3-green과 충돌하지 않도록 이 후속 수정 뒤에는 xcode/test를 실행하지 않음. 부모가 focused new RED를 직접 실행 예정.
- StorageRecoveryFlowTests.swift SHA-256: `ecd50c3e888442144c20cfa9d8f9b4f80af68358dd9acb84b03f8131349dbb7a` → `b52f1863386a9d21d56505d7cdb0df38a8f5874d2694cd635c48f70f76a12174`.

### 후속 unknown 옵션 assertion 수정 (미실행)

- 근거: `XCTUnwrap`은 throwing initializer의 `invalidArguments`를 전달하기 전에 자체 XCTest failure를 기록하므로, 바깥 `XCTAssertThrowsError`가 오류를 잡아도 테스트가 실패함.
- 변경: `XCTAssertThrowsError(try UITestBootstrap(...))`로 initializer를 직접 검증. throw만 통과하며 nil 또는 정상 반환은 여전히 `XCTAssertThrowsError` 실패가 됨.
- 실행: 부모의 T3-green 검증과 충돌하지 않도록 수정 뒤 테스트를 실행하지 않음.
- RecoveryBootstrapTests.swift SHA-256: `9f5ac32245e1099a942235c4d0bf743eb064b3d861389d87bd3d2dcf1d3e91c6` → `088cabc98572e282d767944813299d2e6a8260d399197b5b61101e79c4aef560`.

## 케이스

### RecoveryBootstrapTests (7)

1. invalidState가 읽기 가능한 v1이면서 inconsistentStage로만 실패.
2. readOnce가 동일 modelStore 첫 active read만 실패하고 다음 읽기는 ready 원본을 복원.
3. readAlways가 동일 modelStore의 모든 active read를 실패시키고 원본 보존.
4. backupFail이 실제 modelStore/AppModel 복구 경로에서 backupFailed 및 원본 보존.
5. backupMismatch가 다른 실제 백업 바이트를 기록하고 readback 검증에서 정리 차단.
6. cleanupFail이 정확한 검증 백업을 유지하고 cleanupFailed 및 원본 보존.
7. 알 수 없는 recovery 옵션 거부.

modelStore는 computed factory일 수 있으므로 readOnce/readAlways 모두 getter를 한 번만 평가한 뒤 같은 저장소 인스턴스에 load를 반복한다. getter identity나 캐시를 생산 계약으로 요구하지 않는다.

### StorageRecoveryFlowTests (9)

1. corrupt/unsupported/invalidState/readAlways 4종의 원인, 복구 2버튼, 자동 정리 없음.
2. 재시도 실패 후 최신 오류 화면/복구 선택지/원본/무백업 유지.
3. readOnce 재시도 성공 후 main 복원 및 원본 bytes 불변.
4. 정리 확인 안내와 취소 후 오류 복귀, 원본/백업/route 불변.
5. corrupt/unsupported 정리 성공 시 정확한 actual backup JSON, active absent, cardEntry 및 무시드 재실행.
6. backupFail/readAlways 보존 실패 시 recoveryFailure와 오류 화면/원본/복구 선택지 유지.
7. backupMismatch가 active 삭제와 cardEntry 전환을 차단하고 다른 actual backup 노출.
8. cleanupFail이 정확한 검증 백업과 원본을 유지하고 오류 화면 유지.
9. UIKit 공식 Accessibility XXXL raw value 적용을 `test.dynamicTypeSize=accessibility5`로 확인한 뒤 스크롤로 취소/확인 버튼을 실제 탭 가능.

## 깨짐 명명

각 테스트 본문의 `깨짐 명명:` 주석에 기록했다. 집합은 잘못된 오류 분기, retry read 누락, 원본 write/delete 부작용, 백업 불일치 검증 누락, cleanup 실패 성공 오인, unknown 옵션 fallback, 큰 글자 버튼 접근 불가를 잡는다. 기댓값은 고정 fixture/문구/실제 디스크 bytes이며 운영 알고리즘으로 재계산하지 않는다.

## 실패 확인 명령

```sh
FOCUSMATE_SIMULATOR_ID=EC533489-C7FF-4620-B46D-E3D8461427DB python3 scripts/check-ios.py test ios/FocusMateTests/RecoveryBootstrapTests.swift ios/FocusMateUITests/StorageRecoveryFlowTests.swift > .dev/codex-feat-storage-error-recovery/t3-red-agent.log 2>&1
```

## 실패 결과

```text
RecoveryBootstrapTests: Executed 7 tests, with 22 failures (2 unexpected)
testReadOnce...: Expected StorageIssue unreadable
testReadAlways...: corrupt is not equal to unreadable
testInvalidState...: invalidArguments
testUnknownRecoveryOption...: XCTAssertThrowsError failed: did not throw
testBackupFail...: confirmCleanup returned true; ready(cardEntry), recoveryFailure nil, active file absent
testBackupMismatch...: confirmCleanup returned true; recoveryFailure nil; backup bytes equal original
testCleanupFail...: confirmCleanup returned true; ready(cardEntry), recoveryFailure nil, active file absent

StorageRecoveryFlowTests examples:
Failed to tap "storage.cleanup": No matches found for identifier storage.cleanup
Failed to tap "storage.retry": No matches found for identifier storage.retry
Final runner: Restarting after unexpected exit, crash, or test timeout
Failing summary lists all 7 unit and all 9 UI test methods.
** TEST FAILED **
```

로그: `.dev/codex-feat-storage-error-recovery/t3-red-agent.log`

## 참조 파일

- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-dev/references/codex-roles/red-writer.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-tdd/references/testing-anti-patterns.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-tdd/references/frontend-testing.md`
- `.dev/codex-feat-storage-error-recovery/prd.md`
- `.dev/codex-feat-storage-error-recovery/design.md`
- `ios/FocusMateUITests/Phase1FlowTests.swift`
- `ios/FocusMateTests/HarnessTests.swift`
- `ios/FocusMateTests/AppRecoveryTests.swift`
- `ios/FocusMateTests/StorageTestSupport.swift`
- `ios/FocusMateTests/RecoveryBootstrapTests.swift`
- `ios/FocusMateUITests/StorageRecoveryFlowTests.swift`

## 테스트 코드 전문

### ios/FocusMateTests/RecoveryBootstrapTests.swift

```swift
import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class RecoveryBootstrapTests: XCTestCase {
    private static let corruptBytes = Data("{broken".utf8)
    private static let readySnapshot = stage(
        true,
        StationSnapshot(id: "seongsu", name: "성수", direction: 1),
        StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1)
    )

    // 깨짐 명명: invalidState 시드가 손상 JSON이거나 일관된 단계이면 inconsistentStage 분기를 실행하지 못해 실패.
    func testInvalidStateSeedWritesReadableV1ThatFailsOnlyStageValidation() throws {
        try withBootstrapDirectory { applicationSupport in
            let bootstrap = try self.bootstrap(
                applicationSupport: applicationSupport,
                seed: "invalidState"
            )
            try bootstrap.prepare()

            self.assertStorageIssue(.invalidState(.inconsistentStage)) {
                _ = try bootstrap.modelStore.load()
            }

            let bytes = try Data(contentsOf: bootstrap.fileURL)
            let root = try XCTUnwrap(JSONSerialization.jsonObject(with: bytes) as? [String: Any])
            let state = try XCTUnwrap(root["state"] as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 1)
            XCTAssertEqual(state["cardIssued"] as? Bool, false)
            XCTAssertTrue(state["currentStation"] is NSNull)
            let station = try XCTUnwrap(state["initialStation"] as? [String: Any])
            XCTAssertEqual(station["id"] as? String, "seongsu")
            XCTAssertEqual(station["name"] as? String, "성수")
            XCTAssertEqual(station["direction"] as? Int, 1)
        }
    }

    // 깨짐 명명: readOnce가 첫 활성 읽기 뒤에도 계속 실패하거나 실제 파일 대신 대체 snapshot을 반환하면 실패.
    func testReadOnceFailsFirstActiveReadThenLoadsTheUnchangedReadyFile() throws {
        try withBootstrapDirectory { applicationSupport in
            let bootstrap = try self.bootstrap(
                applicationSupport: applicationSupport,
                seed: "ready",
                recovery: "readOnce"
            )
            try bootstrap.prepare()
            let original = try Data(contentsOf: bootstrap.fileURL)
            let store = bootstrap.modelStore

            self.assertStorageIssue(.unreadable) {
                _ = try store.load()
            }
            XCTAssertEqual(try store.load(), Self.readySnapshot)
            XCTAssertEqual(try Data(contentsOf: bootstrap.fileURL), original)
        }
    }

    // 깨짐 명명: readAlways가 두 번째 읽기를 실제 파일로 통과시키거나 원본을 변경하면 실패.
    func testReadAlwaysFailsEveryActiveReadAndPreservesTheSeededBytes() throws {
        try withBootstrapDirectory { applicationSupport in
            let bootstrap = try self.bootstrap(
                applicationSupport: applicationSupport,
                seed: "corrupt",
                recovery: "readAlways"
            )
            try bootstrap.prepare()
            let original = try Data(contentsOf: bootstrap.fileURL)
            let store = bootstrap.modelStore

            for _ in 0..<2 {
                self.assertStorageIssue(.unreadable) {
                    _ = try store.load()
                }
            }

            XCTAssertEqual(original, Self.corruptBytes)
            XCTAssertEqual(try Data(contentsOf: bootstrap.fileURL), original)
        }
    }

    // 깨짐 명명: backupFail 옵션이 실제 modelStore의 백업 쓰기에 연결되지 않거나 실패 뒤 원본을 지우면 실패.
    func testBackupFailFlowsThroughModelStoreAndLeavesTheActiveFileUntouched() throws {
        try withBootstrapDirectory { applicationSupport in
            let bootstrap = try self.bootstrap(
                applicationSupport: applicationSupport,
                seed: "corrupt",
                recovery: "backupFail"
            )
            try bootstrap.prepare()
            let original = try Data(contentsOf: bootstrap.fileURL)
            let model = AppModel(store: bootstrap.modelStore)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertEqual(model.recoveryFailure, .backupFailed)
            self.assertActiveFile(bootstrap.fileURL, equals: original)
            XCTAssertTrue(try self.backups(nextTo: bootstrap.fileURL).isEmpty)
        }
    }

    // 깨짐 명명: backupMismatch가 원본과 같은 바이트를 쓰거나 readback 검증을 우회해 활성 파일을 삭제하면 실패.
    func testBackupMismatchWritesDifferentBytesAndModelStoreBlocksCleanup() throws {
        try withBootstrapDirectory { applicationSupport in
            let bootstrap = try self.bootstrap(
                applicationSupport: applicationSupport,
                seed: "corrupt",
                recovery: "backupMismatch"
            )
            try bootstrap.prepare()
            let original = try Data(contentsOf: bootstrap.fileURL)
            let model = AppModel(store: bootstrap.modelStore)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertFalse(model.confirmCleanup())

            let backups = try self.backups(nextTo: bootstrap.fileURL)
            XCTAssertEqual(model.recoveryFailure, .backupFailed)
            self.assertActiveFile(bootstrap.fileURL, equals: original)
            XCTAssertEqual(backups.count, 1)
            if let backupURL = backups.first {
                XCTAssertNotEqual(try Data(contentsOf: backupURL), original)
            }
        }
    }

    // 깨짐 명명: cleanupFail이 백업 검증 전 실패하거나 검증 백업을 제거하거나 정리 성공으로 보고하면 실패.
    func testCleanupFailKeepsAnExactBackupAndReportsCleanupFailure() throws {
        try withBootstrapDirectory { applicationSupport in
            let bootstrap = try self.bootstrap(
                applicationSupport: applicationSupport,
                seed: "unsupported",
                recovery: "cleanupFail"
            )
            try bootstrap.prepare()
            let original = try Data(contentsOf: bootstrap.fileURL)
            let model = AppModel(store: bootstrap.modelStore)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertFalse(model.confirmCleanup())

            let backups = try self.backups(nextTo: bootstrap.fileURL)
            XCTAssertEqual(model.launchState, .failed(.unsupportedVersion(999)))
            XCTAssertEqual(model.recoveryFailure, .cleanupFailed)
            self.assertActiveFile(bootstrap.fileURL, equals: original)
            XCTAssertEqual(backups.count, 1)
            if let backupURL = backups.first {
                XCTAssertEqual(try Data(contentsOf: backupURL), original)
            }
        }
    }

    // 깨짐 명명: 알 수 없는 recovery 값이 기본 동작으로 조용히 폴백하면 잘못된 테스트 실행이 정상처럼 보이므로 실패.
    func testUnknownRecoveryOptionIsRejected() throws {
        try withBootstrapDirectory { applicationSupport in
            XCTAssertThrowsError(
                try UITestBootstrap(
                    arguments: [
                        "--fm-ui-test-id", UUID().uuidString,
                        "--fm-ui-seed", "corrupt",
                        "--fm-ui-recovery", "unknown-recovery-mode",
                    ],
                    applicationSupport: applicationSupport
                )
            )
        }
    }

    private func bootstrap(
        applicationSupport: URL,
        seed: String,
        recovery: String? = nil
    ) throws -> UITestBootstrap {
        var arguments = [
            "--fm-ui-test-id", UUID().uuidString,
            "--fm-ui-seed", seed,
        ]
        if let recovery {
            arguments += ["--fm-ui-recovery", recovery]
        }
        return try XCTUnwrap(
            UITestBootstrap(arguments: arguments, applicationSupport: applicationSupport)
        )
    }

    private func withBootstrapDirectory(_ operation: (URL) throws -> Void) throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("FocusMate-RecoveryBootstrapTests-\(UUID().uuidString)", isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        try operation(root)
    }

    private func backups(nextTo fileURL: URL) throws -> [URL] {
        let directory = fileURL.deletingLastPathComponent()
        return try FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ).filter {
            $0.lastPathComponent.hasPrefix("app-state.recovery-") && $0.pathExtension == "backup"
        }
    }

    private func assertActiveFile(
        _ fileURL: URL,
        equals expected: Data,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(FileManager.default.fileExists(atPath: fileURL.path), file: file, line: line)
        XCTAssertEqual(try? Data(contentsOf: fileURL), expected, file: file, line: line)
    }
}
```

### ios/FocusMateUITests/StorageRecoveryFlowTests.swift

```swift
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
        XCTAssertEqual(try value("main.direction", in: app), "역방향")
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
```
