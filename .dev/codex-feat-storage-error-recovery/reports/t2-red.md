# T2 RED 보고서 — AppModel recovery 상태 전이

## Status

- 분류: **MISSING_INTERFACE**
- focused 결과: exit 65, 컴파일 RED
- 신규 테스트: `ios/FocusMateTests/AppRecoveryTests.swift`
- 케이스 수: 16
- 생산 코드 열람/검색/수정: 없음
- 테스트 외 수정: 이 보고서뿐

## 실패 확인 명령

```sh
FOCUSMATE_SIMULATOR_ID=EC533489-C7FF-4620-B46D-E3D8461427DB python3 scripts/check-ios.py test ios/FocusMateTests/AppRecoveryTests.swift > .dev/codex-feat-storage-error-recovery/t2-red-agent.log 2>&1
```

명령은 지시대로 1회만 실행했다. 로그: `.dev/codex-feat-storage-error-recovery/t2-red-agent.log`.

## 실패 결과

```text
Testing failed:
AppRecoveryTests.swift: error: value of type 'AppModel' has no member 'retryLoad'
AppRecoveryTests.swift: error: value of type 'AppModel' has no member 'requestCleanup'
AppRecoveryTests.swift: error: value of type 'AppModel' has no member 'cancelCleanup'
AppRecoveryTests.swift: error: value of type 'AppModel' has no member 'confirmCleanup'
AppRecoveryTests.swift: error: value of type 'AppModel' has no member 'isCleanupConfirmationPresented'
AppRecoveryTests.swift: error: value of type 'AppModel' has no member 'isRecovering'
Exit status: 65
```

`XCTAssertFalse(model.confirmCleanup())`의 `cannot convert value of type '_' to expected argument type 'Bool'` 진단은 `confirmCleanup` 부재에서 파생된 2차 진단이다. 지시된 신규 AppModel API가 아직 선언되지 않아 assertion RED까지 도달할 수 없다. 선언-only bridge 후 같은 focused 테스트로 실제 동작 RED를 확인해야 한다.

## 케이스와 깨짐 명명

1. AC2 retry 성공: 실제 재읽기 생략, route/snapshot 미갱신, retry 중 저장을 검출.
2. AC3 retry 최신 오류: 최초 오류 고정, 실패 뒤 snapshot/path 잔존, 원본 변경을 검출.
3. AC2 retry nil: 파일 없음의 empty/cardEntry 전환 누락과 쓰기를 검출.
4. AC4 request/cancel: 확인 상태 오류, 백업·삭제·원본 변경을 검출.
5. AC4 confirm without request: 유효 캡처 없이 백업/삭제 시작을 검출.
6. AC1 loading/ready 보호: recovery API가 I/O 또는 확인 상태 변경을 일으키는 회귀를 검출.
7. AC5 실제 정리 성공: 백업 바이트 불일치, failed 잔존, empty/cardEntry 및 재실행 복구 누락을 검출.
8. AC6 backup write 실패: 성공 오판, failed/recovering 종료 상태 오류를 검출.
9. AC6 backup mismatch: readback 비교 생략, 원본 삭제, 성공 오판을 검출.
10. AC7 remove 실패: 성공 오판, 검증 백업 손실, recovering 잔존을 검출.
11. AC7 post-delete check 실패: 확인 오류 성공 오판과 검증 백업 손실을 검출.
12. AC6 source changed: 이전 캡처로 변경 원본 백업/삭제, sourceChanged 누락을 검출.
13. AC8 normal restored: 정상 v1 삭제/백업, notRequired 누락을 검출.
14. AC6 실패 후 새 retry/request: 이전 recoveryFailure가 최신 흐름에 남는 회귀를 검출.
15. AC5 callback 재진입: confirm/retry/request/save가 중복 I/O를 만드는 회귀를 검출.
16. AC5 성공 후 반복: 소비된 캡처 재사용과 추가 읽기/백업/삭제를 검출.

## 테스트 품질 근거

- 모든 테스트 메서드는 `@MainActor` 클래스 안에 있다.
- 실제 `LocalSnapshotStore`를 사용하고 파일 경계만 closure로 격리했다.
- Codec mock은 없다.
- 성공 정리·파일 보호·백업 검증은 실제 임시 파일과 Foundation I/O로 확인한다.
- fixture는 고정 v1 JSON, 고정 손상 JSON, 고정 미지원 v4 JSON을 사용한다.
- expected route/issue/바이트는 리터럴 또는 설계가 제공한 테스트 생성 경계로 정의했고 SnapshotCodec 결과로 계산하지 않았다.
- escaping closure 안 helper 호출은 `self.seed`처럼 `self.`를 명시했다.

## 참조한 파일

- `.dev/codex-feat-storage-error-recovery/prd.md`
- `.dev/codex-feat-storage-error-recovery/design.md`
- `ios/FocusMateTests/AppFoundationTests.swift`
- `ios/FocusMateTests/StorageTestSupport.swift`
- `ios/FocusMateTests/StorageRecoveryTests.swift`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-red/SKILL.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-dev/references/codex-runtime.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-dev/references/codex-roles/red-writer.md`
- `/Users/bonseung/.codex/plugins/cache/oh-my-gx/oh-my-gx/1.33.0/.claude/skills/gx-tdd/references/testing-anti-patterns.md`

생산 파일 `ios/FocusMate/**`는 읽거나 검색하지 않았다.

## 수정 이력

- 초안의 AC8 정상 복원 케이스는 `.bytes(corrupt)` 캡처 뒤 정상 v1로 바뀌어 설계 순서상 `sourceChanged`가 먼저였다.
- 의도한 `notRequired` 경계를 유지하도록 최초 load=손상, request 캡처=읽기 불가(`.unreadable`), confirm=실제 정상 v1 읽기로 수정했다.
- 이는 원본 비교보다 decode 보호가 먼저 실행되도록 기대한 계약 불일치를 바로잡은 변경이며, 검증을 약화하지 않는다.
- 신규 AppModel API 부재라는 실패 분류는 변하지 않아 focused 명령은 반복하지 않았다.

## 테스트 코드 전문

```swift
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
    private static let unsupportedV4Bytes = Data(#"{"version":4,"state":null}"#.utf8)
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
                return readCalls == 1 ? Self.corruptBytes : Self.unsupportedV4Bytes
            },
            writeData: { _, _ in writeCalls += 1 },
            removeData: { _ in removeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()

        model.retryLoad()

        XCTAssertEqual(model.launchState, .failed(.unsupportedVersion(4)))
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
```
