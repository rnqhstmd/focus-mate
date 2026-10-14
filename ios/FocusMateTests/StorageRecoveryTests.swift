import Foundation
import XCTest
@testable import FocusMate

final class StorageRecoveryTests: XCTestCase {
    private enum ProbeError: Error { case expected }

    private static let backupUUID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
    private static let corruptBytes = Data("{broken".utf8)
    private static let changedBytes = Data("{changed".utf8)
    private static let existingBackupBytes = Data("existing-backup".utf8)
    private static let v1Bytes = Data(
        #"{"version":1,"state":{"cardIssued":false,"initialStation":null,"currentStation":null}}"#.utf8
    )
    private static let v2Bytes = Data(
        #"{"state":{"cardIssued":false,"cards":{"items":[]},"currentStation":null,"initialStation":null,"journey":{"active":null},"records":{"items":[]}},"version":2}"#.utf8
    )

    // 깨짐 명명: recoverySource가 없음/읽기 오류를 bytes로 뭉개거나 실제 바이트를 다른 값으로 반환하면 실패.
    func testAC5_recoverySource는_바이트_없음_읽기불가를_구분한다() {
        let cases: [(name: String, read: (URL) throws -> Data, expected: RecoverySource)] = [
            ("bytes", { _ in Self.corruptBytes }, .bytes(Self.corruptBytes)),
            ("missing", { _ in throw CocoaError(.fileReadNoSuchFile) }, .missing),
            ("unreadable", { _ in throw CocoaError(.fileReadNoPermission) }, .unreadable),
        ]

        for item in cases {
            let store = LocalSnapshotStore(
                fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
                readData: item.read
            )

            XCTAssertEqual(store.recoverySource(), item.expected, item.name)
        }
    }

    // 깨짐 명명: 검증 전에 삭제하거나 활성 파일에 쓰거나 백업 바이트를 바꾸거나 성공 뒤 활성 파일을 남기면 실패.
    func testAC5_실파일_복구는_원본바이트를_백업하고_활성파일을_제거한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            var activeWriteCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                writeData: { _, _ in activeWriteCalls += 1 },
                backupID: { Self.backupUUID }
            )

            let backupURL = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))

            XCTAssertEqual(backupURL, expectedBackupURL(for: fileURL))
            XCTAssertEqual(try Data(contentsOf: backupURL), Self.corruptBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
            XCTAssertNil(try LocalSnapshotStore(fileURL: fileURL).load())
            XCTAssertEqual(activeWriteCalls, 0)
        }
    }

    // 깨짐 명명: 백업 쓰기 오류를 성공으로 삼거나 오류 뒤 원본을 삭제하면 실패.
    func testAC6_백업쓰기실패는_backupFailed이고_원본을_보존한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { _, _ in throw ProbeError.expected },
                removeData: { _ in removeCalls += 1 }
            )

            assertRecoveryIssue(.backupFailed) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
        }
    }

    // 깨짐 명명: readback 바이트 비교를 생략하거나 불일치인데 활성 원본을 삭제하면 실패.
    func testAC6_백업_readback_불일치는_backupFailed이고_원본을_보존한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            var removeCalls = 0
            let backupURL = expectedBackupURL(for: fileURL)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { url in
                    if url == backupURL { return Self.changedBytes }
                    return try Data(contentsOf: url)
                },
                backupID: { Self.backupUUID },
                writeBackup: { data, url in try self.seed(url, data) },
                removeData: { _ in removeCalls += 1 }
            )

            assertRecoveryIssue(.backupFailed) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
        }
    }

    // 깨짐 명명: 백업 재읽기 오류를 무시하거나 오류 뒤 활성 원본을 삭제하면 실패.
    func testAC6_백업_readback_오류는_backupFailed이고_원본을_보존한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            var removeCalls = 0
            let backupURL = expectedBackupURL(for: fileURL)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { url in
                    if url == backupURL { throw CocoaError(.fileReadNoPermission) }
                    return try Data(contentsOf: url)
                },
                backupID: { Self.backupUUID },
                writeBackup: { data, url in try self.seed(url, data) },
                removeData: { _ in removeCalls += 1 }
            )

            assertRecoveryIssue(.backupFailed) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
            XCTAssertEqual(try Data(contentsOf: backupURL), Self.corruptBytes)
        }
    }

    // 깨짐 명명: 고정 ID 백업 충돌에서 기존 백업을 덮어쓰거나 지우거나 정리를 계속하면 실패.
    func testAC6_백업경로충돌은_기존백업과_원본을_모두_보존한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            let backupURL = expectedBackupURL(for: fileURL)
            try seed(backupURL, Self.existingBackupBytes)
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                removeData: { _ in removeCalls += 1 }
            )

            assertRecoveryIssue(.backupFailed) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
            XCTAssertEqual(try Data(contentsOf: backupURL), Self.existingBackupBytes)
        }
    }

    // 깨짐 명명: 실행 시 원본 읽기 실패를 missing/성공으로 바꾸거나 백업·삭제를 시도하면 실패.
    func testAC6_실행시_원본읽기실패는_backupFailed이고_Io를_진행하지_않는다() {
        var backupCalls = 0
        var removeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in throw CocoaError(.fileReadNoPermission) },
            backupID: { Self.backupUUID },
            writeBackup: { _, _ in backupCalls += 1 },
            removeData: { _ in removeCalls += 1 }
        )

        assertRecoveryIssue(.backupFailed) {
            _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
        }

        XCTAssertEqual(backupCalls, 0)
        XCTAssertEqual(removeCalls, 0)
    }

    // 깨짐 명명: 확인 뒤 변경된 원본을 예전 기대값으로 백업하거나 삭제하면 실패.
    func testAC6_확인후_원본변경은_sourceChanged이고_변경본을_보존한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.changedBytes)
            var backupCalls = 0
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { _, _ in backupCalls += 1 },
                removeData: { _ in removeCalls += 1 }
            )

            assertRecoveryIssue(.sourceChanged) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(backupCalls, 0)
            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.changedBytes)
        }
    }

    // 깨짐 명명: 확인 뒤 소실된 원본을 성공으로 취급하거나 백업을 만들면 실패.
    func testAC6_확인후_원본소실은_sourceMissing이고_백업하지_않는다() {
        var backupCalls = 0
        var removeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in throw CocoaError(.fileReadNoSuchFile) },
            backupID: { Self.backupUUID },
            writeBackup: { _, _ in backupCalls += 1 },
            removeData: { _ in removeCalls += 1 }
        )

        assertRecoveryIssue(.sourceMissing) {
            _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
        }

        XCTAssertEqual(backupCalls, 0)
        XCTAssertEqual(removeCalls, 0)
    }

    // 깨짐 명명: 확인 때 missing이었는데 새 파일이 생긴 경우 그 파일을 백업·삭제하면 실패.
    func testAC6_missing확인후_파일등장은_sourceChanged이고_새파일을_보존한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.changedBytes)
            var backupCalls = 0
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { _, _ in backupCalls += 1 },
                removeData: { _ in removeCalls += 1 }
            )

            assertRecoveryIssue(.sourceChanged) {
                _ = try store.backupAndClear(expectedSource: .missing)
            }

            XCTAssertEqual(backupCalls, 0)
            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.changedBytes)
        }
    }

    // 깨짐 명명: unreadable 캡처를 영구 실패로 고정하거나 현재 확보된 오류 바이트가 아닌 값을 백업하면 실패.
    func testAC5_unreadable확인후_읽힌_오류바이트를_정확히_백업해_정리한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            let store = LocalSnapshotStore(fileURL: fileURL, backupID: { Self.backupUUID })

            let backupURL = try store.backupAndClear(expectedSource: .unreadable)

            XCTAssertEqual(try Data(contentsOf: backupURL), Self.corruptBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        }
    }

    // 깨짐 명명: unreadable 캡처 뒤 정상화된 파일을 보호하지 않고 백업·삭제하면 실패.
    func testAC8_unreadable확인후_정상화파일은_notRequired로_삭제를_거부한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v2Bytes)
            var backupCalls = 0
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { _, _ in backupCalls += 1 },
                removeData: { _ in removeCalls += 1 }
            )

            assertRecoveryIssue(.notRequired) {
                _ = try store.backupAndClear(expectedSource: .unreadable)
            }

            XCTAssertEqual(backupCalls, 0)
            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.v2Bytes)
        }
    }

    // 깨짐 명명: 백업 검증 뒤 바뀐 활성 원본을 그대로 삭제하거나 성공을 반환하면 실패.
    func testAC7_백업후_원본변경은_sourceChanged이고_검증백업을_유지한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            let backupURL = expectedBackupURL(for: fileURL)
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { data, url in
                    try self.seed(url, data)
                    try Self.changedBytes.write(to: fileURL)
                },
                removeData: { _ in removeCalls += 1 }
            )

            assertRecoveryIssue(.sourceChanged) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: backupURL), Self.corruptBytes)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.changedBytes)
        }
    }

    // 깨짐 명명: removeData throw를 성공으로 삼거나 검증 백업을 지우면 실패.
    func testAC7_remove오류는_cleanupFailed이고_검증백업과_원본을_유지한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            let backupURL = expectedBackupURL(for: fileURL)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                removeData: { _ in throw ProbeError.expected }
            )

            assertRecoveryIssue(.cleanupFailed) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(try Data(contentsOf: backupURL), Self.corruptBytes)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
        }
    }

    // 깨짐 명명: removeData no-op 뒤 존재 확인을 생략해 성공을 반환하면 실패.
    func testAC7_remove무동작은_cleanupFailed이고_검증백업과_원본을_유지한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            let backupURL = expectedBackupURL(for: fileURL)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                removeData: { _ in }
            )

            assertRecoveryIssue(.cleanupFailed) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(try Data(contentsOf: backupURL), Self.corruptBytes)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
        }
    }

    // 깨짐 명명: 삭제 뒤 확인 읽기의 권한 오류를 없음으로 오인해 성공을 반환하면 실패.
    func testAC7_삭제후_확인읽기실패는_cleanupFailed이고_검증백업을_유지한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.corruptBytes)
            let backupURL = expectedBackupURL(for: fileURL)
            var didRemove = false
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { url in
                    if url == fileURL, didRemove { throw CocoaError(.fileReadNoPermission) }
                    return try Data(contentsOf: url)
                },
                backupID: { Self.backupUUID },
                removeData: { url in
                    try FileManager.default.removeItem(at: url)
                    didRemove = true
                }
            )

            assertRecoveryIssue(.cleanupFailed) {
                _ = try store.backupAndClear(expectedSource: .bytes(Self.corruptBytes))
            }

            XCTAssertEqual(try Data(contentsOf: backupURL), Self.corruptBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        }
    }

    // 깨짐 명명: 정상 v1/v2를 오류 파일로 취급해 백업하거나 삭제하면 기존 저장 계약 회귀로 실패.
    func testAC8_정상_v1_v2는_notRequired로_삭제를_거부한다() throws {
        for item in [("v1", Self.v1Bytes), ("v2", Self.v2Bytes)] {
            try withTemporaryFile { fileURL in
                try seed(fileURL, item.1)
                var backupCalls = 0
                var removeCalls = 0
                let store = LocalSnapshotStore(
                    fileURL: fileURL,
                    backupID: { Self.backupUUID },
                    writeBackup: { _, _ in backupCalls += 1 },
                    removeData: { _ in removeCalls += 1 }
                )

                assertRecoveryIssue(.notRequired, item.0) {
                    _ = try store.backupAndClear(expectedSource: .bytes(item.1))
                }

                XCTAssertEqual(backupCalls, 0, item.0)
                XCTAssertEqual(removeCalls, 0, item.0)
                XCTAssertEqual(try Data(contentsOf: fileURL), item.1, item.0)
            }
        }
    }

    // 깨짐 명명: 오류 버전 파일을 정상화하거나 재인코딩해 원본과 다른 백업을 만들면 실패.
    func testAC8_오류버전은_원본바이트_그대로_백업에_보존된다() throws {
        let cases: [(name: String, bytes: Data)] = [
            ("version 0", Data(#"{"version":0,"state":null}"#.utf8)),
            ("version 4", Data(#"{"version":4,"state":null}"#.utf8)),
            ("string version", Data(#"{"version":"2","state":null}"#.utf8)),
        ]

        for item in cases {
            try withTemporaryFile { fileURL in
                try seed(fileURL, item.bytes)
                let store = LocalSnapshotStore(fileURL: fileURL, backupID: { Self.backupUUID })

                let backupURL = try store.backupAndClear(expectedSource: .bytes(item.bytes))

                XCTAssertEqual(try Data(contentsOf: backupURL), item.bytes, item.name)
                XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path), item.name)
            }
        }
    }

    private func expectedBackupURL(for fileURL: URL) -> URL {
        fileURL.deletingLastPathComponent()
            .appendingPathComponent("app-state.recovery-\(Self.backupUUID.uuidString).backup")
    }

    private func seed(_ fileURL: URL, _ bytes: Data) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try bytes.write(to: fileURL)
    }

    private func assertRecoveryIssue(
        _ expected: StorageRecoveryIssue,
        _ message: String = "",
        file: StaticString = #filePath,
        line: UInt = #line,
        operation: () throws -> Void
    ) {
        do {
            try operation()
            XCTFail("Expected StorageRecoveryIssue \(expected) \(message)", file: file, line: line)
        } catch let actual as StorageRecoveryIssue {
            XCTAssertEqual(actual, expected, message, file: file, line: line)
        } catch {
            XCTFail("Expected StorageRecoveryIssue \(expected) but got \(error) \(message)", file: file, line: line)
        }
    }
}
