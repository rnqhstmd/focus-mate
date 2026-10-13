import Foundation
import XCTest

@MainActor
final class CardStorageFlowTests: XCTestCase {
    private let timeout: TimeInterval = 3
    private let idPattern = "^FM-[0-9]{8}$"

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: AC-10

    func testAC10_카드_없는_기존_사용자는_메인으로_가고_카드가_보충된다() throws {
        // 깨짐 명명: 보충하지 않거나 cardEntry를 거치거나 실행마다 id가 바뀌거나 진동이 울리면 실패한다.
        let h = FocusMateUIHarness.launch(seed: "issuedWithoutCard")
        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardEntry").exists)
        let first = try cardID(try h.snapshot())
        XCTAssertNotNil(first.range(of: idPattern, options: .regularExpression), "id: \(first)")
        XCTAssertEqual(try cardCount(try h.snapshot()), 1)
        XCTAssertEqual(h.element("main.currentStation").value as? String, "서울숲")
        XCTAssertEqual(try h.diagnostic("test.hapticCount"), "0")

        h.relaunch()

        XCTAssertTrue(h.element("screen.main").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardEntry").exists)
        XCTAssertEqual(try cardCount(try h.snapshot()), 1)
        XCTAssertEqual(try cardID(try h.snapshot()), first)
        XCTAssertEqual(h.element("main.currentStation").value as? String, "서울숲")
        XCTAssertEqual(try h.diagnostic("test.hapticCount"), "0")
    }

    // MARK: AC-14

    nonisolated private static let station = #""currentStation":{"direction":-1,"id":"seoulForest","name":"서울숲"},"initialStation":{"direction":1,"id":"seongsu","name":"성수"}"#
    private static let card1 = #"{"id":"FM-20261013","issuedAt":"2026-10-13T09:00:00Z"}"#

    private static func raw(issued: Bool = true, cards: String, records: String = "", stations: String = station) -> String {
        #"{"state":{"cardIssued":\#(issued),"cards":{"items":[\#(cards)]},\#(stations),"journey":{"active":null},"records":{"items":[\#(records)]}},"version":2}"#
    }

    private static let nullStations = #""currentStation":null,"initialStation":null"#
    private static let notReadable = "저장된 이용 상태를 확인할 수 없어요."
    private static let badFormat = "저장된 데이터 형식을 읽을 수 없어요."

    func testAC14a_카드_id가_너무_짧으면_저장소_오류로_바이트를_보존한다() throws {
        try assertPreserved(
            seed: "invalidCardShortId",
            json: Self.raw(cards: #"{"id":"FM-1234","issuedAt":"2026-10-13T09:00:00Z"}"#),
            message: Self.notReadable)
    }

    func testAC14b_카드_id_접두어가_다르면_저장소_오류로_바이트를_보존한다() throws {
        try assertPreserved(
            seed: "invalidCardPrefix",
            json: Self.raw(cards: #"{"id":"NS-12345678","issuedAt":"2026-10-13T09:00:00Z"}"#),
            message: Self.notReadable)
    }

    func testAC14c_발급_시각이_날짜가_아니면_형식_오류로_바이트를_보존한다() throws {
        try assertPreserved(
            seed: "invalidCardIssuedAt",
            json: Self.raw(cards: #"{"id":"FM-20261013","issuedAt":"어제"}"#),
            message: Self.badFormat)
    }

    func testAC14d_카드가_두_장이면_저장소_오류로_바이트를_보존한다() throws {
        try assertPreserved(
            seed: "duplicateCards",
            json: Self.raw(cards: Self.card1 + #","# + #"{"id":"FM-20261014","issuedAt":"2026-10-13T09:00:00Z"}"#),
            message: Self.notReadable)
    }

    func testAC14e_미발급인데_카드가_있으면_저장소_오류로_바이트를_보존한다() throws {
        try assertPreserved(
            seed: "cardWithoutIssuance",
            json: Self.raw(issued: false, cards: Self.card1, stations: Self.nullStations),
            message: Self.notReadable)
    }

    func testAC14f_정의되지_않은_기록이_있으면_형식_오류로_보충_없이_바이트를_보존한다() throws {
        try assertPreserved(
            seed: "undefinedRecord",
            json: Self.raw(cards: "", records: #"{"kind":"x"}"#),
            message: Self.badFormat)
    }

    // MARK: helpers

    private func assertPreserved(seed: String, json: String, message: String) throws {
        // 깨짐 명명: 보충·정규화로 파일을 다시 쓰거나 다른 화면으로 가거나 문구가 다르면 실패한다.
        let expected = Data(json.utf8).base64EncodedString()
        let h = FocusMateUIHarness.launch(seed: seed)

        try assertStorageError(h, message: message, expected: expected)
        h.relaunch()
        try assertStorageError(h, message: message, expected: expected)
    }

    private func assertStorageError(_ h: FocusMateUIHarness, message: String, expected: String) throws {
        XCTAssertTrue(h.element("screen.storageError").waitForExistence(timeout: timeout))
        XCTAssertFalse(h.element("screen.cardEntry").exists)
        XCTAssertFalse(h.element("screen.main").exists)
        let error = h.element("storage.error")
        XCTAssertTrue(error.waitForExistence(timeout: timeout))
        XCTAssertEqual(error.value as? String, message)
        XCTAssertEqual(try h.diagnostic("test.persistedBytes"), expected)
    }

    private func cardItems(_ snapshot: [String: Any]) throws -> [[String: Any]] {
        let cards = try XCTUnwrap(snapshot["cards"] as? [String: Any], "cards 섹션 없음")
        return try XCTUnwrap(cards["items"] as? [[String: Any]], "cards.items 없음")
    }

    private func cardCount(_ snapshot: [String: Any]) throws -> Int {
        try cardItems(snapshot).count
    }

    private func cardID(_ snapshot: [String: Any]) throws -> String {
        let first = try XCTUnwrap(try cardItems(snapshot).first, "카드 없음")
        return try XCTUnwrap(first["id"] as? String)
    }
}
