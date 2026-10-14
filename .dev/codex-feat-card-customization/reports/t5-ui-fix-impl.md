# T5 UI fix isolated implementer report

Status: **NEEDS_CONTEXT — GREEN NOT ACHIEVED; build/test slot released.**

## Source changes retained

Only `ios/FocusMate/CardCustomizationView.swift` was edited, via same-directory temporary file + rename each time.

1. The clear gesture canvas has explicit `frame(width: size.width, height: size.height)` before `contentShape(Rectangle())`.
2. The preview ZStack also defines `contentShape(Rectangle())` after its fixed-size frame.
3. The oversized artwork/selection AX aggregate is replaced with `accessibilityRepresentation` containing a card-size clear view and the unchanged `카드 미리보기` label and `cardCustomization.preview` identifier. The representation replaces decorative children without changing visible artwork or gestures.

PassFace already disabled hit testing, so no PassFace edit was needed. Slider range, continuous binding, actual-photo-width VoiceOver value, controllers/models/stores, RootView and all tests were untouched. Earlier three visual precheck changes and placement preservation remained.

## Independent investigation

**05:** First focused retry after only bounding clear frame still failed NotHittable. Its native AX failure attachment shows the clear child at `{{24,-99.3},{354,222.3}}`, but preview aggregate at `{{-242.2,-652.5},{886.3,1328.7}}` including the oversized selected portrait/handle. This aggregate covers the y-increase button at `{{334,611.7},{44,44}}`. Thus the clear bounding alone did not bound AX geometry.

After replacing the preview AX representation, all 30 y-increase taps synthesized, color background changed, and save completed with saved style equal to the actual draft. However the independently asserted selected-photo centerY remained 0.5 rather than 2.0 (line 148), so AX tap reachability is not proof of movement. The additional outer contentShape did not change this outcome. Underlying reason for movement not taking effect remains unresolved; do not classify 05 as PASS or weaken its centerY oracle. Snapshot `t5-ui-fix-r4-moving.png` during the test shows the visible editor at its upper content while test activity was querying y controls, motivating independent coordinate/AX diagnostics. This is an observation, not a confirmed framework defect.

**04:** Native normalized-slider request 0.5 produced widths 1.422891080379486 (r1), 1.4619499951601027 (r3), and 1.4315548866987229 (r4), all outside literal 1.325 ±0.02. CenterX=0.55 and centerY=0.45 passed before width failure; later assertions were not reached. The source getter/setter linearly exposes width in 0.15...2.5 with unchanged width-percent accessibility value. r1 actual AX maximum-width slider was label `사진 크기`, value `250퍼센트`, frame `{{24,512.7},{354,31}}`. No actual before/after normalizedSliderPosition AX read was added because tests are locked. Apple documents `adjust(toNormalizedSliderPosition:)` as best effort with no absolute fidelity guarantee. Product-linear-binding correctness and exact native automation movement are distinct; return to isolated test author for diagnostics, without removing real-width VO feedback or policy changes.

## Focused execution command

All runs used the same command, only log filename changed:

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=88EC0B32-40D7-4592-A34F-E09C051CECFA' \
  -derivedDataPath .build/ios -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO \
  -collect-test-diagnostics never \
  '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test04_실제_두사진을_순서대로_추가해_선택사진만_편집한다' \
  '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test05_카드밖_사진은_색과_저장탭을_가로채지_않고_목록에서_복귀한다'
```

| Run | Result | Log | xcresult under `.build/ios/Logs/Test/` |
|---|---|---|---|
| r1 clear bound | 0 pass / 2 fail; exit 65 | `t5-ui-fix-focused.log` | `Test-FocusMate-2026.10.14_21-38-40-+0900.xcresult` |
| r2 rejected AX-frame candidate | compile failure, 0 tests; exit 65 | `t5-ui-fix-focused-r2.log` | `Test-FocusMate-2026.10.14_21-41-12-+0900.xcresult` |
| r3 AX representation | 0 pass / 2 fail; exit 65 | `t5-ui-fix-focused-r3.log` | `Test-FocusMate-2026.10.14_21-41-48-+0900.xcresult` |
| r4 outer hit shape | 0 pass / 2 fail; exit 65 | `t5-ui-fix-focused-r4.log` | `Test-FocusMate-2026.10.14_21-45-32-+0900.xcresult` |

The r2 `accessibilityFrame` candidate was removed immediately after the compiler reported SwiftUI has no such member. Installed SDK swiftinterface confirms supported accessibilityRepresentation; r3/r4 compiled. Retained source has no accessibilityFrame call.

No full12 or cumulative259 executed, because two-focused-PASS prerequisite was not achieved. No simultaneous build/test, other device edits, commits, dependencies or cleanup.

## Evidence and warnings

- `t5-ui-fix-attachments/1B21E380-9048-470C-BBBF-4551B100D374.txt`: native r1 failure AX hierarchy.
- `t5-ui-fix-attachments/A7117D30-E14B-4273-A6B4-EA5DB15EE0B2`: native failure UI snapshot.
- `t5-ui-fix-activities05.json`: native r1 activity tree.
- `t5-ui-fix-r4-moving.png`: actual owned simulator screenshot captured during r4.
- r1/r3/r4 compile warnings only report skipped AppIntents metadata extraction because no AppIntents.framework dependency. Native launch logs also report debugger version lookup noURL. No compiler actor-isolation or unused-binding warnings observed in these logs.
- Test19 hashes checked against locked JSON before edit and after final source edits: **19/19 exact git blob matches**. `t5-ui-fix-test-hashes-after.json` records final values.
- Data-volume available disk measured 62Gi at start and during r4. No cleanup needed/performed.

## Official API references

- [XCUI slider adjustment](https://developer.apple.com/documentation/xcuiautomation/xcuielement/adjust%28tonormalizedsliderposition%3A%29): best-effort move, absolute fidelity not guaranteed.
- [SwiftUI accessibilityRepresentation](https://developer.apple.com/documentation/swiftui/view/accessibilityrepresentation%28representation%3A%29/): synthetic hidden/noninteractive accessibility replacement.
- [SwiftUI contentShape](https://developer.apple.com/documentation/swiftui/view/contentshape%28_%3Aeofill%3A%29): hit-testing shape.

## Self-review and next gate

No test or non-screen source changes. The source refinements have narrowed AX hit geometry but have not satisfied actual movement acceptance. Keep 05 production failure open; obtain actual pointer hit/scroll/AX coordinate diagnostics before claiming fix. 04 requires isolated author evaluation of approximate native slider oracle. PhotosPicker, VoiceOver, Reduce Motion, final visuals, full12, cumulative259 all remain pending parent gates.
