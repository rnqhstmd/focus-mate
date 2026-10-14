# T3 사전 테스트 초안

Status: NEEDS_CONTEXT (사전 초안 작성 완료; discard 이후 requestExit 반환 계약 불충분)

## 범위와 실행 상태
실제 ios/FocusMateTests에 쓰거나 복사하지 않았다. production 열람·검색·수정, build/test/testcompile, provider 호출, 새 agent, commit/push를 수행하지 않았다. 아래 작성 건수는 통과 건수가 아니다. 실패 확인 명령·실패 메시지·실패 사유는 **미실행/해당 없음**이다. T2 완료 후 부모가 선언 계약을 확인하고 RED author로 승격한다.

## 선언 요청 (최종 design 계약만)
CardCustomizationController의 전체 initializer와 draft/selectedPhotoID/isImporting/isSaving/didSave/notice, hasChanges/canUndo/canAddPhotos 및 selectPhoto/setBackground/setPlacement/moveLayer/deletePhoto/undo/restoreDefault/importPhotos/requestExit/continueEditing/discard/save가 필요하다. CardCustomizationSaving.saveCardStyle(_:forCardID:)/saveFailure, CardPhotoInput.init(load:), CardCustomizationNotice 4 case, CardLayerDirection와 CardCustomizationExitDecision가 필요하다. T2의 CardColor/CardPhoto/CardStyle/CardSnapshot/ProcessedCardPhoto/CardPhotoProcessing/CardPhotoProcessingIssue 및 StorageIssue(.writeFailed, .notReady) 선언을 사용한다. 선언용 placeholder/stub는 작성하지 않았다. 테스트 전용 production setter나 신규 mocking seam을 요구하지 않는다.

## 우려사항과 해석 경계
- discard 후 requestExit의 반환값은 최종 계약에 명시되지 않았다. 모든 변경 메서드, select, continueEditing, discard, import, save의 비활성 동작을 검증하지만 종료 결정값은 추측하지 않는다. 부모가 requestExit까지 모든 메서드 범위에 포함하려면 반환 계약이 필요하다 (그 부분은 NEEDS_CONTEXT).
- 늦은 await 결과 테스트는 draft/notice/isImporting의 관찰 가능한 효과를 검증한다. discard에서 이미 false인 isImporting에 오래된 defer가 false를 재할당하는 내부 쓰기 자체는 동일한 관찰 결과이므로 구별할 수 없다. 내부 generation 필드 접근이나 production setter로 검증 범위를 확장하지 않는다.
- 저장 ID는 saver capture로 검증한다. controller가 issuedAt을 노출하지 않으므로 발급시각과 실제 저장 카드/정류장/여정/기록 보존은 T4/실제 store 통합 경계다.
- processed Data([byte])와 fixture.photo는 controller 값/순서/배치 테스트 전용이다. 실제 이미지 유효성·RGB/원본 보존의 증거로 사용하지 않는다. T2 ImageIO/실제 store 통합과 분리한다.
- 저장 중 재진입/종료 동작의 동기 saver 재진입 관찰은 이번 사전 초안 범위를 넘긴다. 실제 타깃 컴파일 및 RED 결과는 아직 없으며 Swift concurrency 적합성도 실행 검증하지 않았다.

## 테스트 더블과 동기화
saver boundary는 ID·후보 외형·호출을 캡처한다. processor는 immutable Sendable struct 또는 actor gate를 가진 struct이다. loader/processor gate는 continuation start signal과 explicit release를 사용하며 sleep/poll/yield loop가 없다. 대기 중 assert는 throwing unwrap/early return 없이 실행하고 모든 시작된 task는 release 후 await한다. cancellation 무시 late 결과를 의도적으로 모델링한다. UUID는 1...6, 99, 101...의 고정 sequence이며 기대 배치·clamp·undo20 잔여색은 독립 literal이다. baseline 복원을 비교할 때 직전 값 캡처는 외형 undo 계약을 검증하기 위한 것이며 기대값을 controller 함수로 계산하지 않는다.

## 전체 초안
- [Controller 테스트 초안](../drafts/CardCustomizationControllerTests.swift)
- [테스트 더블](../drafts/test-double.swift)

## 케이스 목록 / AC 매핑 / 예상 broken behavior
작성된 테스트 함수: 45개 (실행 0회, pass/fail 미확인).

| 케이스 | AC | Given → When → Then | 잡히는 잘못된 변경 |
|---|---|---|---|
| `InitialDraftCopiesSavedStyleAndSaveUsesOriginalCardID` | 03,04,26 | 저장 외형과 고정 ID의 카드 → 편집 후 명시적 저장 → 초안은 저장 외형에서 시작하며 saver는 원래 ID와 편집 외형을 받는다 | 초안을 기본값으로 대체하거나 저장 ID를 새로 생성 |
| `BackgroundChoiceChangesDraftWithoutSaving` | 03 | 기본색 사진0장 → 사용자색 선택 → 초안 색만 바뀌고 저장 호출 없음 | setBackground에서 saver 호출 또는 색 무시 |
| `InvalidRGBIsWholeNoOp` | 03 | 변경 없는 초안 → 범위 밖 또는 비유한 RGB 적용 → 초안과 history 유지 | RGB 유효성 검사 제거 |
| `ImportCreatesEditablePhotoWithLiteralInitialPlacement` | 04 | 사진0장 → 사진 읽기 성공 → 새 사진 중심과 너비가 초기값이며 이동 가능 | 초기 배치가 0 또는 이동 메서드가 no-op |
| `FullCardRejectsImportBeforeLoader` | 06 | 6장 → 추가 요청 → loader0회 maximumPhotos | 6장 가드 뒤에 loader 호출 |
| `OverflowProcessesOnlyRemainingSlots` | 07 | 5장 → 정상3장 선택 → 첫1장만 추가하고 나머지 loader 미호출 | 만석 이후 입력 처리 또는 omittedCount 오계산 |
| `FailureDoesNotConsumeRemainingSlot` | 07,09 | 5장 → 실패 다음 성공 다음 미처리 입력 → 성공이 마지막 자리를 쓰고 실패 생략 안내 | 실패를 자리 소비로 계산 |
| `EmptyPickerCancellationPreservesDraftWithoutHistory` | 08 | 2장 이력 없음 → 빈 선택 → 외형과 history 유지 | 빈 선택이 history를 추가 |
| `EmptyInputKeepsExistingFailureNotice` | 08,10 | 실패 안내 있는 세션 → 빈 선택 → notice 유지 | 빈 배열 분기가 notice 초기화 |
| `PartialSuccessIsOneUndoBatch` | 09,15 | 기존1장 → 정상 실패 정상 입력 → 성공 순서 보존하고 undo1회로 전체 batch 제거 | 성공마다 history를 만들거나 순서를 역전 |
| `PartialFailureAllowsEditingAndSave` | 09 | 부분 성공 안내 → 색 편집 후 저장 → 입력 잠금 해제되고 저장 허용 | 실패 후 isImporting 해제 누락 |
| `AllFailuresKeepPreviousHistoryAndFailureOrder` | 10 | 색 변경 이력 → processor실패 둘 → 외형 이력 유지 실패 선택순 안내 | 실패 batch가 history를 지우거나 오류 순서 역전 |
| `LoaderNilThrowAndActiveCancellationAreUnreadable` | 10 | 활성 세션 → nil 일반오류 cancellation 입력 → 세 실패 unreadable 후 재입력 가능 | loader 오류를 삼키거나 cancellation을 세션 폐기로 처리 |
| `PlacementChangesOnlyTargetAndKeepsAspect` | 11 | 서로 다른 배치의2장 → 한장 배치 변경 → 선택 대상 배치만 변경 치수와 나머지 보존 | 모든 사진에 배치 적용 또는 치수 변경 |
| `PlacementClampsMinimum` | 11 | 한장 → 범위 밖 배치 → 각축 너비 clamp | clamp 하한 또는 상한 오설정 |
| `PlacementClampsMaximum` | 11 | 한장 → 범위 밖 배치 → 각축 너비 clamp | clamp 하한 또는 상한 오설정 |
| `NonFinitePlacementRejectsWholeOperation` | 11 | 정상 배치 → 한 필드만 비유한 다른 필드는 정상 변경 → 전체 no-op history없음 | finite 필드만 부분 적용 |
| `LayerMovesOneStepForward` | 13 | A B C → B를 한단계 이동 → 순서만 변경 | 앞뒤 방향 반전 또는 끝으로 이동 |
| `LayerMovesOneStepBackward` | 13 | A B C → B를 한단계 이동 → 순서만 변경 | 앞뒤 방향 반전 또는 끝으로 이동 |
| `LayerEndsDoNotCreateHistory` | 13,16 | A B C → 맨앞 forward 맨뒤 backward → 외형 이력 유지 | 끝단 이동이 history 생성 |
| `DeleteReopensSlotAndUndoRestoresExactPhoto` | 14,15 | 6장 → 선택 사진 삭제 후 undo → 해당사진만 제거 슬롯 재개 undo복원 | 다른 사진 삭제 또는 undo에서 원본 배치 손실 |
| `UndoReversesEachMutationWithoutSaving` | 15 | 기존1장 → 추가 색 이동 크기 순서 삭제를 수행 후 역 undo → 매번 직전 외형 복원 저장0회 | 한 변이 history 누락 |
| `UndoRemovedSelectedPhotoClearsSelection` | 15 | 추가 사진 선택 → 추가 undo → 선택nil | undo후 존재하지 않는 선택 유지 |
| `UndoRetainsLiteralFirstChangeAfterTwentyUndos` | 16 | 서로 다른 색 변경21회 → undo20회 → 첫 변경 0.01 남고 더 undo불가 | history 21개 유지 또는 19개만 유지 |
| `SelectionAndEqualValuesDoNotConsumeHistory` | 16 | 기존1장과 한 색 변경 → 선택 해제 재선택 같은색 같은배치 → undo1회로 baseline | 선택이나 동일값에 history 생성 |
| `UnknownIDsAreNoOpsIncludingSelection` | 11,13,14,16 | 알려진 사진 선택 → 없는ID 선택 변경 삭제 순서 → 선택 초안 이력 유지 | unknownID 선택 허용 또는 변경 생성 |
| `RestoreDefaultCanBeUndoneAsOneMutation` | 17 | 다른색 사진3장 → 기본복원 후 undo → literal기본색0장 복원 전 외형 undo | 복원이 사진만 지우거나 history 누락 |
| `RestoringAlreadyDefaultIsNoOp` | 16,17 | 기본 초안 → 기본복원 → history없음 | 동일기본 복원이 history 생성 |
| `PristineExitDismissesWithoutSaving` | 19 | 변경없음 → 종료 → dismiss 저장0회 | 모든 종료에 확인 반환 |
| `ContinueEditingPreservesUnsavedDraftAndHistory` | 20 | 미저장색 변경 → 종료확인 계속편집 → 초안과 history 유지 | continue에서 baseline복원 |
| `DiscardRestoresBaselineAndClearsSessionState` | 21 | 미저장변경 선택 실패안내 → 버리기 → baseline와 비활성 초기상태 | discard가 draft selection notice history 잔존 |
| `InactiveSessionRejectsAllDefinedMutationMethods` | 21,22 | 버린 세션 → 모든변경 import save 호출 → draft selection notice유지 savefalse 경계0회 | 한 메서드의 비활성 가드 누락 |
| `ImportBlocksMutationsReimportAndSaveButAllowsSelectionAndExit` | 23 | loader 대기 중 기존 2장과 색 변경 이력 → 변경재입력저장선택종료 요청 → 변경잠금 선택 종료확인 허용 | import 잠금 가드 누락 또는 선택/종료까지 차단 |
| `CompletionDuringConfirmationThenContinue` | 20,21,22 | import중 종료확인 → 확인 중 입력완료 후 Continue → 완료draft유지 | dialog에서 입력취소 또는 완료후 버리기 baseline불복원 |
| `CompletionDuringConfirmationThenDiscard` | 20,21,22 | import중 종료확인 → 확인 중 입력완료 후 Discard → baseline복원 | dialog에서 입력취소 또는 완료후 버리기 baseline불복원 |
| `DiscardIgnoresLateLoaderSuccess` | 22 | await중 → 버린 뒤 늦은 Success → 결과 notice defer상태가 세션 재활성화하지 않음 | await 뒤 generation 검사 또는 defer 보호 누락 |
| `DiscardIgnoresLateLoaderError` | 22 | await중 → 버린 뒤 늦은 Error → 결과 notice defer상태가 세션 재활성화하지 않음 | await 뒤 generation 검사 또는 defer 보호 누락 |
| `DiscardIgnoresLateLoaderCancellation` | 22 | await중 → 버린 뒤 늦은 Cancellation → 결과 notice defer상태가 세션 재활성화하지 않음 | await 뒤 generation 검사 또는 defer 보호 누락 |
| `DiscardIgnoresLateProcessorSuccess` | 22 | await중 → 버린 뒤 늦은 Success → 결과 notice defer상태가 세션 재활성화하지 않음 | await 뒤 generation 검사 또는 defer 보호 누락 |
| `DiscardIgnoresLateProcessorError` | 22 | await중 → 버린 뒤 늦은 Error → 결과 notice defer상태가 세션 재활성화하지 않음 | await 뒤 generation 검사 또는 defer 보호 누락 |
| `DiscardIgnoresLateProcessorCancellation` | 22 | await중 → 버린 뒤 늦은 Cancellation → 결과 notice defer상태가 세션 재활성화하지 않음 | await 뒤 generation 검사 또는 defer 보호 누락 |
| `SaveFailureFallbackKeepsDraftSelectionAndHistory` | 26 | 변경 draft와 선택 → saverfalse → 명시적오류 또는 fallback 안내 draft 이력 선택 유지 | 실패를 성공처리 또는 실패에서 draft/history 초기화 |
| `SaveFailureExplicitKeepsDraftSelectionAndHistory` | 26 | 변경 draft와 선택 → saverfalse → 명시적오류 또는 fallback 안내 draft 이력 선택 유지 | 실패를 성공처리 또는 실패에서 draft/history 초기화 |
| `RetrySuccessUpdatesBaselineClearsHistoryAndNotice` | 26 | 저장 실패한 변경 → 재시도 성공 후 새 변경과 버리기 → 성공 안내상태 historyclear 새 baseline 유지 | 성공 baseline갱신 또는 history/notice 초기화 누락 |

| `DeselectClearsOnlySelection` | 04,16 | 기존 사진 선택 → select(nil) → 선택만 해제하고 외형/history 유지 | nil 선택 무시 또는 history 생성 |

## 정적 초안 검토
입력 중 잠금 테스트는 기존 이력을 만들어 undo 차단도 관찰한다. 비활성 세션과 입력 중 각 변경 직후에 상태를 비교하여 이후 undo/discard가 앞선 잘못된 변경을 덮어 감추지 않도록 했다. saver 후보는 controller draft에서 계산하지 않고 독립 CardStyle 기대값을 사용한다. 이 검토는 텍스트 확인이며 test/compile 실행이 아니다.

## 참조한 파일 전체
- `.dev/codex-feat-card-customization/prd.md`
- `.dev/codex-feat-card-customization/design.md` (최종 계약 보강 부록 우선)
- `.dev/codex-feat-card-customization/reports/testability-draft.md` (이전 조건부 평가; 최종 design이 대체)
- `ios/FocusMateTests/CardStyleTests.swift` (기존 XCTest/변이 주석 스타일)
- `ios/FocusMateTests/CardIssuanceControllerTests.swift` (@MainActor/DI/async 테스트 스타일)
- `ios/FocusMateTests/CardPhotoTestFixtures.swift` (photo 값 fixture만 사용; ImageIO helper 미호출)
- `/Users/bonseung/.codex/plugins/cache/superpowers-marketplace/superpowers/7.0.0/skills/using-superpowers/SKILL.md` (전담 dispatch는 스킬 적용 제외)
- `/Users/bonseung/.codex/memories/MEMORY.md` (W10 관련 빠른 검색, 관련 결과 없음; 계약 근거로 사용하지 않음)
초안 생성 후 읽은 검토 대상은 위 두 draft와 이 report뿐이다.

## 다음 단계
부모가 T2 완료를 확인한 후 실제 RED author로 승격 → 계약 선언/초안 검토 → 실제 타깃에 테스트 반영 → compile 자체 오류 수정 → assertion 실패를 직접 확인한다. 현재 초안은 실패 테스트나 검증 완료를 주장하지 않는다.

## 2026-10-14 최종 종료 계약 반영

최종 design의 `notice·편집·종료 계약`이 “비활성 `requestExit`는 상태 변경 없이 `dismiss`를 반환한다”로 보강되어 이전 NEEDS_CONTEXT 원인은 해소됐다. draft에 `testInactiveRequestExitDismissesWithoutStateChanges`를 별도 추가했다. discard로 비활성화한 뒤 `.dismiss`, baseline draft, nil selection/notice, undo·changes·import·save 비활성 상태, saver 0회를 함께 관찰한다. 기존 45개 테스트의 기대나 강도는 변경하지 않았으며 현재 draft는 **46개**다. 실제 target 승격·컴파일·실행 전이므로 결과 상태는 `READY_FOR_RED_PROMOTION_AFTER_T2_REVIEW`이고 pass/fail은 미확인이다.

### 선언 필요 인터페이스

- `CardCustomizationController.init(card:saver:processor:makeID:)`
- 읽기 상태: `draft`, `selectedPhotoID`, `isImporting`, `isSaving`, `didSave`, `notice`, `hasChanges`, `canUndo`, `canAddPhotos`
- 동작: `selectPhoto`, `setBackground`, `setPlacement`, `moveLayer`, `deletePhoto`, `undo`, `restoreDefault`, `importPhotos`, `requestExit`, `continueEditing`, `discard`, `save`
- `CardCustomizationExitDecision: Equatable`의 `.dismiss`, `.confirmDiscard`
- `CardCustomizationSaving.saveCardStyle(_:forCardID:) -> Bool`, `saveFailure`
- `CardCustomizationNotice`의 `.maximumPhotos`, `.importFailed`, `.partialImport`, `.saveFailed`
- `CardPhotoInput.init(load:)`, `CardLayerDirection.forward/backward`
- T2 값·경계: `CardColor`, `CardPhoto`, `CardStyle`, `CardSnapshot`, `ProcessedCardPhoto`, `CardPhotoProcessing`, `CardPhotoProcessingIssue`, `StorageIssue.writeFailed/notReady`

placeholder, 선언 전용 stub, 테스트 전용 production setter는 요구하지 않는다. `test-double.swift`는 이번 계약 보강에 필요한 변경이 없어 그대로 유지했다.

### 동기 saver 재진입 후속 테스트 제안만 기록

design은 동기 저장 중 중복 저장을 막는다고 명시하므로 saver callback 안에서 `controller.isSaving == true`, 재진입 `controller.save() == false`, 최종 saver 호출 1회를 관찰하는 테스트는 계약 근거가 분명하다. 실제 RED 승격 뒤 별도 경계 케이스 후보로 남긴다. 반면 “저장 중 종료를 막는다”는 문장은 `requestExit()`가 `.dismiss`와 `.confirmDiscard` 중 무엇을 반환해야 하는지 정하지 않는다. enum에 blocked 결과도 없으므로 exit 반환값은 추측하지 않고 테스트를 추가하지 않았다. 이번 준비 단계에서는 saver callback double도 작성하지 않았다.

## 2026-10-14 동기 saver 재진입 경계 추가

명확한 저장 잠금 계약을 `testSynchronousSaverCallbackObservesSavingLockAndBlocksReentrantSave`로 draft에 추가했다. saver callback은 외부 호출을 먼저 1건 기록한 시점에 실행되며, callback 안에서 `isSaving == true`, 중첩 `save() == false`, callback 중·종료 후 saver 호출 총 1회를 검증한다. 외부 저장은 성공하고 `didSave == true`, `isSaving == false`, 독립 literal 편집 외형 유지, 새 baseline으로 `hasChanges/canUndo == false`, `notice == nil`도 확인한다.

`DraftCardSaver.onSave`는 기본 `nil`인 optional `@MainActor` closure다. 기존 테스트 동작은 바뀌지 않는다. 새 테스트는 controller와 saver를 weak capture하고, 중첩 저장 직전에 callback을 nil로 해제하여 잠금 회귀가 있어도 무한 재귀하지 않는다. 실행 뒤에도 callback을 nil로 정리한다. 저장 중 `requestExit` 반환값은 여전히 계약이 특정하지 않으므로 assertion을 추가하지 않았다.

draft 테스트 수는 **47개**다. 실제 target 승격·컴파일·실행은 T2 review 이후 부모 후속 신호 전까지 금지 상태이며, 새 callback이 호출되는지와 실제 RED/PASS는 미확인이다. 선언-only controller가 saver를 호출하지 않으면 callback 관찰값이 nil로 남아 정상 RED가 된다.
