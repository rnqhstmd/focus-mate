# T2 PNG/WebP integrity — 독립 테스트 초안

Status: DONE_WITH_CONCERNS (DRAFT ONLY; 컴파일·실행·실제 RED 미확인)

## 범위와 계약

- 산출물: `drafts/CardPhotoIntegrityTests.swift`. 동기화된 `ios/FocusMateTests` 밖에 있으며 실제 XCTest target에 등록하지 않았다.
- AC-W10-05와 설계서의 실제 이미지 검증 계약: 손상·부분 복구 입력은 `.unreadable`, 정상 PNG 변형은 수용한다.
- 실제 API: `try await ImageIOCardPhotoProcessor().process(input)`. 모의 processor 및 프로덕션 인코더를 사용하지 않는다.
- 프로덕션 파일을 읽거나 변경하지 않았다. 기존 두 테스트 파일은 읽기만 했고 fixture는 변경하지 않았다. 빌드·테스트·에이전트·커밋을 실행하지 않았다.
- 본문·CRC·zlib 생성기는 이 초안 안의 private 테스트 도우미다. 외부 의존성 없이 RFC의 stored DEFLATE 블록을 직접 작성한다. SDK zlib 바인딩이나 PNG writer의 interlace 옵션을 가정하지 않는다.

## 케이스와 회귀 검출 대상

| 번호 | 테스트 / 입력 | 기대 동작 | 잡는 변경 |
|---|---|---|---|
| 1 | `testPNG_정상CRC라도_잘린IDAT본문은_unreadable이다` | `.unreadable` | chunk CRC만 확인하거나 ImageIO 부분 복구를 성공으로 인정 |
| 2 | `testPNG_정상zlib라도_스캔라인이부족하면_unreadable이다` | `.unreadable` | 정상 zlib/checksum만 확인하고 부족한 래스터를 인정 |
| 3 | `testPNG_여러IDAT는_색과투명도를보존하여_처리된다` | 8×8, RGB·alpha 보존 | 첫 IDAT만 읽기, IDAT마다 별도 zlib 처리, alpha 누락 |
| 4 | `testPNG_Adam7은_색과투명도를보존하여_처리된다` | 8×8, RGB·alpha 보존 | interlace 거절, 비인터레이스 행 길이 적용, alpha 누락 |
| 5 | `testWebP_정상헤더의_손상본문은_unreadable이다` | `.unreadable` | RIFF/VP8L 헤더만 확인하고 불완전 transform 허용 |

정상 입력 두 케이스는 수용 회귀 방지용이다. 모든 테스트가 실패한다고 주장하지 않는다. 테스트 본문 앞에 깨짐 명명을 기록했고, 실제 processor 결과의 오류 또는 디코딩된 내용만 관찰한다. 빈 반환·다른 색·alpha 누락·정상 입력 거절을 검출하도록 작성했다. 변이 실행은 하지 않았다.

## 입력의 독립성

### PNG

8×8, bit depth 8, color type 6, straight-alpha 픽셀 `(200,80,40,128)`을 직접 기록한다. sRGB chunk도 넣는다. 기대값은 processor에서 계산하지 않고 손으로 도출한 premultiplied `(100,40,20,128)` 리터럴이며 SDK 반올림에 1의 오차만 허용한다.

일반 래스터는 행마다 filter None 1바이트 + RGBA 32바이트, 총 264바이트다. 첫 손상 케이스는 LEN=264/NLEN과 원래 Adler-32를 유지한 채 4행만 남긴다. IDAT chunk 자체는 새 길이·CRC로 다시 작성하고 IEND도 유지한다. stored block이 요구하는 데이터보다 실제 남은 바이트가 적어 본문은 불완전하다. 두 번째 케이스는 1행 33바이트에 대해 유효한 LEN/NLEN·Adler-32를 작성하지만 IHDR 높이는 8로 유지한다. zlib 자체의 무결성과 이미지의 완전성을 분리한다.

multi-IDAT 케이스는 한 zlib stream을 1/9/나머지 바이트로 분할하여 연속 IDAT 세 개에 넣는다. Adam7은 `(x0,y0,dx,dy)` 일곱 패스를 직접 순회한다. 8×8에서는 패스 픽셀 수가 `1,1,2,4,8,16,32`, 행 수가 `1,1,1,2,2,4,4`라서 전체 래스터는 271바이트다. 모든 패스가 비어 있지 않으며 각 행에 filter None을 기록한다. writer 또는 Pillow의 interlace flag를 쓰지 않는다.

규격 근거: [W3C PNG Third Edition](https://www.w3.org/TR/png-3/), 특히 §5.3/5.5 chunk·CRC, §8.1 Adam7, §10 compression, §11.2.1/11.2.3 IHDR·IDAT. zlib 구조·Adler-32는 [RFC 1950](https://www.rfc-editor.org/rfc/rfc1950), stored DEFLATE의 LEN/NLEN은 [RFC 1951 §3.2.4](https://www.rfc-editor.org/rfc/rfc1951)를 따른다.

### WebP

기존 `losslessWebP()`의 실제 40×20 입력을 유효 control로 사용한다. 초안 실행 시 먼저 SDK complete decode를 확인하도록 작성했다. RIFF/WEBP/VP8L 위치와 signature를 guard하고 원래 VP8L 이미지 헤더 5바이트를 그대로 유지한다. 본문은 `0xff` 한 바이트로 대체한다. LSB-first에서 transform 존재 1비트 + color indexing 타입 2비트 뒤에는 5비트만 남지만, 다음 color table size 필드는 8비트가 필요하다. 따라서 palette와 이미지 본문을 구성할 수 없다. payload 길이 6, RIFF 길이 18, 파일 길이 26으로 외곽 길이를 맞추고 짝수 payload라 padding도 필요 없다.

이 구분은 헤더/본문을 임의 추측한 것이 아니라 [Google WebP lossless specification](https://developers.google.com/speed/webp/docs/webp_lossless_bitstream_specification)의 §2/3 bit order·header, §4 transform type, §4.4 color indexing 규칙에 따른 구성이다. 형식상 정상 헤더/불완전 본문의 근거는 확보했으므로 NEEDS_CONTEXT로 분류하지 않는다. 대상 SDK에서 유효 control과 손상 입력의 실제 처리 결과는 아직 확인하지 않았다.

## 실행 증거와 인계

- 실패 확인 명령: **없음 — DRAFT ONLY 지시에 따라 실행 금지**.
- 실패 메시지: **없음 — 실제 RED 확인하지 않음**.
- 실패 사유 분류: **미확정**. `.unreadable` 기대가 assertion으로 실패하는지, 이미 거절하는지는 실행 후 분류해야 한다.
- SDK fixture decode/draw, Swift 컴파일, 이미지 처리 결과, mutation 검사는 모두 미실행이다. 수작업 규격 검토만 수행했다.
- 정상 PNG 입력의 색·alpha sanity는 `CardPhotoTestFixtures.completeDecoded/rgba`로 검사하도록 초안에 포함했다. 손상 PNG에 `completeDecoded`를 호출해 테스트 본문 진입을 막지 않는다.
- 일색 fixture는 잘못된 반환 색·투명도·치수와 포맷 거절을 검출하지만 공간별 픽셀 순서 회귀까지 검증하지는 않는다.
- 다음 단계: 오케스트레이터가 live XCTest 작업 종료 후 이 초안을 검토하고 실제 target으로 통합한다. 확인된 프로젝트 시험 명령에서 `CardPhotoIntegrityTests`만 선택하여 실행하고, 실제 결과·로그로 RED/PASS/fixture 오류를 분류한다. 기존 fixture 또는 processor 수정은 별도 소유자의 작업이다.

## 참조한 파일 전체 목록과 사용처

| 읽은 파일 | 사용처 |
|---|---|
| `.dev/codex-feat-card-customization/prd.md` | AC-W10-05: 읽기 불가능 입력 거절·허용 사진 수용 |
| `.dev/codex-feat-card-customization/design.md` | process API·오류 enum·부분 복구 거절·alpha 보존·실제 ImageIO 검증 |
| `ios/FocusMateTests/CardPhotoProcessorTests.swift` | async XCTest·오류 cast equality·SDK decode/rgba 검사 컨벤션 |
| `ios/FocusMateTests/CardPhotoTestFixtures.swift` | 기존 SDK decode/rgba 도우미와 유효 WebP control만 재사용 |
| `/Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md` | 스킬 적용 지침 확인; 사용자 DRAFT ONLY·에이전트 금지 지시 우선 |
| `drafts/CardPhotoIntegrityTests.swift` | 작성 후 보고서에 전문 복사·정적 재검토 |

디렉터리/파일명 목록만 조회했으며 다른 프로덕션 파일의 내용을 읽지 않았다. 외부 자료는 위에 링크한 공식 PNG/WebP/RFC 규격이다. 실패 메시지·테스트 통과·SDK 유효성 증거를 생성했다고 주장하지 않는다.

## 테스트 코드 전문

```swift
// DRAFT ONLY: outside the synchronized XCTest target. Not compiled or executed.
import Foundation
import XCTest
@testable import FocusMate

final class CardPhotoIntegrityTests: XCTestCase {
    // 깨짐 명명: PNG chunk CRC와 복구된 thumbnail만 확인하고 잘린 zlib 본문을 허용하면 실패한다.
    func testPNG_정상CRC라도_잘린IDAT본문은_unreadable이다() async throws {
        let full = IntegrityPNGFixture.zlibStored(IntegrityPNGFixture.rows(count: 8))
        // Keep the zlib header and LEN=264/NLEN, but only four of eight scanlines.
        // IEND is present; all chunk lengths and CRCs describe the new payload.
        var damaged = Data(full.prefix(7 + 4 * 33))
        damaged.append(contentsOf: full.suffix(4)) // original Adler-32, not repaired
        let input = IntegrityPNGFixture.png(idats: [damaged])
        await assertUnreadable(input)
    }

    // 깨짐 명명: zlib/Adler-32 검증 후 IHDR 높이에 필요한 래스터 길이를 검사하지 않으면 실패한다.
    func testPNG_정상zlib라도_스캔라인이부족하면_unreadable이다() async throws {
        // Valid complete zlib stream and checksum, but one row for IHDR height=8.
        let short = IntegrityPNGFixture.zlibStored(IntegrityPNGFixture.rows(count: 1))
        let input = IntegrityPNGFixture.png(idats: [short])
        await assertUnreadable(input)
    }

    // 깨짐 명명: IDAT 하나만 읽거나 각 IDAT를 별도 zlib로 처리하면 정상 입력이 거절된다.
    func testPNG_여러IDAT는_색과투명도를보존하여_처리된다() async throws {
        let stream = IntegrityPNGFixture.zlibStored(IntegrityPNGFixture.rows(count: 8))
        // Split inside the zlib header and inside the raster, not just at block boundaries.
        let input = IntegrityPNGFixture.png(idats: [
            Data(stream.prefix(1)), Data(stream.dropFirst(1).prefix(9)),
            Data(stream.dropFirst(10))
        ])
        try await assertAcceptedRGBA(input)
    }

    // 깨짐 명명: Adam7을 거절하거나 비인터레이스 행 크기로 검증하면 정상 입력이 거절된다.
    func testPNG_Adam7은_색과투명도를보존하여_처리된다() async throws {
        let stream = IntegrityPNGFixture.zlibStored(IntegrityPNGFixture.adam7Rows())
        let input = IntegrityPNGFixture.png(idats: [stream], interlace: 1)
        try await assertAcceptedRGBA(input)
    }

    // 깨짐 명명: WebP의 RIFF/VP8L 헤더만 확인하고 불완전 transform 본문을 허용하면 실패한다.
    func testWebP_정상헤더의_손상본문은_unreadable이다() async throws {
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

```

## 2026-10-14 XCTest discovery 이름 수리

현재 파일은 `ios/FocusMateTests/CardPhotoIntegrityTests.swift`로 실제 `FocusMateTests` target에 연결되어 컴파일된다. 기존 focused 로그 `t2-integrity-before-fix.log`는 `-only-testing:FocusMateTests/CardPhotoIntegrityTests`가 빌드 성공 뒤 **0 tests**를 실행했으므로 PASS 증거가 아니다. XCTest discovery 호환성을 위해 테스트 본문·helper·기대값은 유지하고 메서드 이름만 다음처럼 ASCII로 바꿨다.

| 기존 이름 | discovery용 이름 |
|---|---|
| `testPNG_정상CRC라도_잘린IDAT본문은_unreadable이다` | `testPNGRecomputedCRCTruncatedIDATIsUnreadable` |
| `testPNG_정상zlib라도_스캔라인이부족하면_unreadable이다` | `testPNGValidZlibShortRasterIsUnreadable` |
| `testPNG_여러IDAT는_색과투명도를보존하여_처리된다` | `testPNGMultipleIDATPreservesColorAndAlpha` |
| `testPNG_Adam7은_색과투명도를보존하여_처리된다` | `testPNGAdam7PreservesColorAndAlpha` |
| `testWebP_정상헤더의_손상본문은_unreadable이다` | `testWebPValidHeaderCorruptBodyIsUnreadable` |

leading `DRAFT ONLY` 주석도 실제 target 상태와 맞지 않아 제거했다. 이 수리 태스크에서는 빌드·테스트를 실행하지 않았으므로 변경 뒤 discovery와 RED/PASS 결과는 **아직 미검증**이다. 부모 오케스트레이터가 같은 focused 명령으로 실행 건수와 실제 결과를 확인한다.

## 부모 수정 전 실제 실행
ASCII method rename 후 target5cases발견/실행,4PASS1FAIL. 정상PNG multi-IDAT/Adam7, 손상CRC정상IDAT 및 짧은raster는PASS. 실제validheader/corruptVP8L body가 성공으로부분복구되어 unreadable기대FAIL. 컴파일성공/실행5건, t2-integrity-before-fix-actual.log exit65. 모든기댓값/fixture유지. 최소WebP 필수프리픽스 무결성수리도fixR1에포함.
