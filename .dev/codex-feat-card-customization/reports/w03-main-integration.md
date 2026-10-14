# Latest main W03 maintenance integration

Status **DONE / Debug build PASS / focused545 PASS / slot RELEASED**. Full combined regression remains the parent's final gate.

ROOT `/Users/bonseung/.codex/worktrees/w10-card-customization/new`; DEV `ROOT/.dev/codex-feat-card-customization`.

## Preservation and maintenance merge

Starting HEAD216b965 with all W10 uncommitted production/tests/docs. Actual disk check65Gi available. Before mutation verified all22 frozen test Git blobs.

Executed:

```sh
git stash push -u -m W10-before-W03-main-integration-2026-10-15-isolated
git merge --no-edit origin/main
git stash apply 39de43102c35a3d19f04020439598e4f4feeb6bf
```

New retained stash **39de43102c35a3d19f04020439598e4f4feeb6bf**. Existing `W10 checkpoint before W11 main integration` and older W03 stash retained, none dropped/popped. Merge maintenance commit **8bf0b92247a6ea9b370dc21cb0b4fb8f70ccee72**, containing latest origin/main **5a9b611**, including3cb82ba. `git merge-base --is-ancestor 5a9b611 HEAD` exit0. Merge `.dev/plan.md` cleanly shows W03 complete/W10 in progress. Stash apply auto-merged AppModel/DestinationScreen/FocusMateApp/UITestBootstrap with **zero conflicts**; no manual Swift source edit was required. This commit brings main in; W10 work remains uncommitted, not accidentally committed as completed development.

`git diff --name-only 216b965 HEAD -- ios` reports **23 inherited iOS paths**, comprising:

```text
FocusMate/AVSoundPreviewPlayer.swift
FocusMate/AppModel.swift
FocusMate/DestinationScreen.swift
FocusMate/FocusMateApp.swift
FocusMate/PreparationDraft.swift
FocusMate/PreparationView.swift
FocusMate/Resources/Audio/travel-bus-rain-v2.wav
FocusMate/Resources/Audio/travel-bus-v2.wav
FocusMate/Resources/Audio/travel-forest-v2.wav
FocusMate/Resources/Audio/travel-subway-v2.wav
FocusMate/Resources/Fonts/SOURCE.md
FocusMate/Resources/Fonts/SeoulAlrim-Bold.ttf
FocusMate/Resources/Fonts/SeoulAlrim-Medium.ttf
FocusMate/SoundPreviewController.swift
FocusMate/TimeSelectionView.swift
FocusMate/UITestBootstrap.swift
FocusMateTests/AudioResourceTests.swift
FocusMateTests/PreparationDetailsTests.swift
FocusMateTests/PreparationDraftTests.swift
FocusMateTests/PreparationModelTests.swift
FocusMateTests/SoundPreviewControllerTests.swift
FocusMateUITests/PreparationEditorUITests.swift
FocusMateUITests/PreparationFlowUITests.swift
```

Paths above are under ROOT/ios. Source-composition comparison against W10 stash is preserved as DEV `w03-composed-source-diff.txt`: AppModel inherits preparation draft/request/sound preview API while W10 editor/save extension stays intact; DestinationScreen adds PreparationView alongside W10 Profile callback; FocusMateApp combines bootstrap sound preview injection with FontCatalog registration and existing W10 Root setup; UITestBootstrap gains W03 sound-preview setup while preserving W10 manifest/import gate/save-failure flags/diagnostics. TimeSelection's upstream font correction matches the W10 bytes already present.

## Actual resource build failure and mechanical fix

First actual Debug build **exit65**, log `w03-integration-build-first.log`, with three `Multiple commands produce` errors for app bundle `SOURCE.md`, `SeoulAlrim-Bold.ttf`, `SeoulAlrim-Medium.ttf`. Both W10 `ios/FocusMate/Fonts/` and upstream `ios/FocusMate/Resources/Fonts/` copied identical basename resources into the flat app bundle.

Compared complete bytes and Git blobs before removal. Removed only the three untracked W10 duplicate files and now-empty Fonts directory, keeping upstream Resources/Fonts. Their copies remain in the retained W10 stash. No font bytes, filename, FontCatalog, PostScript family or source attribution modified. Actual app Info has no UIAppFonts entry; existing programmatic FontCatalog.register remains the registration mechanism and was not replaced by a new plist policy.

| File | identical SHA256 | identical Git blob |
|---|---|---|
| SeoulAlrim-Bold.ttf | eb0420723b27ca16bf2f42d734263a97ff23353143d452c29afa2c1d5a370ce9 |2518e66dce8d7c7e92ac6dac2762d33ed897de19|
| SeoulAlrim-Medium.ttf |6e00e4c55c765cc48b142c9770bdbf84a2794a763126147a929092f3075e73e5|bed00a536f965af8712e7fe53358bd6aa6525a78|
| SOURCE.md |23565b23626b88c4916598a12bea08446682ae6c7fd2294eccc46cc311a6bff1|2422e1b222a6a4c57fb19b2532d48da6c25bbf19|

Evidence `w03-font-identical-evidence.json`. Rebuilt app bundle Bold/Medium hashes directly match this table. Resources/Fonts/SOURCE.md preserves 서울특별시 provenance, official links/date and distribution conditions exactly.

Second actual Debug build **exit0 / BUILD SUCCEEDED**, log `w03-integration-build.log`:

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=F226C28A-81D5-4708-B939-81B605AC748E' \
  -derivedDataPath .build/ios -parallel-testing-enabled NO build CODE_SIGNING_ALLOWED=NO
```

The only post-merge adaptation was duplicate resource removal; no speculative feature/design/serialization policy changed.

## Focused combined verification

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=F226C28A-81D5-4708-B939-81B605AC748E' \
  -derivedDataPath .build/ios -parallel-testing-enabled NO test CODE_SIGNING_ALLOWED=NO \
  -collect-test-diagnostics never \
  '-only-testing:FocusMateTests' \
  '-only-testing:FocusMateUITests/ProfileUITests/testAC24_프로필에서_실제편집을_저장하면_복귀안내와외형을_유지한다' \
  '-only-testing:FocusMateUITests/ProfileUITests/testAC25_실제편집을_변경없이닫으면_프로필과정체성과기록을_보존한다' \
  '-only-testing:FocusMateUITests/ProfileUITests/testW10AC35_XXXL메인을_실제스크롤해_프로필편집을_열고닫는다' \
  '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test13_실제드래그와_크기조절후에도_선택사진을_유지한다' \
  '-only-testing:FocusMateUITests/PreparationFlowUITests/testProceedingWithSelectedBusOpensPreparationWithSelectionAndNoActiveJourney' \
  '-only-testing:FocusMateUITests/PreparationEditorUITests/testAC4_AC12_TaskLimitAndTrimmedPreparationRequestPreserveJourney' \
  > .dev/codex-feat-card-customization/w03-integration-focused.log 2>&1
```

Actual **539 unit +6 UI =545 PASS /0 failures /exit0 /TEST SUCCEEDED**. Unit539 took7.923s, UI6 took182.313s. No all-UI/full suite run. Only owned27F226, one build/test at a time; no other simulator lifecycle/Photos/VO action.

| Actual UI case | PASS duration |
|---|---|
| W10 native drag/resize13 +empty/topmost tap guards |59.979s|
| W03 task80-unit limit/trimmed confirmed request/journey preservation |34.406s|
| W03 selected bus→real PreparationView +no active persisted journey |17.710s|
| Profile actual editor save/return/current notice/style/stats preservation |32.218s|
| Profile unchanged-close/identity/records/file preservation |16.974s|
| XXXL main→profile→editor→profile physical access |21.025s|

Result bundle `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/ios/Logs/Test/Test-FocusMate-2026.10.15_00-07-43-+0900.xcresult`.

## Integrity and self-review

All **22/22 original test Git blobs** match frozen manifest before stash and after focused PASS; `w03-test-hashes-after.json`. No test edits. All six newly inherited W03 test files (five unit plus PreparationEditorUITests) also match origin/main exact Git blobs. PreparationFlowUITests is inherited via merge, untouched by this executor.

**13 W10 source files byte-identical to retained stash**, independently read from stash tracked tree or untracked parent: RootView, CardCustomizationView, CardCustomizationController, CardPhotoProcessor, CardStyle, AppSnapshot, SnapshotCodec, LocalSnapshotStore, PassFace, FontCatalog, ProfileView, TimeSelectionView, AppModel+Profile. File SHA256 and stash provenance are in `w03-source-preservation-evidence.json`. In particular Root notice/actual VO binding/Profile callback, native gesture fix, v3 persistence, processor, controller and card artwork policy did not change. Existing direct runtime evidence remains tied to unchanged implementation/font bytes; this is preservation evidence, not a new full runtime run.

No refactor beyond maintenance integration. Merge/stash did not delete W10 source or drop existing stashes. No remote push, cleanup of other worktrees/caches, new test adaptation or new dependency.

## Warnings and remaining uncertainty

- Current compile repeats known JourneyStartModelTests128 unused choose result and SDK metadata-skipped notices; immutable prior baseline report already documents the unused choose warning.
- Newly inherited AudioResourceTests23 emits an actual AVAudioSession warning about main-thread activation responsiveness; test passes. It is an upstream runtime warning, not a W10 compiler regression or source fix made here. Native debugger noURL notices also remain. No warning-free claim.
- Parent's interrupted pre-W03 whole execution had unit472 and initialW10 UI positives but exit130 due required new-main integration; it is not final PASS or product FAIL. Parent archives those logs separately.
- Combined full regression on this merge/source is **still required**. This executor ran the specified focused gate only. No final entire-app design/runtime PASS claimed.

Slot RELEASED immediately after545PASS; no running build/test remains owned by this executor.
