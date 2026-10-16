import Foundation
import XCTest
@testable import FocusMate

@MainActor
final class CardSupplementTests: XCTestCase {
    private static let v1Issued = Data(
        #"{"version":1,"state":{"cardIssued":true,"initialStation":null,"currentStation":null}}"#.utf8
    )
    private static let v1NotIssued = Data(
        #"{"version":1,"state":{"cardIssued":false,"initialStation":null,"currentStation":null}}"#.utf8
    )

    private func decode(_ bytes: Data?) throws -> AppSnapshot {
        try SnapshotCodec.decode(try XCTUnwrap(bytes))
    }

    private func assertCardID(_ id: String?, file: StaticString = #filePath, line: UInt = #line) {
        guard let id else { return XCTFail("카드 없음", file: file, line: line) }
        XCTAssertNotNil(id.range(of: #"^FM-[0-9]{8}$"#, options: .regularExpression), id, file: file, line: line)
    }

    // 깨짐 명명: 보충을 하지 않거나, version을 올리지 않거나, 정류장/journey/records를 건드리거나, 표시 경로를 바꾸면 실패.
    func testAC9_버전1_발급_파일은_시작하면_카드가_보충되고_나머지는_그대로다() throws {
        let fake = memoryStore(initial: Self.v1Issued)
        let model = AppModel(store: fake.store)

        model.start()

        let saved = try decode(fake.bytes())
        let root = try XCTUnwrap(JSONSerialization.jsonObject(with: try XCTUnwrap(fake.bytes())) as? [String: Any])
        XCTAssertEqual(root["version"] as? Int, 5)
        XCTAssertEqual(saved.cards.items.count, 1)
        assertCardID(saved.currentCard?.id)
        XCTAssertNil(saved.initialStation)
        XCTAssertNil(saved.currentStation)
        XCTAssertNil(saved.journey.active)
        XCTAssertEqual(saved.records.items.count, 0)
        XCTAssertEqual(model.presentedRoute, .initialStationEntry)
        XCTAssertEqual(model.snapshot, saved)
    }

    // 깨짐 명명: 새 프로세스(인스턴스)에서 이미 보충된 카드를 다시 만들거나 파일을 다시 쓰면 실패.
    func testAC9_두_번째_실행은_같은_카드_id와_같은_바이트를_유지한다() throws {
        let fake = memoryStore(initial: Self.v1Issued)
        AppModel(store: fake.store).start()
        let firstBytes = try XCTUnwrap(fake.bytes())
        let firstID = try decode(firstBytes).currentCard?.id
        let writesAfterFirst = fake.writeCount()

        let second = AppModel(store: fake.store)
        second.start()

        XCTAssertEqual(try decode(fake.bytes()).currentCard?.id, firstID)
        XCTAssertEqual(fake.bytes(), firstBytes)
        XCTAssertEqual(fake.writeCount(), writesAfterFirst)
        XCTAssertEqual(second.presentedRoute, .initialStationEntry)
    }

    // 깨짐 명명: 보충 실패를 saveFailure로 노출하거나 화면을 막거나 supplementFailure를 기록하지 않으면 실패.
    func testAC11_보충_쓰기가_실패해도_메인_화면은_열리고_실패만_기록된다() {
        let fake = memoryStore(initial: Self.v1Issued, writeFails: { _ in true })
        let model = AppModel(store: fake.store)

        model.start()

        XCTAssertEqual(model.presentedRoute, .initialStationEntry)
        XCTAssertEqual(model.supplementFailure, .writeFailed)
        XCTAssertNil(model.saveFailure)
        XCTAssertEqual(fake.bytes(), Self.v1Issued)
    }

    // 깨짐 명명: cardIssued=false 파일에도 카드를 보충하면 실패.
    func testAC12_미발급_버전1_파일은_보충하지_않고_발급_화면으로_간다() {
        let fake = memoryStore(initial: Self.v1NotIssued)
        let model = AppModel(store: fake.store)

        model.start()

        XCTAssertEqual(model.snapshot?.cards.items.count, 0)
        XCTAssertEqual(model.presentedRoute, .cardEntry)
        XCTAssertEqual(fake.writeCount(), 0)
        XCTAssertEqual(fake.bytes(), Self.v1NotIssued)
    }

    // 깨짐 명명: start 재호출마다 보충 저장을 다시 하면 실패 (성공 경로).
    func testIdempotent_같은_인스턴스에서_start를_두_번_불러도_보충_쓰기는_한_번이다() {
        let fake = memoryStore(initial: Self.v1Issued)
        let model = AppModel(store: fake.store)

        model.start()
        model.start()

        XCTAssertEqual(fake.writeCount(), 1)
    }

    // 깨짐 명명: 실패 뒤 start 재호출이 보충을 다시 시도하면 실패 (실패 경로).
    func testIdempotent_보충이_실패해도_start를_두_번_불러도_쓰기는_한_번이다() {
        let fake = memoryStore(initial: Self.v1Issued, writeFails: { _ in true })
        let model = AppModel(store: fake.store)

        model.start()
        model.start()

        XCTAssertEqual(fake.writeCount(), 1)
        XCTAssertEqual(model.supplementFailure, .writeFailed)
    }

    // 깨짐 명명: loadIfNeeded가 보충 쓰기를 하게 되면 "읽기는 쓰지 않는다"가 깨져 실패.
    func testRegression_loadIfNeeded만_부르면_보충_쓰기가_없다() {
        let fake = memoryStore(initial: Self.v1Issued)
        let model = AppModel(store: fake.store)

        model.loadIfNeeded()

        XCTAssertEqual(fake.writeCount(), 0)
        XCTAssertEqual(fake.bytes(), Self.v1Issued)
        XCTAssertEqual(model.snapshot?.cards.items.count, 0)
    }
}
