# T5 confirmed F1 artwork-only GREEN fix

Status: **DONE / focused GREEN / build-test slot RELEASED**. Parent's full cumulative/boundary verification and actual27 runtime remain separate gates.

## Implementation

Only production `ios/FocusMate/PassFace.swift:13` changed, via atomic same-directory temp+rename:

```diff
- .overlay { artwork.accessibilityHidden(true).allowsHitTesting(false) }
+ .overlay { artwork.environment(\.dynamicTypeSize, .large).accessibilityHidden(true).allowsHitTesting(false) }
```

PassFace is the fixed352×221.1875 decorative graphic defined by design.md's clarified policy. Its internal typography shares the fixed coordinate system and is now rendered at regular `.large` Dynamic Type independently of the parent's size. The outer single-image accessibility element, full `PassIdentity.displayName` label, image trait, hit-testing exclusion, card proportions and style/photo behavior are unchanged. FontCatalog/global body policy did not change. Editor heading/body/controls/save remain at actual inherited Dynamic Type. No model/controller/Root/source outside PassFace edited; disputed F2 layer row untouched.

Input evidence: isolated author's `reports/t5-passface-accessibility-red.md`, parent direct actual `t5-parent-passface-red.log`, `t5-review.md` Important1 and design.md final XXXL policy. The new metamorphic component assertion was actual RED while same-size determinism, nonblank and size checks already passed. No tests changed by this implementer.

## GREEN evidence

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=88EC0B32-40D7-4592-A34F-E09C051CECFA' \
  -derivedDataPath .build/ios -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO \
  -collect-test-diagnostics never \
  '-only-testing:FocusMateTests/PassFaceAccessibilityTests' \
  '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test12_XXXL에서_도구와복원이_고정저장위로_도달한다' \
  > .dev/codex-feat-card-customization/t5-artwork-green.log 2>&1
```

Actual result: **2 tests PASS / 0 failures / exit0 / TEST SUCCEEDED**. Unit1 `testDecorativeCardCompositionIsInvariantAtAccessibilityTextSize` passed0.068s; UI1 `test12_XXXL에서_도구와복원이_고정저장위로_도달한다` passed79.324s. They appear in separate unit/UI suite summaries (one each). Build compiled changed PassFace and linked before executing; no stale-runner pass substitution. Log: DEV `t5-artwork-green.log`. xcresult: `ROOT/.build/ios/Logs/Test/Test-FocusMate-2026.10.14_22-37-50-+0900.xcresult`.

Only this exact focused set ran, once. No full suite/cumulative, other device use, new dependency, subagent, commit/push or cleanup. Source read-back/diff showed the single-line modifier. Disk start62Gi available.

## Direct final screenshot verification

Exported only UItest12 PNGs to DEV `t5-artwork-green-attachments/`. New basic-start attachment:

- Original: `3B56F80B-BC99-4C2F-A86C-E4CD7CE6B840.png`, exact name `T5 XXXL-basic-start_0_86580E31-69CC-4E0A-8BEC-0EE5AB66899A.png`.
- Review copy: `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.dev/codex-feat-card-customization/reports/simulator/final/t5-artwork-fixed-xxxl-basic-start.png`.
- Native1206×2622px,402×874pt,3x, owned88EC device. Directly opened and visually checked, displayed942×2048 by viewer.

The card's `Focus Mate`, full `집중동행카드`, and full `나를 위한 시간, 한 장으로.` are all visible at separated reference-relative positions; no prior vertical overlap or right-edge text clipping remains. The surrounding editor title, both instruction sentences, section text and fixed save CTA remain visibly XXXL, proving the policy did not shrink the screen globally. Component rendering invariance and whole-screen legibility are separate supporting evidence. Current actual VoiceOver speech was not executed by this fix; the unchanged full AX image label is a source fact, not a fresh speech result.

## Refactor / self-review

No refactor needed for a one-line scoped fix; no additional cleanup or tests written. Reviewed exact before/after diff and verified policy scope is artwork-only. Found no overimplementation. Fixed code preserves normal-size artwork, semantics and controls; the unit's same-size determinism/nonblank controls remain meaningful.

All **20/20 test files** matched parent's locked `t5-test-hashes.json` before edit and after GREEN. After values: DEV `t5-artwork-test-hashes-after.json`. Final PassFace SHA256: `011fd7664a63257ed4b5f8d8c7b84121cd615b969ad5cf49092864ae7632db8c`.

## Concerns and remaining gates

- F1 is resolved for the focused component and current XXXL basic screen. Parent handles cumulative/boundary verification after production change.
- F2 was disputed by independent visual reviewer; prior report assertion was withdrawn to PENDING and no layer-row production change made. Do not state it is a confirmed defect.
- Actual27 picker/VoiceOver/ReduceMotion and visible overlap/handle, and error-notice viewport evidence remain separate pending runtime/visual gates.
- Build emitted two existing skipped AppIntents metadata extraction warnings (no dependency); native debugger version noURL and duplicate font registration diagnostics were not compiler/test failures. No actor isolation/unused-variable warnings in this execution.
