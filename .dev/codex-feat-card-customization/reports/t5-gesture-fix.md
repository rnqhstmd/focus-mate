# T5 native gesture selection GREEN fix

Status: **DONE / focused actual GREEN / exclusive slot RELEASED**.

## Minimal implementation and cause

Only `ios/FocusMate/CardCustomizationView.swift` production changed, atomically via same-directory temp+rename. Existing preview drag `onChanged`/`onEnded` callbacks and their selection/placement calculations were left unchanged. Replaced two independently attached gestures, DragGesture plus `.simultaneousGesture(SpatialTapGesture...)`, with one `.gesture(DragGesture...exclusively(before: SpatialTapGesture...))`.

The prior actual native resize changed width but ended with selection nil (parent's genuine RED at selection assertion). The old composition allowed the tap callback to participate alongside an actual drag/resize. The new composition lets recognized dragging take precedence, so a completed edit cannot also run tap deselection. When the drag fails to recognize a simple tap, the original SpatialTapGesture callback still executes. No timing flag, test branch, logging, fake setter, added state or controller policy change.

API verified from installed primary SDK `SwiftUICore.swiftinterface:1821` and [Apple exclusively(before:) documentation](https://developer.apple.com/documentation/swiftui/gesture/exclusively%28before%3A%29): only one composed gesture succeeds, with precedence to the first. This is appropriate to mutually exclusive photo editing and photo/empty-canvas tap selection.

## Actual focused GREEN

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=F226C28A-81D5-4708-B939-81B605AC748E' \
  -derivedDataPath .build/ios -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO \
  -collect-test-diagnostics never \
  '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test13_실제드래그와_크기조절후에도_선택사진을_유지한다' \
  > .dev/codex-feat-card-customization/t5-gesture-green.log 2>&1
```

Actual **1 test PASS / 0 failures / exit0 / TEST SUCCEEDED**,61.155s. ROOT actual project rebuilt changed source and installed current runner/app before executing. This was not the independent runtime clone or an old test-without-building product. Owned iOS27F226 only;26.5/unknown18Pro untouched. No other build/test launched, no full12/13/cumulative. Parent owns subsequent cross-runtime/full boundary validation.

xcresult: `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/ios/Logs/Test/Test-FocusMate-2026.10.14_23-03-17-+0900.xcresult`.

Actual landscape A ID: `8B6B8035-9329-4BC5-9C46-09B62AF3E371`.

| Native stage | selected | A centerX | A centerY | A width |
|---|---|---|---|---|
| before-drag | A |0.5|0.5|0.6|
| after-drag | A |0.5677966101694916|0.5524475989631809|0.6|
| before-resize | A |same|same|0.6|
| after-resize | A |same|same|0.656497175141243|
| after-empty-tap | nil |same|same|same|
| after-topmost-overlap-tap | A |same|same|same|

All test13 assertions passed: positive actual displacement/size increase, fixed center during resizing, original data/hash/dimensions, untouched other photo, unchanged background/order as specified, unchanged saved/persisted state. Empty-canvas/topmost-overlap compatibility guards also actually compiled and ran; they were not inferred from source. These outcomes establish the bounded one-landscape/inside-handle path, not every pointer/multitouch/off-card gesture.

Six native stage txt attachments were exported without video into DEV `t5-gesture-attachments/`, with manifest. The original screenshots remain retained in xcresult. Exact key files: before-drag `8A6AAA95-C77E-43A4-A353-261A18DE54CD.txt`; after-drag `5D460F79-E241-43BE-976A-15528A480242.txt`; before-resize `A9880588-B527-451D-A766-B4F215042AD2.txt`; after-resize `E18EBEFD-56E7-4069-B1A5-2303F2F01B7F.txt`; empty-tap `13C73B53-E002-4314-9E6C-87597458B837.txt`; topmost `D10E5C20-85ED-494C-B877-083BBAD64F35.txt`.

## Refactor and self-review

No refactor necessary after the minimal gesture composition change. Reviewed exact diff: three changed gesture punctuation/composition lines, callbacks/geometry/locks/accessibility/preview hit bounds unchanged. No extra feature or speculative F2/focus change. PassFace/font fix untouched. No source outside permitted view edited.

Locked20/20 test git blob hashes matched `t5-test-hashes.json` before edit and after PASS. Final hashes retained in DEV `t5-gesture-test-hashes-after.json`. Final CardCustomizationView SHA256: `b27fda9f15fe8347f15510c4500893ce3c23e196960c596fe9968d3fb5dfe35b`.

Warnings were three existing skipped AppIntents metadata extraction messages (no framework dependency), plus native debugger version lookup noURL notices. No compile failures/actor-isolation/unused warnings observed. Disk check60GiB available. No dependencies, subagents, commits/pushes, cache cleanup or device lifecycle operations.

## Remaining concerns

No known concern in this focused path. Parent full native regression on26.5 and actual runtime owner clone refresh must consume the changed view before final R40/VoiceOver/Photos results. The independent runtime clone is not silently refreshed by editing ROOT. Existing no-manual VoiceOver notice-focus results and disputed F2 are outside this fix.
