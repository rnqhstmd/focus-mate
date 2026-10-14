# Typed card notice reasons — isolated GREEN

Status: **DONE / focused8 PASS / slot RELEASED**.

## Scope and implementation

Only `ios/FocusMate/CardCustomizationController.swift`'s `CardCustomizationNotice.message` computed property changed. All controller state/lifecycle/import/save code following `@MainActor @Observable` is byte-identical to the pre-change source. View already shares `.message` for displayed text and actual SystemAccessibilityAnnouncer; no view/layout, model, processor, persistence or storage strategy changes were made.

The generic legacy message is retained and typed reasons are appended:

| Typed reason | Added explanation |
|---|---|
| inputTooLarge | 선택한 입력 사진은 장당8MiB 이하여야 함 |
| unsupportedAspectRatio | 가로·세로 비율0.1~10 범위 |
| cannotMeetStorageLimit |1MiB 이하로 압축해 저장하지 못함 |
| encodingFailed | 사진 변환 실패; capacity exceeded라고 단정하지 않음 |
| save invalidCardStyle.photoTooLarge | 사진 한 장 저장 용량1MiB 초과 |
| save invalidCardStyle.totalPhotosTooLarge | 사진 전체 저장 용량6MiB 초과 |

Local `importMessage` keeps first-seen ordering and appends each distinct reason string once. Partial imports keep the exact existing max6/omission base when omittedCount>0 and append all distinct typed reasons. Without omission the original failed-photo count/retry base remains. The `.unreadable` case adds nothing, preserving exact old unreadable-only import/partial outputs. Save capacity reason extraction recursively unwraps `.writeBlocked(cause)`; unrelated failures receive no invented capacity reason.

**Exact legacy fallbacks retained:**

- importFailed unreadable-only: `사진을 읽지 못했어요. 사진 추가로 다시 선택해주세요.`
- partialImport omitted>0 unreadable-only: `사진은 최대 6장까지 넣을 수 있어요. 일부 사진은 추가하지 않았어요.`
- partialImport no omission unreadable-only: `사진 N장을 읽지 못했어요. 사진 추가로 다시 선택해주세요.` (same actual N)
- ordinary writeFailed/unreadable save: `카드 외형을 저장하지 못했어요. 초안은 유지돼요. 저장 버튼으로 다시 시도해주세요.`
- maximumPhotos unchanged.

This is presentation of already typed errors. No limit values, error classification, processing, cleanup, history or storage policy changed. Existing generic-message direct VO evidence is not replaced by a new VO run; preserving the exact fallback text avoids changing that contract.

## Actual focused GREEN

Parent supplied genuine corrected RED: new8 compiled,21 assertion failures across7 failing cases and1 generic positive pass, exit65. Parent froze existing22 plus new file as23 before this change. New test Git blob `a732e151e7fd6cd8a44a67604192ea459b6cf986` matched before editing.

```sh
FOCUSMATE_SIMULATOR_ID=F226C28A-81D5-4708-B939-81B605AC748E \
python3 scripts/check-ios.py test ios/FocusMateTests/CardCustomizationNoticeMessageTests.swift \
> .dev/codex-feat-card-customization/notice-policy-green.log 2>&1
```

Actual output:

```text
Executed 8 tests, with 0 failures (0 unexpected) in 0.006 (0.014) seconds
** TEST SUCCEEDED **
```

Actual **exit0 /8 PASS /0 FAIL**. New source compiled; owned27F226 only, `.build/ios`, parallel testing disabled by existing script. Result: `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/ios/Logs/Test/Test-FocusMate-2026.10.15_00-33-58-+0900.xcresult`. Full raw log DEV `notice-policy-green.log`.

Only these8 unit cases ran. No full suite, UI, Photos, VO or device lifecycle action. Exclusive build/test slot was released immediately after success. The user interruption of the lengthy previous whole run was respected; no whole run resumed by this executor.

## Self-review / refactor / integrity

No refactor necessary after the minimum message mapping. Reviewed exact diff `notice-policy-source-diff.txt`: enum computed presentation property only, no new state/cache/dependency/test branch. Scoped private local helpers provide dedup and recursive cause reuse without expanding storage/model APIs.

All **23/23 test Git blob hashes unchanged**, verified before/after; `notice-policy-test-hashes-after.json`. The controller class body exact-byte equality was checked separately. Final controller source SHA256 `194aafc7e80f7423ef2d1a9057d2121b0631f8e4d0ef7f842727bfb6ed374253`.

One existing AppIntents metadata-skipped SDK warning appears; no source compiler warning/error. Disk65GiB free at start. No agents/dependencies/commits/pushes.

## Remaining evidence boundary

- The8 tests cover required user-facing reason categories, partial combined reasons, duplicate suppression and generic guidance. They do not explicitly exercise a writeBlocked wrapper; that reuse path compiled but is not a separately executed wrapper test. No test was added/edited outside the frozen author file.
- Existing fallback output exactness is supported by unchanged literal base strings and the `.unreadable -> nil`/noncapacity-save fallback; no claim of fresh actual VoiceOver speech.
- Parent handles short final combined unit547 and Release validation, delta review/acceptance and PR/merge. No unrequested UI/full-native rerun performed here.
