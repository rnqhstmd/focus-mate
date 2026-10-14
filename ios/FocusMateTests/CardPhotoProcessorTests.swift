import Foundation
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import FocusMate

final class CardPhotoProcessorTests: XCTestCase {
    private func assertProcessIssue(_ expected: CardPhotoProcessingIssue, input: Data,
                                    file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await ImageIOCardPhotoProcessor().process(input)
            XCTFail("Expected \(expected)", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? CardPhotoProcessingIssue, expected, file: file, line: line)
        }
    }
    private func assertStoredInvalid(_ photo: CardPhoto,
                                     file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertThrowsError(try ImageIOCardPhotoProcessor.validateStoredPhoto(photo), file: file, line: line) {
            XCTAssertEqual($0 as? SnapshotValidationIssue, .invalidCardPhoto, file: file, line: line)
        }
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_JPEG_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .jpeg)
        _ = try CardPhotoTestFixtures.completeDecoded(input)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertGreaterThan(inputRGBA[0], 240, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 15, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 15, "원본 fixture sRGB blue")
        XCTAssertEqual(inputRGBA[3], 255, "원본 fixture alpha")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_PNG_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .png)
        _ = try CardPhotoTestFixtures.completeDecoded(input)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertGreaterThan(inputRGBA[0], 240, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 15, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 15, "원본 fixture sRGB blue")
        XCTAssertEqual(inputRGBA[3], 255, "원본 fixture alpha")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: 빈 반환 또는 디코딩하지 않은 입력 반환은 실패한다.
    func testAC05_HEIC_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .heic)
        _ = try CardPhotoTestFixtures.completeDecoded(input)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertGreaterThan(inputRGBA[0], 240, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 15, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 15, "원본 fixture sRGB blue")
        XCTAssertEqual(inputRGBA[3], 255, "원본 fixture alpha")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
    }

    // 깨짐 명명: alpha를 버리고 JPEG로 저장하면 실제 투명도에서 실패한다.
    func testPNG_투명도를_실제내용에_보존한다() async throws {
        let input = try CardPhotoTestFixtures.image(alpha: true)
        _ = try CardPhotoTestFixtures.completeDecoded(input)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertEqual(Double(inputRGBA[3]), 128, accuracy: 1, "원본 fixture alpha")
        XCTAssertGreaterThan(inputRGBA[0], 120, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 5, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 5, "원본 fixture sRGB blue")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertEqual(Double(rgba[3]), 128, accuracy: 1)
        XCTAssertGreaterThan(rgba[0], 120)
        XCTAssertLessThan(rgba[1], 5)
    }

    // 깨짐 명명: orientation을 무시하거나 이중 회전하면 출력 치수와 저장 검증에서 실패한다.
    func testOrientation6_한번만_회전해_저장한다() async throws {
        let input = try CardPhotoTestFixtures.image(type: .jpeg, orientation: 6)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 20)
        XCTAssertEqual(result.pixelHeight, 40)
        let decoded = try CardPhotoTestFixtures.decoded(result.data)
        XCTAssertEqual(decoded.width, 20)
        XCTAssertEqual(decoded.height, 40)
        let source = try CardPhotoTestFixtures.source(result.data)
        let properties = try XCTUnwrap(CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [CFString: Any])
        let orientation = properties[kCGImagePropertyOrientation] as? Int
        XCTAssertTrue(orientation == nil || orientation == 1)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 20, height: 40)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioLower() async throws {
        let input = try CardPhotoTestFixtures.image(width: 10, height: 100)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 10)
        XCTAssertEqual(result.pixelHeight, 100)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 10, height: 100)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioUpper() async throws {
        let input = try CardPhotoTestFixtures.image(width: 100, height: 10)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        XCTAssertEqual(result.pixelWidth, 100)
        XCTAssertEqual(result.pixelHeight, 10)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 100, height: 10)))
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioBelow() async throws {
        let input = try CardPhotoTestFixtures.image(width: 9, height: 100)
        await assertProcessIssue(.unsupportedAspectRatio, input: input)
    }

    // 깨짐 명명: 비율 경계를 잘못 판정하거나 이미지 비율을 늘여서 통과시키면 실패한다.
    func testAC05_RatioAbove() async throws {
        let input = try CardPhotoTestFixtures.image(width: 101, height: 10)
        await assertProcessIssue(.unsupportedAspectRatio, input: input)
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Empty_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data())
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Unsupported_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data("<svg xmlns=\"http://www.w3.org/2000/svg\"></svg>".utf8))
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_DamagedBody_거절() async throws {
        await assertProcessIssue(.unreadable, input: try CardPhotoTestFixtures.damagedBody())
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_TruncatedBody_거절() async throws {
        await assertProcessIssue(.unreadable, input: Data(try CardPhotoTestFixtures.image().prefix(40)))
    }

    // 깨짐 명명: 크기 선행 검사 또는 실제 본문 decode 검사를 빼면 실패한다.
    func testAC05_Above8MiB_거절() async throws {
        await assertProcessIssue(.inputTooLarge, input: Data(repeating: 1, count: 8_388_609))
    }

    // 깨짐 명명: 원본을 반환하거나 긴 변만 줄여 찌그러뜨리면 실패한다.
    func testLongSideAbove2048_비율을_유지하여_축소한다() async throws {
        let result = try await ImageIOCardPhotoProcessor().process(CardPhotoTestFixtures.image(width: 4096, height: 2048))
        XCTAssertEqual(result.pixelWidth, 2048)
        XCTAssertEqual(result.pixelHeight, 1024)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(CardPhotoTestFixtures.photo(data: result.data, width: 2048, height: 1024)))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testDeclaredWidthMismatch() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(), width: 41, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testDeclaredHeightMismatch() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(), width: 40, height: 21))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredLongSideTooLarge() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 2049, height: 1025), width: 2049, height: 1025))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredRatioBelow() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 9, height: 100), width: 9, height: 100))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredRatioAbove() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.image(width: 101, height: 10), width: 101, height: 10))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredDamagedBody() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: try CardPhotoTestFixtures.damagedBody(), width: 40, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredEmpty() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: Data(), width: 40, height: 20))
    }

    // 깨짐 명명: 저장 이미지 실제 decode·치수·긴 변·비율 확인을 생략하면 실패한다.
    func testStoredUnsupported() throws {
        assertStoredInvalid(CardPhotoTestFixtures.photo(data: Data("unsupported".utf8), width: 40, height: 20))
    }

    // 깨짐 명명: 읽을 수 있는 WebP를 거절하거나 빈/다른 색 이미지로 반환하면 실패한다.
    func testAC05_WebP_실제이미지는_보존가능한_내용으로_처리된다() async throws {
        let input = try CardPhotoTestFixtures.losslessWebP()
        let inputImage = try CardPhotoTestFixtures.completeDecoded(input)
        XCTAssertEqual(inputImage.width, 40)
        XCTAssertEqual(inputImage.height, 20)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.completeDecoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(Double(decoded.width) / Double(decoded.height), 2)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        // 불투명 입력. JPEG 재인코딩 오차는 허용하되 다른 색으로 대체하면 실패한다.
        XCTAssertEqual(Double(rgba[0]), 220, accuracy: 8)
        XCTAssertEqual(Double(rgba[1]), 40, accuracy: 8)
        XCTAssertEqual(Double(rgba[2]), 80, accuracy: 8)
        XCTAssertEqual(rgba[3], 255)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(
            CardPhotoTestFixtures.photo(data: result.data, width: 40, height: 20)))
    }

    // 깨짐 명명: 입력 한도를 >=8MiB로 거절하거나 메타데이터 포함 원본을 그대로 반환하면 실패한다.
    func testAC05_Exact8MiB_완전한PNG는_내용을_보존하여_처리된다() async throws {
        let input = try CardPhotoTestFixtures.exact8MiBPNG()
        XCTAssertEqual(input.count, 8_388_608)
        let inputImage = try CardPhotoTestFixtures.completeDecoded(input)
        XCTAssertEqual(inputImage.width, 40)
        XCTAssertEqual(inputImage.height, 20)
        // 원본 fixture sanity: processor와 독립적으로 sRGB 입력 의미를 확인한다.
        let inputRGBA = try CardPhotoTestFixtures.rgba(input)
        XCTAssertGreaterThan(inputRGBA[0], 240, "원본 fixture sRGB red")
        XCTAssertLessThan(inputRGBA[1], 15, "원본 fixture sRGB green")
        XCTAssertLessThan(inputRGBA[2], 15, "원본 fixture sRGB blue")
        XCTAssertEqual(inputRGBA[3], 255, "원본 fixture alpha")
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let decoded = try CardPhotoTestFixtures.completeDecoded(result.data)
        XCTAssertEqual(decoded.width, 40)
        XCTAssertEqual(decoded.height, 20)
        XCTAssertEqual(Double(decoded.width) / Double(decoded.height), 2)
        XCTAssertEqual(result.pixelWidth, 40)
        XCTAssertEqual(result.pixelHeight, 20)
        XCTAssertLessThanOrEqual(result.data.count, 1_048_576)
        let rgba = try CardPhotoTestFixtures.rgba(result.data)
        XCTAssertGreaterThan(rgba[0], 240)
        XCTAssertLessThan(rgba[1], 15)
        XCTAssertLessThan(rgba[2], 15)
        XCTAssertEqual(rgba[3], 255)
        XCTAssertNoThrow(try ImageIOCardPhotoProcessor.validateStoredPhoto(
            CardPhotoTestFixtures.photo(data: result.data, width: 40, height: 20)))
    }
}
