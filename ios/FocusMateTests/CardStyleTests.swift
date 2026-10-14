import Foundation
import XCTest
@testable import FocusMate

final class CardStyleTests: XCTestCase {
    private let id = CardPhotoTestFixtures.photoID
    private func assertIssue(_ expected: CardStyleValidationIssue, _ style: CardStyle,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try style.validate(), file: file, line: line) {
            XCTAssertEqual($0 as? CardStyleValidationIssue, expected, file: file, line: line)
        }
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_NaN_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: .nan, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_PositiveInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: .infinity, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_NegativeInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: -.infinity, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_BelowZero_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: -0.01, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_red_AboveOne_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 1.01, green: 0.5, blue: 0.5), photos: []))
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_red_Zero_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0, green: 0.5, blue: 0.5), photos: []).validate())
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_red_One_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 1, green: 0.5, blue: 0.5), photos: []).validate())
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_NaN_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: .nan, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_PositiveInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: .infinity, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_NegativeInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: -.infinity, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_BelowZero_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: -0.01, blue: 0.5), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_green_AboveOne_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 1.01, blue: 0.5), photos: []))
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_green_Zero_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0.5, green: 0, blue: 0.5), photos: []).validate())
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_green_One_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0.5, green: 1, blue: 0.5), photos: []).validate())
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_NaN_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: .nan), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_PositiveInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: .infinity), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_NegativeInfinity_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: -.infinity), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_BelowZero_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: -0.01), photos: []))
    }

    // 깨짐 명명: RGB 유한값 또는 범위 검사를 빼면 실패한다.
    func testRGB_blue_AboveOne_거절() throws {
        assertIssue(.invalidColor, CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: 1.01), photos: []))
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_blue_Zero_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: 0), photos: []).validate())
    }

    // 깨짐 명명: 색 경계를 열린 구간으로 바꾸면 실패한다.
    func testRGB_blue_One_허용() throws {
        XCTAssertNoThrow(try CardStyle(background: CardColor(red: 0.5, green: 0.5, blue: 1), photos: []).validate())
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_CenterX_Lower_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: -1)]).validate())
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_CenterX_Upper_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: 2)]).validate())
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_Below_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: -1.01)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_Above_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: 2.01)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_NaN_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: .nan)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_Infinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: .infinity)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterX_NegativeInfinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(x: -.infinity)]))
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_CenterY_Lower_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: -1)]).validate())
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_CenterY_Upper_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: 2)]).validate())
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_Below_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: -1.01)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_Above_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: 2.01)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_NaN_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: .nan)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_Infinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: .infinity)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_CenterY_NegativeInfinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(y: -.infinity)]))
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_Width_Lower_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: 0.15)]).validate())
    }

    // 깨짐 명명: 배치 경계를 열린 구간으로 바꾸면 실패한다.
    func testAC12_Width_Upper_저장허용() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: 2.5)]).validate())
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_Below_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: 0.14)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_Above_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: 2.51)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_NaN_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: .nan)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_Infinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: .infinity)]))
    }

    // 깨짐 명명: 잘못된 저장 배치를 clamp하거나 통과시키면 실패한다.
    func testAC12_Width_NegativeInfinity_저장거절() throws {
        assertIssue(.invalidPlacement(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(fraction: -.infinity)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_LowerRatio() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 10, height: 100)]).validate())
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_UpperRatio() throws {
        XCTAssertNoThrow(try CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 100, height: 10)]).validate())
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_BelowRatio() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 9, height: 100)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_AboveRatio() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 101, height: 10)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_ZeroWidth() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 0, height: 20)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_ZeroHeight() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 40, height: 0)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_NegativeWidth() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: -1, height: 20)]))
    }

    // 깨짐 명명: 치수 또는 비율 경계를 잘못 판정하면 실패한다.
    func testAC05_NegativeHeight() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 40, height: -1)]))
    }

    // 깨짐 명명: 빈 사진 데이터 검사를 빼면 실패한다.
    func testEmptyData_거절() throws {
        assertIssue(.emptyPhotoData(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: Data())]))
    }

    // 깨짐 명명: 사진 ID 중복 검사를 빼면 실패한다.
    func testDuplicateID_거절() throws {
        let photo = CardPhotoTestFixtures.photo()
        assertIssue(.duplicatePhotoID, CardPhotoTestFixtures.style([photo, photo]))
    }

    // 깨짐 명명: 최대 장수를 7로 늘리면 실패한다.
    func testSevenPhotos_거절() throws {
        let photos = (0..<7).map { index in CardPhotoTestFixtures.photo(id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", index + 1))!) }
        assertIssue(.tooManyPhotos(7), CardPhotoTestFixtures.style(photos))
    }

    // 깨짐 명명: 검증 순서를 수량 우선으로 바꾸면 실패한다.
    func testValidationOrder_RGBBeforeCount() throws {
        let style = CardStyle(background: CardColor(red: .nan, green: 0, blue: 0), photos: Array(repeating: CardPhotoTestFixtures.photo(), count: 7))
        assertIssue(.invalidColor, style)
    }

    // 깨짐 명명: 중복 ID보다 바이트 검사를 먼저 하면 실패한다.
    func testValidationOrder_DuplicateBeforeBytes() throws {
        let photo = CardPhotoTestFixtures.photo(data: Data(repeating: 1, count: 1_048_577))
        assertIssue(.duplicatePhotoID, CardPhotoTestFixtures.style([photo, photo]))
    }

    // 깨짐 명명: style 갱신이 카드 ID/발급시각을 새로 생성하거나 입력 style을 버리면 실패한다.
    func testCardStyleUpdate_카드정체성을_유지한다() throws {
        let original = CardSnapshot(id: "FM-01234567", issuedAt: Date(timeIntervalSince1970: 1_791_882_000))
        let style = CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo()])
        let changed = original.updating(style: style)
        XCTAssertEqual(changed.id, "FM-01234567")
        XCTAssertEqual(changed.issuedAt, Date(timeIntervalSince1970: 1_791_882_000))
        XCTAssertEqual(changed.style, style)
        XCTAssertTrue(original.style.isStandard)
        XCTAssertFalse(changed.style.isStandard)
    }

    // 깨짐 명명: 수량보다 중복ID를 먼저 검사하면 실패한다.
    func testValidationOrder_CountBeforeDuplicate() throws {
        assertIssue(.tooManyPhotos(7), CardPhotoTestFixtures.style(Array(repeating: CardPhotoTestFixtures.photo(), count: 7)))
    }

    // 깨짐 명명: 빈 데이터보다 치수를 먼저 검사하면 실패한다.
    func testValidationOrder_EmptyBeforeDimensions() throws {
        assertIssue(.emptyPhotoData(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(data: Data(), width: 0)]))
    }

    // 깨짐 명명: 치수보다 배치를 먼저 검사하면 실패한다.
    func testValidationOrder_DimensionsBeforePlacement() throws {
        assertIssue(.invalidDimensions(id), CardPhotoTestFixtures.style([CardPhotoTestFixtures.photo(width: 0, x: .nan)]))
    }
}
