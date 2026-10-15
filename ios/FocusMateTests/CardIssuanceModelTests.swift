import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class CardIssuanceModelTests: XCTestCase {
    private static let seongsu = StationSnapshot(id: "seongsu", name: "성수")
    private static let fixedNow = Date(timeIntervalSince1970: 1_791_882_000)

    private static let issuedV2 = Data(
        #"{"state":{"cardIssued":true,"cards":{"items":[{"id":"FM-01234567","issuedAt":"2026-10-13T09:00:00Z"}]},"currentStation":null,"initialStation":null,"journey":{"active":null},"records":{"items":[]}},"version":2}"#.utf8
    )
    private static let mainV5 = Data(
        #"{"state":{"cardIssued":true,"cards":{"items":[{"id":"FM-01234567","issuedAt":"2026-10-13T09:00:00Z"}]},"currentStation":{"id":"seongsu","name":"성수"},"initialStation":{"id":"seongsu","name":"성수"},"journey":{"active":null},"records":{"items":[]}},"version":5}"#.utf8
    )

    private func factory(_ values: [UInt32]) -> CardSnapshotFactory {
        let random = SequenceRandom(values)
        return CardSnapshotFactory(randomNumber: { random.next() }, now: { Self.fixedNow })
    }

    private func idsInFile(_ bytes: Data?) throws -> [String] {
        let data = try XCTUnwrap(bytes)
        return try SnapshotCodec.decode(data).cards.items.map(\.id)
    }

    // 깨짐 명명: issueCard가 launchState를 .initialStationEntry로 바꾸지 않거나, presentedRoute가 즉시 .initialStationEntry가 되면 실패.
    func testAC3_발급_성공_직후_완료_화면을_유지한다() throws {
        let fake = memoryStore(initial: nil)
        let model = AppModel(store: fake.store, cardFactory: factory([12_345_678]))
        model.start()

        XCTAssertTrue(model.issueCard())

        XCTAssertEqual(model.presentedRoute, .cardEntry)
        XCTAssertEqual(model.launchState, .ready(.initialStationEntry))
        XCTAssertEqual(model.snapshot?.currentCard?.id, "FM-12345678")
        XCTAssertEqual(try idsInFile(fake.bytes()), ["FM-12345678"])
    }

    // 깨짐 명명: finishCardIssuance가 플래그를 내리지 않으면 실패.
    func testAC4_완료_후_다음_단계로_진행하면_정류장_입력_경로가_된다() {
        let fake = memoryStore(initial: nil)
        let model = AppModel(store: fake.store, cardFactory: factory([12_345_678]))
        model.start()
        model.issueCard()

        model.finishCardIssuance()

        XCTAssertEqual(model.presentedRoute, .initialStationEntry)
    }

    // 깨짐 명명: 플래그가 영속되어 재실행이 .cardEntry로 시작하거나 카드 id가 바뀌면 실패.
    func testAC6_재실행하면_정류장_입력으로_시작하고_카드_id가_같다() {
        let fake = memoryStore(initial: nil)
        let first = AppModel(store: fake.store, cardFactory: factory([12_345_678]))
        first.start()
        first.issueCard()

        let second = AppModel(store: fake.store, cardFactory: factory([99_999_999]))
        second.start()

        XCTAssertEqual(second.presentedRoute, .initialStationEntry)
        XCTAssertEqual(second.snapshot?.currentCard?.id, "FM-12345678")
        XCTAssertEqual(fake.writeCount(), 1)
    }

    // 깨짐 명명: finish 뒤 issueCard가 다시 진행되어 카드를 쓰거나 .cardEntry로 되돌리면 실패.
    func testAC4_발급_뒤에는_경로가_다시_cardEntry가_되지_않고_재발급은_쓰기가_없다() {
        let fake = memoryStore(initial: nil)
        let model = AppModel(store: fake.store, cardFactory: factory([12_345_678, 22_222_222]))
        model.start()
        model.issueCard()
        model.finishCardIssuance()

        XCTAssertFalse(model.issueCard())

        XCTAssertEqual(model.presentedRoute, .initialStationEntry)
        XCTAssertEqual(model.snapshot?.currentCard?.id, "FM-12345678")
        XCTAssertEqual(fake.writeCount(), 1)
    }

    // 깨짐 명명: 실패 시 snapshot/saveFailure를 바꾸거나 false 대신 true를 반환하면 실패.
    func testAC7_쓰기가_모두_실패하면_발급은_false이고_상태가_그대로다() {
        let fake = memoryStore(initial: nil, writeFails: { _ in true })
        let model = AppModel(store: fake.store, cardFactory: factory([12_345_678]))
        model.start()

        XCTAssertFalse(model.issueCard())

        XCTAssertNil(model.saveFailure)
        XCTAssertEqual(model.snapshot?.cardIssued, false)
        XCTAssertEqual(model.snapshot?.cards.items.count, 0)
        XCTAssertEqual(model.presentedRoute, .cardEntry)
        XCTAssertEqual(fake.writeCount(), 1)
        XCTAssertNil(fake.bytes())
    }

    // 깨짐 명명: 재시도에서 난수를 재사용하지 않고 첫 시도 id를 쓰거나 카드가 2장 쌓이면 실패 (순차 난수로 구분).
    func testAC8_첫_쓰기_실패_뒤_재시도하면_카드가_한_장만_저장된다() throws {
        let fake = memoryStore(initial: nil, writeFails: { $0 == 1 })
        let model = AppModel(store: fake.store, cardFactory: factory([11_111_111, 22_222_222]))
        model.start()

        XCTAssertFalse(model.issueCard())
        XCTAssertEqual(model.snapshot?.cards.items.count, 0)

        XCTAssertTrue(model.issueCard())
        XCTAssertEqual(model.snapshot?.cards.items.count, 1)
        XCTAssertEqual(try idsInFile(fake.bytes()), ["FM-22222222"])
        XCTAssertEqual(fake.writeCount(), 2)
    }

    // 깨짐 명명: 이미 발급된 상태에서 가드 없이 다시 쓰면 실패.
    func testBR2_이미_발급된_상태에서는_발급이_거부되고_쓰기가_없다() {
        for bytes in [Self.issuedV2, Self.mainV5] {
            let fake = memoryStore(initial: bytes)
            let model = AppModel(store: fake.store, cardFactory: factory([55_555_555]))
            model.start()
            let writesAfterStart = fake.writeCount()

            XCTAssertFalse(model.issueCard())

            XCTAssertEqual(fake.writeCount(), writesAfterStart)
            XCTAssertEqual(fake.bytes(), bytes)
        }
    }

    // 깨짐 명명: load 전 snapshot nil에서 강제 언래핑하거나 쓰기를 시도하면 실패.
    func testBR3_로드_전에는_발급이_거부되고_쓰기가_없다() {
        let fake = memoryStore(initial: nil)
        let model = AppModel(store: fake.store, cardFactory: factory([12_345_678]))

        XCTAssertFalse(model.issueCard())

        XCTAssertEqual(fake.writeCount(), 0)
        XCTAssertNil(model.snapshot)
    }
}
