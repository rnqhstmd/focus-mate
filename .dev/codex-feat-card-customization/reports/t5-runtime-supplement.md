# T5 실제 런타임 보강 — 순차 실행 재개 체크포인트

상태: **READY TO RESUME / 실제 W10 런타임 검증 미실행**. 2026-10-14 사용자 디스크 규칙에 따라 부모의 명시적 실행 슬롯 해제를 기다린다. 이 체크포인트 작성에서는 빌드·테스트·기기 상태 변경을 하지 않았다.

## 중단 상태와 증거 경계

- 대상은 소유 iOS 27 기기 `F226C28A-81D5-4708-B939-81B605AC748E` 한 대다. 부모가 shutdown을 실행했다고 전달했다. 여기서는 재부팅·삭제·erase하지 않았다.
- 읽기 전용 `ps` 확인 결과 photos-probe/W10Runtime xcodebuild 프로세스는 없다. 현재 소유 실행 PID 없음.
- `df -h /System/Volumes/Data`: 가용 **66GiB**, 68% 사용. 이전 실행 당시 가용 106~531MiB 사이에서 변동했고 설치 단계에서 ENOSPC가 발생했다.
- `runtime01`: 최초 probe 파일 생성 명령의 상대 경로 오류가 있었다. 이후 파일을 올바른 독립 경로에 작성했다. 이 실행은 중단되었고 결과 기록 마무리 오류까지 남았다. XCTest case 시작 0, 실제 트리 0, Motion marker 0. 과거 PID `56851`, exit 73. 이 시도를 제품 실패나 검증 PASS로 해석하지 않는다.
- `runtime02`: 수정된 독립 probe를 컴파일했으나 runner 설치 단계에서 실패했다. 로그 322행 `Simulator device failed to install the application`, 361/364행 `No space left on device`; 382행 `TEST FAILED`. XCTest case 시작 0, 실제 트리 0, Motion marker 0. 과거 PID `17968`, exit 73.
- `runtime03`: 중간 파일 정리와 test-without-building 호출을 포함한 도구 요청이 사용자에 의해 중단되었다. 현재 `runtime03.log`/`runtime03.xcresult` 모두 없으며, 정리 대상 Index/ModuleCache/SDKExplicitPrecompiledModules/Intermediates도 남아 있다. 새 실행이 이루어졌다는 증거가 없다.
- 따라서 현재 W10의 PhotosPicker 선택/취소/재선택, 저장, 원본 삭제 후 보존, VoiceOver, `test.reduceMotion=true`는 **모두 미검증**이다. 앞서 독립 Settings/Photos 앱에서 얻은 증거와 구분한다.

## 보존한 독립 복사본

ROOT: `/Users/bonseung/.codex/worktrees/w10-card-customization/new`

전용 프로젝트: `ROOT/.build/photos-probe/project`

- 현재 ROOT의 `ios/FocusMate` 전체(폰트·asset·새 모델 포함)와 xcodeproj를 복사했다. 현재 ROOT production/tests는 변경하지 않았다.
- production 파일 36개의 해시 목록: `ROOT/.build/photos-probe/clone-source-hashes.json`.
- 목록의 정렬 JSON SHA-256: `b0595c042a4a2fb1ec6556ee51f0343ddb424b5b6859df2d7b965eb0add49d37`.
- 이 복사본 이후 부모의 UI 레이아웃 수정이 있을 수 있으므로 최종판 검증 전에 차이를 확인한다. 새 복사본/빌드가 필요하면 기존 검증 결과와 별도 해시로 기록한다.
- 독립 UI target은 기존 `UITestLaunchSupport.swift`와 `W10RuntimeProbeTests.swift`만 포함한다. unit target에는 빈 `ProbeBuildTests` scaffold가 있다. 현재 프로젝트의 전체 UI12는 복사하지 않았다.
- probe 소스 SHA-256: `15ac644e0bc5b43bf0eb0a0f74eab9bcc0a5d958bf4d8968d3444d5b182fb19a`.
- 현재 probe case는 `test01ObserveActualPicker` 하나다. seed `ready`, UUID `018BD717-0327-4893-A981-E3EE9C181010`; 실제 환경 `test.reduceMotion` assertion 후 편집기와 실제 picker 트리/스크린샷을 수집하도록 작성했다. 아직 case 시작이 없으므로 이 UUID를 seed한 증거도 없다. 재시도 전에 실행 여부를 다시 확인한다.

## 실행파일 및 로그

아래는 모두 존재를 직접 확인했다. 앱 실행 시 debug dylib와 resource가 필요하므로 단일 Mach-O만 분리하지 않고 전체 `.app`을 보존한다.

```text
ROOT/.build/photos-probe/derived/Build/Products/Debug-iphonesimulator/FocusMate.app/FocusMate
ROOT/.build/photos-probe/derived/Build/Products/Debug-iphonesimulator/FocusMateUITests-Runner.app/FocusMateUITests-Runner
ROOT/.build/photos-probe/derived/Build/Products/Debug-iphonesimulator/FocusMateUITests-Runner.app/PlugIns/FocusMateUITests.xctest/FocusMateUITests
ROOT/.build/photos-probe/runtime01.log
ROOT/.build/photos-probe/runtime01.xcresult
ROOT/.build/photos-probe/runtime02.log
ROOT/.build/photos-probe/runtime02.xcresult
```

`runtime02.log`에 `W10RuntimeProbeTests.swift` 컴파일 기록이 있다. Products 아래 `.xctestrun` 파일은 없다. 아래 scheme 기반 test-without-building 명령은 **재개 후보이며 아직 실행 성공을 검증하지 않았다**. Xcode가 기존 build record를 복원하지 못하면, 슬롯 해제 후 동일 독립 프로젝트를 한 번 `build-for-testing`하여 xctestrun을 생성하고 그 경로로 실행한다. 병렬 빌드·테스트는 금지한다.

```sh
cd /Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/project
xcodebuild -project ios/FocusMate.xcodeproj -scheme FocusMate \
  -destination 'platform=iOS Simulator,id=F226C28A-81D5-4708-B939-81B605AC748E' \
  -derivedDataPath /Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/derived \
  -resultBundlePath /Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/runtime03.xcresult \
  -parallel-testing-enabled NO -collect-test-diagnostics never \
  '-only-testing:FocusMateUITests/W10RuntimeProbeTests/test01ObserveActualPicker' \
  test-without-building CODE_SIGNING_ALLOWED=NO \
  > /Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/runtime03.log 2>&1
```

## 보존된 Photos/Settings 상태

- 앞선 `photos-library-preparation.md`: 기존 사진 6개를 보존하고 소유 PNG 두 개를 추가했으며, 실제 Photos AX와 화면에서 8개를 확인했다. 이번 실행에서는 사진을 선택하거나 삭제하지 않았다.
- 소유 원본은 `W10-Owned-A-79A4547A-E6AA-4D10-9AE6-978F5A3A4E38.png`(120×80 RGB 빨강 체크), `W10-Owned-B-79A4547A-E6AA-4D10-9AE6-978F5A3A4E38.png`(80×120 RGBA 파랑/alpha 체크).
- Photos에서 마지막으로 관찰한 두 자산 label은 모두 `사진, 10월 14일, 오전 11:52`; 8개 그리드에서 index 6/7, 세 번째 행 첫째/둘째 열이었다. **PhotosPicker나 재정렬 이후 순서를 일반화하지 않는다.** 기존 6개는 소유 자산이 아니며 삭제 대상에서 제외한다.
- 앞선 `reduce-motion-setting.md`: 실제 Settings `REDUCE_MOTION` 내부 Switch로 0→1, Settings 재실행 후에도 1을 직접 확인했다. 현재 W10 환경 diagnostic 값은 아직 읽지 못했다. 강제 환경 플래그나 guessed preference key는 사용하지 않았다.

## 순차 재개 시 남은 단계

1. 부모의 명시적 슬롯 해제 후 가용 용량과 복사본 해시/최종 UI 차이를 확인한다. 대상 27 기기만 사용한다.
2. 위 첫 case로 실제 `test.reduceMotion=true`, editor AX, 시스템 PhotosPicker AX/스크린샷을 관찰한다. 확인한 실제 selector로만 후속 probe를 작성한다.
3. 실제 picker에서 소유 A/B를 선택한다. draft의 치수/순서/ID/sha256을 기록한다. 두 사진이 있고 undo가 없는 상태를 구성한 뒤 picker 취소 전후 draft/selected/history/file 불변을 비교한다. 동일 자산 재선택이 실제로 다시 동작하는지도 별도 기록한다.
4. 선택 사진의 X/Y 대체 버튼과 크기 slider를 조작하고 변화 전후 JSON을 보존한다. 저장 후 같은 UUID로 재실행하여 photo ID/data hash/placement를 비교한다.
5. 성공 저장 후에만 실제 Photos를 열어 소유 두 자산의 색상·날짜·위치를 다시 식별한다. 가능하면 실제 정보 화면의 고유 파일명을 확인한다. ownership이 애매하면 삭제하지 않는다. 실제 선택/삭제 버튼과 확인 dialog를 먼저 관찰한 뒤 그 두 개만 삭제하고 실제 8→6을 확인한다. fixture 파일 삭제로 대체하지 않는다. 같은 UUID로 앱을 다시 열어 저장된 사진 ID/hash/순서/배치가 그대로인지 비교한다.
6. `XCUIDevice.shared.voiceOverService`의 실제 `enable/currentSpeech/moveForward/moveBackward` 결과로 이름·선택·현재 값·버튼·비활성 상태를 기록한다. 실제 X/Y 대체 조작과 slider 접근성 조작을 확인한다. import/save 후에는 탐색으로 focus를 만들어내지 않고 `currentSpeech`를 관찰하여 자동 focus/발화를 구분한다. 테스트 종료 시 VoiceOver를 해제한다.
7. DEBUG manifest/manual hold는 import lock 및 안내 focus를 오래 관찰하는 보조 실행에만 사용할 수 있다. 실제 PhotosPicker 성공 증거와 분리한다. 현재 복사본의 `UITestFeedbackRecorder.announce`는 기록 후 `system.announce`도 호출하지만, diagnostic announcements 배열만으로 actual speech/focus PASS를 주장하지 않는다.
8. 최종 보고에서는 실제 통과 case/관찰 실패/관찰 불가를 구분하고 clone hash, raw log, xcresult, 트리, 화면을 연결한다. 현재 단계에는 제품 동작 PASS가 없다.

현재 ROOT production/tests/Git, 다른 시뮬레이터, 사용자 자료는 변경하지 않았다. 기존 로그·xcresult·Photos 두 소유 자산 및 기존 6개는 보존한다.


## 최종 27 검증 준비 — 실행 슬롯 대기

최신 상태는 **PREPARED / COMPILE 및 RUNTIME 미검증**이다. 아래 내용은 위 초기 한-case 체크포인트를 대체하는 준비 내역이다. 기존 production clone/실행파일은 갱신하지 않았고, 기기를 boot하거나 build/test하지 않았다. 수정한 것은 ignored 독립 `project/ios/FocusMateUITests/W10RuntimeProbeTests.swift`와 이 보고서뿐이다.

- probe 소스 SHA-256: `2592e760d7e1db579345de977dedc0f77bc36558337c74558c17d15219510b23` (395행).
- 독립 native case 7개를 준비했다. 동작 실행은 부모가 최종 production freeze와 단독 build/test 슬롯을 명시 해제한 후에만 한다.
- 이전 실행파일은 이전 한-case 버전이므로 **현재 suite에 test-without-building을 곧바로 적용하면 안 된다**. 최종 production 전체(폰트/resources 포함)를 snapshot copy하고 새 해시 목록을 보존한 뒤 독립 probe를 한 번 build-for-testing해야 한다. 부모가 보고한 clone 2개 drift 파일만 임의 복사하는 대신 전체 snapshot 일관성을 확인한다.
- 시험 대상은 F226 27 한 대, 다른 기기/ROOT production/tests/Git 변경 금지. fixture stage는 그 시점의 실제 app container에만 하고 실제 보관함 추가 import를 반복하지 않는다.

### 순차 실행 순서

| 단계 | 독립 case | 진행 조건과 관찰 |
|---|---|---|
| A | `test01ObserveActualPicker` | fresh UUID를 출력. 실제 `test.reduceMotion=true`, 편집기/실제 picker/SpringBoard AX·화면. 아직 asset selector를 추정하지 않음 |
| B | `test02ActualPickerCancelReselectDragResizeSave` | A의 실제 picker asset A/B·완료·취소 mapping을 `observedPicker`에 기록한 뒤 실행. 두 사진 선택→저장/재실행→undo 없는 두 사진 상태에서 취소 불변→동일 A 재선택으로 새 ID+동일 hash→undo→선택 A 실제 drag/resize→R40→저장/같은 UUID 재실행 |
| C | `test03ActualVoiceOverImportLockNoticeXYAndSaveFocus` | 현재27 container에 mixed/valid2/hold 실제 manifest를 stage한 뒤 boolean gate를 켬. manual import lock의 native availability, 실제 VO 탐색/선택/값 발화, import 안내 자동 currentSpeech, 실제 XY double-tap 값, 실패/성공 저장 후 자동 currentSpeech. 별도 UUID라 B 저장 baseline 보존 |
| D | `test04ActualVoiceOverAdjustableSlider` | C trace에서 정적 `사진 크기`와 구별되는 실제 adjustable slider 전문을 `observedAdjustableSliderSpeech`에 채움. 해당 actual focus에서 swipeUp, 실제 width 증가·상한·다른 축 불변 및 실제 speech 기록. 정밀 slider step 크기를 추정하지 않음 |
| E | `test05ObservePhotosOwnershipBeforeDeletion` | 실제 Photos의 최신 8개 AX/화면만 수집. 선택/삭제 없음. 최초6+고유 A/B 색/날짜/가능하면 Info 파일명을 다시 확인 |
| F | `test05bObserveOwnedSelectionAndDeleteDialogWithoutConfirming` | B 저장 성공과 E 소유권 검토 후 `reviewedOwnership`을 채움. 전체8 label/order가 당시 증거와 같을 때만 소유2 선택→실제 선택수 witness 및 삭제 확인 dialog를 캡처. **확인 버튼을 누르지 않음**. Photos terminate만 수행. 다음 실행에 dialog가 남으면 관찰된 취소로 해제한 뒤 재관찰해야 하며 자동 추정하지 않음 |
| G | `test06DeleteOnlyObservedOwnedAssetsAndVerifySavedBytes` | B의 UUID/cardID/saved Style, E/F의 최신8 label·owned index·정확히2선택 witness·실제 확인 selector를 `observedDeletion`에 기록. 저장 baseline 먼저 확인→소유2만 실제 확인 삭제→6개 및 기존6 label순서 보존→B의 같은 UUID relaunch 후 photo ID/hash/order/placement 전체 및 persistedBytes 동일 비교 |

단계별 `-only-testing:FocusMateUITests/W10RuntimeProbeTests/<위 메서드>`를 하나씩 지정한다. selector/config 수정 시 독립 test bundle 재빌드는 필요하지만 현재 project source를 변경하지 않는다. 각 실행은 이전과 다른 결과 경로(예: `runtime-final-A.xcresult`)를 쓰고 이미 있는 raw 결과를 덮어쓰지 않는다. 병렬 실행하지 않는다.

`observedPicker`, `reviewedOwnership`, `observedDeletion`, `observedAdjustableSliderSpeech`는 현재 모두 nil이고 fixture stage gate도 false다. 미관찰 계약이 필요한 case는 XCTSkip으로 중단한다. **SKIP은 해당 coverage 미검증이며 PASS 통계로 완료 처리하지 않는다.** `ObservedElement`는 element type/identifier/exact label/매칭 count/index를 모두 검사한다. selector 일치만으로 이미지 소유권을 증명하지 않으므로 reviewed screenshot/Info provenance가 별도로 필요하다. 고유 원본명을 AX가 실제 노출한다고 가정하지 않는다.

### R40 필수 화면과 oracle

B에서 두 실제 PhotosPicker 입력을 유지한 채 landscape A를 선택해 실제 drag/resize하고 sand를 선택한다. snapshot geometry로 두 사진 overlap, 한 사진 card-edge clipping, 선택 A의 32×32 handle이 preview 내부에 완전히 들어옴을 확인한 후 `t5-final-r40-overlap-handle.png`와 raw `t5-final-r40-overlap-handle.json` 이름의 XCTAttachment를 남긴다. 최종 export 시 정확히 같은 이름으로 DEV에 보관한다. geometry assertion은 사전 조건이며 export한 실제 pixels를 열어 overlap/clip/handle/sand 선택과 최종 레이아웃을 육안 확인해야 한다. 기존 selected portrait 60% 화면을 이 근거로 대체하지 않는다.

### 증거와 제한

- 취소는 State 전체와 persistedBytes를 비교한다. 재선택은 기존 두 사진 불변 + 신규 ID + A의 기존 hash와 동일을 검사한다. 사진 처리기로 기대 hash를 새로 계산하지 않는다.
- drag/resize는 실제 coordinate press/drag gesture이며 JSON 설정을 우회하지 않는다. native touch 이동량과 preview 크기에서 기대 placement를 계산하고 선택되지 않은 사진 전체가 불변인지 검사한다.
- `reach`는 실제 대상의 frame을 app/body/footer 위 영역에 포함시키고 hittable을 확인한다. 스크롤 결과를 가정하지 않고 미도달 시 geometry와 화면을 남겨 실패한다. 별도 probe helper이며 기존 test05 oracle을 바꾸지 않았다.
- 실제 VO API는 설치 SDK `XCUIVoiceOverService.h`의 enable/disable/currentSpeech/moveForward 계약과 기존 실행된 legacy helper를 사용한다. currentSpeech는 SDK상 현재 focus element의 speech다. diagnostic announcement 배열로 대체하지 않는다. 안내 자동 focus는 moveForward 없이 bounded currentSpeech만 관찰한다.
- C의 names/selected/disabled/value trace는 실제 출력 수집이다. 버튼 availability의 native assertion과 별개로, 각 역할/선택/비활성 표현이 실제 발화되는지는 raw trace를 직접 검토해 표로 판정해야 한다. scan 전체가 통과했다는 이유만으로 모든 항목을 PASS로 간주하지 않는다.
- fixture 기반 C/D는 lock/안내/VO를 장시간 관찰하기 위한 보조 범위이며 B의 실제 PhotosPicker 증거와 분리한다.
- 현재 source는 정적 독해만 했으며 compile/native 동작은 아직 확인하지 않았다. 첫 build에서 발견되는 probe 컴파일 문제는 독립 probe 안에서만 고친 뒤 실행한다. 제품 FAIL과 probe/환경 FAIL을 구분한다.
- Photos 삭제 계약은 nil이므로 현재 준비 상태에서 삭제 경로에 진입할 수 없다. 원본 삭제 이후 B를 다시 실행하려면 새로운 소유 자산 추가가 필요하므로 B/C/D/R40/선택 증거를 먼저 완료하고 G를 마지막에 둔다. Recently Deleted 영구 삭제는 범위 밖이다.


## Production freeze 반영 및 정적 점검 — 2026-10-14 22:18 이후

상태: **CLONE READY / COMPILE PENDING / RUNTIME PENDING**. 부모 cumulative259가 실행 중이므로 빌드·테스트·install·boot는 하지 않았다. 시작 시 Data volume 가용 62GiB를 확인했다.

- ROOT `ios/FocusMate`의 전체 36개 파일(폰트/resources 포함)을 독립 clone에 복사했다. source manifest를 복사 전/후 두 번 산출하고 clone과 비교하여 **36/36 경로 및 SHA-256 동일**을 확인했다. 기존 clone과 달랐던 파일은 `CardCustomizationView.swift`, `CardIssuanceController.swift` 두 개였다.
- 현재 manifest aggregate SHA-256: `f3d2047d2a8d93b9175fe02d4cad3c13139dcb4d665ebb1dcfa080139b60f654`.
- 전체 ROOT 전후/clone 파일별 SHA 목록: `ROOT/.build/photos-probe/final-root-production-manifest-20261014.json` (capturedAt `2026-10-14T22:18:48.991375+09:00`). 이전 clone hash 파일은 이력으로 남겨두었다.
- xcodeproj/project.pbxproj와 공유 scheme은 ROOT/clone 바이트가 이미 같아 수정하지 않았다. 독립 unit scaffold와 UITestLaunchSupport도 그대로 보존했다. ROOT unit/UI test 파일 49개를 복사 전후 및 최종 점검에서 비교해 모두 변경 없음을 확인했다. ROOT 잠금 test19도 이 범위에 포함되며 수정하지 않았다.
- 최종 정적 점검 기록: `ROOT/.build/photos-probe/final-probe-static-review-20261014.json`.
- 독립 probe는 7 case/409행, SHA-256 `f9e0df4b9da467b1a11afa3a8e812752765c68599e33976bad08d384293962ff`다. 복사 후 정적 개선으로 probe 파일만 바꿨으므로 production 복사 manifest의 `preservedProbeAndUnitFiles`는 복사 시점의 이전 probe hash이고 이 값이 최신 probe hash다.

정적 점검에서 두 가지를 보완했다. 실제 drag는 겹침의 최상위 사진을 hit-test하므로 선택 A를 실제 `앞으로` 버튼으로 위에 놓은 다음 drag/resize한다. 선택만 했다는 이유로 아래 레이어 A가 드래그될 것이라고 가정하지 않는다. VoiceOver target 탐색은 forward 이후 backward도 관찰하며 동일 발화 3회 또는 방향당60회로 제한해 끝 지점 정체를 피한다. native selector resolver에는 MainActor를 명시했다.

XCTest API는 설치 primary header의 currentSpeech/moveForward/moveBackward/enable/disable, XCUICoordinate screenPoint/coordinateWithOffset/press-drag와 기존 실행된 legacy helper를 대조했다. State Codable 구조는 현재 compact cardStyleJSON key, placement/사진 정책 및 실제 UI ID와 정적으로 맞춰 보았다. **Swift type-check/actor 검사와 실제 native selector·제스처·VO 성공은 컴파일/실행 없이는 확정할 수 없으므로 PENDING**이다.

미관찰 picker/삭제/slider speech 계약은 계속 nil이며 fixture-stage gate도 false다. 따라서 삭제나 미확정 selector 경로를 준비 상태에서 실행할 수 없다. 이전 executable은 현재 production/probe와 다르므로 재사용 성공을 주장하지 않는다. 실제 슬롯 해제 시 ROOT가 다시 바뀌지 않았는지 production equality를 재확인하고 필요한 snapshot을 만든 뒤 독립 build-for-testing 1개만 시작한다.


## 실제27 첫 실행 완료·슬롯 반환 — 2026-10-14 22:32

상태: **첫 관찰 실행 PASS / 실제 picker 자산·이후 전체 흐름은 미검증 / SLOT RELEASED**. 부모가 XXXL 시각 결함 수정으로 freeze를 철회하여 첫 inventory만 마치고 멈췄다. 후속 시험·사진 선택·삭제·VO는 실행하지 않았다.

- 실행 전 ROOT/clone production 36개 SHA가 freeze manifest와 같은지 재확인했다. 지정 소유26.5 `88EC0B32-40D7-4592-A34F-E09C051CECFA`만 shutdown한 뒤 소유27 `F226C28A-81D5-4708-B939-81B605AC748E`만 boot했다. 알 수 없는 다른 기기는 건드리지 않았다.
- `final-build01.log` 422행 `TEST BUILD SUCCEEDED`, exit0. 이 빌드에는 준비한 7개 native case 전체가 포함되어 Swift 컴파일을 통과했다. 실제로 실행한 것은 `test01ObserveActualPicker` 한 건뿐이다.
- 독립 실행 helper `ROOT/.build/photos-probe/run_native_probe.py`는 해당27의 `app.focusmate.prototype.uitests.xctrunner`만 uninstall하고 빌드한 앱과 runner를 설치했다. 주 앱 데이터는 uninstall하지 않았다. xctestrun으로 test-without-building을 실행했다.
- `runtime-final-A01.log`/`.xcresult`: **1 test, 0 failures, 13.885초, exit0**. 초기 seeded UUID는 `A1FE20D6-EF55-476C-B19E-390F75EB1EEB`.
- `runtime-final-A01-installed-hashes.json`: 실행 전후 모두 built/installed **4개 실행파일·debug dylib + 1개 dSYM** SHA 일치. 실제 UI test bundle executable SHA `67a785bfb72bba6bd6b976cf7c32242af4675c5fac72bfa6a4e5c268a7190b71`, production debug dylib `4a172442b3feca64bee3b0fa260cb824454db6f6e6529191d73ece4f5c8ea0aa`.
- 실제 `test.reduceMotion` native value **true**: 로그116/218행과 test assertion. 앱 환경을 강제하는 인자를 사용하지 않았다.
- 실제 picker는 표시되었지만 첫 캡처는 tap 직후 약0.5초의 로딩 화면이다. 트리에 `NavigationBar PUPickerUnavailableView`, Button label **Cancel**, ActivityIndicator **In progress** value1, StaticText **Loading…**를 관찰했다. 실제 스크린샷도 spinner/Loading을 확인했다. 해당 ID를 영구 unavailable 오류로 해석하지 않는다.
- 사진 A/B, 완료 버튼, picker 준비 완료 상태는 관찰하지 못했다. 따라서 A01의 XCTest PASS는 관찰 코드/Motion assertion 성공이며 실제 사진 가져오기 PASS가 아니다. `observedPicker`는 여전히 nil이다.
- raw export: `ROOT/.build/photos-probe/runtime-final-A01-attachments/`; picker screenshot `5FF7A7CC-42C4-4D75-A3C1-0FCDA0FDEEE4.png`, tree `CB06CB57-FC3B-4FE7-BF71-30E4750D0223.txt`, before-picker state `BB4BDB45-54C0-49B9-854B-D7AD054B9572.txt`. 원본 로그/xcresult/해시 JSON 모두 보존했다.
- 테스트 종료 후 소유27을 shutdown(exit0)하고 부모에게 슬롯 RELEASE를 알렸다. Photos 자산은 선택/삭제하지 않았고 저장 fixture를 내보내거나 지우지도 않았다. 기존6+소유2 상태를 변경하는 행위가 없었으나 이번 실행에서 Photos count를 다시 읽은 것은 아니다.

다음 관찰용 probe에 실제 관찰된 `Loading…`의 `waitForNonExistence(timeout:25)`와 종료 후 트리/화면 기록을 추가했다. 아직 이 변경을 compile/run하지 않았다. 최신 probe SHA-256은 `e97f1582404b4923c82dc09fe02b65b40cb3704ca8e5f3a9a9bfd96ad91e7c67`. 기존 build는 위 로딩 대기 전 probe이며 재개 시 rebuild가 필요하다. 부모의 final source 재확정 후 production 전체를 다시 sync/hash 검증하고, 단독 슬롯에서 A inventory부터 재개한다. B~G, R40, 실제 VO 및 원본 삭제 후 보존은 모두 남아 있다.


## F1 수정 후 실제27 재개 — 2026-10-14 22:48

- 현재 production은 F1 PassFace SHA `011fd7664a63257ed4b5f8d8c7b84121cd615b969ad5cf49092864ae7632db8c`, 전체36개 ROOT/clone 동일. `final-root-production-manifest-F1.json`에 기록했다.
- A02 실제 picker inventory 1/1 PASS. 관찰된 Loading을 최대25초 기다린 후 8개 실제 자산 확인. 첫 blue B, 둘째 red A이며 모두 `사진, 10월 14일, 오전 11:52` label이고 그 label에 맞는 항목은 정확히2개다. 나머지6개는 기존 자연사진이다. 실제 `test.reduceMotion=true`.
- B01은 실패 실행이다. 실패 이전 실제 picker A→B 선택·2개 import·저장·동일UUID 재실행·취소 후 전체state/저장bytes 불변·동일A 재선택 새ID/동일imagehash assertion을 통과했다. 이후 독립 helper가 고정상단 undo를 본문 viewport 안으로 스크롤하려 해 실패했다. 실제 undo frame은 `(358,80.333,16,15.667)`, isHittable=true. 이 결과로 제품 drag/resize 성공이나 실패를 주장하지 않는다.
- ignored probe reach에 고정header close/undo 예외를 추가했다. ROOT source/tests 변경 없음. final-build05 컴파일exit0 후 B02 엄격한 drag/resize 포함 재실행 중.
- 현재27 컨테이너의 a/b/unreadable/mixed/valid2/hold 6개 파일은 소유fixture 원본과 바이트일치 확인; VO/error complementary 경로를 준비했다. 실제 PhotosPicker 검증과 별개이다.
- 모든 실행은 독립 helper로 해당 owned runner만 제거·재설치하며 built/installed binary SHA를 전후 확인한다. A02/B01 각각 `*-installed-hashes.json` 5개 일치. Photos 라이브러리 삭제는 아직 수행하지 않았다.


## B02 / C01 / E01 / G01 관찰 — 2026-10-14 22:58

- B02 **FAIL**: actual PhotosPicker A→B import/order, save/relaunch, cancel state/bytes invariants, A reselect newID/samehash, undo, layer forward, actual drag and resize numeric assertions passed. Subsequently R40 selected-photo assertion failed because `selectedPhotoID=null`. This is not dismissed as harness failure: parent received raw evidence and is preparing an independent production UI regression before any fix. UUID `08160490-9829-4727-B770-0303716B9CE8`. Initial2 saved photos remain; modified geometry was still draft at failure.
- B02 A `37B6996A-A558-4423-95AD-34AD061A7B4C`: centerX .56779661016949157, centerY .55244759896318085, widthFraction .65649717514124295. B `80581223-2751-4F87-900E-879334111A33` remained .5/.5/.6. OutputA hash `7ed7ccd9b1025a9a3d46ce07c36a98a50fbe48498bb1a386e62be5fc866bf106`; B `c88c7f316a868283868d57ecc6a754dc9c7be88c80151163998e433887f8f0ae`.
- B02 actual screenshot `runtime-final-B02-attachments/BA10E428-90D6-4D7B-BE9A-D8DD5BCF2A75.png`: visually reviewed overlapping red/blue photos, portrait clips to rounded card; selection outline/handle absent. Rawstate `EB66716E-29D9-48BB-BE7D-18BC67D05D6E.txt`; fullvideo `1CBA1CA0-E509-4D24-BD67-CAD42FD16154.mp4`. R40 final screenshot **not completed**.
- C01 **FAIL** at automatic import-notice focus. Actual VoiceOver service enabled; held import save/picker disabled, close enabled assertions pass. Actual VO utterance `이 카드로 저장하기 흐리게 표시됨 버튼` confirms disabled speech. After manual release, partial error notice exists but currentSpeech remained `테스트 사진 불러오기 버튼` for8seconds. DEBUG release-button replacement may affect focus, so product-only causal conclusion remains open. Save focus/XY/slider in this case were not reached.
- E01 **PASS inventory only**, 8 Photos still present, no selection/deletion. Fresh screenshot `runtime-final-E01-attachments/91534BFB-DC13-43FD-B03D-3659146D5C9D.png` personally reviewed: original6 nature photos then owned redA/blueB at indices6/7. Tree `E529C6BB-3DBD-46E9-AA62-44084E1ECF53.txt` records exact8labels. Metadata/Info UI still not reviewed; deletion not enabled.
- G01 **PASS inventory code only**, actual native custom ColorPicker sheet did not open from center tap of `cardCustomization.color.custom`; captured AX is editor. CustomRGB remains unverified, do not count test PASS as product success. Need tap actual observed swatch after screen inspection or VO activation and observe native controls first.
- C02 no-manual mixed fixture + fail-once save focused observation currently running. It records all three automatic currentSpeech outcomes before asserting. This will distinguish DEBUG manual-button replacement from other focus behavior; native PhotosPicker import-focus remains a separate boundary.
- Root source/tests unchanged. All logs/xcresults and before/after installed5hashes retained under `.build/photos-probe`. Photos original6+owned2 preserved.


## 실행 슬롯 반환 및 C02 확정 — 2026-10-14 22:59

**SLOT RELEASED / owned27 BOOTED 유지(부모 요청) / 실행 중 build/test 없음.** 부모가 selection retention 실제 UI13 RED 검증을 이어받는다. VO는 tearDown에서 disable했다. Photos8개를 그대로 보존했으며 삭제는0건이다. ROOT source/독립clone production36개 SHA를 다시 비교해 전부 동일했다.

C02 `test03bObserveNoManualImportAndSaveAutomaticFocus`: **1 test/0 failures, exit0**, installed5hash 전후 일치. seededUUID `4CD274DC-94ED-42A5-9749-A6B6D5406EBB`. manual hold/해제 버튼을 쓰지 않는 mixed fixture import와 fail-once save 경로다. 실제 XCUIVoiceOverService.currentSpeech가 다음 세 문장을 이동 명령 없이 자동으로 반환했고, 마지막 `focusResults`는 `import=true, saveFailure=true, saveSuccess=true`다.

1. `사진 1장을 읽지 못했어요. 사진 추가로 다시 선택해주세요.`
2. `카드 외형을 저장하지 못했어요. 초안은 유지돼요. 저장 버튼으로 다시 시도해주세요.`
3. `카드 외형을 저장했어요.`

C01 실패는 manual DEBUG 해제→입력 버튼 교체와 연결된 시험 환경 차이로 분리한다. C02는 실제 VoiceOver 발화/초점 증거이며 `test.announcements` 진단만을 성공 근거로 삼지 않았다. 단, 이 오류 입력은 실제 PhotosPicker가 아닌 소유fixture complementary 경로다.

실제 탐색 발화에서 `선택됨 기본 검정 버튼`, `선택됨 사진 1 버튼`, `사진 크기 60퍼센트 조절 가능 값을 조절하려면 한 손가락으로 쓸어올리거나 쓸어내리십시오.`, `50% 50퍼센트`, `앞으로 흐리게 표시됨 버튼`, `뒤로 흐리게 표시됨 버튼`을 확인했다. 실제 XY 증감과 slider swipe는 아직 수행하지 않았으므로 별도 PENDING이다.

추가 시각 요구인 **화면 안 오류 안내 캡처 완료**: `DEV/t5-final-save-error-visible-vo.png` (원본 C02 attachments `FC69A37A-5269-416C-AF38-143197065912.png`). 직접 열어 오류 전체문장 두 줄, VoiceOver 초점사각형, 재시도 저장버튼이 한 화면에 보이는 것을 확인했다. 기본크기에서 앞으로/뒤로/삭제 텍스트도 완전히 보인다. XXXL layer clipping 판정으로 일반화하지 않는다.

### 재개 시 남은 작업
- 부모 UI13 선택 유지 회귀 처리 및 최종productionfreeze 후 clone 전체36개 다시동기화/hash 및 rebuild. 현재 B02를 재선택으로 우회해 전체PASS 처리하지 않는다.
- B02 흐름에서 실제 import/order/cancel/reselect/initialsave/relaunch/drag/resize 수치까지 증거 있음. 최종선택 유지/R40 sand+overlap+handle 캡처 및 그geometry 저장 후 relaunch는 미완료.
- 실제 VO 비드래그 XY 증감 및 정확히 관찰된 adjustable 발화에 도달한 후 swipe 조절 확인. 현재 probe test04의 observedAdjustableSliderSpeech에는 위 실제 발화를 입력할 수 있다(아직nil).
- 실제 ColorPicker는 center tap에 sheet가 안 열렸음; 다음은 화면에 관찰된 swatch hit 또는 실제 VO 활성화 후 native tree를 먼저 확인. customRGB/discard/save보존 미완료.
- Photos Info 실제metadata검토 → owned2 정확선택 및 삭제dialog 관찰 → 확인 후8→6, original6labels불변 → 성공 저장UUID 사진ID/hash/placement/bytes 불변. 현재 deletion contract nil이며 삭제0.
- 다음 run은 부모의 명시 슬롯 재부여 이후만 실행한다.


### C02 최종 증거 대조: 발화와 시각초점 경계

- SDK primary: `/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneSimulator.platform/Developer/Library/Frameworks/XCUIAutomation.framework/Headers/XCUIVoiceOverService.h:49–52`는 currentSpeech가 currently focused element의 speech를 반환한다고 정의한다. 따라서 3개 currentSpeech assertion은 실제 SDK 초점발화 관찰이다.
- **하지만 import 지속적 시각초점/자동스크롤은 미확정**이다. log64행 notice speech 이후 약1.5초의 screenshot `04109ED8-224F-4C9B-AE05-E228C816C66C.png`에서는 notice가 viewport 밖이고 초점사각형은 DEBUG입력 위치에 있다. SDK speech 시점과 후속화면을 같은 상태라고 단정하지 않는다. `DEV/t5-import-notice-vo-observation.png`로 보존했다. 이 스크린샷을 import notice 가시성 PASS로 쓰지 않는다.
- 저장 실패는 log270행 실제notice currentSpeech 및 `DEV/t5-final-save-error-visible-vo.png`에서 안내전체/그 위초점사각형/저장버튼을 직접 확인했다.
- 저장 성공은 log417행 실제notice currentSpeech 및 `DEV/t5-final-save-success-vo.png`에서 저장된카드/안내전체/그 위초점사각형을 직접 확인했다.
- log209행 선택됨사진1, 215행60퍼센트 조절가능, 475행세 currentSpeech결과true. raw index `.build/photos-probe/C02-focus-evidence-index.json`은 원본attachment경로/이름/시각을 연결한다.
- C02가 일시적인 import focused speech만 확인한 범위와 저장fail/success 지속visualfocus까지 확인한 범위를 분리한다. 남은 실제picker의 import focus와 입력버튼 없는원래UI 시각초점은 후속관찰 대상이다.

ColorPicker read-only AX검토: G01 tree109행에는 `Button cardCustomization.color.custom`, frame(24,525.7,110,28), label직접고르기, valueverydarkgrayish 하나만 노출된다. 별도 ColorWell/자식button은 현재트리에 없다. center.tap 직후9.99초 캡처만 있어 sheet표시 지연을 충분히배제하지 못했다. 다음관찰은 실제VO로이button에초점을맞춰doubleTap후boundedwait/AXinventory를 먼저하고, 미관찰 nativecontrol명이나좌표를 성공근거로하지않는다.


## W11 통합 후 runtime 재개 준비/실행

부모 integration GREEN 종료와 단독슬롯 명시승인 후 ROOT production/resources39개를 독립clone에 전체동기화했다. ROOT/clone 전경로SHA동일, project/scheme바이트동일. `final-root-production-manifest-W11.json`이 기준이다. 독립 `final-build07` compilePASS 후 H01 네case를 한 XCTest invocation, parallel-testing-disabled로 실행 중이다. ROOTsource/test변경0.

probe차이: 진입을 실제main→open.profile→profile.customize로갱신했고, native visible-scroll helper를쓴다. B는actualdrag와resize각각selectedID유지assertion을추가해앞선결함을우회하지않는다. VOcase는C02관찰된정확adjustable발화와선택됨사진2에실제로도달한뒤X/Y버튼doubleTap각+0.05, 실제widthswipe,새profile저장완료발화/반환을검증한다. Photos/Colorcase는미관찰nativecontrols inventory만수행하며전체기능PASS로세지않는다. PhotosInfo확인과삭제confirmation은후속실제관찰로만연결한다.


## H01 통합 앱 실제 결과

- H01 전체는 **4 cases / 1 failure / exit65**다. B full lifecycle은123.988초 PASS, VO case는width swipe 뒤값증가대기에서FAIL, Photos/Color는inventory코드PASS다. 네case전체를제품PASS로일괄표현하지않는다. installed5binary는전후일치.
- **B 실제 완료**: PhotosPicker A/B순서import, cancel전체state/bytes불변, A재선택새ID/같은hash, undo, layer앞으로, native drag/resize 각수치및선택유지, sand, 저장, 같은UUID재실행 사진ID/hash/placement/색상 동일. UUID `C6ECAE03-8FF8-43E9-B934-017DB763B3D2`, cardID `FM-20261013`. 이저장카드를Photos원본삭제후검증기준으로쓴다.
- 저장순서 B→A: B id`0DCC48B3-1F7D-48F0-B0DC-86D50EF85E5B`, center .5/.5,width .6; A id`4ADAC9F5-69EC-4DD4-9785-58E58CF177DC`, center .56779661016949157/.55244759896318085,width .65649717514124295. 사진hash는앞선actualinput결과와같다. 전체literalstate는H01 log1282행.
- **R40 캡처 완료**: DEV `t5-final-r40-overlap-handle.png`와 `.json`. 실제PNG를열어sand배경/blue세로사진상하cardclip/red가로사진앞겹침/흰선택outline/오른쪽아래원형resizehandle을확인했다. geometry한계를핑계로재선택우회하지않고제스처직후선택유지를assert했다.
- **실제 VO 핵심동작**: `선택됨 사진 2 버튼` actualutterance, 가로/세로늘리기actualfocus→doubleTap으로X/Y각 .50→.55, 서로의값과width .6보존. raw `vo.actualXYButtons.state` H01 log1530부근. 접근성대체위치조작의직접증거다.
- **VO width bonus 미확정**: 정확한 `사진 크기 60퍼센트 조절 가능...` 발화에맞춘후 `slider.swipeUp()`은합성되었으나값증가assertion이timeout. 제품결함/성공어느쪽도확정하지않는다. 설치SDK서비스는enable/disable/currentSpeech/moveForward/backward/moveIn/out만제공하며increment/swipe서비스API가없다. 원래test04실패를보존하고생산코드를수정하지않는다. width이후최신profile저장focus는그case에서미실행이므로J01별도C02case로확인한다.
- Photos ownedA 상세화면의실제red패턴과정보아이콘확인. 최초AX는전환도중controls누락이었으므로I01에서안정화후 `PUOneUpBarButtonItemIdentifierToggleDetails`(정보), `BackButton`(뒤로)를관찰했다. 여전히Photos삭제0.
- 실제 ColorPicker VO활성화로native격자/스펙트럼/슬라이더sheet표시확인. H01 `7E8EB271-1044-4920-8A28-83F9934EC6BE.png`. 관찰된RGBsliders/textFields ID는sliderRed/Green/Blue. I01숫자입력시field가의도값과다르게반영되어literalRGBassertionFAIL(FF787A). 이입력방식의실패를제품binding성공으로바꾸지않으며J01은nativeSlider실제drag와보이는채널값대draft의독립비교를사용한다.


## 재리뷰용 중간 증거 — AC18/31 및 W11 AC34/35

최신 검증 대상은 `final-root-production-manifest-W11.json`의 ROOT/clone 동일39개 파일이다. 아래 실행에서는 ROOT 생산 코드와 잠금 테스트를 수정하지 않았다. 실제 사용자 인터랙션과 진단값, XCTest 관찰 성공 범위를 나누어 기록한다.

### AC18 / 실제 편집 전체 흐름

- 로그: `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/runtime-final-H01.log`
- 결과: 같은 경로 `runtime-final-H01.xcresult`. B 메서드 `test02ActualPickerCancelReselectDragResizeSave`는 **123.988초 PASS**(log1360행). H01 전체는 별도 width bonus 실패 때문에 exit65이므로 전체 PASS로 표시하지 않는다.
- 실제 picker의 A→B 선택 순서, 취소 불변, 동일 원본 재선택, 드래그·크기 조절, 각각의 선택 유지, 저장 및 같은 UUID 재실행을 완료했다. 코드로 선택을 강제하거나 생산 setter를 호출하지 않았다. H01 log1281–1282행이 저장 UUID와 완전한 사진ID/hash/placement/RGB 기준값이다.
- R40 실제 화면은 DEV `t5-final-r40-overlap-handle.png`, 원본 상태는 같은 이름 `.json`. 직접 시각 검토한 결과 샌드 배경, 사진 겹침, 카드 경계 클립, 선택 outline 및 원형 핸들이 모두 보인다. 이 캡처는 뒤에 사진 재선택을 넣어 제스처 결함을 우회한 결과가 아니다.

### AC31 / 실제 VoiceOver 읽기와 비드래그 위치 조작

- 같은 H01 log1474행: `선택됨 사진 2 버튼` actual `XCUIVoiceOverService.currentSpeech` 출력.
- log1482/1742행: `사진 크기 60퍼센트 조절 가능 값을 조절하려면 한 손가락으로 쓸어올리거나 쓸어내리십시오.` 실제 발화. 정적 label assertion만으로 대체하지 않았다.
- log1491–1505행에서 실제 가로 늘리기 초점을 확인하고 doubleTap; log1510–1524행에서 실제 세로 늘리기 초점을 확인하고 doubleTap. log1530행 `vo.actualXYButtons.state`에서 선택된 B의 centerX/centerY가 각각 .50→.55이며 width .6과 다른 사진이 유지된다. 각 단계 숫자 assertion은 통과했다. 이 증거가 드래그 없이 위치를 변경하는 필수 경로다.
- H01 width swipe bonus는 위 실제 adjustable 발화에 도달한 후 native `slider.swipeUp`을 합성했지만 값 증가 대기에서 실패했다(log1792행). SDK에 별도 increment/swipe 서비스 API가 없어 전달 방식과 제품 동작을 분리하지 못했다. **VO width 조절 성공은 주장하지 않으며, 이 bonus 미확정을 필수 X/Y 경로 실패나 생산 결함으로 일반화하지 않는다.** 실패 원본은 보존한다.
- C02/J01 탐색 원문에는 선택 상태, disabled 버튼, 현재 퍼센트, 버튼 이름이 실제로 읽힌다. 최신 J01의 정확 원문은 `runtime-final-J01.log`와 attachments에 있다.

### 최신 W11 저장 안내의 실제 VO 발화/시각초점

- 로그: `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/runtime-final-J01.log`
- 결과: 같은 경로 `runtime-final-J01.xcresult`. `test03bObserveNoManualImportAndSaveAutomaticFocus` **56.290초 PASS**(log566행). log563행 결과 `import=true, saveFailure=true, saveSuccess=true`. manual hold/release 버튼을 쓰지 않는 소유 mixed fixture 경로이며 실제 PhotosPicker 성공 증거와 구분한다.
- 실제 `currentSpeech()`로 가져오기 오류·저장 실패·저장 성공 안내를 이동 명령 없이 관찰했다. 서비스 primary header는 현재 초점을 가진 요소의 발화라고 정의한다. `test.announcements` 문자열을 성공 근거로 쓰지 않는다.
- 최신 프로필 복귀 후 실제 시각초점도 확인: DEV `t5-final-profile-save-success-vo.png`. 원본 `runtime-final-J01-attachments/04BCA59B-45AD-414F-B521-FA8BEC90264F.png`. 이미지를 직접 열어 마이페이지/저장된 카드와 화면 하단 성공 안내 전체, 그 안내 위 VoiceOver focus rectangle을 확인했다.
- 가져오기 안내는 이전 C02에서 발화 직후 화면의 초점 지속성과 자동 스크롤이 서로 달랐으므로 그 경계는 유지한다. 최신 성공 화면의 명확한 시각초점과 혼동하지 않는다.
- W11 AC34/35의 profile identity/records/statistics/XXXL 전체 assertion 증거는 부모의 독립 integration GREEN 보고서가 담당한다. 본 runtime은 실제 profile 진입/편집/저장 복귀/성공안내를 보완하며 XXXL을 별도 실행했다고 주장하지 않는다.

### 남은 별도 검증

AC25 Photos 원본 삭제 후 보존과 native custom RGB discard/save/relaunch는 현재 K01 focused 실행을 진행 중이다. 사진 삭제는 아직0건이며 두 고유 원본명을 native Info value로 확인한 뒤 관찰된 삭제 확인 UI로만 수행한다. 이 두 미완료 항목을 위 AC18/31의 직접 확인된 부분과 섞어 일괄 완료 처리하지 않는다. 모든 raw log/xcresult/installed hash JSON은 `.build/photos-probe/`에 보존했다.


## Native 사용자 RGB 검증 완료 — M01

- `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/runtime-final-M01.log` 및 `.xcresult`: **2 tests / 0 failures / exit0**. `test08ActualNativeRGBDiscardSaveAndRelaunch` 100.834초 PASS, Photos 삭제dialog 관찰 11.979초 PASS.
- 실제 ColorPicker의 관찰된 `슬라이더` 탭과 sliderRed/Green/Blue를 조작했다. UIKit native adjust는 best-effort이므로 임의 목표64/128/192를 제품 요구사항으로 강제하지 않았다. 세 조작이 끝난 후 화면의 최종 RGB 숫자값을 읽어 제품 draft의 채널값과 비교했다. UI값 반영이 안정화되기 전 read 및 native숫자 입력 방식에서 발생한 이전 probe 실패를 보존한다. 생산 코드/원래 테스트 변경은 없다.
- 첫 사용자색 선택 후 실제 편집 닫기→변경 버리기 확인으로 원래 저장색과 재진입 초안이 불변임을 확인했다. 다시 native RGB를 선택해 실제 저장했고 같은UUID 재실행/프로필 편집 재진입에서 저장색과 draft가 정확히 같았다.
- UUID `0D74161A-9D07-4AB3-906B-080710E8C1D1`; 최종 RGB red `.352935791015625`, green `.560577392578125`, blue `.7696685791015625`. M01 log1670행에 완전한 저장/초안 상태가 있다. 임의 생산setter나 진단 입력값으로 색상을 주입하지 않았다.
- 실제 재실행 화면: DEV `t5-final-custom-rgb-relaunch.png`(원본 M01 attachments `4396A5F4-5B72-4395-8D74-6BA41CDE7C96.png`).

Photos 소유권은 K01 log36/197행 native Info `com.apple.photos.infoPanel.filename.value`에서 A/B 전체 고유 basename과 UUID를 확인했다. 확장자는 Info가 표시하지 않으므로 basename/UUID로 검증했다. M01은 원래6개가 선택되지 않고 소유2개만 Selected인 것, `선택된 항목 표시(2개)`, native `Delete 2 Photos`를 실제관찰했다. 확인 버튼은 이 단계에서 누르지 않았고 N01이 최종 삭제와 데이터보존을 담당한다.


## 최종 Photos 원본 삭제·보존 검증 및 슬롯 반환 — N01/O01

- **실제 Photos 원본 삭제 완료:** 소유 원본 `W10-Owned-A-79A4547A-E6AA-4D10-9AE6-978F5A3A4E38`와 B의 동일 UUID 고유명을 native Info value로 확인했다. N01에서 기존 6개 미선택, 소유 A/B만 선택된 2개임을 assert한 뒤 실제 `Delete 2 Photos` 버튼을 **한 번만** 눌렀다. Recently Deleted 30일 이동이며 추가 영구삭제는 하지 않았다.
- N01은 삭제 뒤 기존 AX image query의 count==6 대기가 timeout으로 exit65였다. 실패 원본을 보존한다. 그 직후 실제 화면에 6 Photos/기존 자연 사진 6개만 보인 것을 직접 확인했으며 재삭제하지 않았다. N01 로그: `.build/photos-probe/runtime-final-N01.log`, 결과 `.xcresult`.
- **읽기 전용 O01 후속 1/1 PASS, 31.072초, exit0.** `test06bReadOnlyAfterConfirmedDeletion`은 삭제 동작 없이 동일 앱 UUID를 실행하고 Photos를 재실행·관찰했다. 관찰된 선택 모드에서 정확히 6개이며 최초 6개 날짜 labels와 순서가 전부 동일하고 모두 미선택임을 assert했다. 마지막에는 선택 모드를 취소했다. 이 결과로 8→6 및 기존 6개 보존을 확인한다. N01의 stale/AX 전환 내부 원인은 확정하지 않는다.
- O01 로그 `/Users/bonseung/.codex/worktrees/w10-card-customization/new/.build/photos-probe/runtime-final-O01.log`: 41행은 삭제 후 완전한 state, 234행 이후 실제 Photos selection inventory, 444행 PASS. 같은 경로 `.xcresult` 및 `-attachments/manifest.json`에 원본 화면/트리가 있다.
- 동일 UUID `C6ECAE03-8FF8-43E9-B934-017DB763B3D2`, cardID `FM-20261013`의 삭제 후 상태가 H01 삭제 전 기준과 정확히 같다. 두 사진 ID·이미지 SHA256·byteCount·픽셀 크기·배치/크기·순서 및 RGB 모두 비교 통과했다. 추가 cold launch 후에도 같은 상태이며 `test.persistedBytes` 전체가 동일했다. 전체 저장파일 bytes 비교는 **삭제 후 두 번의 실행 간** 증거다. 삭제 직전 local 변수는 N01 실패로 비교까지 도달하지 않았으므로 삭제 전후 전체 파일 bytes까지 비교했다고 확대하지 않는다. 이미지 데이터 hash의 삭제 전후 일치는 직접 비교했다.
- 실제 시스템 Reduce Motion은 O01에서도 `test.reduceMotion == true`였다. 강제 환경 주입을 사용하지 않았다.
- 최종 화면/상태: DEV `t5-final-photos-six-preserved.png`, `t5-final-same-uuid-after-source-deletion.png`, `t5-final-same-uuid-after-source-deletion.json`. Photos 이미지를 직접 열어 기존 자연 사진 6개와 6 Photos 표시를 확인했다.
- `final-production-equality-after-runtime.json`: ROOT/clone **39개 파일 모두 SHA256 동일**, W11 freeze manifest와도 동일(2026-10-14 23:56:53). O01 `-installed-hashes.json`은 실제 설치된 main/runner 5개 binary가 빌드 산출물과 동일함을 확인한다. ROOT 생산 코드 및 잠금 테스트 수정 없음.
- **23:57:36 O01 종료 후 exclusive build/test slot RELEASE.** owned 27 F226은 booted, VoiceOver off, 원래6개 보존. 추가 빌드/시험/기기 변경을 중단하고 부모 최종 전체 검증에 인계했다. 본 보고서/증거 export만 후처리했다.

필수 runtime 보완 결과: 실제 picker 선택/취소/재선택/순서·drag/resize·선택 유지·R40 핸들·저장/재실행(H01 B), 실제 VO 선택/이름/현재값/비활성 및 X/Y 조작(H01/C02), 최신 W11 안내 3개 실제 자동 발화와 프로필 저장 성공 시각초점(J01), native RGB discard/save/relaunch(M01), 실제 Photos 소유 원본 삭제 뒤 동일 카드 이미지 보존(O01)을 확인했다. 전체 probe 실행 묶음을 일괄 PASS로 바꾸지 않는다. VO width swipe bonus는 여전히 성공 미확정이며, 가져오기 안내의 발화 후 시각초점 지속/자동 스크롤도 별도 한계로 남긴다. 필수 X/Y 대체조작과 최신 저장 안내 증거를 이 bonus 한계와 구분한다.

## W03 main 합류 뒤 증거 적용 범위
최신 main5a9b611을 maintenance8bf0b922로 합류했다. 부모가 stash39de431의 tracked/untracked 원본과 현재13개 핵심 Swift 파일(RootView·CardCustomizationView/Controller·processor·style·snapshot·codec·store·PassFace·FontCatalog·ProfileView·AppModel+Profile·TimeSelectionView)을 직접 bytes 비교하여 모두 동일함을 확인했다. 서울알림 Bold/Medium도 기존 W10 Fonts에서 main Resources/Fonts로 중복을 제거했으며 동일 bytes다. 기존 실제 Photos/VO/시각 관찰을 통합 후 새로 수행했다고 주장하지 않고 이 불변성과 최신통합 unit539+핵심UI6 PASS, 후속 전체 검증으로 연결한다. AppModel/DestinationScreen/앱init/Bootstrap의 상류 추가는 전체 브랜치 리뷰와 최신 전체 회귀 범위다.
