import Foundation
import XCTest
@testable import FocusMate

final class CardCustomizationNoticeMessageTests: XCTestCase {
    func testOversizedInputExplainsTheEightMiBInputLimit() {
        // Regression: a typed oversized input is reduced to a generic import failure.
        let message = CardCustomizationNotice.importFailed([.inputTooLarge]).message
        assertLimit("8MiB", in: message)
        assertContainsAny(["입력", "원본", "선택한 사진"], in: message)
    }

    func testUnsupportedAspectRatioExplainsBothAllowedBounds() {
        let message = CardCustomizationNotice.importFailed([.unsupportedAspectRatio]).message
        XCTAssertTrue(message.contains("비율"))
        XCTAssertTrue(message.contains("0.1"))
        XCTAssertTrue(message.contains("10"))
    }

    func testCompressionLimitAndEncodingFailureExplainTheirDistinctCauses() {
        let limitFailure = CardCustomizationNotice.importFailed([.cannotMeetStorageLimit]).message
        assertLimit("1MiB", in: limitFailure)
        assertContainsAny(["변환", "압축", "저장"], in: limitFailure)

        let encodingFailure = CardCustomizationNotice.importFailed([.encodingFailed]).message
        assertContainsAny(["변환", "인코딩"], in: encodingFailure)
        assertContainsAny(["실패", "못", "오류"], in: encodingFailure)
        assertContainsAny(["다시", "재선택", "선택"], in: encodingFailure)
        let compact = compactWhitespace(encodingFailure)
        XCTAssertFalse(compact.contains("1MiB초과") || compact.contains("1MiB를초과"),
                       "An encoding failure alone must not claim that the photo exceeded 1MiB")
    }

    func testOversizedStoredPhotoExplainsThePerPhotoOneMiBLimit() {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let message = CardCustomizationNotice.saveFailed(
            .invalidState(.invalidCardStyle(.photoTooLarge(id)))
        ).message
        assertLimit("1MiB", in: message)
        assertContainsAny(["사진 한 장", "사진당", "장당", "각 사진"], in: message)
    }

    func testOversizedPhotoTotalExplainsSixMiBAndPreservedDraftRetry() {
        let message = CardCustomizationNotice.saveFailed(
            .invalidState(.invalidCardStyle(.totalPhotosTooLarge))
        ).message
        assertLimit("6MiB", in: message)
        assertContainsAny(["전체", "합계", "합산", "모든 사진"], in: message)
        assertDraftPreservedAndRetry(message)
    }

    func testPartialImportKeepsDistinctFailureReasonsAndSixPhotoOmissionReason() {
        let message = CardCustomizationNotice.partialImport(
            failures: [.inputTooLarge, .unsupportedAspectRatio, .cannotMeetStorageLimit],
            omittedCount: 2
        ).message
        assertLimit("8MiB", in: message)
        XCTAssertTrue(message.contains("비율"))
        XCTAssertTrue(message.contains("0.1"))
        XCTAssertTrue(message.contains("10"))
        assertLimit("1MiB", in: message)
        let compact = compactWhitespace(message)
        XCTAssertTrue(compact.contains("6장"), "Partial import must retain the six-photo capacity reason")
        assertContainsAny(["제외", "누락", "추가하지", "추가되지", "초과"], in: message)
    }

    func testRepeatedFailuresDoNotRepeatTheSameLimitExplanation() {
        let distinct = CardCustomizationNotice.partialImport(
            failures: [.inputTooLarge, .unsupportedAspectRatio], omittedCount: 1
        ).message
        let repeated = CardCustomizationNotice.partialImport(
            failures: [.inputTooLarge, .inputTooLarge, .unsupportedAspectRatio,
                       .inputTooLarge, .unsupportedAspectRatio], omittedCount: 1
        ).message
        assertLimit("8MiB", in: distinct)
        assertLimit("8MiB", in: repeated)
        XCTAssertTrue(distinct.contains("0.1"))
        XCTAssertTrue(repeated.contains("0.1"))
        XCTAssertEqual(occurrences(of: "8MiB", in: repeated), occurrences(of: "8MiB", in: distinct))
        XCTAssertEqual(occurrences(of: "0.1", in: repeated), occurrences(of: "0.1", in: distinct))
    }

    func testUnreadableImportAndSaveFailuresKeepTheirExistingRecoveryGuidance() {
        let unreadableImport = CardCustomizationNotice.importFailed([.unreadable]).message
        XCTAssertTrue(unreadableImport.contains("읽"), "Unreadable imports must explain the reading failure")
        assertContainsAny(["다시", "재선택", "선택"], in: unreadableImport)

        let saveMessages = [
            CardCustomizationNotice.saveFailed(.unreadable).message,
            CardCustomizationNotice.saveFailed(.writeFailed).message
        ]
        for message in saveMessages {
            XCTAssertTrue(message.contains("저장"))
            assertDraftPreservedAndRetry(message)
        }
    }

    private func assertLimit(_ limit: String, in message: String,
                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(compactWhitespace(message).contains(limit), "Missing specified limit: " + limit,
                      file: file, line: line)
        XCTAssertFalse(message.contains("MB"), "Binary limits must use the unambiguous MiB unit",
                       file: file, line: line)
    }

    private func assertDraftPreservedAndRetry(_ message: String,
                                             file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(message.contains("초안"), file: file, line: line)
        assertContainsAny(["유지", "보존", "남아"], in: message, file: file, line: line)
        assertContainsAny(["다시", "재시도"], in: message, file: file, line: line)
    }

    private func assertContainsAny(_ words: [String], in message: String,
                                   file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(words.contains { message.contains($0) },
                      "Missing user-facing explanation from category: " + words.joined(separator: ", "),
                      file: file, line: line)
    }

    private func compactWhitespace(_ message: String) -> String {
        message.filter { !$0.isWhitespace }
    }

    private func occurrences(of token: String, in message: String) -> Int {
        compactWhitespace(message).components(separatedBy: token).count - 1
    }
}
