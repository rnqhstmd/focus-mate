import Foundation
import XCTest
@testable import FocusMate

final class SnapshotCodecTests: XCTestCase {
    private static let seongsu = StationSnapshot(id: "seongsu", name: "성수", direction: 1)

    private static let v1Issued = """
    {"version":1,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}}}
    """
    private static let v1Mismatch = """
    {"version":1,"state":{"cardIssued":false,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}}}
    """
    private static let stageJSON = """
    "cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}
    """
    private static let emptyAreas = #""cards":{"items":[]},"journey":{"active":null},"records":{"items":[]}"#

    private func data(_ s: String) -> Data { Data(s.utf8) }

    private func v2(_ state: String) -> Data {
        data(#"{"version":2,"state":{\#(state)}}"#)
    }

    private func assertDecode(_ input: Data, _ expected: StorageIssue, file: StaticString = #filePath, line: UInt = #line) {
        let label = "input=\(String(decoding: input, as: UTF8.self))"
        assertStorageIssue(expected, label, file: file, line: line) {
            _ = try SnapshotCodec.decode(input)
        }
    }

    // 깨짐 명명: 인코더가 키/순서/version 값을 바꾸면 golden 문자열이 달라져 실패한다.
    func testEncodeEmptySnapshotMatchesGolden() throws {
        let out = try SnapshotCodec.encode(AppSnapshot.empty)
        XCTAssertEqual(
            String(decoding: out, as: UTF8.self),
            #"{"state":{"cardIssued":false,"cards":{"items":[]},"currentStation":null,"initialStation":null,"journey":{"active":null},"records":{"items":[]}},"version":2}"#
        )
    }

    // 깨짐 명명: v1 마이그레이션에서 정류장을 버리거나 영역 골격을 빼면 실패한다.
    func testEncodeOfDecodedV1MatchesGolden() throws {
        let out = try SnapshotCodec.encode(try SnapshotCodec.decode(data(Self.v1Issued)))
        XCTAssertEqual(
            String(decoding: out, as: UTF8.self),
            #"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":2}"#
        )
    }

    // 깨짐 명명: 디코더가 정류장 필드 하나라도 누락하면 왕복 비교가 실패한다.
    func testDecodeOfEncodeRoundTripsToEqualSnapshot() throws {
        let original = AppSnapshot.empty.updatingStage(
            cardIssued: true,
            initialStation: Self.seongsu,
            currentStation: StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1)
        )
        XCTAssertEqual(try SnapshotCodec.decode(try SnapshotCodec.encode(original)), original)
    }

    // 깨짐 명명: 인코더가 비결정적 키 순서를 쓰면 바이트가 달라져 실패한다.
    func testReEncodingSameStateYieldsIdenticalBytes() throws {
        let snapshot = try SnapshotCodec.decode(data(Self.v1Issued))
        let first = try SnapshotCodec.encode(snapshot)
        let second = try SnapshotCodec.encode(try SnapshotCodec.decode(first))
        XCTAssertEqual(first, second)
    }

    func testCurrentVersionIsTwo() {
        // 깨짐 명명: currentVersion이 2가 아니면 실패한다.
        XCTAssertEqual(SnapshotCodec.currentVersion, 2)
    }

    // 깨짐 명명: 헤더/버전 검사 순서나 분류가 틀리면 해당 입력에서 실패한다.
    func testHeaderAndVersionClassification() {
        let cases: [(String, StorageIssue)] = [
            ("", .corrupt),
            ("{}", .corrupt),
            (#"{"version":null}"#, .corrupt),
            (#"{"version":"2"}"#, .corrupt),
            ("not json", .corrupt),
            (#"{"state":{}}"#, .corrupt),
            (#"{"version":0,"state":{}}"#, .unsupportedVersion(0)),
            (#"{"version":-1,"state":{}}"#, .unsupportedVersion(-1)),
            (#"{"version":3,"state":{}}"#, .unsupportedVersion(3)),
            (#"{"version":999}"#, .unsupportedVersion(999)),
        ]
        for (input, issue) in cases {
            assertDecode(data(input), issue)
        }
    }

    // 깨짐 명명: v2에서 영역 키 누락을 허용(기본값 채움)하면 실패한다.
    func testV2MissingAreaKeyIsCorrupt() {
        let cases = [
            #""cardIssued":false,"initialStation":null,"currentStation":null,"journey":{"active":null},"records":{"items":[]}"#,
            #""cardIssued":false,"initialStation":null,"currentStation":null,"cards":{"items":[]},"records":{"items":[]}"#,
            #""cardIssued":false,"initialStation":null,"currentStation":null,"cards":{"items":[]},"journey":{"active":null}"#,
        ]
        for state in cases { assertDecode(v2(state), .corrupt) }
    }

    // 깨짐 명명: 영역이 객체가 아닌데 통과시키면 실패한다.
    func testV2AreaWithWrongShapeIsCorrupt() {
        let cases = [
            #""cards":[],"journey":{"active":null},"records":{"items":[]}"#,
            #""cards":null,"journey":{"active":null},"records":{"items":[]}"#,
            #""cards":{"items":[]},"journey":"x","records":{"items":[]}"#,
            #""cards":{"items":[]},"journey":{"active":null},"records":1"#,
        ]
        for area in cases {
            assertDecode(v2(#""cardIssued":false,"initialStation":null,"currentStation":null,\#(area)"#), .corrupt)
        }
    }

    // 깨짐 명명: 영역 골격 키(items/active) 누락·null·잘못된 타입을 허용하면 실패한다.
    func testV2AreaSkeletonViolationsAreCorrupt() {
        let cases = [
            #""cards":{},"journey":{"active":null},"records":{"items":[]}"#,
            #""cards":{"items":[]},"journey":{},"records":{"items":[]}"#,
            #""cards":{"items":[]},"journey":{"active":null},"records":{}"#,
            #""cards":{"items":null},"journey":{"active":null},"records":{"items":[]}"#,
            #""cards":{"items":{}},"journey":{"active":null},"records":{"items":[]}"#,
        ]
        for area in cases {
            assertDecode(v2(#""cardIssued":false,"initialStation":null,"currentStation":null,\#(area)"#), .corrupt)
        }
    }

    // 깨짐 명명: 카드 원소의 필수 키가 없거나 여정·기록이 미정의 원소면 .corrupt로 처리하지 않으면 실패한다.
    func testV2MalformedOrUndefinedElementsAreCorrupt() {
        let cases = [
            #""cards":{"items":[1]},"journey":{"active":null},"records":{"items":[]}"#,
            #""cards":{"items":[{}]},"journey":{"active":null},"records":{"items":[]}"#,
            #""cards":{"items":[]},"journey":{"active":null},"records":{"items":[{}]}"#,
            #""cards":{"items":[]},"journey":{"active":"x"},"records":{"items":[]}"#,
            #""cards":{"items":[]},"journey":{"active":{}},"records":{"items":[]}"#,
        ]
        for area in cases {
            assertDecode(v2(#""cardIssued":false,"initialStation":null,"currentStation":null,\#(area)"#), .corrupt)
        }
    }

    // 깨짐 명명: 모르는 키에서 실패(strict 디코딩)하면 실패한다.
    func testUnknownKeysInAreasAndStateRootAreIgnored() throws {
        let plain = try SnapshotCodec.decode(v2(#""cardIssued":false,"initialStation":null,"currentStation":null,\#(Self.emptyAreas)"#))
        let noisy = try SnapshotCodec.decode(v2(
            #""extra":1,"cardIssued":false,"initialStation":null,"currentStation":null,"cards":{"items":[],"x":1},"journey":{"active":null,"y":[]},"records":{"items":[],"z":"q"}"#
        ))
        XCTAssertEqual(noisy, plain)
        XCTAssertEqual(noisy, AppSnapshot.empty)
    }

    // 깨짐 명명: v1 결과에 validate를 생략하면 invalidState가 아니라 성공해 실패한다.
    func testV1InconsistentStageIsInvalidState() {
        assertDecode(data(Self.v1Mismatch), .invalidState(.inconsistentStage))
    }

    // 깨짐 명명: 영역 누락 검사 전에 validate를 하면 invalidState가 되어 실패한다.
    func testV2MissingAreaTakesPrecedenceOverInconsistentStage() {
        assertDecode(
            v2(#""cardIssued":false,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1},"journey":{"active":null},"records":{"items":[]}"#),
            .corrupt
        )
    }

    // 깨짐 명명: v2에서 validate를 생략하면 성공해 실패한다.
    func testV2WellFormedButInconsistentStageIsInvalidState() {
        assertDecode(
            v2(#""cardIssued":false,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1},\#(Self.emptyAreas)"#),
            .invalidState(.inconsistentStage)
        )
    }

    // 깨짐 명명: 마이그레이션이 발급/정류장을 보존하지 않거나 영역을 비우지 않으면 실패한다.
    func testMigrateV1PreservesStageFieldsAndEmptiesAreas() throws {
        let legacy = try JSONDecoder().decode(
            LegacySnapshotV1.self,
            from: data(#"{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seoulForest","name":"서울숲","direction":-1}}"#)
        )
        let migrated = SnapshotCodec.migrateV1(legacy)
        XCTAssertEqual(
            migrated,
            AppSnapshot.empty.updatingStage(
                cardIssued: true,
                initialStation: Self.seongsu,
                currentStation: StationSnapshot(id: "seoulForest", name: "서울숲", direction: -1)
            )
        )
        XCTAssertTrue(migrated.cards.items.isEmpty)
        XCTAssertNil(migrated.journey.active)
        XCTAssertTrue(migrated.records.items.isEmpty)
    }

    // 깨짐 명명: v1 읽기에서 정류장이나 launchRoute 계산이 틀리면 실패한다.
    func testDecodeV1IssuedStateMigratesToMainRoute() throws {
        let snapshot = try SnapshotCodec.decode(data(Self.v1Issued))
        XCTAssertTrue(snapshot.cardIssued)
        XCTAssertEqual(snapshot.initialStation, Self.seongsu)
        XCTAssertEqual(snapshot.currentStation, Self.seongsu)
        XCTAssertTrue(snapshot.cards.items.isEmpty)
        XCTAssertNil(snapshot.journey.active)
        XCTAssertTrue(snapshot.records.items.isEmpty)
        XCTAssertEqual(try snapshot.launchRoute(), .main)
    }
}
