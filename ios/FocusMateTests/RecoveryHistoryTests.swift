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
