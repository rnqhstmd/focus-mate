import Foundation
import XCTest
@testable import FocusMate

#if DEBUG
final class ProfileSeedTests: XCTestCase {
    private func decodeSeed() throws -> AppSnapshot {
        let raw = try XCTUnwrap(UITestBootstrap.rawSeeds["profileRecords"])
        return try SnapshotCodec.decode(Data(raw.utf8))
    }

    // 깨짐 명명: 시드 키 제거, 저장 형식(version/필드) 위반, 카드 id 변경 시 실패.
    func testAC6_profileRecords_시드는_저장_형식_검증을_통과한다() throws {
        XCTAssertNoThrow(try decodeSeed())
    }

    // 깨짐 명명: 카드 id가 "FM-12345678"이 아니거나 카드가 없으면 실패.
    func testAC6_profileRecords_시드는_카드번호_FM12345678을_담는다() throws {
        XCTAssertEqual(try decodeSeed().currentCard?.id, "FM-12345678")
    }

    // 깨짐 명명: 기록 개수가 3이 아니거나 id가 중복되어 걸러지면 실패.
    func testAC9_profileRecords_시드는_기록_3건을_담는다() throws {
        let items = try decodeSeed().records.items
        XCTAssertEqual(items.count, 3)
        XCTAssertEqual(Set(items.map(\.id)), ["journey-a", "journey-b", "journey-c"])
    }

    // 깨짐 명명: 분 값이 25·25·15에서 바뀌어 합이 65가 아니면 실패.
    func testSeed_profileRecords_시드_기록_분의_합은_65이다() throws {
        let items = try decodeSeed().records.items
        XCTAssertEqual(items.map(\.minutes).sorted(), [15, 25, 25])
        XCTAssertEqual(items.reduce(0) { $0 + $1.minutes }, 65)
    }

    // 깨짐 명명: 카드·역 정보가 빠져 진입 화면으로 라우팅되면 실패.
    func testSeed_profileRecords_시드는_메인으로_열린다() throws {
        XCTAssertEqual(try decodeSeed().launchRoute(), .main)
    }
}
#endif
