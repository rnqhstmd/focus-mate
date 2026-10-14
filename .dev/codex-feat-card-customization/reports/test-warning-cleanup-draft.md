# CardStyleStorageTests 경고 정리 초안

Status: **DRAFT ONLY — T5 locked gate 이후 부모 승인 대기**

Cold compile이 신규 경고로 보고한 `CardStyleStorageTests.swift:243`과 `:292`를 기계적으로 확인했다. 두 위치의 `original` 상수는 이후 기대식에서 사용되지 않는다. 반면 같은 파일의 line 267 `original`은 line 276에서 실패 뒤 원본 bytes 불변 검증에 사용되므로 변경 대상이 아니다.

제안 patch는 아래 두 줄뿐이다.

```diff
--- a/ios/FocusMateTests/CardStyleStorageTests.swift
+++ b/ios/FocusMateTests/CardStyleStorageTests.swift
@@ testAC27_PerPhotoLimit
-            let original = try Data(contentsOf: url)
+            _ = try Data(contentsOf: url)
@@ testAC27_TotalLimit
-            let original = try Data(contentsOf: url)
+            _ = try Data(contentsOf: url)
```

이 치환은 초기 snapshot save 직후 파일을 실제로 읽고, 읽기 실패를 test failure로 전파하는 throwing read를 그대로 유지한다. 성공 경계의 후보 저장, write count 1, 재시작 load와 candidate 동등성 기대식은 변경하지 않는다. `PerPhotoAboveLimit`의 원본 bytes 보존 기대식과 다른 미사용 변수는 건드리지 않는다.

이번 단계에서는 실제 test 파일·production을 수정하지 않았고 build/test를 실행하지 않았다. 부모가 T5 locked gate 이후 승인하면 위 두 치환만 적용하고 focused test와 cold compile 경고 재측정으로 닫아야 한다.

읽은 파일:

- `ios/FocusMateTests/CardStyleStorageTests.swift` lines 225–305
- `.dev/codex-feat-card-customization/reports/warnings-baseline-evidence.md`

쓴 파일: 본 draft 보고서만.

## T5 implementation r2 추가 경고 분석

Status: **DRAFT ONLY — 19 test blob hash 잠금 유지**

`t5-impl-ui-r2.log`에서 새 test compiler warning은 다음 한 파일·한 선언뿐이다. 동일 diagnostic이 module emission과 compile 과정에서 두 번 인쇄되었지만 고유 원인은 하나다.

- `ios/FocusMateTests/CardCustomizationAppModelTests.swift:15:101`: `@MainActor` test class의 static `cardID`를 default argument의 nonisolated context에서 참조함. Swift 6 language mode에서는 error가 될 예정인 actor-isolation warning.

제안 patch:

```diff
--- a/ios/FocusMateTests/CardCustomizationAppModelTests.swift
+++ b/ios/FocusMateTests/CardCustomizationAppModelTests.swift
@@
-    private static let cardID = "FM-01234567"
+    nonisolated private static let cardID = "FM-01234567"
```

`cardID`는 immutable `String`이며 `String`은 Sendable이므로 상수를 `nonisolated`로 노출하는 것이 default argument의 실행 격리와 맞는다. 값, snapshot 기본 ID, 모든 identity 기대식은 그대로 유지된다. default argument에 동일 literal을 한 번 더 복제하는 대안보다 기대값의 단일 원천도 유지한다.

`t5-impl-ui-r2.log` warning inventory:

- `ios/FocusMateTests/CardCustomizationAppModelTests.swift`: 신규 test compiler warning 1개 원인(로그 2회 인쇄).
- `ios/FocusMate/CardIssuanceView.swift`: 기존 cold baseline actor warning이며 test warning 신규 목록에서 제외.
- AppIntents metadata extraction skipped: SDK/tooling warning이며 test source compiler warning이 아님.
- `JourneyStartModelTests.swift`: 이 r2 로그에는 인쇄되지 않았고, 지시대로 기존 baseline에서 신규로 재분류하지 않음.
- 앞서 확인한 `CardStyleStorageTests.swift`의 unused `original` 두 건도 이 incremental r2 로그에는 인쇄되지 않았다. cold compile에서 확인된 별도 미해결 제안으로 위 절에 유지한다.

이번 추가 분석에서도 actual test와 production을 수정하지 않았고 build/test를 실행하지 않았다. 읽은 추가 자료는 허용된 `CardCustomizationAppModelTests.swift` 선두 선언부와 `t5-impl-ui-r2.log`의 warning 행뿐이며, 쓴 파일은 본 draft 보고서뿐이다.
