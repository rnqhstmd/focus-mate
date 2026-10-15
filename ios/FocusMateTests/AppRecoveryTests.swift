import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class AppRecoveryTests: XCTestCase {
    private enum ProbeError: Error { case expected }

    private static let backupUUID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
    private static let corruptBytes = Data("{broken".utf8)
    private static let changedBytes = Data("{changed".utf8)
    private static let readyV1Bytes = Data(
        #"{"version":1,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1}}}"#.utf8
    )
    private static let unsupportedV5Bytes = Data(#"{"version":5,"state":null}"#.utf8)
    private static let initialStation = StationSnapshot(id: "seongsu", name: "성수", direction: 1)
    private static let currentStation = StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1)
    private static let readySnapshot = stage(true, initialStation, currentStation)

    // 깨짐 명명: retryLoad가 실제 재읽기를 생략하거나 성공 route/snapshot을 갱신하지 않거나 저장을 수행하면 실패.
    func testAC2_retry성공은_저장상태route와snapshot을복원하고_쓰지않는다() {
        var readCalls = 0
        var directoryCalls = 0
        var writeCalls = 0
        var removeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                readCalls += 1
                if readCalls == 1 { throw CocoaError(.fileReadNoPermission) }
                return Self.readyV1Bytes
            },
            createDirectory: { _ in directoryCalls += 1 },
            writeData: { _, _ in writeCalls += 1 },
            removeData: { _ in removeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()

        model.retryLoad()

        XCTAssertEqual(readCalls, 2)
        XCTAssertEqual(directoryCalls, 0)
        XCTAssertEqual(writeCalls, 0)
        XCTAssertEqual(removeCalls, 0)
        XCTAssertEqual(model.snapshot, Self.readySnapshot)
        XCTAssertEqual(model.launchState, .ready(.main))
        XCTAssertEqual(model.path, [])
    }

    // 깨짐 명명: retryLoad가 최초 오류를 고정하거나 실패 뒤 snapshot/path를 남기거나 원본을 변경하면 실패.
    func testAC3_retry실패는_최신의다른오류를표시하고_빈상태와원본을유지한다() {
        var readCalls = 0
        var writeCalls = 0
        var removeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                readCalls += 1
                return readCalls == 1 ? Self.corruptBytes : Self.unsupportedV5Bytes
            },
            writeData: { _, _ in writeCalls += 1 },
            removeData: { _ in removeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()

        model.retryLoad()

        XCTAssertEqual(model.launchState, .failed(.unsupportedVersion(5)))
        XCTAssertNil(model.snapshot)
        XCTAssertEqual(model.path, [])
        XCTAssertEqual(readCalls, 2)
        XCTAssertEqual(writeCalls, 0)
        XCTAssertEqual(removeCalls, 0)
    }

    // 깨짐 명명: retryLoad가 사라진 파일을 계속 오류로 취급하거나 empty/cardEntry 전환 대신 nil을 유지하면 실패.
    func testAC2_retry에서_원본없음은_empty카드입력으로복구하고_쓰지않는다() {
        var readCalls = 0
        var writeCalls = 0
        var removeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                readCalls += 1
                if readCalls == 1 { return Self.corruptBytes }
                throw CocoaError(.fileReadNoSuchFile)
            },
            writeData: { _, _ in writeCalls += 1 },
            removeData: { _ in removeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()

        model.retryLoad()

        XCTAssertEqual(model.snapshot, .empty)
        XCTAssertEqual(model.launchState, .ready(.cardEntry))
        XCTAssertEqual(model.path, [])
        XCTAssertEqual(readCalls, 2)
        XCTAssertEqual(writeCalls, 0)
        XCTAssertEqual(removeCalls, 0)
    }

    // 깨짐 명명: request/cancel이 확인 상태를 잘못 유지하거나 백업·삭제·원본 수정을 수행하면 실패.
    func testAC4_정리요청과취소는_확인상태만바꾸고_파일을그대로둔다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            var backupCalls = 0
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { _, _ in backupCalls += 1 },
                removeData: { _ in removeCalls += 1 }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()

            model.requestCleanup()
            XCTAssertTrue(model.isCleanupConfirmationPresented)
            model.cancelCleanup()

            XCTAssertFalse(model.isCleanupConfirmationPresented)
            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertEqual(backupCalls, 0)
            XCTAssertEqual(removeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.backupURL(for: fileURL).path))
        }
    }

    // 깨짐 명명: 유효한 requestCleanup 캡처 없이 confirmCleanup이 백업이나 삭제를 시작하면 실패.
    func testAC4_확인없는정리실행은_false이고_Io가없다() {
        var readCalls = 0
        var backupCalls = 0
        var removeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in
                readCalls += 1
                return Self.corruptBytes
            },
            backupID: { Self.backupUUID },
            writeBackup: { _, _ in backupCalls += 1 },
            removeData: { _ in removeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()
        let readsBeforeConfirm = readCalls

        XCTAssertFalse(model.confirmCleanup())

        XCTAssertEqual(readCalls, readsBeforeConfirm)
        XCTAssertEqual(backupCalls, 0)
        XCTAssertEqual(removeCalls, 0)
        XCTAssertEqual(model.launchState, .failed(.corrupt))
        XCTAssertFalse(model.isRecovering)
    }

    // 깨짐 명명: loading/ready에서 복구 API가 저장소를 읽거나 확인 상태를 열거나 정리를 수행하면 실패.
    func testAC1_loading과ready에서는_복구Api가_Io없이무시된다() {
        var loadingReads = 0
        var loadingBackups = 0
        var loadingRemoves = 0
        let loadingStore = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/loading.json"),
            readData: { _ in loadingReads += 1; return Self.corruptBytes },
            backupID: { Self.backupUUID },
            writeBackup: { _, _ in loadingBackups += 1 },
            removeData: { _ in loadingRemoves += 1 }
        )
        let loadingModel = AppModel(store: loadingStore)

        loadingModel.retryLoad()
        loadingModel.requestCleanup()
        loadingModel.cancelCleanup()
        XCTAssertFalse(loadingModel.confirmCleanup())

        XCTAssertEqual(loadingReads, 0)
        XCTAssertEqual(loadingBackups, 0)
        XCTAssertEqual(loadingRemoves, 0)
        XCTAssertEqual(loadingModel.launchState, .loading)

        var readyReads = 0
        var readyBackups = 0
        var readyRemoves = 0
        let readyStore = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/ready.json"),
            readData: { _ in readyReads += 1; return Self.readyV1Bytes },
            backupID: { Self.backupUUID },
            writeBackup: { _, _ in readyBackups += 1 },
            removeData: { _ in readyRemoves += 1 }
        )
        let readyModel = AppModel(store: readyStore)
        readyModel.loadIfNeeded()
        let readsAfterLoad = readyReads

        readyModel.retryLoad()
        readyModel.requestCleanup()
        readyModel.cancelCleanup()
        XCTAssertFalse(readyModel.confirmCleanup())

        XCTAssertEqual(readyReads, readsAfterLoad)
        XCTAssertEqual(readyBackups, 0)
        XCTAssertEqual(readyRemoves, 0)
        XCTAssertEqual(readyModel.launchState, .ready(.main))
        XCTAssertFalse(readyModel.isCleanupConfirmationPresented)
    }

    // 깨짐 명명: 성공 정리가 원본과 다른 백업을 만들거나 failed를 유지하거나 새 모델 재실행에서 오류를 되살리면 실패.
    func testAC5_실제정리성공은_정확한백업과empty카드입력을만들고_재실행에도유지된다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            let model = AppModel(store: LocalSnapshotStore(fileURL: fileURL, backupID: { Self.backupUUID }))
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertTrue(model.confirmCleanup())

            XCTAssertEqual(try Data(contentsOf: self.backupURL(for: fileURL)), Self.corruptBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
            XCTAssertEqual(model.snapshot, .empty)
            XCTAssertEqual(model.launchState, .ready(.cardEntry))
            XCTAssertEqual(model.path, [])
            XCTAssertNil(model.saveFailure)
            XCTAssertNil(model.recoveryFailure)
            XCTAssertFalse(model.isRecovering)

            let relaunched = AppModel(store: LocalSnapshotStore(fileURL: fileURL))
            relaunched.loadIfNeeded()
            XCTAssertEqual(relaunched.snapshot, .empty)
            XCTAssertEqual(relaunched.launchState, .ready(.cardEntry))
            XCTAssertEqual(relaunched.path, [])
        }
    }

    // 깨짐 명명: 백업 쓰기 실패를 성공 처리하거나 failed/recovering 종료 상태를 잘못 남기면 실패.
    func testAC6_백업쓰기실패는_false_failed_backupFailed_recoveringFalse다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { _, _ in throw ProbeError.expected }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertNil(model.snapshot)
            XCTAssertEqual(model.path, [])
            XCTAssertEqual(model.recoveryFailure, .backupFailed)
            XCTAssertFalse(model.isRecovering)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
        }
    }

    // 깨짐 명명: 백업 readback 불일치를 무시하거나 정리를 성공시키거나 원본을 삭제하면 실패.
    func testAC6_백업불일치는_false_failed_backupFailed이고_원본을보존한다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { _, backupURL in try self.seed(backupURL, Self.changedBytes) }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertEqual(model.recoveryFailure, .backupFailed)
            XCTAssertFalse(model.isRecovering)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
            XCTAssertEqual(try Data(contentsOf: self.backupURL(for: fileURL)), Self.changedBytes)
        }
    }

    // 깨짐 명명: remove 실패를 성공 처리하거나 검증 백업을 없애거나 recovering을 true로 남기면 실패.
    func testAC7_remove실패는_false_cleanupFailed이고_검증백업을유지한다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                removeData: { _ in throw ProbeError.expected }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertEqual(model.recoveryFailure, .cleanupFailed)
            XCTAssertFalse(model.isRecovering)
            XCTAssertEqual(try Data(contentsOf: self.backupURL(for: fileURL)), Self.corruptBytes)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.corruptBytes)
        }
    }

    // 깨짐 명명: 삭제 후 존재 확인 오류를 성공으로 오인하거나 검증 백업을 지우면 실패.
    func testAC7_삭제후확인실패는_false_cleanupFailed이고_검증백업을유지한다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
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
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertEqual(model.recoveryFailure, .cleanupFailed)
            XCTAssertFalse(model.isRecovering)
            XCTAssertEqual(try Data(contentsOf: self.backupURL(for: fileURL)), Self.corruptBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))
        }
    }

    // 깨짐 명명: 확인 뒤 바뀐 원본을 이전 캡처로 백업·삭제하거나 sourceChanged 대신 성공시키면 실패.
    func testAC6_확인후원본변경은_sourceChanged로실패하고_변경본을보호한다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            let model = AppModel(store: LocalSnapshotStore(fileURL: fileURL, backupID: { Self.backupUUID }))
            model.loadIfNeeded()
            model.requestCleanup()
            try self.seed(fileURL, Self.changedBytes)

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertEqual(model.recoveryFailure, .sourceChanged)
            XCTAssertFalse(model.isRecovering)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.changedBytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.backupURL(for: fileURL).path))
        }
    }

    // 깨짐 명명: 확인 뒤 정상 v1로 회복된 파일을 오류 원본처럼 백업·삭제하거나 성공 정리로 표시하면 실패.
    func testAC8_확인후정상복원은_notRequired로실패하고_정상파일을보호한다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            var activeReadCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { url in
                    if url == fileURL {
                        activeReadCalls += 1
                        if activeReadCalls == 2 { throw CocoaError(.fileReadNoPermission) }
                    }
                    return try Data(contentsOf: url)
                },
                backupID: { Self.backupUUID }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()
            try self.seed(fileURL, Self.readyV1Bytes)

            XCTAssertFalse(model.confirmCleanup())

            XCTAssertEqual(model.launchState, .failed(.corrupt))
            XCTAssertEqual(model.recoveryFailure, .notRequired)
            XCTAssertFalse(model.isRecovering)
            XCTAssertEqual(activeReadCalls, 3)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.readyV1Bytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: self.backupURL(for: fileURL).path))
        }
    }

    // 깨짐 명명: 정리 실패 안내가 새 retry/request 뒤에도 남아 최신 복구 상태와 섞이면 실패.
    func testAC6_정리실패후_새retry와request는_recoveryFailure를해제한다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                backupID: { Self.backupUUID },
                writeBackup: { _, _ in throw ProbeError.expected }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()
            XCTAssertFalse(model.confirmCleanup())
            XCTAssertEqual(model.recoveryFailure, .backupFailed)

            model.retryLoad()
            XCTAssertNil(model.recoveryFailure)
            XCTAssertEqual(model.launchState, .failed(.corrupt))

            model.requestCleanup()
            XCTAssertNil(model.recoveryFailure)
            XCTAssertTrue(model.isCleanupConfirmationPresented)
        }
    }

    // 깨짐 명명: writeBackup 콜백 안 재진입 confirm/retry/request/save가 중복 읽기·백업·삭제·저장을 만들면 실패.
    func testAC5_복구콜백재진입은_confirm_retry_request_save를차단하고_Io를추가하지않는다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            var readCalls = 0
            var backupCalls = 0
            var removeCalls = 0
            var writeCalls = 0
            var model: AppModel!
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { url in
                    readCalls += 1
                    return try Data(contentsOf: url)
                },
                writeData: { _, _ in writeCalls += 1 },
                backupID: { Self.backupUUID },
                writeBackup: { data, url in
                    backupCalls += 1
                    try self.seed(url, data)
                    let readsBeforeReentry = readCalls
                    XCTAssertFalse(model.confirmCleanup())
                    model.retryLoad()
                    model.requestCleanup()
                    XCTAssertFalse(model.save(Self.readySnapshot))
                    XCTAssertEqual(readCalls, readsBeforeReentry)
                },
                removeData: { url in
                    removeCalls += 1
                    try FileManager.default.removeItem(at: url)
                }
            )
            model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()

            XCTAssertTrue(model.confirmCleanup())

            XCTAssertEqual(backupCalls, 1)
            XCTAssertEqual(removeCalls, 1)
            XCTAssertEqual(writeCalls, 0)
            XCTAssertEqual(model.launchState, .ready(.cardEntry))
            XCTAssertNil(model.recoveryFailure)
            XCTAssertFalse(model.isRecovering)
        }
    }

    // 깨짐 명명: 성공 뒤 반복 recovery 호출이 이전 캡처를 재사용해 추가 백업·삭제·읽기를 만들면 실패.
    func testAC5_성공후반복복구호출은_추가Io없이_성공상태를유지한다() throws {
        try withTemporaryFile { fileURL in
            try self.seed(fileURL, Self.corruptBytes)
            var readCalls = 0
            var backupCalls = 0
            var removeCalls = 0
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                readData: { url in
                    readCalls += 1
                    return try Data(contentsOf: url)
                },
                backupID: { Self.backupUUID },
                writeBackup: { data, url in
                    backupCalls += 1
                    try self.seed(url, data)
                },
                removeData: { url in
                    removeCalls += 1
                    try FileManager.default.removeItem(at: url)
                }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.requestCleanup()
            XCTAssertTrue(model.confirmCleanup())
            let readsAfterSuccess = readCalls
            let backupsAfterSuccess = backupCalls
            let removesAfterSuccess = removeCalls

            model.retryLoad()
            model.requestCleanup()
            model.cancelCleanup()
            XCTAssertFalse(model.confirmCleanup())

            XCTAssertEqual(readCalls, readsAfterSuccess)
            XCTAssertEqual(backupCalls, backupsAfterSuccess)
            XCTAssertEqual(removeCalls, removesAfterSuccess)
            XCTAssertEqual(model.snapshot, .empty)
            XCTAssertEqual(model.launchState, .ready(.cardEntry))
            XCTAssertEqual(model.path, [])
        }
    }

    private func backupURL(for fileURL: URL) -> URL {
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
}
