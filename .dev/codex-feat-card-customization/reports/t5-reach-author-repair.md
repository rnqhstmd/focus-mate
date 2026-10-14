# T5 actual-button reach repair

Status: **DONE / FOCUSED 2 TESTS PASS / BUILD-TEST SLOT RELEASED**

Only `ios/FocusMateUITests/CardCustomizationFlowTests.swift` was edited for this repair. No production source was opened or edited. The parent granted exclusive build/test use of device `88EC0B32-40D7-4592-A34F-E09C051CECFA` and `.build/ios`. Disk check reported 62GiB free. No other simulator/worktree was inspected or modified.

## Cause and exact behavior change

The authorized diagnostic report records 30 Y taps and zero Y callbacks, while the actual child button frame `(334,845,44,44)` extends past the 874pt screen and below the save footer. The old helper reached the container and accepted `isHittable`, allowing synthesized child taps without full visibility.

```diff
@@ step
 let container = control(h, axis)
-try reach(container, h)
 ... // existing exact action/label mapping remains
 let button = container.buttons[helperID(axis + "." + action)]
+try reach(button, h)
```

`reach` now requires `isHittable` AND full target-frame containment in the visible body rectangle: `body.frame ∩ app.frame`, clipped above the explicit `above` element or fixed save footer. The lower bound is the actual visible body top; both scroll direction and final assertion use these bounds. This rejects the previously observed partially offscreen child.

The save button uses full app containment. Known fixed close/undo/DEBUG fixture/release controls use full app containment above the save footer, so body-top constraints do not falsely exclude fixed header controls. Their IDs, labels and actions are unchanged. All other content controls require full body visibility. Scrolling uses only the existing physical `scrollBody` gesture; no setters, new controls or source accommodation were introduced.

All 12 test methods and product assertions remain unchanged, including test05's exact saved Y=2 and return Y=0.5 checks. Previously authorized test04 width outcome assertions and test05 observation attachments remain intact. Generic strict-ID queries and scoped native-alert helpers remain intact.

## Initial run and executable provenance correction

`t5-reach-author-ui.log`: initial `test` invocation compiled the correct ROOT test file for both arm64 and x86_64, yet runtime test04 reported the superseded line107 midpoint assertion. Its execution cannot validate the new source. The owned xcodebuild PID14031 was interrupted; exit75. Results/logs were preserved.

An explicit sequential `build-for-testing` then succeeded (exit0), log `t5-reach-author-build.log`. Before reinstall:

- Newly built test binary SHA256 `3d3744d4762f7f5104bb43b4eb65ea59100542dd06dae09aba560b3cee529048`, modified 2026-10-14 22:09:25 local.
- Installed prior runner test binary SHA256 `ac800d21bb7fae686e960e17528dc7712afbd2716b9a3042d183262ea52970d4`, modified 22:07:17 local.
- Both binaries contain the observer marker; marker existence alone does not establish which width oracle executes. The precise cause of the first source/runtime discrepancy is not proven.

Only the owned `app.focusmate.prototype.uitests.xctrunner` bundle was uninstalled. The actual app and its data/fixtures were preserved. A sequential focused `test-without-building` invocation then reinstalled the runner. The installed binary SHA256 was directly checked and equals the new built SHA `3d3744...9048`. Runtime advanced beyond test04's width assertions to its layer actions, corroborating that the old midpoint failure is gone in this execution.

## Focused command

```sh
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=88EC0B32-40D7-4592-A34F-E09C051CECFA' \
  -derivedDataPath .build/ios -parallel-testing-enabled NO \
  test-without-building CODE_SIGNING_ALLOWED=NO -collect-test-diagnostics never \
  '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test04_실제_두사진을_순서대로_추가해_선택사진만_편집한다' \
  '-only-testing:FocusMateUITests/CardCustomizationFlowTests/test05_카드밖_사진은_색과_저장탭을_가로채지_않고_목록에서_복귀한다'
```

Final log: DEV `t5-reach-author-ui-r2.log`. Exit **0**, `TEST EXECUTE SUCCEEDED`, **2 tests / 0 failures / 0 unexpected**, 370.773 seconds. test04 passed in 54.822 seconds; test05 passed in 315.951 seconds. The test05 exact saved Y=2 and final Y=0.5 assertions both executed successfully. Its 30 positive and 30 negative Y actions were retained; no action count or expected value changed.

Result: `.build/ios/Logs/Test/Test-FocusMate-2026.10.14_22-09-54-+0900.xcresult`.

Static final check: exactly 12 test methods. Owned test source SHA256: `61798b5d49842296d38d63fcd0d9055e83f5e28cb64601d6dd7866341e1840db`.

The exclusive build/test slot is **released**. No process is left running by this author. All logs/results were preserved. No other worktree, simulator, source or app data was modified. Parent should regenerate the locked 19-file test hashes before the next executor run. This focused run does not establish the remaining ten UI cases or a full cumulative suite.
