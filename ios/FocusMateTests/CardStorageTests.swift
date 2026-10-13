import Foundation
import XCTest
@testable import FocusMate

final class CardStorageTests: XCTestCase {
    private static let seongsu = StationSnapshot(id: "seongsu", name: "성수", direction: 1)
    private static let issuedAt = Date(timeIntervalSince1970: 1_791_882_000) // 2026-10-13T09:00:00Z

    private static let stations = #""currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"}"#

    private static func file(issued: Bool = true, stations: String = stations, cards: String, records: String = "") -> Data {
        Data(#"{"state":{"cardIssued":\#(issued),"cards":{"items":[\#(cards)]},\#(stations),"journey":{"active":null},"records":{"items":[\#(records)]}},"version":2}"#.utf8)
    }

    private static func card(id: String = "FM-01234567", issuedAt: String = "2026-10-13T09:00:00Z") -> String {
        #"{"id":"\#(id)","issuedAt":"\#(issuedAt)"}"#
    }

    private static let nullStations = #""currentStation":null,"initialStation":null"#

    // 깨짐 명명: id를 숫자로 바꿔 앞자리 0을 잃거나, 날짜를 다른 형식으로 쓰거나, 재저장 바이트가 달라지거나, version이 2가 아니면 실패.
    func testAC13_카드항목은_저장_로드_재저장해도_값과_바이트가_같다() throws {
        try withTemporaryFile { fileURL in
            let snapshot = Self.stage(true, Self.seongsu, Self.seongsu)
                .issuingCard(CardSnapshot(id: "FM-01234567", issuedAt: Self.issuedAt))
            let store = LocalSnapshotStore(fileURL: fileURL)
            try store.save(snapshot)
            let firstBytes = try Data(contentsOf: fileURL)

            let loaded = try XCTUnwrap(try store.load())
            XCTAssertEqual(loaded.currentCard, CardSnapshot(id: "FM-01234567", issuedAt: Self.issuedAt))
            XCTAssertEqual(loaded.currentCard?.id, "FM-01234567")
            XCTAssertEqual(loaded, snapshot)

            try store.save(loaded)
            XCTAssertEqual(try Data(contentsOf: fileURL), firstBytes)

            let root = try XCTUnwrap(try JSONSerialization.jsonObject(with: firstBytes) as? [String: Any])
            XCTAssertEqual(root["version"] as? Int, 2)
            XCTAssertEqual(
                String(decoding: firstBytes, as: UTF8.self),
                #"{"state":{"cardIssued":true,"cards":{"items":[{"id":"FM-01234567","issuedAt":"2026-10-13T09:00:00Z"}]},"currentStation":{"direction":1,"id":"seongsu","name":"성수"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":2}"#
            )
        }
    }

    // 깨짐 명명: 짧은 id를 디코딩에서 통과시키거나 .corrupt로 분류하면 실패.
    func testAC14a_짧은_카드번호는_invalidCardID이다() throws {
        try assertLoadIssue(Self.file(cards: Self.card(id: "FM-1234")), .invalidState(.invalidCardID))
    }

    // 깨짐 명명: FM- 접두를 검사하지 않으면 실패.
    func testAC14b_접두가_다른_카드번호는_invalidCardID이다() throws {
        try assertLoadIssue(Self.file(cards: Self.card(id: "NS-12345678")), .invalidState(.invalidCardID))
    }

    // 깨짐 명명: 날짜 파싱 실패를 invalidState로 분류하거나 무시하면 실패.
    func testAC14c_날짜가_아닌_issuedAt은_corrupt이다() throws {
        try assertLoadIssue(Self.file(cards: Self.card(issuedAt: "어제")), .corrupt)
    }

    // 깨짐 명명: 카드 수 검사를 생략하거나 개수를 잘못 담으면 실패.
    func testAC14d_카드_두_장은_multipleCards_2이다() throws {
        let cards = Self.card(id: "FM-01234567") + "," + Self.card(id: "FM-76543210")
        try assertLoadIssue(Self.file(cards: cards), .invalidState(.multipleCards(2)))
    }

    // 깨짐 명명: 미발급 상태의 카드를 허용하면 실패.
    func testAC14e_미발급인데_카드가_있으면_cardWithoutIssuance이다() throws {
        try assertLoadIssue(
            Self.file(issued: false, stations: Self.nullStations, cards: Self.card()),
            .invalidState(.cardWithoutIssuance)
        )
    }

    // 깨짐 명명: 미정의 기록 원소를 버리거나 invalidState로 분류하면 실패.
    func testAC14f_정의되지_않은_기록_원소는_corrupt이다() throws {
        try assertLoadIssue(Self.file(cards: "", records: #"{"kind":"x"}"#), .corrupt)
    }

    // 깨짐 명명: 잘못된 데이터 파일 위에 쓰기를 허용하거나 바이트를 바꾸면 실패.
    func testAC14_잘못된_데이터_파일은_저장이_차단되고_바이트가_보존된다() throws {
        let cases: [(name: String, bytes: Data, issue: StorageIssue)] = [
            ("a", Self.file(cards: Self.card(id: "FM-1234")), .invalidState(.invalidCardID)),
            ("b", Self.file(cards: Self.card(id: "NS-12345678")), .invalidState(.invalidCardID)),
            ("c", Self.file(cards: Self.card(issuedAt: "어제")), .corrupt),
            ("d", Self.file(cards: Self.card() + "," + Self.card(id: "FM-76543210")), .invalidState(.multipleCards(2))),
            ("e", Self.file(issued: false, stations: Self.nullStations, cards: Self.card()), .invalidState(.cardWithoutIssuance)),
            ("f", Self.file(cards: "", records: #"{"kind":"x"}"#), .corrupt),
        ]
        for item in cases {
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
                    try store.save(Self.stage(true, Self.seongsu, Self.seongsu))
                }
                XCTAssertEqual(directoryCalls, 0, item.name)
                XCTAssertEqual(writeCalls, 0, item.name)
                XCTAssertEqual(try Data(contentsOf: fileURL), item.bytes, item.name)
            }
        }
    }

    // 깨짐 명명: 길이·접두·숫자 판정이 느슨하면(길이 10/12 허용, 문자·전각 숫자 허용) 실패.
    func testCardID_형식_경계를_판정한다() {
        XCTAssertTrue(CardSnapshot.isValidID("FM-01234567"))
        XCTAssertFalse(CardSnapshot.isValidID("FM-0123456"))
        XCTAssertFalse(CardSnapshot.isValidID("FM-012345678"))
        XCTAssertFalse(CardSnapshot.isValidID("FM-0123456A"))
        XCTAssertFalse(CardSnapshot.isValidID("FM-０１２３４５６７"))
        XCTAssertFalse(CardSnapshot.isValidID("fm-01234567"))
    }

    // 깨짐 명명: 발급됐지만 카드가 없는 상태(보충 대상)를 오류로 막으면 실패.
    func testCardIssued이고_카드가_0개인_파일은_유효하게_로드된다() throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, Self.file(cards: ""))

            let loaded = try XCTUnwrap(try LocalSnapshotStore(fileURL: fileURL).load())

            XCTAssertTrue(loaded.cardIssued)
            XCTAssertNil(loaded.currentCard)
            XCTAssertTrue(loaded.needsCardSupplement)
        }
    }

    private func assertLoadIssue(_ bytes: Data, _ expected: StorageIssue, file: StaticString = #filePath, line: UInt = #line) throws {
        try withTemporaryFile { fileURL in
            try seed(fileURL, bytes)
            assertStorageIssue(expected, file: file, line: line) {
                _ = try LocalSnapshotStore(fileURL: fileURL).load()
            }
        }
    }

    private func seed(_ fileURL: URL, _ bytes: Data) throws {
        try FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try bytes.write(to: fileURL)
    }
}
