import Foundation
import XCTest
@testable import FocusMate

final class StorageV2Tests: XCTestCase {
    private enum ProbeError: Error { case expected }

    private static let seongsu = StationSnapshot(id: "seongsu", name: "성수")
    private static let seoulForest = StationSnapshot(id: "seoulForest", name: "서울숲")

    private static let v1Seongsu = Data(
        #"{"version":1,"state":{"cardIssued":true,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}}}"#.utf8
    )
    private static let v5Seongsu = Data(
        #"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"id":"seongsu","name":"성수"},"initialStation":{"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":5}"#.utf8
    )
    private static let g2Seongsu = Data(
        #"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":2}"#.utf8
    )
    private static let v1Inconsistent = Data(
        #"{"version":1,"state":{"cardIssued":false,"initialStation":{"id":"seongsu","name":"성수","direction":1},"currentStation":{"id":"seongsu","name":"성수","direction":1}}}"#.utf8
    )
    private static let v2MissingRecords = Data(
        #"{"state":{"cardIssued":true,"cards":{"items":[]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null}},"version":2}"#.utf8
    )

    // 깨짐 명명: load가 v1을 읽지 못하고 .corrupt/.unsupportedVersion(1)을 던지거나 읽기 중 파일을 바꾸면 실패.
    // (W16b: v1의 정류장은 비워지므로 정류장 값은 여기서 보지 않는다. 비움 동작은 별도 파일이 다룬다.)
    func testAC1_v1파일은_카드_기록_여정_없이_읽히고_파일은_변하지_않는다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v1Seongsu)

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertEqual(loaded.cards.items.count, 0)
            XCTAssertNil(loaded.journey.active)
            XCTAssertEqual(loaded.records.items.count, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.v1Seongsu)
        }
    }

    // 깨짐 명명: 읽기 중 변환 결과를 디스크에 쓰거나 디렉토리를 만들면 카운트가 1이 되어 실패.
    func testAC1_v1읽기는_디렉토리생성과_쓰기를_하지_않는다() throws {
        var directoryCalls = 0
        var writeCalls = 0
        let store = LocalSnapshotStore(
            fileURL: URL(fileURLWithPath: "/unused/app-state.json"),
            readData: { _ in Self.v1Seongsu },
            createDirectory: { _ in directoryCalls += 1 },
            writeData: { _, _ in writeCalls += 1 }
        )

        let loaded = try XCTUnwrap(try store.load())

        XCTAssertEqual(loaded.cards.items.count, 0)
        XCTAssertEqual(directoryCalls, 0)
        XCTAssertEqual(writeCalls, 0)
    }

    // 깨짐 명명: save가 version 1로 쓰거나 새 영역 키를 빠뜨리면 실패.
    func testAC2a_파일없음에서_저장하면_v5형식이고_재로드와_재저장이_동일하다() throws {
        try withTemporaryFile { fileURL in
            let snapshot = Self.stage(true, Self.seongsu, Self.seoulForest)
            try LocalSnapshotStore(fileURL: fileURL).save(snapshot)
            let firstBytes = try Data(contentsOf: fileURL)

            let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: firstBytes) as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 5)
            let state = try XCTUnwrap(root["state"] as? [String: Any])
            XCTAssertEqual(
                Set(state.keys),
                ["cardIssued", "initialStation", "currentStation", "cards", "journey", "records"]
            )

            XCTAssertEqual(try LocalSnapshotStore(fileURL: fileURL).load(), snapshot)

            try LocalSnapshotStore(fileURL: fileURL).save(snapshot)
            XCTAssertEqual(try Data(contentsOf: fileURL), firstBytes)
        }
    }

    // 깨짐 명명: v5 로드 실패 또는 저장 바이트가 v5 기대값과 다르면(키 누락·version 4/6·정류장 값 손실·direction 키 잔존) 실패.
    func testAC2b_v5에서_읽은_상태를_저장하면_정확한_v5바이트가_기록된다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v5Seongsu)
            let store = LocalSnapshotStore(fileURL: fileURL)
            let loaded = try XCTUnwrap(try store.load())

            try store.save(loaded)

            XCTAssertEqual(try Data(contentsOf: fileURL), Self.v5Seongsu)
            let reloaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())
            XCTAssertEqual(reloaded, Self.stage(true, Self.seongsu, Self.seongsu))
        }
    }

    // 깨짐 명명: 미지원/손상 파일을 읽어 버리거나 다른 오류 종류를 던지면 실패.
    func testAC3_보호대상_파일은_읽기_오류를_던진다() throws {
        for item in Self.protectedCases {
            try withTemporaryFile { fileURL in
                try seed(fileURL, item.bytes)
                let store = LocalSnapshotStore(fileURL: fileURL)

                assertStorageIssue(item.issue, "load: \(item.name)") {
                    _ = try store.load()
                }
            }
        }
    }

    // 깨짐 명명: 보호 파일 위에 덮어쓰거나 디렉토리 생성/쓰기를 시도하면 실패.
    func testAC3_보호대상_파일은_저장이_차단되고_바이트가_보존된다() throws {
        for item in Self.protectedCases {
            try withTemporaryFile { fileURL in
                try seed(fileURL, item.bytes)
                var directoryCalls = 0
                var writeCalls = 0
                let store = LocalSnapshotStore(
                    fileURL: fileURL,
                    createDirectory: { _ in directoryCalls += 1 },
                    writeData: { _, _ in writeCalls += 1 }
                )

                assertStorageIssue(.writeBlocked(item.issue), "save: \(item.name)") {
                    try store.save(Self.stage(true, Self.seongsu, Self.seoulForest))
                }
                XCTAssertEqual(directoryCalls, 0, item.name)
                XCTAssertEqual(writeCalls, 0, item.name)
                XCTAssertEqual(try Data(contentsOf: fileURL), item.bytes, item.name)
            }
        }
    }

    // 깨짐 명명: 내용 불일치 v1을 통과시키면 load가 값을 반환해 실패.
    func testAC4a_내용불일치_v1은_읽기_오류이고_저장이_차단된다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.v1Inconsistent)
            var writeCalls = 0
            let store = LocalSnapshotStore(fileURL: fileURL, writeData: { _, _ in writeCalls += 1 })

            assertStorageIssue(.invalidState(.inconsistentStage)) {
                _ = try store.load()
            }
            assertStorageIssue(.writeBlocked(.invalidState(.inconsistentStage))) {
                try store.save(Self.stage(true, Self.seongsu, Self.seoulForest))
            }
            XCTAssertEqual(writeCalls, 0)
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.v1Inconsistent)
        }
    }

    // 깨짐 명명: 쓰기 오류를 삼키거나 .writeFailed 외 오류로 바꾸거나 기존 파일을 직접 변형하면 실패.
    func testAC4b_쓰기실패는_writeFailed이고_기존_v2파일이_보존된다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.g2Seongsu)
            let store = LocalSnapshotStore(
                fileURL: fileURL,
                writeData: { _, _ in throw ProbeError.expected }
            )

            assertStorageIssue(.writeFailed) {
                try store.save(Self.stage(true, Self.seongsu, Self.seoulForest))
            }
            XCTAssertEqual(try Data(contentsOf: fileURL), Self.g2Seongsu)
        }
    }

    private static let protectedCases: [(name: String, bytes: Data, issue: StorageIssue)] = [
        ("버전 6", Data(#"{"version":6,"state":null}"#.utf8), .unsupportedVersion(6)),
        ("버전 999", Data(#"{"version":999,"state":null}"#.utf8), .unsupportedVersion(999)),
        ("버전 0", Data(#"{"version":0,"state":null}"#.utf8), .unsupportedVersion(0)),
        ("빈 파일", Data(), .corrupt),
        ("버전 없음", Data(#"{"state":{}}"#.utf8), .corrupt),
        ("버전 문자열", Data(#"{"version":"2"}"#.utf8), .corrupt),
        ("v2 records 누락", v2MissingRecords, .corrupt),
    ]

    private func seed(_ fileURL: URL, _ bytes: Data) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try bytes.write(to: fileURL)
    }
}
