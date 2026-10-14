# T5 native alert helper 수리 초안

Status: **DRAFT ONLY — implementer의 19 test blob hash 잠금 유지**

## 관찰된 실패

`t5-impl-ui-r3.log`의 test03/test06/test07 실패는 product assertion RED가 아니라 test query ambiguity다. 실제 AX sparse tree에서 label이 `변경 내용을 버릴까요?`인 하나의 Alert 아래에 같은 ID·label을 가진 Button이 부모/자식으로 중첩 노출된다.

- continue: ID `cardCustomization.continueEditing`, label `계속 편집`
- discard: ID `cardCustomization.discard`, label `변경 버리기`

현재 `FocusMateUIHarness.element`는 `app.descendants(matching: .any)[identifier]`이고 generic `tap`은 이 결과의 frame을 `reach`에서 읽는다. 동일 ID 두 개가 잡혀 single snapshot 조회가 실패한다. 로그가 보여 주는 것은 같은 alert branch의 중첩 match이며, 두 독립 product action이 존재한다는 증거는 없다. platform이 항상 wrapper를 생성한다고 일반화하지 않는다.

## 제안하는 좁은 수리

generic `element`, `control`, `tap`, `reach`는 그대로 둔다. native confirmation의 두 action만 정확한 alert label로 scope하고, 그 안에서 Button role + 정확한 ID + 정확한 label을 모두 적용한 query의 `firstMatch`를 사용한다. 관찰된 tree 순서에서 이는 바깥 Button match를 선택한다. 전역 `firstMatch`나 ID-only 완화가 아니다.

```diff
--- a/ios/FocusMateUITests/CardCustomizationFlowTests.swift
+++ b/ios/FocusMateUITests/CardCustomizationFlowTests.swift
@@ test03 / test06 / test07 native confirmation actions only
-        try tap(h, "continueEditing")
+        try tapConfirmation(h, "continueEditing", label: "계속 편집")
-        try tap(h, "discard")
+        try tapConfirmation(h, "discard", label: "변경 버리기")
@@ helpers
     private func confirmation(_ h: FocusMateUIHarness) throws {
-        XCTAssertTrue(control(h, "continueEditing").waitForExistence(timeout: timeout))
-        XCTAssertTrue(control(h, "discard").exists)
+        XCTAssertTrue(confirmationButton(h, "continueEditing", label: "계속 편집")
+            .waitForExistence(timeout: timeout))
+        XCTAssertTrue(confirmationButton(h, "discard", label: "변경 버리기").exists)
     }
+    private func confirmationButton(
+        _ h: FocusMateUIHarness,
+        _ suffix: String,
+        label: String
+    ) -> XCUIElement {
+        let alert = h.app.alerts
+            .matching(NSPredicate(format: "label == %@", "변경 내용을 버릴까요?"))
+            .firstMatch
+        let buttons = alert.buttons
+            .matching(identifier: helperID(suffix))
+            .matching(NSPredicate(format: "label == %@", label))
+        return buttons.firstMatch
+    }
+    private func tapConfirmation(
+        _ h: FocusMateUIHarness,
+        _ suffix: String,
+        label: String
+    ) throws {
+        let alert = h.app.alerts
+            .matching(NSPredicate(format: "label == %@", "변경 내용을 버릴까요?"))
+            .firstMatch
+        XCTAssertTrue(alert.waitForExistence(timeout: timeout))
+        let button = confirmationButton(h, suffix, label: label)
+        XCTAssertTrue(button.waitForExistence(timeout: timeout))
+        XCTAssertTrue(button.isEnabled)
+        XCTAssertTrue(button.isHittable)
+        button.tap()
+    }
```

실제 적용 시 test03의 두 continue/discard, test06의 continue, test07의 discard 네 호출만 바꾼다. test01의 alert 부재 확인과 그 밖의 모든 unique-ID query는 strict한 기존 helper를 유지한다. 실제 alert·실제 Button을 tap한 뒤 기존 초안/undo/파일/새 세션 기대식을 그대로 실행하므로 제품 행동 검증은 약화되지 않는다.

이 변경은 새로운 제품 기능이 아니라 r3에서 관찰된 AX 중첩을 처리하는 test author helper repair다. implementer gate 이후 부모가 author 수리를 승인하고 동일 focused UI run으로 ambiguity 제거와 후속 제품 assertion을 확인하기 전까지 PASS 또는 GREEN으로 분류하지 않는다.

읽기: `t5-impl-ui-r3.log`의 native alert 관련 slice, `CardCustomizationFlowTests.swift`의 호출/helper, `UITestLaunchSupport.swift`. 쓰기: 본 draft 보고서만. production과 actual tests는 수정하지 않았고 build/test를 실행하지 않았다.
