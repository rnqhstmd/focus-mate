import Foundation
import XCTest
@testable import FocusMate

final class RecordStorageTests: XCTestCase {
    private enum ProbeError: Error { case expected }

    private static let seoul = TimeZone(identifier: "Asia/Seoul")!
    private static let seongsu = StationSnapshot(id: "seongsu", name: "성수", direction: 1)
    private static let seoulForest = StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1)

    // 깨짐 명명: 실제 저장 뒤 새 store/AppModel이 메모 또는 완료 필드 하나라도 잃으면 실패.
    @MainActor
    func testAC10_실제파일은_새Store와_새AppModel에서_모든필드를_복원한다() throws {
        try withTemporaryFile { fileURL in
            try LocalSnapshotStore(fileURL: fileURL).save(Self.readySnapshot)
            let firstModel = AppModel(store: LocalSnapshotStore(fileURL: fileURL))
            firstModel.loadIfNeeded()

            XCTAssertTrue(firstModel.recordCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul))
            XCTAssertTrue(firstModel.saveRecordMemo("오늘 계획을 마쳤다", forJourneyID: "journey-001"))

            let restoredModel = AppModel(store: LocalSnapshotStore(fileURL: fileURL))
            restoredModel.loadIfNeeded()
            let restored = try XCTUnwrap(restoredModel.snapshot?.records.items.first)
            XCTAssertEqual(restoredModel.snapshot?.records.items.count, 1)
            assertRecord(restored, id: "journey-001", completedAt: "2026-10-13T01:00:00Z", date: "2026-10-13", minutes: 25, memo: "오늘 계획을 마쳤다")
            XCTAssertEqual(restoredModel.launchState, .ready(.main))

            let object = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any])
            let state = try XCTUnwrap(object["state"] as? [String: Any])
            let records = try XCTUnwrap(state["records"] as? [String: Any])
            let items = try XCTUnwrap(records["items"] as? [[String: Any]])
            XCTAssertEqual(items.count, 1)
            XCTAssertEqual(items[0]["memo"] as? String, "오늘 계획을 마쳤다")
            XCTAssertEqual(items[0]["minutes"] as? Int, 25)
        }
    }

    // 깨짐 명명: 201자 저장 메모를 부분 복원·절단하거나 저장으로 덮어쓰면 실패.
    func testAC11_메모201자_파일은_전체읽기실패하고_저장거부와_원본보존이다() throws {
        let bytes = Self.envelope(records: [Self.rawRecord(memo: String(repeating: "가", count: 201))])
        try assertProtected(
            bytes,
            loadIssue: .invalidState(.invalidRecords(.memoTooLong)),
            saveIssue: .writeBlocked(.invalidState(.invalidRecords(.memoTooLong)))
        )
    }

    // 깨짐 명명: 필수 ID가 없는 raw JSON을 기본값으로 복구하거나 덮어쓰면 실패.
    func testAC11_ID누락_파일은_corrupt이고_원본바이트를_보존한다() throws {
        let missingID = ##"{"completedAt":"2026-10-13T01:00:00Z","date":"2026-10-13","bus":"버스2014","tag":"독서","tagColor":"#12ABef","task":"책 한 챕터 읽기","minutes":25,"sound":"빗소리","from":"성수역","to":"서울숲 입구","memo":""}"##
        let bytes = Self.envelope(records: [missingID])

        try assertProtected(bytes, loadIssue: .corrupt, saveIssue: .writeBlocked(.corrupt))
    }

    // 깨짐 명명: 동일 ID 두 건을 자동 병합·제거하거나 일부만 복원하면 실패.
    func testAC11_중복ID_파일은_전체읽기실패하고_원본바이트를_보존한다() throws {
        let bytes = Self.envelope(records: [
            Self.rawRecord(),
            Self.rawRecord(completedAt: "2026-10-13T02:00:00Z"),
        ])
        let issue = StorageIssue.invalidState(.invalidRecords(.duplicateJourneyID("journey-001")))

        try assertProtected(bytes, loadIssue: issue, saveIssue: .writeBlocked(issue))
    }

    // 깨짐 명명: 미지원 v3에서 완료·메모 저장이 파일을 쓰거나 원인을 잃으면 실패.
    @MainActor
    func testAC12_미지원버전_AppModel은_완료와_메모저장을_차단하고_원본을_보존한다() throws {
        let bytes = Data(#"{"version":3,"state":null}"#.utf8)
        try withTemporaryFile { fileURL in
            try seed(fileURL, bytes)
            let model = AppModel(store: LocalSnapshotStore(fileURL: fileURL))
            model.loadIfNeeded()
            XCTAssertEqual(model.launchState, .failed(.unsupportedVersion(3)))

            XCTAssertFalse(model.recordCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul))
            XCTAssertEqual(model.saveFailure, .writeBlocked(.unsupportedVersion(3)))
            XCTAssertFalse(model.saveRecordMemo("메모", forJourneyID: "journey-001"))
            XCTAssertEqual(model.saveFailure, .writeBlocked(.unsupportedVersion(3)))
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
        }
    }

    // 깨짐 명명: records 갱신이 카드·여정·정류장 또는 version 값을 바꾸면 실패.
    @MainActor
    func testAC13_완료저장은_v2의_다른영역을_보존한다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.emptyV2)
            let model = AppModel(store: LocalSnapshotStore(fileURL: fileURL))
            model.loadIfNeeded()
            XCTAssertTrue(model.recordCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul))

            let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: Data(contentsOf: fileURL)) as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 2)
            let state = try XCTUnwrap(root["state"] as? [String: Any])
            XCTAssertEqual(state["cardIssued"] as? Bool, true)
            XCTAssertEqual(((state["cards"] as? [String: Any])?["items"] as? [Any])?.count, 0)
            XCTAssertTrue((state["journey"] as? [String: Any])?["active"] is NSNull)
            assertStationJSON(state["initialStation"], id: "seongsu", name: "성수", direction: 1)
            assertStationJSON(state["currentStation"], id: "seoulForest", name: "서울숲", direction: -1)
            let records = try XCTUnwrap(state["records"] as? [String: Any])
            XCTAssertEqual((records["items"] as? [Any])?.count, 1)
        }
    }

    // 회귀: W00에서 이미 통과할 수 있으며 신규 API의 RED 근거와 구분한다.
    func testAC14_기존_v1과_빈records_v2는_빈기록과_정류장을_복원한다() throws {
        let fixtures = [Self.v1, Self.emptyV2]

        for bytes in fixtures {
            let store = LocalSnapshotStore(fileURL: URL(fileURLWithPath: "/unused/app-state.json"), readData: { _ in bytes })
            let loaded = try XCTUnwrap(try store.load())
            XCTAssertEqual(loaded.records.items.count, 0)
            XCTAssertEqual(loaded.cardIssued, true)
            XCTAssertTrue(try XCTUnwrap(loaded.initialStation).id.utf16.elementsEqual("seongsu".utf16))
            XCTAssertTrue(try XCTUnwrap(loaded.currentStation).id.utf16.elementsEqual("seoulForest".utf16))
        }
    }

    // 깨짐 명명: raw v2 복원에서 분수초를 문자열로 정렬하거나 파일을 재작성하면 실패.
    func testAC15_파일복원은_최신순이며_읽기중_원본을_재작성하지않는다() throws {
        let bytes = Self.envelope(records: [
            Self.rawRecord(id: "whole", completedAt: "2026-10-13T01:00:00Z"),
            Self.rawRecord(id: "fraction", completedAt: "2026-10-13T01:00:00.001Z"),
            Self.rawRecord(id: "older", completedAt: "2026-10-13T00:59:59Z"),
        ])
        try withTemporaryFile { fileURL in
            try seed(fileURL, bytes)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertEqual(loaded.records.items.map(\.id), ["fraction", "whole", "older"])
            XCTAssertTrue(loaded.records.items[0].completedAt.utf16.elementsEqual("2026-10-13T01:00:00.001Z".utf16))
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes)
        }
    }

    // 회귀+신규 경계: 제외 outcome은 메모리·파일 쓰기를 만들지 않아야 한다.
    @MainActor
    func testAC2_AppModel의_진행_포기_예시는_false이고_쓰기없음이다() {
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in Self.emptyV2 },
            createDirectory: { _ in },
            writeData: { _, _ in writeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()

        XCTAssertFalse(model.recordCompletion(Self.input(id: "active"), outcome: .active, timeZone: Self.seoul))
        XCTAssertFalse(model.recordCompletion(Self.input(id: "abandoned"), outcome: .abandoned, timeZone: Self.seoul))
        XCTAssertFalse(model.recordCompletion(Self.input(id: "example"), outcome: .alighted, isExample: true, timeZone: Self.seoul))
        XCTAssertEqual(writeCalls, 0)
        XCTAssertNil(model.saveFailure)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // 깨짐 명명: 동일 ID 완료 재요청 또는 동일 메모가 불필요한 파일 쓰기를 하면 실패.
    @MainActor
    func testAC3_AppModel의_동일완료와_동일메모는_쓰기없는_성공이다() {
        let existing = Self.envelope(records: [Self.rawRecord(memo: "첫 메모")])
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in existing },
            createDirectory: { _ in },
            writeData: { _, _ in writeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()

        XCTAssertTrue(model.recordCompletion(Self.input(minutes: 99), outcome: .alighted, timeZone: Self.seoul))
        XCTAssertTrue(model.saveRecordMemo("첫 메모", forJourneyID: "journey-001"))
        XCTAssertEqual(writeCalls, 0)
        XCTAssertNil(model.saveFailure)
        let record = model.snapshot?.records.items.first
        XCTAssertEqual(record?.minutes, 25)
        XCTAssertTrue(record?.memo.utf16.elementsEqual("첫 메모".utf16) == true)
    }

    // 깨짐 명명: canonical equality만 보고 NFC/NFD 메모를 같은 원문으로 오인하면 쓰기와 원문 교체가 누락되어 실패.
    @MainActor
    func test메모_noOp판정은_NFC_NFD가아닌_UTF16원문을_사용한다() throws {
        let composed = "é"
        let decomposed = "e\u{301}"
        let existing = Self.envelope(records: [Self.rawRecord(memo: composed)])
        var writeCalls = 0
        var writtenData: Data?
        let loadedStore = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in existing },
            createDirectory: { _ in },
            writeData: { data, _ in
                writeCalls += 1
                writtenData = data
            }
        )
        let model = AppModel(store: loadedStore)
        model.loadIfNeeded()

        XCTAssertTrue(model.saveRecordMemo(decomposed, forJourneyID: "journey-001"))

        XCTAssertEqual(writeCalls, 1)
        XCTAssertTrue(model.snapshot?.records.items.first?.memo.utf16.elementsEqual(decomposed.utf16) == true)
        let data = try XCTUnwrap(writtenData)
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: data) as? [String: Any])
        let state = root["state"] as? [String: Any]
        let records = state?["records"] as? [String: Any]
        let items = records?["items"] as? [[String: Any]]
        let persistedMemo = try XCTUnwrap(items?.first?["memo"] as? String)
        XCTAssertTrue(persistedMemo.utf16.elementsEqual(decomposed.utf16))
    }

    // 깨짐 명명: 도메인 오류가 파일 접근을 하거나 StorageIssue 매핑을 잃으면 실패.
    @MainActor
    func testAC6_AppModel의_잘못된분은_도메인오류이고_쓰기없음이다() {
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in Self.emptyV2 },
            createDirectory: { _ in },
            writeData: { _, _ in writeCalls += 1 }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()

        XCTAssertFalse(model.recordCompletion(Self.input(minutes: 0), outcome: .alighted, timeZone: Self.seoul))

        XCTAssertEqual(model.saveFailure, .invalidState(.invalidRecords(.invalidMinutes(0))))
        XCTAssertEqual(writeCalls, 0)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
    }

    // 깨짐 명명: 기록 저장 실패가 메모리 snapshot·route·path를 먼저 바꾸면 실패.
    @MainActor
    func test기록쓰기실패는_기존상태와경로를_보존한다() {
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in Self.emptyV2 },
            createDirectory: { _ in },
            writeData: { _, _ in throw ProbeError.expected }
        )
        let model = AppModel(store: store)
        model.loadIfNeeded()
        model.open(.records)

        XCTAssertFalse(model.recordCompletion(Self.input(), outcome: .alighted, timeZone: Self.seoul))

        XCTAssertEqual(model.saveFailure, .writeFailed)
        XCTAssertEqual(model.snapshot?.records.items.count, 0)
        XCTAssertEqual(model.launchState, .ready(.main))
        XCTAssertEqual(model.path, [.records])
    }

    // 깨짐 명명: 실제 기존 메모 변경의 write 실패 전에 메모리 snapshot을 교체하거나 원본 파일을 변형하면 실패.
    @MainActor
    func test기존메모_쓰기실패는_snapshot과route_path_실제파일을_모두보존한다() throws {
        let originalBytes = Self.envelope(records: [Self.rawRecord(memo: "첫 메모")])
        try withTemporaryFile { fileURL in
            try seed(fileURL, originalBytes)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                writeData: { _, _ in throw ProbeError.expected }
            )
            let model = AppModel(store: store)
            model.loadIfNeeded()
            model.open(.records)

            XCTAssertFalse(model.saveRecordMemo("수정", forJourneyID: "journey-001"))

            XCTAssertEqual(model.saveFailure, .writeFailed)
            XCTAssertEqual(model.launchState, .ready(.main))
            XCTAssertEqual(model.path, [.records])
            let snapshot = try XCTUnwrap(model.snapshot)
            XCTAssertEqual(snapshot.cardIssued, true)
            XCTAssertEqual(snapshot.cards.items.count, 0)
            XCTAssertNil(snapshot.journey.active)
            XCTAssertTrue(try XCTUnwrap(snapshot.initialStation).id.utf16.elementsEqual("seongsu".utf16))
            XCTAssertTrue(try XCTUnwrap(snapshot.currentStation).id.utf16.elementsEqual("seoulForest".utf16))
            XCTAssertEqual(snapshot.records.items.count, 1)
            assertRecord(
                try XCTUnwrap(snapshot.records.items.first),
                id: "journey-001",
                completedAt: "2026-10-13T01:00:00Z",
                date: "2026-10-13",
                minutes: 25,
                memo: "첫 메모"
            )
            XCTAssertEqual(try Data(contentsOf: fileURL), originalBytes)
        }
    }

    private static let readySnapshot = stage(true, seongsu, seoulForest)
    private static let v1 = Data(
        #"{"version":1,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1}}}"#.utf8
    )
    private static let emptyV2 = Data(
        #"{"version":2,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1},"cards":{"items":[]},"journey":{"active":null},"records":{"items":[]}}}"#.utf8
    )

    private static func input(
        id: String = "journey-001",
        minutes: Int = 25
    ) -> RecordCompletionInput {
        RecordCompletionInput(
            id: id,
            completedAt: "2026-10-13T01:00:00Z",
            bus: "버스2014",
            tag: "독서",
            tagColor: "#12ABef",
            task: "책 한 챕터 읽기",
            minutes: minutes,
            sound: "빗소리",
            from: "성수역",
            to: "서울숲 입구"
        )
    }

    /// 프로덕션 encoder를 거치지 않는 손수 작성 raw JSON fixture.
    private static func rawRecord(
        id: String = "journey-001",
        completedAt: String = "2026-10-13T01:00:00Z",
        date: String = "2026-10-13",
        memo: String = ""
    ) -> String {
        ##"{"id":"\##(id)","completedAt":"\##(completedAt)","date":"\##(date)","bus":"버스2014","tag":"독서","tagColor":"#12ABef","task":"책 한 챕터 읽기","minutes":25,"sound":"빗소리","from":"성수역","to":"서울숲 입구","memo":"\##(memo)"}"##
    }

    /// 프로덕션 encoder를 거치지 않는 손수 작성 v2 envelope.
    private static func envelope(records: [String]) -> Data {
        Data(
            #"{"version":2,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1},"cards":{"items":[]},"journey":{"active":null},"records":{"items":[\#(records.joined(separator: ","))]}}}"#.utf8
        )
    }

    private func assertRecord(
        _ actual: RecordSnapshot,
        id: String,
        completedAt: String,
        date: String,
        minutes: Int,
        memo: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(actual.id.utf16.elementsEqual(id.utf16), file: file, line: line)
        XCTAssertTrue(actual.completedAt.utf16.elementsEqual(completedAt.utf16), file: file, line: line)
        XCTAssertTrue(actual.date.utf16.elementsEqual(date.utf16), file: file, line: line)
        XCTAssertTrue(actual.bus.utf16.elementsEqual("버스2014".utf16), file: file, line: line)
        XCTAssertTrue(actual.tag.utf16.elementsEqual("독서".utf16), file: file, line: line)
        XCTAssertTrue(actual.tagColor.utf16.elementsEqual("#12ABef".utf16), file: file, line: line)
        XCTAssertTrue(actual.task.utf16.elementsEqual("책 한 챕터 읽기".utf16), file: file, line: line)
        XCTAssertEqual(actual.minutes, minutes, file: file, line: line)
        XCTAssertTrue(actual.sound.utf16.elementsEqual("빗소리".utf16), file: file, line: line)
        XCTAssertTrue(actual.from.utf16.elementsEqual("성수역".utf16), file: file, line: line)
        XCTAssertTrue(actual.to.utf16.elementsEqual("서울숲 입구".utf16), file: file, line: line)
        XCTAssertTrue(actual.memo.utf16.elementsEqual(memo.utf16), file: file, line: line)
    }

    private func assertProtected(
        _ bytes: Data,
        loadIssue: StorageIssue,
        saveIssue: StorageIssue,
        file: StaticString = #filePath,
        line: UInt = #line
    ) throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, bytes)
            let store = LocalSnapshotStore(fileURL: fileURL)
            assertStorageIssue(loadIssue, file: file, line: line) { _ = try store.load() }
            assertStorageIssue(saveIssue, file: file, line: line) { try store.save(Self.readySnapshot) }
            XCTAssertEqual(try Data(contentsOf: fileURL), bytes, file: file, line: line)
        }
    }

    private func assertStationJSON(
        _ value: Any?,
        id: String,
        name: String,
        direction: Int,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let station = value as? [String: Any] else {
            return XCTFail("Expected station JSON", file: file, line: line)
        }
        XCTAssertEqual(station["id"] as? String, id, file: file, line: line)
        XCTAssertEqual(station["name"] as? String, name, file: file, line: line)
        XCTAssertEqual(station["direction"] as? Int, direction, file: file, line: line)
    }

    private func seed(_ fileURL: URL, _ bytes: Data) throws {
        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: fileURL)
    }
}
