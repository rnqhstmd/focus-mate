import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers
import XCTest
@testable import FocusMate

/// 실제 ImageIO 입력. 프로덕션 processor/encoder로 기대 이미지를 만들지 않는다.
enum CardPhotoTestFixtures {
    static let photoID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!

    static func image(width: Int = 40, height: Int = 20, alpha: Bool = false,
                      type: UTType = .png, orientation: Int = 1) throws -> Data {
        let context = try XCTUnwrap(CGContext(data: nil, width: width, height: height,
            bitsPerComponent: 8, bytesPerRow: width * 4, space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        // 입력의 pure red는 context와 같은 명시적 sRGB에서 정의한다.
        let color = try XCTUnwrap(CGColor(colorSpace: try XCTUnwrap(context.colorSpace),
            components: [1, 0, 0, alpha ? 0.5 : 1]))
        context.setFillColor(color)
        context.fill(CGRect(x: 0, y: 0, width: CGFloat(width), height: CGFloat(height)))
        let image = try XCTUnwrap(context.makeImage())
        let bytes = NSMutableData()
        let destination = try XCTUnwrap(CGImageDestinationCreateWithData(bytes, type.identifier as CFString, 1, nil))
        CGImageDestinationAddImage(destination, image, [kCGImagePropertyOrientation: orientation] as CFDictionary)
        guard CGImageDestinationFinalize(destination) else { throw FixtureIssue.encoding }
        return bytes as Data
    }

    static func source(_ bytes: Data) throws -> CGImageSource {
        try XCTUnwrap(CGImageSourceCreateWithData(bytes as CFData, nil))
    }

    static func decoded(_ bytes: Data) throws -> CGImage {
        let source = try source(bytes)
        return try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
    }

    static func rgba(_ bytes: Data) throws -> [UInt8] {
        let image = try decoded(bytes)
        let context = try XCTUnwrap(CGContext(data: nil, width: 1, height: 1,
            bitsPerComponent: 8, bytesPerRow: 4, space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: 1, height: 1))
        let pointer = try XCTUnwrap(context.data).assumingMemoryBound(to: UInt8.self)
        return Array(UnsafeBufferPointer(start: pointer, count: 4))
    }

    /// PNG signature와 IHDR은 남기고 IDAT payload를 깨뜨린다. 헤더만 읽는 구현을 잡는다.
    static func damagedBody() throws -> Data {
        var bytes = try image()
        let range = try XCTUnwrap(bytes.range(of: Data("IDAT".utf8)))
        let start = range.upperBound
        guard start + 4 < bytes.count else { throw FixtureIssue.encoding }
        bytes.replaceSubrange(start..<(bytes.count - 12), with: Data(repeating: 0, count: bytes.count - 12 - start))
        return bytes
    }

    static func photo(data: Data = Data([1]), width: Int = 40, height: Int = 20,
                      id: UUID = photoID, x: Double = 0.5, y: Double = 0.5,
                      fraction: Double = 0.6) -> CardPhoto {
        CardPhoto(id: id, data: data, pixelWidth: width, pixelHeight: height,
                  centerX: x, centerY: y, widthFraction: fraction)
    }

    static func style(_ photos: [CardPhoto]) -> CardStyle {
        CardStyle(background: CardColor(red: 0.2, green: 0.3, blue: 0.4), photos: photos)
    }

    static func seed(_ bytes: Data, at url: URL) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try bytes.write(to: url)
    }


    /// 부모가 번들 Python3 Pillow lossless WebP encoder로 자체 생성한 40×20 RGB(220,40,80), 38bytes.
    /// 외부 사진/라이선스 없음. 출처: .dev/codex-feat-card-customization/reports/t2-fixture-input.md,
    /// test-webp-base64.txt 및 t2-fixture-validation.log (macOS ImageIO complete/decode/draw 성공).
    /// 대상 iOS 지원은 skip 없이 실제 processor 테스트에서 검증한다.
    static func losslessWebP() throws -> Data {
        try XCTUnwrap(Data(base64Encoded: "UklGRh4AAABXRUJQVlA4TBEAAAAvJ8AEAAdQlHIXqv+BiOh/AAA="))
    }

    /// 기존 ImageIO PNG의 IEND 앞에 정상 tEXt 메타데이터를 삽입한다. 후행 padding이 아니다.
    /// 전체 입력 한도에는 메타데이터도 포함된다: base + 12(chunk overhead) + 8(key+NUL) + payload.
    static func exact8MiBPNG() throws -> Data {
        var bytes = try image()
        let targetCount = 8_388_608
        let keyword = Data("padding\0".utf8)
        let payloadCount = targetCount - bytes.count - 12 - keyword.count
        guard payloadCount >= 0 else { throw FixtureIssue.encoding }

        // PNG chunk 경계를 따라 IEND를 찾는다. 압축 본문 안의 우연한 문자열과 혼동하지 않는다.
        var offset = 8
        var iendOffset: Int?
        while offset <= bytes.count - 12 {
            let length = bytes[offset..<(offset + 4)].reduce(0) { ($0 << 8) | Int($1) }
            guard length <= bytes.count - offset - 12 else { throw FixtureIssue.encoding }
            let type = bytes[(offset + 4)..<(offset + 8)]
            if Data(type) == Data("IEND".utf8) {
                guard length == 0, offset + 12 == bytes.count else { throw FixtureIssue.encoding }
                iendOffset = offset
                break
            }
            offset += length + 12
        }
        let insertionOffset = try XCTUnwrap(iendOffset)
        var text = keyword
        text.append(Data(repeating: 0x78, count: payloadCount)) // 유효한 Latin-1 tEXt 값 'x'.
        var crcInput = Data("tEXt".utf8)
        crcInput.append(text)
        var chunk = bigEndianBytes(UInt32(text.count))
        chunk.append(crcInput)
        chunk.append(bigEndianBytes(crc32(crcInput)))
        bytes.insert(contentsOf: chunk, at: insertionOffset)
        return bytes
    }

    private static func bigEndianBytes(_ value: UInt32) -> Data {
        Data([UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
              UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)])
    }

    // PNG CRC는 chunk type+data를 대상으로 하는 표준 reflected CRC32다.
    private static func crc32(_ bytes: Data) -> UInt32 {
        var crc: UInt32 = 0xFFFF_FFFF
        for byte in bytes {
            crc ^= UInt32(byte)
            for _ in 0..<8 {
                crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xEDB8_8320 : 0)
            }
        }
        return crc ^ 0xFFFF_FFFF
    }

    /// 프로덕션 processor와 독립적인 ImageIO 검사. 부분 복구 입력도 성공으로 인정하지 않는다.
    static func completeDecoded(_ bytes: Data) throws -> CGImage {
        let source = try source(bytes)
        guard CGImageSourceGetStatus(source) == .statusComplete,
              CGImageSourceGetStatusAtIndex(source, 0) == .statusComplete else {
            XCTFail("Fixture/output ImageIO source and index must be complete")
            throw FixtureIssue.encoding
        }
        let image = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        let context = try XCTUnwrap(CGContext(data: nil, width: image.width, height: image.height,
            bitsPerComponent: 8, bytesPerRow: image.width * 4, space: try XCTUnwrap(CGColorSpace(name: CGColorSpace.sRGB)),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: 0, y: 0, width: CGFloat(image.width), height: CGFloat(image.height)))
        _ = try XCTUnwrap(context.data)
        return image
    }

    enum FixtureIssue: Error { case encoding }
}
