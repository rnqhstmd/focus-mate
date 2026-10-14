# T5 placement callback diagnostic

Status: **NEEDS_CONTEXT / diagnostic complete / slot RELEASED**. Original test05 remains FAIL; no product fix or test change performed in this diagnostic.

## Observed result

Width-only callback positive control worked: **43 entry / 43 exit** records from `FocusMate[99075]`, unified-log timestamps **2026-10-14 22:00:30.402–22:00:31.205**. The initial report of 45 pairs was an estimate from a truncated read and is superseded by the exact parsed 43 pairs here.

All entries have `x=nil y=nil width=Optional(...)` for photo `05D4F4FB-6976-4BE4-B859-92F683E14874`. Width progresses from 0.6 to 2.5, and every before/after X and Y remains 0.5. There are **0 Y-only entries**, **0 X/Y drag entries**, **0 missing-ID guards** and no further placement events after the width operation. Logger validity is proven by the current test's actual width mutation.

Original test05 synthesized **30 Y-increase taps**, t=22.73–137.03 seconds. No Y placement callback was received. This narrows the failure to the path between synthesized taps and the existing Button→place call, before the model's setPlacement guard/clamp/apply path. It does not identify the actual recipient of the touch or prove a particular SwiftUI framework defect.

## Author observation attachments

All three stages retain the same selected photo, `isImporting=false`, centerX=0.5, centerY=0.5 and width=2.5. The other photo stays at width=0.6 and centers=0.5. Sand changes only background. There is no Y=2 state that is later lost on preview scroll, color selection or save.

| Stage | Activity timestamp | body frame | preview frame | Y+ button frame | selected Y |
|---|---|---|---|---|---|
| after Y loop, before preview scroll | t139.96 attachment | (0,134,402,740) | (24,134,354,222.3333) | (334,845,44,44) | 0.5 |
| after preview scroll, before sand | t142.61 attachment | same | same | same | 0.5 |
| after sand, before save | t146.76 attachment | same | same | same | 0.5 |

The Y+ frame reaches y=889, beyond the 874pt screen and below the fixed save footer observed in earlier failure AX. The preview remains at the top. The original reach(container) path did not establish actual visibility of the child button. A separate independent probe should measure exact button visibility and native viewport/footer intersection before one tap. Do not weaken the strict Y=2/return Y=0.5 policy assertions.

Current stage attachments contain frames and JSON, not native ScrollView count/role or first-click state. Exported binary UI snapshots were minimally inspected but did not provide a full editor tree/body role. Body native-role/count and actual hit recipient remain unmeasured in this diagnostic. No new test instrumentation was added.

Attachment files under `t5-placement-attachments/`:

- `3F42BDAF-444B-4E3F-AE4E-01C5A011BDB0.txt`: after-y-loop.
- `1E6E7A83-DC9E-41AD-8E95-41CFA0FD94C4.txt`: after-preview-scroll.
- `F5A38470-A77B-4C97-974A-920A008DE0BF.txt`: after-sand.
- `AF7A4183-61B0-4A6A-A6DA-88015538BC3B.mp4`: native test screen recording, exported and preserved, not visually reviewed here.
- `manifest.json`: full 41 exported native attachments, including synthesized events and UI snapshots.

## Exact execution

Temporary source-only DEBUG NSLog entry before ID guard and exit after setPlacement recorded optional inputs, photo ID, before/after coordinates and width. No @State, overlay, new model API, dependencies, accessibility or layout changes.

```sh
xcrun simctl spawn 88EC0B32-40D7-4592-A34F-E09C051CECFA log stream --level debug --style compact \
  --predicate 'eventMessage CONTAINS "W10PlacementProbe"' \
  > .dev/codex-feat-card-customization/t5-placement-events.log 2>&1

xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=88EC0B32-40D7-4592-A34F-E09C051CECFA' \
  -derivedDataPath .build/ios -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO \
  -collect-test-diagnostics never \
  '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test05_카드밖_사진은_색과_저장탭을_가로채지_않고_목록에서_복귀한다' \
  > .dev/codex-feat-card-customization/t5-placement-diagnostic-ui.log 2>&1
```

Actual result **0 pass / 1 fail**, 152.428 seconds, exit65. Strict line173 saved selected centerY `Optional(0.5)` vs `Optional(2.0)`. Save closed.saved==expected draft and background checks passed before that failure. No full12/cumulative run. xcresult: `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_22-00-01-+0900.xcresult`.

Unified stream was stopped via the owned exec session after test completion. Build/test slot is released. Warnings: three skipped AppIntents metadata extraction warnings and existing native debugger version noURL messages; no source compile errors or actor/unused warnings.

## Cleanup and integrity

Source cleanup used atomic temp+rename, restoring the exact bytes in `t5-placement-source-before.swift`. SHA-256 of restored CardCustomizationView.swift is **752015bad30a5d57e67084dbb23eea6b4a264ebbaf4f64d510127b0537b13d18**, equal to the pre-probe source and coordinate investigation. No `W10PlacementProbe` remains in production source. Existing bounded preview fixes are preserved, with zero net source change from this diagnostic. A rebuild is required before treating the installed app as a logging-free binary.

All19 test git blob hashes matched the parent-regenerated `t5-test-hashes.json` before instrumentation and after cleanup. Exact after values saved to `t5-placement-test-hashes-after.json`. No test file edited, no commits, no other device/worktree/cache operation.

## Previous screenshot device provenance

The exact earlier r4 screenshot command from this implementer's tool history was:

```sh
xcrun simctl io 88EC0B32-40D7-4592-A34F-E09C051CECFA screenshot .dev/codex-feat-card-customization/t5-ui-fix-r4-moving.png
```

It used the explicit owned device UUID, not `booted` or the unknown iPhone18Pro. Output named default display 51B30A44-CFA6-4267-B45D-C66ECFB9A9FE. This proves the requested simulator provenance; image timestamp interpretation remains as documented in the coordinate investigation.
