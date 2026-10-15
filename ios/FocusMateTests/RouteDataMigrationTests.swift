import Foundation
import XCTest
@testable import FocusMate

/// SnapshotCodec v5: 옛 버전(1~4)은 정류장·진행 여정을 비우고 카드·기록은 유지한다.
final class RouteDataMigrationTests: XCTestCase {
    private typealias F = W16bFixtures

    private static let v1Issued = """
    {"version":1,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}}}
    """
    private static let v1Mismatch = """
    {"version":1,"state":{"cardIssued":false,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}}}
    """

    // 깨짐: currentVersion이 5가 아니면 실패한다.
    func testCurrentVersionIsFive() {
        XCTAssertEqual(SnapshotCodec.currentVersion, 5)
    }

    // 깨짐: encode가 version 5를 쓰지 않거나 정류장에 direction 키를 남기면 실패한다.
    func testEncodeWritesVersionFiveWithoutDirectionKey() throws {
        let out = try SnapshotCodec.encode(F.appSnapshot())
        let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: out) as? [String: Any])
        XCTAssertEqual(root["version"] as? Int, 5)
        let state = try XCTUnwrap(root["state"] as? [String: Any])
        let current = try XCTUnwrap(state["currentStation"] as? [String: Any])
        XCTAssertEqual(current["id"] as? String, "A")
        XCTAssertEqual(current["name"] as? String, "에이")
        XCTAssertNil(current["direction"])
    }

    // 깨짐: v5를 이전 대상으로 취급해 migration을 내거나 정류장을 비우면 실패한다.
    func testV5RoundTripKeepsStationsAndHasNoMigration() throws {
        let original = F.appSnapshot(active: F.journey())
        let report = try SnapshotCodec.decodeReport(try SnapshotCodec.encode(original))
        XCTAssertNil(report.migration)
        XCTAssertEqual(report.snapshot, original)
    }

    // 깨짐: v5 정류장 JSON에 남은 direction 키가 디코딩을 깨뜨리면 실패한다.
    func testV5StationWithLegacyDirectionKeyIsIgnored() throws {
        var root = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try SnapshotCodec.encode(F.appSnapshot())) as? [String: Any]
        )
        var state = try XCTUnwrap(root["state"] as? [String: Any])
        state["currentStation"] = ["id": "A", "name": "에이", "direction": -1]
        root["state"] = state
        let data = try JSONSerialization.data(withJSONObject: root)
        let report = try SnapshotCodec.decodeReport(data)
        XCTAssertEqual(report.snapshot.currentStation, F.stationA)
        XCTAssertNil(report.migration)
    }

    // 깨짐: decode가 decodeReport(...).snapshot과 다른 결과를 내면 실패한다.
    func testDecodeEqualsDecodeReportSnapshot() throws {
        let data = try F.legacyData(version: 4)
        XCTAssertEqual(try SnapshotCodec.decode(data), try SnapshotCodec.decodeReport(data).snapshot)
    }

    // 깨짐: v1에서 정류장을 비우지 않거나 migration을 .routeDataReset으로 내지 않으면 실패한다.
    func testV1WithStationsIsResetAndReported() throws {
        let report = try SnapshotCodec.decodeReport(Data(Self.v1Issued.utf8))
        XCTAssertEqual(report.migration, .routeDataReset)
        XCTAssertNil(report.snapshot.initialStation)
        XCTAssertNil(report.snapshot.currentStation)
        XCTAssertTrue(report.snapshot.cardIssued)
    }

    // 깨짐: v2~v4에서 정류장을 비우지 않거나 카드·기록을 잃으면 해당 버전에서 실패한다.
    func testV2ToV4StationsClearedCardsAndRecordsKept() throws {
        for version in 2...4 {
            let report = try SnapshotCodec.decodeReport(try F.legacyData(version: version))
            XCTAssertEqual(report.migration, .routeDataReset, "v\(version)")
            XCTAssertNil(report.snapshot.initialStation, "v\(version)")
            XCTAssertNil(report.snapshot.currentStation, "v\(version)")
            XCTAssertTrue(report.snapshot.cardIssued, "v\(version)")
            XCTAssertEqual(report.snapshot.cards.items.map(\.id), [F.cardID], "v\(version)")
            XCTAssertEqual(report.snapshot.records.items, [F.record], "v\(version)")
            XCTAssertNil(report.snapshot.journey.active, "v\(version)")
        }
    }

    // 깨짐: v3·v4 진행 여정을 살려 두면 실패한다 (여정은 내용을 해석하지 않고 비운다).
    func testV3AndV4ActiveJourneyIsDroppedWithMigration() throws {
        for version in 3...4 {
            let report = try SnapshotCodec.decodeReport(try F.legacyData(version: version, activeJourney: true))
            XCTAssertNil(report.snapshot.journey.active, "v\(version)")
            XCTAssertEqual(report.migration, .routeDataReset, "v\(version)")
            XCTAssertEqual(report.snapshot.cards.items.map(\.id), [F.cardID], "v\(version)")
            XCTAssertEqual(report.snapshot.records.items, [F.record], "v\(version)")
        }
    }

    // 깨짐: 정류장·여정이 없었는데도 migration을 내면 실패한다 (이전은 실제로 있었을 때만).
    func testLegacyWithoutStationsOrJourneyHasNoMigration() throws {
        for version in 2...4 {
            let report = try SnapshotCodec.decodeReport(try F.legacyData(version: version, station: nil))
            XCTAssertNil(report.migration, "v\(version)")
            XCTAssertEqual(report.snapshot.records.items, [F.record], "v\(version)")
        }
    }

    // 깨짐: 정류장 없이 여정만 있던 파일에서 migration을 내지 않으면 실패한다.
    func testLegacyJourneyWithoutStationsStillReportsMigration() throws {
        let report = try SnapshotCodec.decodeReport(try F.legacyData(version: 4, station: nil, activeJourney: true))
        XCTAssertEqual(report.migration, .routeDataReset)
        XCTAssertNil(report.snapshot.journey.active)
    }

    // 깨짐: 이전 결과를 다시 v5로 인코딩했을 때 version 5가 아니거나 재디코딩이 이전으로 보이면 실패한다.
    func testMigratedSnapshotReEncodesAsV5WithoutFurtherMigration() throws {
        let migrated = try SnapshotCodec.decodeReport(try F.legacyData(version: 4)).snapshot
        let again = try SnapshotCodec.decodeReport(try SnapshotCodec.encode(migrated))
        XCTAssertNil(again.migration)
        XCTAssertEqual(again.snapshot, migrated)
    }

    // 깨짐: 손상 판정(단계 불일치)을 옛 버전에서 건너뛰면 실패한다.
    func testInvalidLegacyStageIsStillRejected() {
        assertStorageIssue(.invalidState(.inconsistentStage)) {
            _ = try SnapshotCodec.decodeReport(Data(Self.v1Mismatch.utf8))
        }
    }

    // 깨짐: 옛 형식 카드가 둘 이상인 손상 파일을 이전하며 통과시키면 실패한다.
    func testLegacyWithTwoCardsIsRejected() throws {
        var root = try XCTUnwrap(
            try JSONSerialization.jsonObject(with: try F.legacyData(version: 4)) as? [String: Any]
        )
        var state = try XCTUnwrap(root["state"] as? [String: Any])
        var cards = try XCTUnwrap(state["cards"] as? [String: Any])
        let items = try XCTUnwrap(cards["items"] as? [[String: Any]])
        var second = try XCTUnwrap(items.first)
        second["id"] = "FM-76543210"
        cards["items"] = items + [second]
        state["cards"] = cards
        root["state"] = state
        let data = try JSONSerialization.data(withJSONObject: root)
        assertStorageIssue(.invalidState(.multipleCards(2))) {
            _ = try SnapshotCodec.decodeReport(data)
        }
    }

    // 깨짐: 버전 6 이상을 읽어 주면 실패한다.
    func testVersionSixIsUnsupported() {
        assertStorageIssue(.unsupportedVersion(6)) {
            _ = try SnapshotCodec.decodeReport(Data(#"{"version":6,"state":{}}"#.utf8))
        }
    }

    // MARK: LocalSnapshotStore.loadReport

    // 깨짐: loadReport가 migration을 버리거나 정류장을 비우지 않으면 실패한다.
    func testLoadReportReturnsMigrationForLegacyFile() throws {
        try withTemporaryFile { fileURL in
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try F.legacyData(version: 4).write(to: fileURL)
            let report = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).loadReport())
            XCTAssertEqual(report.migration, .routeDataReset)
            XCTAssertNil(report.snapshot.currentStation)
            XCTAssertEqual(report.snapshot.cards.items.map(\.id), [F.cardID])
        }
    }

    // 깨짐: v5 파일에서 migration을 내면 실패한다.
    func testLoadReportHasNoMigrationForV5File() throws {
        try withTemporaryFile { fileURL in
            let store = LocalSnapshotStore(fileURL: fileURL)
            try store.save(F.appSnapshot())
            let report = try XCTUnwrap(try store.loadReport())
            XCTAssertNil(report.migration)
            XCTAssertEqual(report.snapshot.currentStation, F.stationA)
        }
    }

    // 깨짐: 파일이 없을 때 nil이 아니면 실패한다.
    func testLoadReportIsNilWhenFileMissing() throws {
        try withTemporaryFile { fileURL in
            XCTAssertNil(try LocalSnapshotStore(fileURL: fileURL).loadReport())
        }
    }

    // 깨짐: load()가 loadReport의 snapshot과 다르면(정류장을 비우지 않으면) 실패한다.
    func testLoadReturnsReportSnapshot() throws {
        try withTemporaryFile { fileURL in
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try F.legacyData(version: 3).write(to: fileURL)
            let store = LocalSnapshotStore(fileURL: fileURL)
            XCTAssertEqual(try store.load(), try store.loadReport()?.snapshot)
            XCTAssertNil(try store.load()?.currentStation)
        }
    }

    // 깨짐: loadReport가 손상 파일을 삼키면 실패한다.
    func testLoadReportRejectsInvalidLegacyFile() throws {
        try withTemporaryFile { fileURL in
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data(Self.v1Mismatch.utf8).write(to: fileURL)
            assertStorageIssue(.invalidState(.inconsistentStage)) {
                _ = try LocalSnapshotStore(fileURL: fileURL).loadReport()
            }
        }
    }
}
