# T5 slider author repair

Status: **APPLIED / PARENT VERIFICATION PENDING**

The parent explicitly released the executor slot and authorized these test-only changes. Only `ios/FocusMateUITests/CardCustomizationFlowTests.swift` was edited, plus this report. No production source was read or changed. No build, test, device, Git, or child-agent operation was performed.

## test04 product oracle correction

Replaced the single exact-width assertion `1.325 ± 0.02` after the real native Slider's normalized `0.5` request with four assertions: finite, within literal `0.15...2.5`, greater than the initial observed photo width (independently asserted earlier as literal `0.6`), and strictly below `2.5`.

The actual Slider query and gesture remain unchanged. Existing X/Y `0.55/0.45`, original dimensions `120/80`, untouched second photo, selection, imported ordering, saved-state, layer movement, deletion, and undo assertions remain unchanged. The suite still contains exactly 12 test methods.

PRD AC11 requires the selected photo to resize while preserving other photos and original aspect ratio; AC12/design define the range and initial width. Exact numerical mapping and clamping remain model/controller policy responsibilities. This outcome check rejects no-op, reverse change, constant min/max, nonfinite and out-of-range results. A wrong arbitrary valid interior constant greater than the initial width remains a stated limitation of this single gesture outcome test; no arbitrary tolerance or observed-private expected midpoint was introduced.

Apple's official [`adjust(toNormalizedSliderPosition:)` documentation](https://developer.apple.com/documentation/xcuiautomation/xcuielement/adjust%28tonormalizedsliderposition%3A%29) states: “The adjustment is a best effort to move the indicator to the desired position; absolute fidelity isn’t guaranteed.” This is a platform gesture precision fact, not a relaxation of product policy.

The directly read DEV-root `t5-resume-ui.log` line 731 records the old line-107 failure with actual `1.4315548866987229` versus `1.325 ± 0.02`. No earlier X/Y failure appears for that case, which reached this width assertion. The subsequent photo2 assertion was not reached under fail-fast. The parent also reports later reproduction widths `1.4228910804` and `1.46195`; this author has not independently read those runs. None of these observed values became the new expected result.

No exact percent/floor/round assertion was added: the approved contract specifies current-value feedback without a rounding or integer-format policy.

## test05 observation only

Added three local `do` blocks containing only state/frame reads, a retained `XCTAttachment(string:)`, and a small print marker:

1. Immediately after the 30 positive-Y actions, before preview scrolling.
2. Immediately after preview scrolling, before the sand color action.
3. Immediately after the sand color action, before saving.

Each attachment includes the actual `test.cardStyleJSON`, observed selected photo ID, body frame, preview frame, and exact existing `cardCustomization.y.increase` button frame. Names identify the observation point. They allow a subsequent run to distinguish ineffective Y actions, a reset during preview scrolling, and a reset during the sand action. No result for that distinction is claimed yet.

No test05 interaction, count, selector, helper, expected value, or existing assertion changed. In particular the strict saved `centerY == 2` and return `centerY == 0.5` expectations remain. Generic strict-ID lookup and scoped confirmation helpers are unchanged. No screenshot or extra gesture was added.

## Verification handoff

Static source inspection is the only check performed by this author. Parent must regenerate all 19 locked test hashes before the next executor invocation and run the focused UI cases. Compilation, new assertions passing, and test05 diagnosis remain unverified until that execution.

References: role `agents/red-writer.md`; DEV `prd.md`, `design.md`, `reports/t5-test-author-repair.md`, `reports/t5-slider-author-draft.md`, and root `t5-resume-ui.log`; the owned UI test; Apple's official documentation above. No production source read.
