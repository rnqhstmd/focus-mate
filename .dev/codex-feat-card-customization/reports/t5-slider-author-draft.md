# T5 slider test-author draft

Status: **DRAFT READY / NOT APPLIED / EXECUTOR HASH LOCK PRESERVED**

Only this report has been created. No test target or production file was changed; no build, test, device, Git, or child-agent action was performed. Apply the proposed hunk only after the parent explicitly releases the executor's active 19-file hash lock and authorizes the test change.

## Product contract and platform assumption

PRD AC-W10-11 requires moving/resizing the selected photo while preserving its original aspect ratio, other photos, and saved appearance. AC-W10-12 and the design define width limits of 15...250%; newly imported photos start at 60%. The UI provides the real width Slider and exposes its current value.

The existing `test04` assertion demands `widthFraction == 1.325 ± 0.02` after requesting normalized position `0.5`. The numeric midpoint is mathematically correct for an exact normalized midpoint in the 15...250% range, but the assumption that XCTest's gesture must land at that exact position is not the product GWT.

Apple's official [`adjust(toNormalizedSliderPosition:)` documentation](https://developer.apple.com/documentation/xcuiautomation/xcuielement/adjust%28tonormalizedsliderposition%3A%29) says: “The adjustment is a best effort to move the indicator to the desired position; absolute fidelity isn’t guaranteed.” This documents the gesture's precision limitation; it does not waive the product's placement or clamp policy.

## Reproduction evidence and limits

Parent/executor-reported reproduction values, not freshly executed or independently log-verified by this author:

- Native request `0.5`: width `1.4315548867` failed the old `1.325 ± 0.02` assertion.
- After the executor's bounded hit-layer fix: width `1.4228910804`; observed normalized position `0.541655779`; old assertion still failed.
- X and Y assertions (`0.55` and `0.45`) passed. The subsequent nonselected-photo assertion was not reached under fail-fast execution, so it has no passing execution evidence yet.
- The supplied relative log path `reports/t5-resume-ui.log` was absent under DEV when queried. No alternate logs were searched outside the authorized path.

The reported widths are larger than the independently specified initial `0.6`, finite, and strictly inside the product's literal bounds. They motivate correcting the platform precision assumption; they are not new expected values.

## Proposed minimal patch: test04 only

```diff
@@ func test04_실제_두사진을_순서대로_추가해_선택사진만_편집한다()
         XCTAssertEqual(moved[0].centerX, 0.55, accuracy: 0.0001)
         XCTAssertEqual(moved[0].centerY, 0.45, accuracy: 0.0001)
-        XCTAssertEqual(moved[0].widthFraction, 1.325, accuracy: 0.02)
+        // XCTest's native slider gesture is best effort; verify the user's resize outcome.
+        XCTAssertTrue(moved[0].widthFraction.isFinite)
+        XCTAssertTrue((0.15...2.5).contains(moved[0].widthFraction))
+        XCTAssertGreaterThan(moved[0].widthFraction, photos[0].widthFraction)
+        XCTAssertLessThan(moved[0].widthFraction, 2.5)
         XCTAssertEqual(moved[0].pixelWidth, 120)
         XCTAssertEqual(moved[0].pixelHeight, 80)
         XCTAssertEqual(moved[1], photos[1])
```

Keep the initial width `0.6` equality, genuine `app.sliders` query, `adjust(toNormalizedSliderPosition: 0.5)`, and every remaining clause unchanged. The suite remains 12 cases. There is no wider tolerance, private midpoint, surrogate control, harness override, new fixture flag, or production setter.

## Mutation coverage

The proposed assertions reject a no-op at `0.6`, a reverse change below the initial width, an always-minimum result, an always-maximum result `2.5`, nonfinite values, and out-of-range values. Existing assertions reject changed X/Y (`0.55/0.45` must remain), changed original dimensions (`120/80`), edits to the second photo, wrong layer order, wrong deletion, and broken undo restoration. The unchanged initial assertions provide an independent literal initial-width oracle; the post-action comparison observes the user's before/after result.

Limits: a wrong constant at an arbitrary valid interior value greater than `0.6` can pass this UI outcome check. This test does not prove exact numerical request-to-placement mapping, every boundary, or clamp behavior. Those remain the model/controller policy test responsibility. It does prove a real native gesture resizes the selected photo while the existing clauses check isolation and preserved state. No actual mutation or test execution was performed here.

## Current-value accessibility

The authorized PRD/design specify current-value accessibility, but do not define percentage wording, integer precision, flooring, or rounding. Therefore this draft does not invent `Int(width * 100)` or another formatting oracle. If an independently approved public contract specifies percent flooring, a subsequent authorized hunk can compare the actual Slider accessibility value with the floor of the observed metadata; exact formatting must come from that contract. Current-value correctness is not newly verified by the proposed minimal hunk and remains an explicit coverage limit.

## Sources read

- `agents/red-writer.md` (role contract)
- DEV `prd.md`, `design.md`, `reports/t5-test-author-repair.md`
- `ios/FocusMateUITests/CardCustomizationFlowTests.swift` (test-author-owned target)
- Apple's official `adjust(toNormalizedSliderPosition:)` documentation, URL above

No production source was read.
