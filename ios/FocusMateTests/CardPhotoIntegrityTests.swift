import Foundation
import XCTest
@testable import FocusMate

final class CardPhotoIntegrityTests: XCTestCase {
    // 깨짐 명명: PNG chunk CRC와 복구된 thumbnail만 확인하고 잘린 zlib 본문을 허용하면 실패한다.
    func testPNGRecomputedCRCTruncatedIDATIsUnreadable() async throws {
        let full = IntegrityPNGFixture.zlibStored(IntegrityPNGFixture.rows(count: 8))
        // Keep the zlib header and LEN=264/NLEN, but only four of eight scanlines.
        // IEND is present; all chunk lengths and CRCs describe the new payload.
        var damaged = Data(full.prefix(7 + 4 * 33))
        damaged.append(contentsOf: full.suffix(4)) // original Adler-32, not repaired
        let input = IntegrityPNGFixture.png(idats: [damaged])
        await assertUnreadable(input)
    }

    // 깨짐 명명: zlib/Adler-32 검증 후 IHDR 높이에 필요한 래스터 길이를 검사하지 않으면 실패한다.
    func testPNGValidZlibShortRasterIsUnreadable() async throws {
        // Valid complete zlib stream and checksum, but one row for IHDR height=8.
        let short = IntegrityPNGFixture.zlibStored(IntegrityPNGFixture.rows(count: 1))
        let input = IntegrityPNGFixture.png(idats: [short])
        await assertUnreadable(input)
    }

    // 깨짐 명명: IDAT 하나만 읽거나 각 IDAT를 별도 zlib로 처리하면 정상 입력이 거절된다.
    func testPNGMultipleIDATPreservesColorAndAlpha() async throws {
        let stream = IntegrityPNGFixture.zlibStored(IntegrityPNGFixture.rows(count: 8))
        // Split inside the zlib header and inside the raster, not just at block boundaries.
        let input = IntegrityPNGFixture.png(idats: [
            Data(stream.prefix(1)), Data(stream.dropFirst(1).prefix(9)),
            Data(stream.dropFirst(10))
        ])
        try await assertAcceptedRGBA(input)
    }

    // 깨짐 명명: Adam7을 거절하거나 비인터레이스 행 크기로 검증하면 정상 입력이 거절된다.
    func testPNGAdam7PreservesColorAndAlpha() async throws {
        let stream = IntegrityPNGFixture.zlibStored(IntegrityPNGFixture.adam7Rows())
        let input = IntegrityPNGFixture.png(idats: [stream], interlace: 1)
        try await assertAcceptedRGBA(input)
    }

    // 깨짐 명명: WebP의 RIFF/VP8L 헤더만 확인하고 불완전 transform 본문을 허용하면 실패한다.
    func testWebPValidHeaderCorruptBodyIsUnreadable() async throws {
        let valid = try CardPhotoTestFixtures.losslessWebP()
        let decoded = try CardPhotoTestFixtures.completeDecoded(valid)
        XCTAssertEqual(decoded.width, 40, "Independent valid-control fixture")
        XCTAssertEqual(decoded.height, 20)
        let input = try corruptedWebP(valid)
        await assertUnreadable(input)
    }

    private func assertUnreadable(_ input: Data,
                                  file: StaticString = #filePath, line: UInt = #line) async {
        do {
            _ = try await ImageIOCardPhotoProcessor().process(input)
            XCTFail("Partially recovered/corrupt input must throw unreadable", file: file, line: line)
        } catch {
            XCTAssertEqual(error as? CardPhotoProcessingIssue, .unreadable, file: file, line: line)
        }
    }

    private func assertAcceptedRGBA(_ input: Data,
                                    file: StaticString = #filePath, line: UInt = #line) async throws {
        // Sanity is SDK decode/draw, never the processor used to generate expected values.
        let original = try CardPhotoTestFixtures.completeDecoded(input)
        XCTAssertEqual(original.width, 8, file: file, line: line)
        XCTAssertEqual(original.height, 8, file: file, line: line)
        try assertLiteralRGBA(input, file: file, line: line)
        let result = try await ImageIOCardPhotoProcessor().process(input)
        let output = try CardPhotoTestFixtures.completeDecoded(result.data)
        XCTAssertEqual(result.pixelWidth, 8, file: file, line: line)
        XCTAssertEqual(result.pixelHeight, 8, file: file, line: line)
        XCTAssertEqual(output.width, 8, file: file, line: line)
        XCTAssertEqual(output.height, 8, file: file, line: line)
        try assertLiteralRGBA(result.data, file: file, line: line)
    }

    private func assertLiteralRGBA(_ bytes: Data,
                                   file: StaticString, line: UInt) throws {
        let rgba = try CardPhotoTestFixtures.rgba(bytes)
        // Hand-derived premultiplied sRGB: (200,80,40) * 128/255 ≈ (100,40,20).
        // One-unit tolerance permits SDK rounding; alpha=255 or missing pixels fail.
        XCTAssertEqual(Double(rgba[0]), 100, accuracy: 1, file: file, line: line)
        XCTAssertEqual(Double(rgba[1]), 40, accuracy: 1, file: file, line: line)
        XCTAssertEqual(Double(rgba[2]), 20, accuracy: 1, file: file, line: line)
        XCTAssertEqual(Double(rgba[3]), 128, accuracy: 1, file: file, line: line)
    }

    private func corruptedWebP(_ valid: Data) throws -> Data {
        // Single VP8L chunk: RIFF(12) + chunk header(8) + image header(5).
        guard valid.count >= 25,
              Data(valid.prefix(4)) == Data("RIFF".utf8),
              Data(valid[8..<16]) == Data("WEBPVP8L".utf8), valid[20] == 0x2f else {
            throw DraftFixtureIssue.unexpectedWebPLayout
        }
        var payload = Data(valid[20..<25]) // retain actual signature/dimensions/alpha/version
        // LSB-first: 1=transform present, 11=color indexing; only 5 bits remain,
        // but its color_table_size requires 8 bits. No palette/pixel body follows.
        payload.append(0xff)
        var input = Data("RIFF".utf8)
        input.append(IntegrityPNGFixture.littleEndian32(18)) // file length 26 minus 8
        input.append(Data("WEBPVP8L".utf8))
        input.append(IntegrityPNGFixture.littleEndian32(6)) // even payload: no pad
        input.append(payload)
        return input
    }

    private enum DraftFixtureIssue: Error { case unexpectedWebPLayout }
}

// Test-only byte builder. No production encoder, ImageIO writer, Pillow, or dependency.
// W3C PNG: https://www.w3.org/TR/png-3/#8Interlace
// zlib/DEFLATE: RFC1950 + RFC1951 (one final uncompressed block).
private enum IntegrityPNGFixture {
    private static let pixel: [UInt8] = [200, 80, 40, 128] // straight-alpha sRGB

    static func rows(count: Int) -> Data {
        var raw = Data()
        for _ in 0..<count {
            raw.append(0) // filter None
            for _ in 0..<8 { raw.append(contentsOf: pixel) }
        }
        return raw
    }

    static func adam7Rows() -> Data {
        // (x origin, y origin, x step, y step), all seven passes populated at 8×8.
        let passes = [(0, 0, 8, 8), (4, 0, 8, 8), (0, 4, 4, 8),
                      (2, 0, 4, 4), (0, 2, 2, 4), (1, 0, 2, 2), (0, 1, 1, 2)]
        var raw = Data()
        for (x0, y0, dx, dy) in passes {
            for _ in stride(from: y0, to: 8, by: dy) {
                raw.append(0)
                for _ in stride(from: x0, to: 8, by: dx) { raw.append(contentsOf: pixel) }
            }
        }
        return raw // 64 pixels×4 + 15 filter bytes = 271 bytes
    }

    static func png(idats: [Data], interlace: UInt8 = 0) -> Data {
        var bytes = Data([137, 80, 78, 71, 13, 10, 26, 10])
        var header = bigEndian32(8)
        header.append(bigEndian32(8))
        header.append(contentsOf: [8, 6, 0, 0, interlace]) // 8-bit RGBA
        bytes.append(chunk("IHDR", header))
        bytes.append(chunk("sRGB", Data([0]))) // explicit sRGB, perceptual intent
        for payload in idats { bytes.append(chunk("IDAT", payload)) }
        bytes.append(chunk("IEND", Data()))
        return bytes
    }

    static func zlibStored(_ raw: Data) -> Data {
        precondition(raw.count <= 65_535)
        let length = UInt16(raw.count)
        let complement = ~length
        var bytes = Data([0x78, 0x01, 0x01, // zlib CMF/FLG, BFINAL=1/BTYPE=00
                          UInt8(truncatingIfNeeded: length), UInt8(length >> 8),
                          UInt8(truncatingIfNeeded: complement), UInt8(complement >> 8)])
        bytes.append(raw)
        var a: UInt32 = 1
        var b: UInt32 = 0
        for byte in raw {
            a = (a + UInt32(byte)) % 65_521
            b = (b + a) % 65_521
        }
        bytes.append(bigEndian32((b << 16) | a))
        return bytes
    }

    private static func chunk(_ name: String, _ payload: Data) -> Data {
        var crcInput = Data(name.utf8)
        crcInput.append(payload)
        var crc: UInt32 = 0xffff_ffff
        for byte in crcInput {
            crc ^= UInt32(byte)
            for _ in 0..<8 { crc = (crc >> 1) ^ ((crc & 1) == 1 ? 0xedb8_8320 : 0) }
        }
        var bytes = bigEndian32(UInt32(payload.count))
        bytes.append(crcInput)
        bytes.append(bigEndian32(crc ^ 0xffff_ffff))
        return bytes
    }

    static func littleEndian32(_ value: UInt32) -> Data {
        Data([UInt8(truncatingIfNeeded: value), UInt8(truncatingIfNeeded: value >> 8),
              UInt8(truncatingIfNeeded: value >> 16), UInt8(truncatingIfNeeded: value >> 24)])
    }

    private static func bigEndian32(_ value: UInt32) -> Data {
        Data([UInt8(truncatingIfNeeded: value >> 24), UInt8(truncatingIfNeeded: value >> 16),
              UInt8(truncatingIfNeeded: value >> 8), UInt8(truncatingIfNeeded: value)])
    }
}
