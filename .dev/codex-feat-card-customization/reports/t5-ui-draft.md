# T5 UI 테스트 초안 인계

Status: **DONE_WITH_CONCERNS — DRAFT ONLY**. T4 RGR active 상태에서 실제 타깃 반영·fixture 생성/staging·빌드·테스트·RED 확인·새 에이전트·커밋을 수행하지 않았다. 실행 가능한 RED 산출물로 승인하거나 PASS/컴파일 성공으로 해석하면 안 된다.

산출물: `../drafts/CardCustomizationFlowTests.swift` (12 test methods). 코드 전문은 해당 초안 파일을 인계한다. 실패 확인 명령/실패 메시지: **실행하지 않음 — 사용자 DRAFT ONLY 지시**. T4 gate 이후 부모가 관찰 계약을 보완하고 실제 `ios/FocusMateUITests`로 승격한다.

## GWT 매트릭스

| 케이스 | Given | When | Then / 잡는 변이 | AC |
|---|---|---|---|---|
| 01 | ready, 한 장/기본 외형 | 열기→변경 없이 명시적 닫기 | ID·시각·수·snapshot·실제 파일 bytes 유지, 기본 도구, 확인 없이 main / 재발급·불필요 write | 01,19,31 |
| 02 | 기본 초안 | sand→undo, blue→restore→undo | 초안만 변경, 복원 하나의 undo, 파일 불변 / 저장 조기 반영·복원 이력 누락 | 03,15,17 |
| 03 | 미저장 색 변경 | close→continue→close→discard→재진입 | continue 초안/undo 유지, discard 마지막 외형·파일 유지 / reset·미저장 write | 20,21 |
| 04 | actual valid2 | 순서 입력→생성 ID 선택→X/Y/width→앞으로→삭제→undo | 치수 120×80/80×120·초기60%·선택 대상만 변화·순서/삭제 복구 / 잘못된 대상·순서·인자 | 04,11,13,14,15,31 |
| 05 | 두 번째 portrait 선택 | 아래로 최대 이동/최대폭→색/저장 클릭→정상폭→목록 재선택→Y 복귀 | clip 밖 interaction이 버튼을 가로채지 않음, 완전히 밖 사진도 복귀 / hit layer 침범·목록에서 상실 | 11,18,31 |
| 06 | hold, undo 가능한 색 변경 | 실제 DEBUG import gate 보류→close/continue→release | 색/추가/undo/restore/save 잠금, close 허용, 초안 유지, release 후 1장·잠금 해제 / 잠금 누락 | 23 |
| 07 | hold 보류 | close/discard→재진입→새 batch/release→undo | 버린 batch가 다시 적용되지 않음·새 gate 동작·파일 불변 / 취소/세대 무효화 누락 | 22 |
| 08 | mixed: 먼저 unreadable, 다음 valid | 입력 | 성공 1장, 실패 안내, save/undo 사용, 파일 불변 / 실패가 자리 소비·성공도 유실 | 09 |
| 09 | 기본0장, seven 정상7장 | 입력→undo | 선택 순서 앞6장, 최대6 안내, 추가 잠금, batch 단일undo / 초과/뒤쪽 우선 | 06,07,15 |
| 10 | invalidPaths, 기본 초안 | 입력 | 모두 실패 안내·초안/undo/원본 유지 / 경로 이탈 읽기·실패 이력 | 10 |
| 11 | valid2 + card-save fail-once | import/sand→실제 write 실패→retry→동일UUID seed없이 relaunch | 실패 초안/선택/undo/파일 보존, retry atomic 성공, 치수·ID·sha256·배치 복원·다른 snapshot 섹션 보존 / write 실패 유실·복원 실패 | 24,26,30 |
| 12 | XXXL + 실제 simulator Reduce Motion ON | 기본/사진 시작·끝 탐색→저장 | 도구/복원 전체가 footer 위로 도달, save hittable / 본문 잘림·도달 불능 | 31 |

각 본문에 깨짐 명명을 먼저 기록했다. 최대 사진수6·초기 너비60%·Stepper 간격5%·치수 등 기대는 설계/독립 fixture의 리터럴이다. before/after 진단 비교는 보존 관계 검증이며 기대 이미지를 SUT로 생성하지 않는다. 표현 색 RGB·여백·폰트 assert, 전체 snapshot golden, screenshot golden은 없다. 전체 snapshot canonical 비교는 무변경 종료의 데이터 보존 검사다.

## 부모가 먼저 준비할 실제 fixture/staging

1. T4 gate 통과 후 독립 생성기를 DEVDIR 아래에서 작성한다. 이 작업은 생성기나 fixture를 만들지 않았다. 유효 PNG는 독립 ImageIO/CoreGraphics 생성과 독립 재읽기로 complete decode·실제 치수·alpha를 확인하고 파일 경로/해시/바이트 수 inventory를 남긴다. production processor로 expected 결과를 생성하지 않는다.
2. 최초 앱 설치/seed 실행 후 앱을 종료하고 **동일 앱 컨테이너**의 `Library/Application Support/FocusMate/UITestPhotoFixtures/`에 parent-owned 파일을 stage한다. manifest와 모든 파일은 각 랜덤 testUUID 실행에서 접근 가능해야 한다. 재설치/컨테이너 변경 시 다시 stage한다. testUUID snapshot 디렉터리에 fixture를 추측하여 두지 않는다.
3. manifest 형식은 `{"items":[{"path":"a.png"},{"path":"b.png"}]}`. path는 manifest 디렉터리 하위 상대경로. 선택 순서가 배열 순서다. 앱 인자는 `--fm-ui-card-photo-manifest FocusMate/UITestPhotoFixtures/<name>.json`. absolute container UUID, 신규 seed/base64 flag는 사용하지 않는다.

| manifest | 배열 순서와 파일 요구 |
|---|---|
| valid2.json | `a.png` 실제 120×80 colored PNG, `b.png` 실제 80×120 다른 colored PNG, alpha 포함. 두 내용/출력 sha는 달라야 한다. 기본 입력은 정상 소형이며 출력1MiB 이하. |
| mixed.json | `unreadable.bin` (명백한 비이미지 실제 파일), `a.png` (위 실제 정상120×80). 첫 실패가 자리를 먹지 않음을 검증. |
| seven.json | `p1.png`…`p7.png`, 각각 실제 치수101×80…107×80, 서로 다른 정상 이미지. 모두 정상 소형, 입력8MiB/출력1MiB 미만. 기본 seed0장에 manifest7장으로 앞6장 선택·1장 생략을 판별. |
| invalidPaths.json | `../escape.png`, `missing.png`. escape.png는 fixture 디렉터리 바깥 parent-owned Application Support 하위에 정상 이미지로 stage해야 한다(경로 검사 누락을 검출). missing.png는 실제 부재 확인. |
| hold.json | `a.png` 정상120×80 한 장. `--fm-ui-card-import-hold manual`로 첫 loader만 release까지 보류. 임의 sleep 없음. |

정상 UI 입력에 쓰는 이미지는 실제 이미지 bytes이다. 8MiB 입력·1MiB 출력 정확 경계/손상 포맷/alpha encoding의 상세 증거는 이미 unit/processor 경계의 책임이며 UI에서 거대한 10개 입력으로 복제하지 않는다. `test.cardStyleJSON`의 실제 processor metadata(id/pixelWidth/pixelHeight/centerX/centerY/widthFraction/byteCount/sha256)를 확인하고 저장 전후 전체 Photo 값의 동등성으로 사진 바이트 해시/배치를 보존하는지 확인한다. 진단만으로 alpha decode/보관함 독립성을 추가 입증했다고 주장하지 않는다.

## 계약과 남은 관찰 항목

- 기존 `FocusMateUIHarness.launch(seed: "ready", extraArguments:, testID: UUID())`, `.element`, `.diagnostic`, `.snapshot`, `.relaunch()`를 그대로 사용한다. draft의 `helperID`는 계약 접두사만 생성한다. relaunch는 같은UUID, seed/fixture/fail-once 생략.
- 최종 palette ID는 standard/slate/blue/mauve/sand/ivory이며 역사적 green/pink/yellow 없음.
- JSON은 설계의 정확한 최상위 `cardID/background/photos/draft/selectedPhotoID/isImporting/canUndo/didSave`, 사진의 위8키만 Decodable로 사용한다. base64·undoCount·가짜 setter·가짜 dialog는 없다.
- **NEEDS_CONTEXT: 실제 X/Y Stepper 하위 버튼 접근성 이름/타입.** 설계에는 Stepper와 x/y ID만 있고 기존 UI시험에 native 버튼 이름 관례가 없다. 추측한 영어/한국어·child index·coordinate 버튼을 넣지 않았다. 부모가 실제 AX 트리를 관찰해 runner 환경 `FM_T5_X_INCREMENT_AX`, `FM_T5_X_DECREMENT_AX`, `FM_T5_Y_INCREMENT_AX`, `FM_T5_Y_DECREMENT_AX`를 채우거나 관찰한 role+name helper로 바꾼다. 현재 누락 시 XCTUnwrap가 context 실패를 반환하므로 이 상태를 정상 RED로 분류하면 안 된다.
- Reduce Motion은 실제 simulator Settings에서 부모가 활성화/확인 후 runner에 `FM_T5_REDUCE_MOTION_STAGED=1`을 제공한다. 환경 표식 자체가 OS 상태 증거는 아니다. 새 앱 flag를 만들지 않았다. XXXL 시작 캡처의 최상단 복귀와 복원/마지막 보존 안내 도달은 실제 화면 관찰 후 보완한다(마지막 안내의 정확한 selector/text 미제공).
- 05는 도구 조작 후 preview를 화면 안으로 되돌리고 추가 스크롤 없이 색/저장을 탭한다. 부모는 실제 시뮬레이터에서 사진의 확대 영역이 해당 버튼 위치에 겹치는 setup을 확인해야 한다. 기기/글자 크기 때문에 겹침이 없으면 clip hit 제한의 증거로 채택하지 않는다.
- 성공 후 편집 화면이 유지되어 `didSave`를 관찰하고 재편집 가능한지는 설계 controller/diagnostic 계약을 따른 초안 전제다. 실제 성공 UI 생명주기를 부모가 확인하고 필요하면 main→재진입을 명시한다. ID·시각·다른 상태·사진 보존 assert는 유지한다.
- notice는 존재/내용 비어있지 않음(한도는6 포함)을 검증한다. 실패/생략 각각의 정확한 최종 사용자 문구·AX value는 제공되지 않아 이를 추측하지 않았다. 부모가 실제 안내 관찰 후 partial failure와 omitted 알림의 의미를 직접 확인/보강한다.
- 07은 **실제 DEBUG gate cancellation** UI 경계다. cancellation을 무시한 loader의 late-success 증거는 기존 unit 경계이며 여기에 인위적인 ignore-cancel hook을 만들지 않는다.
- **실제 PhotosPicker 보충시험 PENDING:** 읽은 harness에는 시스템 보관함 asset을 선택하는 API/관찰된 dialog 역할·접근성 이름이 없다. 시스템 selector를 추측한 가짜 XCTest를 추가하지 않았다. 부모의 fresh simulator library에 독립 owned assets를 주입하고 실제 picker 선택·취소·재선택을 관찰한 후 별도 초안 case를 작성한다. 저장→Photos에서 실제 원본 자산 삭제→동일UUID 재실행→사진 수/내용sha/배치 복원을 확인한다. fixture file 삭제는 AC25 증거가 아니다.
- **VoiceOver 보충검증 PENDING:** 부모가 실제 이름·선택·현재값·잠금·저장/입력 announcement·포커스·드래그 대안 탐색을 관찰한다. XCUITest 자동화 트리만으로 실제 VO 동작을 PASS 처리하지 않는다.

## 캡처/시각 판정

`.keepAlways`: basic, photo2selected, confirmation, import-error, save-error, XXXL-basic-start/end, XXXL-photo-start/end. 부모가 실제 실행 후 기기pt/scale/safe area와 원본을 보존하고 t5-visual-handoff 기준으로 직접 비교한다. photo2selected는 sand 배경/두 번째 사진 선택으로 캡처하며 R40과 같은 겹침 배치는 부모가 참조용 캡처로 추가 보완한다. 본 초안에는 픽셀/스타일/golden 비교가 없으며 기능 PASS는 시안 일치 PASS가 아니다.

## 참조한 파일 전체 목록

내용 읽기:
- `.dev/codex-feat-card-customization/prd.md`
- `.dev/codex-feat-card-customization/design.md` (T5 DEBUG 경로/생명주기 최신 계약 포함)
- `.dev/codex-feat-card-customization/reports/t5-visual-handoff.md`
- `ios/FocusMateUITests/UITestLaunchSupport.swift`
- `ios/FocusMateUITests/CardIssuanceFlowTests.swift`
- `ios/FocusMateUITests/CardStorageFlowTests.swift`
- `ios/FocusMateUITests/LargeTextUITests.swift`
- `ios/FocusMateUITests/SimulatorLargeTextRecoveryTests.swift`
- `ios/FocusMateUITests/HarnessUITests.swift`
- `/Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md` (프로세스 규칙만 확인; 사용자 DRAFT ONLY가 우선)

`rg` 패턴 검색 범위: `ios/FocusMateUITests/*.swift` (위 파일과 FirstStationSearchUITests, Phase1FlowTests, PreparationFlowUITests, RecoveryHistoryFlowTests, StationSaveFailureUITests, StorageRecoveryFlowTests, TimeSelectionUITests). 경로 inventory는 `.dev/codex-feat-card-customization` 및 `ios/FocusMateUITests`에만 수행했다. production 내용·ios/FocusMateTests helpers·기타 reports/memory는 읽지 않았다.

쓰기: 지정된 draft Swift와 본 report 두 파일만. 다음 단계: 부모 T4 gate→fixture/관찰 계약 보완→target promotion→실제 RED/실패분류→GREEN→실행/시각 대조·actual picker/VO 보충증거.

## T4 gate 이후 확정 계약 반영 (2026-10-14)

Status: **DRAFT READY — PROMOTION PENDING**. 부모가 보고한 T4 247/247 PASS 이후 최신 설계 부록의 T5 testability 계약을 초안에 반영했다. 실제 `ios/FocusMateUITests` target 승격, fixture staging, build/test/RED 실행은 부모의 다음 명시 신호 전까지 수행하지 않았다. 12개 test method 수는 유지했고 기대값·보존 검증을 약화하지 않았다.

해결한 조건부 공백:

- 저장 성공은 `screen.cardCustomization` 부재, `screen.main` 존재, `cardCustomization.savedNotice`의 정확한 문구 `카드 외형을 저장했어요.`를 함께 기다린다. 닫힌 diagnostic의 최상위 saved가 저장 직전 draft와 같고 draft/selectedPhotoID가 nil, didSave/canUndo가 false임을 검증한다. 05/11/12는 편집 화면에서 didSave=true를 기다리지 않으며 성공 뒤 진입 버튼으로 새 편집 세션을 열어 남은 검증을 계속한다. 실패 후 편집기·선택·undo·saved·원본 bytes 보존 검증은 그대로다.
- X/Y 조작은 외부 `FM_T5_*_INCREMENT_AX` 추측을 제거했다. 각 x/y control container 안에서 확정 child ID `.decrease/.increase`를 조회하고 한국어 label `가로/세로 위치 줄이기/늘리기`를 정확히 검증한다. test04의 0.50→0.55/0.45 assert가 1회 5% 계약을 계속 관찰한다.
- 모든 본문 탐색은 `cardCustomization.body` 존재를 조기 요구하고 그 ScrollView의 x=2% gutter 좌표에서 bounded drag한다. target이 footer 아래면 content를 위로, 상단 밖이면 아래로 이동하므로 도구에서 preview로 되돌아갈 수 있다. 임의 sleep은 없다. test05/12의 직접 app swipe도 같은 helper로 교체했다.
- test12는 XXXL 도달성 자동화로만 명명·검증한다. `FM_T5_REDUCE_MOTION_STAGED`와 외부 source flag 전제를 제거했다. 실제 Reduce Motion ON은 부모가 owned iOS 27 simulator Settings에서 별도로 켠 뒤 read-only `test.reduceMotion == true`로 확인할 보충 실행이며, 기본 OFF XXXL 케이스를 Reduce Motion 증거로 주장하지 않는다.
- 12개 모두 화면 진입 실패를 즉시 드러내는 실제 element wait와 색/초안/undo/사진 metadata·순서·한도·잠금·경로 거부·write retry·snapshot 보존·XXXL 도달성 중 하나 이상의 제품 관찰 assert를 가진다. NEEDS_CONTEXT dummy, pixel/style/golden assert는 없다.

남은 보충 증거는 실제 PhotosPicker에서 owned asset 선택·취소·재선택 및 저장 후 원본 삭제/relaunch, 실제 VoiceOver 이름·값·포커스·announcement·드래그 대안, 캡처 원본을 시안과 직접 비교하는 visual 판정이다. 이 셋은 fixture DEBUG 경로의 12개 자동화만으로 PASS 처리하지 않는다.

이번 갱신에서 읽은 파일은 draft `CardCustomizationFlowTests.swift`, 본 `t5-ui-draft.md`, 최신 `design.md`, 기존 UI helper `ios/FocusMateUITests/UITestLaunchSupport.swift`이다. production source는 읽거나 수정하지 않았다. 쓴 파일은 draft와 본 report뿐이다. 명령은 허용 파일의 `sed`, `rg`, `git diff` 정적 점검뿐이며 build/test는 실행하지 않았다.
