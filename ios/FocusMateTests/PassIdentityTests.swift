import Foundation
import XCTest
@testable import FocusMate

final class PassIdentityTests: XCTestCase {
    private static func snapshot(cardID: String) -> AppSnapshot {
        let card = CardSnapshot(id: cardID, issuedAt: Date(timeIntervalSince1970: 1_791_882_000))
        return AppSnapshot.empty.issuingCard(card)
    }

    // MARK: - AC-15 이름·번호 단일 출처

    // 깨짐: 이름을 displayName 대신 다른 문구로 채우거나 번호 구분자·간격을 바꾸면 실패
    func testAC15_카드가_있으면_이름과_번호_표기를_돌려준다() {
        let identity = PassIdentity.current(in: Self.snapshot(cardID: "FM-01234567"))

        XCTAssertEqual(identity?.name, "집중동행카드")
        XCTAssertEqual(identity?.numberText, "FM · 0123 4567")
    }

    // 깨짐: 카드가 없을 때 빈 값이나 기본 카드를 만들어 돌려주면 실패
    func testAC15_카드가_없으면_nil이다() {
        XCTAssertNil(PassIdentity.current(in: AppSnapshot.empty))
        XCTAssertNil(PassIdentity.current(in: nil))
    }

    // 깨짐: displayName 상수를 다른 값으로 바꾸면 실패
    func testAC15_표시_이름_상수는_집중동행카드다() {
        XCTAssertEqual(PassIdentity.displayName, "집중동행카드")
    }

    // 깨짐: 번호를 숫자로 변환했다가 문자열로 되돌려 앞자리 0이 사라지면 실패
    func testAC15_번호_표기는_앞자리_0을_유지한다() {
        let identity = PassIdentity(card: CardSnapshot(
            id: "FM-00000042",
            issuedAt: Date(timeIntervalSince1970: 1_791_882_000)
        ))

        XCTAssertEqual(identity.numberText, "FM · 0000 0042")
    }

    // MARK: - BR-1 카드 ID 팩토리

    // 깨짐: 0 채움 폭이나 FM- 접두를 바꾸면 실패
    func testBR1_고정_난수는_앞자리_0을_채운_8자리_ID가_된다() {
        let factory = CardSnapshotFactory(
            randomNumber: { 1_234_567 },
            now: { Date(timeIntervalSince1970: 1_791_882_000) }
        )

        XCTAssertEqual(factory.make().id, "FM-01234567")
    }

    // 깨짐: % 100_000_000 접기를 빼거나 다른 수로 나누면 실패
    func testBR1_범위_밖_난수는_나머지로_접는다() {
        let factory = CardSnapshotFactory(
            randomNumber: { 123_456_789 },
            now: { Date(timeIntervalSince1970: 1_791_882_000) }
        )

        XCTAssertEqual(factory.make().id, "FM-23456789")
    }

    // 깨짐: now()를 그대로 쓰거나 올림·반올림하면 실패
    func testBR1_발급_시각은_초_단위로_내린다() {
        let factory = CardSnapshotFactory(
            randomNumber: { 1 },
            now: { Date(timeIntervalSince1970: 1_791_882_000.75) }
        )

        XCTAssertEqual(factory.make().issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
    }
}
