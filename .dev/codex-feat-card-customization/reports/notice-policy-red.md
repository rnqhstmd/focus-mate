# Card customization notice policy RED preparation

Status: **READY FOR GREEN / CORRECTED ASSERTION RED CONFIRMED / SLOT RELEASED**

Only new test file `ios/FocusMateTests/CardCustomizationNoticeMessageTests.swift` and this report were created. Existing22 frozen files were not edited. No production implementation or declaration file was read. Preparation performed no build/test/device/Git action. After explicit parent authorization, this author ran only the related8 unit tests as documented below; the slot is now released.

## API and specification

The parent-supplied contract is `CardCustomizationNotice.message: String`, shared by actual visible and VoiceOver notice text. This member was initially missing; the parent supplied its mechanically extracted minimal declaration before the actual compiler-successful RED. This author did not read that production declaration or implementation. Missing-member compiler failure would not count as RED.

Independent product oracles are AC-W10-05 input8MiB and ratio0.1...10, AC27 per-photo1MiB/total6MiB with a preserved draft and retry guidance, and the explicitly supplied processing/notice/storage enum cases. Expected limits are literal specification values, not calculated from production policy or formatter output. Tests accept whitespace before MiB but reject MB ambiguity. They test Korean meaning categories rather than freezing whole sentences.

Exactly8 cases:

- `testOversizedInputExplainsTheEightMiBInputLimit`
- `testUnsupportedAspectRatioExplainsBothAllowedBounds`
- `testCompressionLimitAndEncodingFailureExplainTheirDistinctCauses`
- `testOversizedStoredPhotoExplainsThePerPhotoOneMiBLimit`
- `testOversizedPhotoTotalExplainsSixMiBAndPreservedDraftRetry`
- `testPartialImportKeepsDistinctFailureReasonsAndSixPhotoOmissionReason`
- `testRepeatedFailuresDoNotRepeatTheSameLimitExplanation`
- `testUnreadableImportAndSaveFailuresKeepTheirExistingRecoveryGuidance`

The partial-import case demands all three independent failure categories plus the six-photo omission reason, so a generic partial-success summary fails. Repeated-vs-distinct failures compare the frequency of reason tokens rather than demanding entire messages match: accurate counts may vary while repeated error categories cannot multiply identical explanations. Positive unreadable/write guards require reading/saving and retry semantics; write failure also retains draft preservation. These already-working guards may pass and will not be forced to fail.

Mutation targets: collapsing typed errors to a generic string; confusing8MiB/1MiB/6MiB; dropping aspect-ratio bounds; losing omitted-capacity information when import failures coexist; duplicating every error reason; replacing write/read explanations with an unhelpful generic message. This unit suite does not prove the UI is wired to the new property; source executor and focused review must verify visible and VO wording share it.

SHA256: `f444cf09bc258aa88ff76bddacee2a2cb3c32af0b11b1325a27b5091c60c8966`.
Git-blob SHA1: `e2170a5a30cc4872cd00655e9a2e9fb8852e9563`.

After the declaration and exclusive slot are explicitly granted, run only `FocusMateTests/CardCustomizationNoticeMessageTests` on the parent-selected owned runtime using `.build/ios`. A compiler-successful assertion failure is required for genuine RED; no long UI suite is needed. Report actual results before claiming RED.

## Authorized semantic correction

Parent first run compiled and executed8cases with23assertion failures,0unexpected,exit65 (`notice-policy-parent-red.log`). Two method oracles were then explicitly corrected: encodingFailed does not prove a storage-limit excess, so only cannotMeetStorageLimit requires1MiB while encoding requires conversion failure/reselection guidance and cannot falsely assert1MiB excess. Save unreadable retains generic save/draft-preservation/retry semantics; only import unreadable requires a reading explanation. The6other methods and every helper are byte-identical; reverse substitution of the2changed methods exactly reconstructs the pre-correction file. No size/ratio/partial-omission oracle was relaxed.

New exact method names:
- `testCompressionLimitAndEncodingFailureExplainTheirDistinctCauses`
- `testUnreadableImportAndSaveFailuresKeepTheirExistingRecoveryGuidance`

Corrected SHA256: `edbe6a462e6499e2eafbde2021547c875ab02ff4388e7f6594a55c8e4bcccbda`.
Corrected Git-blob SHA1: `a732e151e7fd6cd8a44a67604192ea459b6cf986`.

## Corrected actual RED and handoff

After the2authorized semantic corrections, the exact related-only command was:

```sh
FOCUSMATE_SIMULATOR_ID=F226C28A-81D5-4708-B939-81B605AC748E python3 scripts/check-ios.py test ios/FocusMateTests/CardCustomizationNoticeMessageTests.swift > .dev/codex-feat-card-customization/notice-policy-author-red.log 2>&1
```

Actual **compiler PASS / exit65 /8cases /21assertion failures /0unexpected** in0.125 seconds (selected-suite0.138s). Seven cases are genuine assertion RED. The corrected generic unreadable-import/save/write recovery case **PASS**; it was not forced to fail. Actual failures report missing8MiB/ratio0.1...10/1MiB/6MiB and typed cause explanations. Partial omission's6-photo reason is retained by the baseline; missing typed reasons still fail its positive assertions. The duplication-frequency oracle cannot independently be judged passing when required reason tokens are absent; its positive prerequisite checks remain RED.

Result: `.build/ios/Logs/Test/Test-FocusMate-2026.10.15_00-31-57-+0900.xcresult`.
Log: DEV `notice-policy-author-red.log`.
All22 parent-frozen test hashes match the manifest. No production source was opened/edited, no other test or simulator touched, and no process remains active. **Exclusive build/test slot RELEASED.** Parent can freeze the corrected new-file hash and dispatch the source executor for GREEN. This suite only verifies message policy; visible/VoiceOver wiring still needs source integration review.

## Full corrected test source

```swift
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
```
