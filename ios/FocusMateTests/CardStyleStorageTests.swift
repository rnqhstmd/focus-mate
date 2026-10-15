import Foundation
import XCTest
@testable import FocusMate

final class CardStyleStorageTests: XCTestCase {
    private enum ProbeError: Error { case write, validation }
    private static let station = StationSnapshot(id: "seongsu", name: "성수")
    private static let issuedAt = Date(timeIntervalSince1970: 1_791_882_000)
    private static let recordJSON = ##"{"id":"journey-001","completedAt":"2026-10-13T01:00:00Z","date":"2026-10-13","bus":"버스2014","tag":"독서","tagColor":"#12ABef","task":"책 한 챕터 읽기","minutes":25,"sound":"빗소리","from":"성수역","to":"서울숲 입구","memo":"첫 메모"}"##

    private func snapshot(_ style: CardStyle) -> AppSnapshot {
        Self.stage(true, Self.station, Self.station)
            .issuingCard(CardSnapshot(id: "FM-01234567", issuedAt: Self.issuedAt, style: style))
    }

    /// legacy 입력은 프로덕션 encoder를 사용하지 않는다. v2 style 필드는 모르는 키다.
    private func legacyV2(extraCardKey: String = "") -> Data {
        Data(#"{"version":2,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1},"cards":{"items":[{"id":"FM-01234567","issuedAt":"2026-10-13T09:00:00Z"\#(extraCardKey)}]},"journey":{"active":null},"records":{"items":[\#(Self.recordJSON)]}}}"#.utf8)
    }

    /// v3 손상자료 생성은 독립 JSON fixture를 기반으로 하며 encode의 검증 우회를 요구하지 않는다.
    private func rawV3(photoData: Data, width: Int = 40, height: Int = 20) throws -> Data {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: legacyV2()) as? [String: Any])
        root["version"] = 3
        var state = try XCTUnwrap(root["state"] as? [String: Any])
        let photo: [String: Any] = ["id": "11111111-2222-3333-4444-555555555555",
            "data": photoData.base64EncodedString(), "pixelWidth": width, "pixelHeight": height,
            "centerX": 0.5, "centerY": 0.5, "widthFraction": 0.6]
        state["cards"] = ["items": [["id": "FM-01234567", "issuedAt": "2026-10-13T09:00:00Z",
            "style": ["background": ["red": 0.2, "green": 0.3, "blue": 0.4], "photos": [photo]]]]]
        root["state"] = state
        return try JSONSerialization.data(withJSONObject: root, options: [.sortedKeys])
    }

    // 깨짐 명명: 사진 순서/배치/바이트를 버리거나 카드 정체성을 재생성하면 실패한다.
    func testAC24_실파일_재실행은_여섯장_내용_배치_순서_정체성을_복원한다() throws {
        try withTemporaryFile { url in
            let bytes = try CardPhotoTestFixtures.image(alpha: true)
            let photos = (0..<6).map { index in
                CardPhotoTestFixtures.photo(data: bytes,
                    id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!,
                    x: Double(index) * 0.2, y: 0.4, fraction: 0.3)
            }
            let original = snapshot(CardPhotoTestFixtures.style(photos))
            try LocalSnapshotStore(fileURL: url).save(original)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            let card = try XCTUnwrap(loaded.currentCard)
            XCTAssertEqual(card.id, "FM-01234567")
            XCTAssertEqual(card.issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
            XCTAssertEqual(card.style.background, CardColor(red: 0.2, green: 0.3, blue: 0.4))
            XCTAssertEqual(card.style.photos.count, 6)
            XCTAssertEqual(card.style.photos.map(\.id), [
                UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000004")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000005")!,
                UUID(uuidString: "00000000-0000-0000-0000-000000000006")!])
            for (photo, expectedX) in zip(card.style.photos, [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]) {
                XCTAssertEqual(photo.centerX, expectedX, accuracy: 0.000001)
            }
            XCTAssertEqual(card.style.photos.map(\.centerY), [0.4, 0.4, 0.4, 0.4, 0.4, 0.4])
            XCTAssertEqual(card.style.photos.map(\.widthFraction), [0.3, 0.3, 0.3, 0.3, 0.3, 0.3])
            for photo in card.style.photos {
                XCTAssertEqual(photo.data, bytes)
                XCTAssertEqual(Double(try CardPhotoTestFixtures.rgba(photo.data)[3]), 128, accuracy: 1)
            }
        }
    }

    // 깨짐 명명: 원본 파일 경로에 의존하거나 재로드 시 사진을 잃으면 실패한다.
    func testAC25_입력원본파일_삭제후에도_실제사진을_복원한다() throws {
        try withTemporaryFile { url in
            let sourceURL = url.deletingLastPathComponent().appendingPathComponent("picker-source.png")
            try CardPhotoTestFixtures.seed(CardPhotoTestFixtures.image(alpha: true), at: sourceURL)
            let bytes = try Data(contentsOf: sourceURL)
            let original = snapshot(CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: bytes)]))
            try LocalSnapshotStore(fileURL: url).save(original)
            try FileManager.default.removeItem(at: sourceURL)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            XCTAssertEqual(loaded, original)
            XCTAssertEqual(Double(try CardPhotoTestFixtures.rgba(XCTUnwrap(loaded.currentCard?.style.photos.first).data)[3]), 128, accuracy: 1)
        }
    }

    // 깨짐 명명: v3의 필수 style 누락을 기본 외형으로 채우면 실패한다.
    func testV3_Style누락은_corrupt이며_자동덮어쓰기하지_않는다() throws {
        var root = try XCTUnwrap(JSONSerialization.jsonObject(with: legacyV2()) as? [String: Any])
        root["version"] = 3
        let bytes = try JSONSerialization.data(withJSONObject: root)
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            assertStorageIssue(.corrupt) { _ = try LocalSnapshotStore(fileURL: url).load() }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: v2에서 알 수 없는 style 키를 해석하면 손상/꾸민 외형으로 읽혀 실패한다.
    func testAC29_V2UnknownStyle은_무시하고_표준외형으로_마이그레이션한다() throws {
        let input = legacyV2(extraCardKey: #", "style":{"photos":"broken","background":null},"unknown":7"#)
        let decoded = try SnapshotCodec.decode(input)
        XCTAssertEqual(decoded.currentCard?.style, .standard)
        XCTAssertEqual(decoded.currentCard?.id, "FM-01234567")
        XCTAssertEqual(decoded.currentCard?.issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
        XCTAssertTrue(try XCTUnwrap(decoded.currentCard).style.isStandard)
    }

    // 깨짐 명명: v2 읽기가 재저장되거나 꾸미기 저장이 기존 단계/기록을 잃으면 실패한다.
    func testAC29_V2_읽기는_원본보존_꾸미기저장후_현재버전으로_이용상태를_유지한다() throws {
        try withTemporaryFile { url in
            let bytes = legacyV2()
            try CardPhotoTestFixtures.seed(bytes, at: url)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            XCTAssertEqual(try Data(contentsOf: url), bytes)
            XCTAssertEqual(loaded.currentCard?.style, .standard)
            let card = try XCTUnwrap(loaded.currentCard)
            let styledCard = card.updating(style: CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image())]))
            let updated = loaded.updating(cards: snapshot(styledCard.style).cards)
            try LocalSnapshotStore(fileURL: url).save(updated)
            let restored = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            XCTAssertEqual(restored, updated)
            XCTAssertTrue(restored.cardIssued)
            XCTAssertNil(restored.initialStation)
            XCTAssertNil(restored.currentStation)
            XCTAssertNil(restored.journey.active)
            XCTAssertEqual(restored.records.items.count, 1)
            let record = try XCTUnwrap(restored.records.items.first)
            XCTAssertEqual(record.id, "journey-001")
            XCTAssertEqual(record.minutes, 25)
            XCTAssertEqual(record.memo, "첫 메모")
            XCTAssertEqual(restored.records, loaded.records)
            XCTAssertEqual(restored.currentCard?.id, "FM-01234567")
            XCTAssertEqual(restored.currentCard?.issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
            let root = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 5)
        }
    }

    // 깨짐 명명: v1 변환을 제거하거나 읽기 중 쓰면 실패한다. 자동 카드 보충은 기존 별도 통합 시험이다.
    func testAC29_V1_읽기는_단계를_유지하고_옛_정류장은_비우며_쓰지_않는다() throws {
        let bytes = Data(#"{"version":1,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}}}"#.utf8)
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: url).load())
            XCTAssertTrue(loaded.cardIssued)
            XCTAssertNil(loaded.initialStation)
            XCTAssertNil(loaded.currentStation)
            XCTAssertTrue(loaded.cards.items.isEmpty)
            XCTAssertNil(loaded.journey.active)
            XCTAssertTrue(loaded.records.items.isEmpty)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: atomic write 오류를 성공으로 처리하거나 원본 사진 바이트를 지우면 실패한다.
    func testAtomicWriteFailure_기존외형과_사진_원본을_유지한다() throws {
        try withTemporaryFile { url in
            let original = snapshot(CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image())]))
            try LocalSnapshotStore(fileURL: url).save(original)
            let bytes = try Data(contentsOf: url)
            let failing = LocalSnapshotStore(fileURL: url, writeData: { _, _ in throw ProbeError.write })
            assertStorageIssue(.writeFailed) { try failing.save(snapshot(.standard)) }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
            XCTAssertEqual(try LocalSnapshotStore(fileURL: url).load(), original)
        }
    }

    // 깨짐 명명: 실제 사진 검사 실패를 무시하거나 다른 오류로 포장하면 쓰기가 발생해서 실패한다.
    func testCandidatePhotoValidatorError는_invalidCardPhoto이며_IO를_하지않는다() throws {
        var reads = 0; var directories = 0; var writes = 0
        let store = LocalSnapshotStore(fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in reads += 1; throw CocoaError(.fileReadNoSuchFile) },
            createDirectory: { _ in directories += 1 }, writeData: { _, _ in writes += 1 },
            validateCardPhotos: { _ in throw ProbeError.validation })
        assertStorageIssue(.invalidState(.invalidCardPhoto)) {
            try store.save(snapshot(CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo()])))
        }
        XCTAssertEqual(reads, 0)
        XCTAssertEqual(directories, 0)
        XCTAssertEqual(writes, 0)
    }

    // 깨짐 명명: 원본 이미지 실패를 후보 오류로 분류하거나 기존 데이터를 덮어쓰면 실패한다.
    func testAC28_InvalidPhotoOriginal은_writeBlocked이며_바이트를_유지한다() throws {
        let bytes = try rawV3(photoData: CardPhotoTestFixtures.damagedBody())
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url, createDirectory: { _ in directories += 1 }, writeData: { _, _ in writes += 1 })
            assertStorageIssue(.invalidState(.invalidCardPhoto)) { _ = try store.load() }
            assertStorageIssue(.writeBlocked(.invalidState(.invalidCardPhoto))) { try store.save(snapshot(.standard)) }
            XCTAssertEqual(writes, 0)
            XCTAssertEqual(directories, 0)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: 실제 사진검증을 정상파일 판정에서 빼면 notRequired가 되어 복구가 실패한다.
    func testAC28_InvalidPhotoOriginal은_원본을_그대로_백업한_후에만_제거한다() throws {
        let bytes = try rawV3(photoData: CardPhotoTestFixtures.damagedBody())
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            let backupID = UUID(uuidString: "99999999-2222-3333-4444-555555555555")!
            let expectedBackup = url.deletingLastPathComponent().appendingPathComponent("app-state.recovery-\(backupID.uuidString).backup")
            let store = LocalSnapshotStore(fileURL: url, backupID: { backupID }, removeData: { original in
                XCTAssertEqual(try Data(contentsOf: expectedBackup), bytes)
                XCTAssertEqual(try Data(contentsOf: original), bytes)
                try FileManager.default.removeItem(at: original)
            })
            let backup = try store.backupAndClear(expectedSource: .bytes(bytes))
            XCTAssertEqual(try Data(contentsOf: backup), bytes)
            XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
        }
    }

    // 깨짐 명명: 손상사진 백업 실패 뒤 원본을 삭제하면 실패한다.
    func testAC28_InvalidPhotoBackupFailure는_원본삭제를_하지않는다() throws {
        let bytes = try rawV3(photoData: CardPhotoTestFixtures.damagedBody())
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            var removals = 0
            let store = LocalSnapshotStore(fileURL: url,
                writeBackup: { _, _ in throw ProbeError.write }, removeData: { _ in removals += 1 })
            XCTAssertThrowsError(try store.backupAndClear(expectedSource: .bytes(bytes))) {
                XCTAssertEqual($0 as? StorageRecoveryIssue, .backupFailed)
            }
            XCTAssertEqual(removals, 0)
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }

    // 깨짐 명명: 장당/전체 byte 경계를 잘못 판정하거나 실패 후보를 쓰면 실패한다.
    // 구조 byte 경계 전용: actual image validator는 no-op이며 실제 이미지 성공 증거가 아니다.
    func testAC27_PerPhotoLimit() throws {
        let counts = [1048576]
        let photos = counts.enumerated().map { index, count in
            CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: count),
                id: index == 0 ? CardPhotoTestFixtures.photoID : UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!)
        }
        let candidate = snapshot(CardPhotoTestFixtures.style(photos))
        try withTemporaryFile { url in
            try LocalSnapshotStore(fileURL: url).save(snapshot(.standard))
            _ = try Data(contentsOf: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url,
                createDirectory: { target in directories += 1; try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true) },
                writeData: { data, target in writes += 1; try data.write(to: target, options: .atomic) },
                validateCardPhotos: { _ in })
            try store.save(candidate)
            XCTAssertEqual(writes, 1)
            let restarted = LocalSnapshotStore(fileURL: url, validateCardPhotos: { _ in })
            XCTAssertEqual(try restarted.load(), candidate)
        }
    }

    // 깨짐 명명: 장당/전체 byte 경계를 잘못 판정하거나 실패 후보를 쓰면 실패한다.
    // 구조 byte 경계 전용: actual image validator는 no-op이며 실제 이미지 성공 증거가 아니다.
    func testAC27_PerPhotoAboveLimit() throws {
        let counts = [1048577]
        let photos = counts.enumerated().map { index, count in
            CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: count),
                id: index == 0 ? CardPhotoTestFixtures.photoID : UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!)
        }
        let candidate = snapshot(CardPhotoTestFixtures.style(photos))
        try withTemporaryFile { url in
            try LocalSnapshotStore(fileURL: url).save(snapshot(.standard))
            let original = try Data(contentsOf: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url,
                createDirectory: { target in directories += 1; try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true) },
                writeData: { data, target in writes += 1; try data.write(to: target, options: .atomic) },
                validateCardPhotos: { _ in })
            assertStorageIssue(.invalidState(.invalidCardStyle(.photoTooLarge(CardPhotoTestFixtures.photoID)))) { try store.save(candidate) }
            XCTAssertEqual(writes, 0)
            XCTAssertEqual(directories, 0)
            XCTAssertEqual(try Data(contentsOf: url), original)
            XCTAssertEqual(try LocalSnapshotStore(fileURL: url).load(), snapshot(.standard))
        }
    }

    // 깨짐 명명: 장당/전체 byte 경계를 잘못 판정하거나 실패 후보를 쓰면 실패한다.
    // 구조 byte 경계 전용: actual image validator는 no-op이며 실제 이미지 성공 증거가 아니다.
    func testAC27_TotalLimit() throws {
        let counts = [1048576, 1048576, 1048576, 1048576, 1048576, 1048576]
        let photos = counts.enumerated().map { index, count in
            CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: count),
                id: index == 0 ? CardPhotoTestFixtures.photoID : UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!)
        }
        let candidate = snapshot(CardPhotoTestFixtures.style(photos))
        try withTemporaryFile { url in
            try LocalSnapshotStore(fileURL: url).save(snapshot(.standard))
            _ = try Data(contentsOf: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url,
                createDirectory: { target in directories += 1; try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true) },
                writeData: { data, target in writes += 1; try data.write(to: target, options: .atomic) },
                validateCardPhotos: { _ in })
            try store.save(candidate)
            XCTAssertEqual(writes, 1)
            let restarted = LocalSnapshotStore(fileURL: url, validateCardPhotos: { _ in })
            XCTAssertEqual(try restarted.load(), candidate)
        }
    }

    // 깨짐 명명: 장당/전체 byte 경계를 잘못 판정하거나 실패 후보를 쓰면 실패한다.
    // 구조 byte 경계 전용: actual image validator는 no-op이며 실제 이미지 성공 증거가 아니다.
    func testAC27_TotalAboveLimit() throws {
        let counts = [1048576, 1048576, 1048576, 1048576, 1048576, 1048577]
        let photos = counts.enumerated().map { index, count in
            CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: count),
                id: index == 0 ? CardPhotoTestFixtures.photoID : UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!)
        }
        let candidate = snapshot(CardPhotoTestFixtures.style(photos))
        try withTemporaryFile { url in
            try LocalSnapshotStore(fileURL: url).save(snapshot(.standard))
            let original = try Data(contentsOf: url)
            var writes = 0; var directories = 0
            let store = LocalSnapshotStore(fileURL: url,
                createDirectory: { target in directories += 1; try FileManager.default.createDirectory(at: target, withIntermediateDirectories: true) },
                writeData: { data, target in writes += 1; try data.write(to: target, options: .atomic) },
                validateCardPhotos: { _ in })
            assertStorageIssue(.invalidState(.invalidCardStyle(.totalPhotosTooLarge))) { try store.save(candidate) }
            XCTAssertEqual(writes, 0)
            XCTAssertEqual(directories, 0)
            XCTAssertEqual(try Data(contentsOf: url), original)
            XCTAssertEqual(try LocalSnapshotStore(fileURL: url).load(), snapshot(.standard))
        }
    }

    // 깨짐 명명: 실제 손상 후보의 이미지 검증을 빼면 read/create/write가 발생한다.
    func testAC28_DamagedCandidate_기존원본_읽기전에_거절한다() throws {
        var reads = 0; var directories = 0; var writes = 0
        let store = LocalSnapshotStore(fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in reads += 1; throw CocoaError(.fileReadNoSuchFile) },
            createDirectory: { _ in directories += 1 }, writeData: { _, _ in writes += 1 })
        let candidate = snapshot(CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.damagedBody())]))
        assertStorageIssue(.invalidState(.invalidCardPhoto)) { try store.save(candidate) }
        XCTAssertEqual(reads, 0)
        XCTAssertEqual(directories, 0)
        XCTAssertEqual(writes, 0)
    }

    // 깨짐 명명: load에서 actual/declared 치수 검사를 빼면 잘못된 배치를 성공으로 읽어 실패한다.
    func testAC28_DeclaredDimensionMismatch_읽기실패는_원본을_유지한다() throws {
        let bytes = try rawV3(photoData: CardPhotoTestFixtures.image(), width: 41)
        try withTemporaryFile { url in
            try CardPhotoTestFixtures.seed(bytes, at: url)
            assertStorageIssue(.invalidState(.invalidCardPhoto)) { _ = try LocalSnapshotStore(fileURL: url).load() }
            XCTAssertEqual(try Data(contentsOf: url), bytes)
        }
    }
}
