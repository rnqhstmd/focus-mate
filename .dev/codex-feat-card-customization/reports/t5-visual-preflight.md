# T5 visual preflight — read-only preparation

Status: **READY FOR FRESH CAPTURE / final visual match PENDING**. This pass changed only this report; no source/test mutation, build/test, simulator action or clone refresh was performed. Isolated author owns the current execution slot.

## Evidence read

Directly viewed both reference PNGs: `reports/design-reference/z3LCu.png` (R39) and `x3PCFl.png` (R40), each 804×1748px representing 402×874pt. Read raw `pencil-read.txt`, design.md final reference contract, `t5-visual-handoff.md`, `t5-visual-precheck.md`, current CardCustomizationView.swift, PassFace.swift, CardStyle.swift, FontCatalog.swift, test screenshot call sites, runtime checkpoint and Photos ownership preparation.

Current-source findings below are static facts, not proof that the final binary renders them. Earlier `t5-ui-fix-r4-moving.png` is a large-portrait diagnostic state, not final R39/R40 visual acceptance. Earlier initial `t5-live-editor.png` predates three precheck fixes.

## Concrete reference comparison

| Area | Exact reference | Current source / remaining visual gate |
|---|---|---|
| Base/layout | #0D0F10; horizontal24pt; card inner352×221.1875 plus outline | Source background exact, horizontal24, PassFace ratio352/221.1875, preview width available354 with corner16. Latest stage AX preview354×222.333 at x24/y134 is compatible with outline/reference y133. Fresh basic cap must verify; no rescale/reflow justified. |
| Header | back x14/y60/52×52, title x74/y75.4, undo near354/78 | Source back52 and leading14, title20, inter-item spacing14 yields title origin near80. This6pt offset is known, but font/safe-area differences and latest title glyph bounds need fresh capture. Not a material new defect from static source alone. |
| Palette | #121416,#4B5661,#244154,#675364,#D9CDB9,#F1EEE7; circles39 and pitch48 | Exact source order/colors/dimensions. Selected48 outer ring/check retained. Verify selected sand thumbnail/outline correspondence and dark/light check contrast in final caps. |
| Native custom color | reference text x24/y537.44, group marker x96..134 | Source caps group at110pt width from x24, minimum44 high. This addresses the precheck's detached picker. Native circular marker shape is allowed. Fresh basic cap must check grouping and vertical rhythm, not replace native control. |
| Photos | title x24/y601.8, add x284.5/y589.5/93×43 | Source photos top10 after colors (precheck excessive-gap repair), section15, add43 high/background #181D20, thumbnails58 with10 gap. Font can change button width. Measure final actual positions before more spacing changes. |
| Restore link | reference text y749.44, underline y764 | Source explicitly underlines link and gives44pt minimum target. Initial missing-underline feedback is implemented statically; visibility above fixed footer still requires new screenshot/scroll. |
| Footer | x24.5/y788.5/353×51, white capsule, black15pt text | Source white capsule, horizontal24, vertical16 text padding, safeAreaInset. Compare physical safe area and visible final y/height; do not freeze y788.5 across different simulator metrics. |
| Typeface | final decision SeoulAlrim Medium/Bold supersedes PNG Noto | Source registration uses bundled font names and .custom PostScript SeoulAlrimTTF-Medium/Bold. Actual registration/use requires final binary evidence; source alone is insufficient. |
| Card states | default identity/dots; custom hides brand/name/purpose; fixed IC/contactless; no card number | Source implements state condition and fixed art order. References show number/brand badge in R40, deliberately superseded by PRD; do not add them back. |
| Selected photo | R40 first image clips outside upper/left; second overlaps lower/right, white border+handle, matching selected thumbnail | Current source has clip, selection stroke and bottom-right32pt handle, thumbnail selection ring. Existing automatic selected-photo capture is centered60% portrait, whose bottom-right handle can lie below the card and be clipped. This capture is **insufficient to verify the R40 visible-handle arrangement**. Obtain a separate real edited overlap state with handle inside card. Do not change initial60% policy to match PNG example53%. |

**No additional material deviation is currently demonstrated well enough to justify another source polish edit.** The known selected-photo control reachability failure is a functional gate, not a reason to invent visual geometry changes. Final current-binary caps are required to decide precheck spacing/underline completion and any new material issue.

R40 reference handle path is about28×44 at card-relative329.7266/170.0312 while source draws32×32 circle. Treat this as a concrete appearance comparison to inspect, not an automatic exact-size requirement: approved handoff mandates visible white handle and independent44pt interaction, and geometry depends on edited photo. Similarly reference photo-width53% is an example, not an expected default.

## Exact screenshot attachment extraction

From the parent's final successful UI12 xcresult (record its full path/HEAD/source hash), export attachments once into a fresh directory, retaining original PNGs and manifest:

```sh
xcrun xcresulttool export attachments --path <FINAL_UI12.xcresult> \
  --output-path <DEV>/t5-final-ui12-attachments
```

Use manifest `suggestedHumanReadableName` plus test identifier to find each name below, then map its `exportedFileName` to a stable copy. Keep original bytes/manifest. Native export adds suffixes such as `_0_<UUID>.png`; do not assume the human name is the actual filename. Confirm deviceId=`88EC0B32-40D7-4592-A34F-E09C051CECFA`, dimensions, timestamp and scale. The `.keepAlways` call sites currently create these nine screenshots:

| Exact attachment.name | Case | Stable final review filename |
|---|---|---|
| `T5 basic` | test01 | `t5-final-r39-basic.png` |
| `T5 photo2selected` | test04 | `t5-final-r40-photo2selected.png` |
| `T5 confirmation` | test03 | `t5-final-confirmation.png` |
| `T5 import-error` | test08 | `t5-final-import-error.png` |
| `T5 save-error` | test11 | `t5-final-save-error.png` |
| `T5 XXXL-basic-start` | test12 | `t5-final-xxxl-basic-start.png` |
| `T5 XXXL-basic-end` | test12 | `t5-final-xxxl-basic-end.png` |
| `T5 XXXL-photo-start` | test12 | `t5-final-xxxl-photo-start.png` |
| `T5 XXXL-photo-end` | test12 | `t5-final-xxxl-photo-end.png` |

Additional runtime screenshot required: `t5-final-r40-overlap-handle.png`, obtained through existing actual edit controls in the runtime probe after two real imports, sand selection, selected photo moved/resized so its handle is visible and photos overlap. Record actual JSON/selection at capture. Do not alter tests merely to recreate example53%; the ordinary selected capture remains an independent default-state check.

For each image first compare ratio/margins/card position/header hierarchy/palette/footer, then typography/selection/clip/fixed decorations. XXXL start/end must expose all tools, restore and final body text above footer without smaller text. Error/confirmation must retain draft/choices/retry context. A screenshot cannot prove touch clipping, drag/undo/save/actual speech.

## Runtime clone refresh checklist — preparation only

1. Wait for parent slot handoff and UI12 source freeze; do not refresh a running independent clone. Run disk check first, use only owned iOS27 `F226C28A-81D5-4708-B939-81B605AC748E`, no second build/test. Keep iOS26.5/unknown devices untouched.
2. Read-only comparison performed in this pass found **two production files different** between ROOT and `.build/photos-probe/project`: `ios/FocusMate/CardCustomizationView.swift` and `ios/FocusMate/CardIssuanceController.swift`. Therefore the previous clone-source manifest is stale for final-source runtime claims.
3. Refresh **entire** ROOT `ios/FocusMate` production directory/resources and current xcodeproj into the independent clone, maintaining its dedicated probe target/file selection. Do not overwrite ROOT tests or import all UI12 into the probe. Copying just the view misses font/assets/other final source. Preserve original probe source and independent project-target modifications before reconciling project metadata.
4. Generate a fresh relative-path→SHA256 manifest of all copied production/resources and verify equality against ROOT; record both current source manifest and probe hash. Compare current `UITestLaunchSupport.swift` with clone support and intentionally sync needed support without losing probe tests. Confirm no temporary `W10PlacementProbe` in clone/source and rebuild the clone: old installed/probe binaries can contain logging even after source cleanup.
5. Use the whole rebuilt `.app` with resources/debug dylib, not just its Mach-O. Reuse prior build records only if manifest matches; stale test-without-building is not final-source verification. Build/test sequentially with probe-only selection and dedicated `.build/photos-probe/derived`. Preserve earlier ENOSPC logs as failed setup attempts, not product results.
6. Confirm actual Settings Reduce Motion switch and W10 `test.reduceMotion=true`; earlier Settings ON alone does not prove app runtime environment. Same simulator UUID and same app seed UUID must be recorded across save/relaunch checks.
7. Open actual PhotosPicker, capture its current AX/screen first, choose owned red120×80/blue80×120 assets using observed selectors and verify draft dimensions/order/IDs/data hashes. Existing eight Photos include six not owned; do not assume picker order6/7. Native picker success must not be substituted by DEBUG import manifest.
8. With unchanged draft/history, cancel picker and compare draft/selection/history/file before/after; reselect same asset in a separate step and verify import completes. Exercise actual alternative X/Y and size controls with before/after state, save, relaunch same UUID, compare IDs/content/placement.
9. Only after successful save, re-identify the two owned assets in Photos by observed pattern/date/metadata; if ambiguous, do not delete. Preserve six prior assets. Delete only the two clearly owned assets through actual Photos UI and verify8→6, then relaunch same app UUID and compare saved photo hashes/order/placement. Fixture file deletion is not Photos-library independence.
10. Enable actual `XCUIVoiceOverService`; record enable/isEnabled/currentSpeech and actual forward/backward navigation. Verify names, selection, current width percent, X/Y controls, disabled/loading states, import/save notices. VoiceOver move/focus speeches are distinct from AX labels/diagnostic announcement arrays. For automatic notice focus, observe currentSpeech without moving focus to manufacture success; keep visible interactive actions and actual speech as separate evidence. Disable VoiceOver in teardown even on failure.
11. Report observed PASS/FAIL/unavailable separately with raw logs, xcresult, actual speech, screenshot and final clone manifest. Earlier legacy W01/W02/W13 actual VO successes do not establish W10 VO. Shut down owned idle simulator after the sequential probe; cleanup/erase only within ownership and parent's requested merge cleanup rule.

No runtime action above was performed by this preflight. Parent runtime gate remains pending.


## 2026-10-14 — focused04 current selected-photo image, preliminary only

Read-only export performed from `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_22-09-54-+0900.xcresult`, restricted to test04 and `--filter '*.png'`. Exactly **one PNG** was exported, no video or other case attachments:

- `t5-reach-attachments/53425754-E1B3-45F6-B8A4-54C91BBA076D.png`
- manifest name `T5 photo2selected_0_CDDCFC71-72DD-4107-863A-B419F640D1D7.png`
- deviceId `88EC0B32-40D7-4592-A34F-E09C051CECFA`, native1206×2622 (402×874pt,3x), attachment timestamp1791983412.17.

The PNG was directly viewed and compared to the already directly viewed R40 PNG. Viewer showed a resized942×2048 version; coordinate estimates below are visual pt estimates rather than pixel-diff or exact extracted glyph bounds.

**Visible alignment preserved:** black page, circular back/title/undo header, card approximately x24/y134/354×222, two-line instruction, six muted palette circles in approved order, sand check/outer ring, nearby native custom picker, photo row/add button, two thumbnails with the second selected, current60% width and native slider, white fixed save CTA. The card's IC and contactless indicator remain above photo artwork. No card number/brand/name/purpose is shown on custom card, as required by superseding PRD. The red/blue actual fixtures differ from reference city images intentionally; this is not a missing image asset.

**Preliminary differences and limits:**

1. Custom color marker is now adjacent to its text, rather than detached toward screen center. It appears around x106..134 and matches the intended grouping. Native rainbow circle is permitted. This directly supports the old grouping feedback being addressed in the current binary.
2. Instruction and palette start are close to the reference rhythm after safe-area/font differences. The photo-title/add row now appears about **10–20pt higher** than R40 (reference titley601.8/addy589.5). This is a concrete remaining spacing comparison for fresh final basic/selected caps, not sufficient justification for another edit from a single resized image: check measured logical bounds and both empty/selected states first. No overlap or unreadable row is visible.
3. Both real fixture photos remain centered at initial60%; portrait artwork is clipped at top and bottom. Its white selection sides and selected thumbnail are visible, but its bottom-right resize handle is outside the card and clipped. Thus this image does **not** close the R40 visible-handle/lower-right-overlap comparison. A legitimately edited state with visible handle remains required; do not change initial policy or render clipped portions outside card to force this cap to resemble R40.
4. Width label and actual native slider are visible, extending farther than R40's faint/absent track; this is the explicitly approved final design's slider, not an unrequested control. X/Y/layer/delete tools lie below current viewport and must be reviewed in final scrolled/XXXL images and interaction evidence. A static cap does not prove reachability.
5. Restore underline, default card/dots/font behavior, alerts and errors are outside this image. The nine final captures and actual runtime gates remain pending. The selected-state image alone cannot establish final visual PASS.

No source/tests/device edits or build/test executed; parent's exclusive cumulative run was left untouched. No additional material source change is proposed by this preliminary inspection.
