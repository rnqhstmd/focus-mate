# T5 test-author repair

Status: **APPLIED / PARENT VERIFICATION PENDING**

부모가 첫 isolated implementer와 cumulative owned build를 중단하고 test author 수리를 명시 승인한 뒤, production을 읽거나 수정하지 않고 아래 세 test 파일만 좁게 고쳤다. build/test/device/git 작업은 수행하지 않았다. 부모가 19개 test blob hash를 다시 생성하고 UI 12개를 직접 재실행해야 한다.

## 적용한 정확한 변경

### Native alert query ambiguity

`ios/FocusMateUITests/CardCustomizationFlowTests.swift`

- test03의 continue/discard, test06의 continue, test07의 discard 네 호출만 generic `tap`에서 `tapConfirmation`으로 바꿨다.
- `confirmationButton`은 label `변경 내용을 버릴까요?`인 실제 Alert로 먼저 scope한다.
- 그 Alert 안에서 Button role, 정확한 ID, 정확한 label을 모두 적용한다.
  - `cardCustomization.continueEditing` + `계속 편집`
  - `cardCustomization.discard` + `변경 버리기`
- 이 scoped query에서만 `firstMatch`를 사용해 r3 AX tree의 바깥 Button match를 선택한다. 실제 Alert 존재, Button 존재·enabled·hittable을 확인한 뒤 실제 tap을 수행한다.
- generic `FocusMateUIHarness.element`, `control`, `tap`, `reach`와 나머지 unique-ID query는 변경하지 않았다.
- confirmation 이후의 초안, undo, 파일, main 화면, 재진입 기대식은 모두 그대로다.

r3 로그는 하나의 Alert branch 안에서 같은 ID/label Button이 부모/자식으로 중첩 노출된 사실만 보여 준다. 이를 platform의 보편 동작이나 두 개의 독립 product action으로 해석하지 않았다. 이번 수리는 관찰된 native AX wrapper 중복에 한정한 test helper repair다.

핵심 diff:

```diff
-try tap(h, "continueEditing")
+try tapConfirmation(h, "continueEditing", label: "계속 편집")
-try tap(h, "discard")
+try tapConfirmation(h, "discard", label: "변경 버리기")
```

위 치환은 네 native confirmation action에만 적용했고, helper는 exact Alert → exact Button role/ID/label → scoped firstMatch → enabled/hittable → tap 순서다.

### Cold compile unused binding 두 건

`ios/FocusMateTests/CardStyleStorageTests.swift`

```diff
@@ testAC27_PerPhotoLimit
-let original = try Data(contentsOf: url)
+_ = try Data(contentsOf: url)
@@ testAC27_TotalLimit
-let original = try Data(contentsOf: url)
+_ = try Data(contentsOf: url)
```

두 성공 경계 case 모두 초기 snapshot save 직후의 throwing file read를 유지한다. 읽기 실패는 계속 test failure가 된다. candidate save, writes == 1, restart load == candidate 기대식은 변경하지 않았다. `testAC27_PerPhotoAboveLimit`의 line 267 `original`과 line 276 원본 bytes 불변 assertion은 그대로 유지했다. 다른 `original` 선언은 수정하지 않았다.

### Default argument actor-isolation warning

`ios/FocusMateTests/CardCustomizationAppModelTests.swift`

```diff
-private static let cardID = "FM-01234567"
+nonisolated private static let cardID = "FM-01234567"
```

immutable Sendable `String` 상수의 값과 단일 원천을 유지하면서 default argument의 nonisolated 평가 context에서 참조 가능하게 했다. snapshot 기본 ID와 identity 기대식은 바뀌지 않았다.

## 정적 확인

- native confirmation 전용 호출: continue 2곳, discard 2곳.
- generic `tap`/`reach` helper 존재와 내용 유지.
- storage line 243/292만 discarded binding이며 throwing read 유지.
- storage line 267 `original`과 line 276 bytes equality 유지.
- AppModel `cardID` literal과 모든 기대식 유지.

실제 compiler warning 해소, native alert ambiguity 해소, 후속 제품 assertion 결과는 이 단계에서 주장하지 않는다. 부모의 hash 재생성과 direct UI 12-case retry 및 필요한 focused/cold compile이 실행 증거다.
