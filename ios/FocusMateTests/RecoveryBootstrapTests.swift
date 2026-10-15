import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class RecoveryBootstrapTests: XCTestCase {
    private static let corruptBytes = Data("{broken".utf8)
    // W01부터 ready 시드는 고정 카드(FM-20261013, 2026-10-13T09:00:00Z)를 포함한다.
    private static let readySnapshot = stage(
        true,
        StationSnapshot(id: "seongsu", name: "성수"),
        StationSnapshot(id: "seoulForest-r", name: "서울숲")
    ).issuingCard(CardSnapshot(id: "FM-20261013", issuedAt: Date(timeIntervalSince1970: 1_791_882_000)))

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
