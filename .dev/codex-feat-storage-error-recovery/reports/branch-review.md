# W13 전체 브랜치 리뷰

검토 입력: `prd.md`, `design.md`, `codemap.md`, `tasks.md`, `branch-diff.txt`, `reports/t3-review.md`. 변경된 운영 4개 파일과 신규 테스트 4개 파일을 실제 체크아웃과 대조했다. 기존 `SnapshotCodec.swift`, `StorageV2Tests.swift`, `AppFoundationTests.swift`도 버전·시작 계약 확인에 사용했다. 테스트 품질 기준은 설치된 gx-tdd의 `testing-anti-patterns.md`와 `frontend-testing.md`다. 테스트를 재실행하거나 운영 소스를 수정하지 않았다.

## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 (파일:라인 또는 PRD 인용) |
|----|-------|------|
| AC-1 | ✅ | `ios/FocusMate/RootView.swift:84-124`가 오류 원인과 재시도·정리를 표시한다. `ios/FocusMate/AppModel.swift:31-58`의 명시적 호출만 복구를 수행한다. `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:15-34`는 오류 4종의 원인·선택지·활성 바이트 및 백업 무변경을 검증한다. |
| AC-2 | ✅ | `ios/FocusMate/AppModel.swift:31-36,76-83`은 동일 store를 재읽어 snapshot과 기존 launchRoute를 복원하며 쓰기를 호출하지 않는다. `ios/FocusMateTests/AppRecoveryTests.swift:21-49,79-104`가 정상·파일 없음 재시도의 결과와 쓰기·삭제 0회를 검증한다. UI의 실제 main 복귀 및 원본 불변은 `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:53-64`가 검증한다. |
| AC-3 | ✅ | `ios/FocusMate/AppModel.swift:84-87`은 최신 StorageIssue와 nil snapshot·빈 path를 반영한다. `ios/FocusMateTests/AppRecoveryTests.swift:52-76`은 corrupt에서 unsupportedVersion으로 바뀐 오류와 쓰기·삭제 0회를 확인한다. `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:38-50`은 오류 화면과 재시도·원본 불변을 검증한다. |
| AC-4 | ✅ | `ios/FocusMate/RootView.swift:90-98`은 초기화 결과, 내부 원본 보존 선행 조건, 확인·취소를 제공한다. `ios/FocusMate/AppModel.swift:39-49`의 확인 진입은 읽기만, 취소는 캡처 해제만 수행한다. `ios/FocusMateTests/AppRecoveryTests.swift:107-132` 및 `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:68-83`이 취소 시 원본 동일·무백업·첫 시작 미전환을 검증한다. |
| AC-5 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:44-81`은 캡처 비교·정상 파일 거부·백업 쓰기·동일 바이트 readback·활성 원본 재비교·삭제·삭제 완료 확인을 수행한다. 성공 후에만 `ios/FocusMate/AppModel.swift:58-64`가 empty/cardEntry로 전환한다. `ios/FocusMateTests/StorageRecoveryTests.swift:38-55`, `ios/FocusMateTests/AppRecoveryTests.swift:213-235`, `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:86-107`이 정확한 백업·활성 부재·새 모델/앱 재시작을 검증한다. 외부 내보내기·공유 동작은 없다. |
| AC-6 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:46-70`은 원본 읽기, 백업 쓰기/readback·불일치 실패에서 삭제 전 종료한다. `ios/FocusMateTests/StorageRecoveryTests.swift:59-173`은 실패별 원본 보존·삭제 0회와 기존 백업 충돌 보호를 확인한다. `ios/FocusMateTests/AppRecoveryTests.swift:240-283`, `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:111-145`가 failed 유지·보존 실패 안내·재시도·첫 시작 미전환을 검증한다. |
| AC-7 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:72-80`은 검증 백업 뒤 원본 변경·삭제 오류·삭제 완료 확인 오류를 성공으로 처리하지 않는다. `ios/FocusMateTests/StorageRecoveryTests.swift:278-368`, `ios/FocusMateTests/AppRecoveryTests.swift:287-337`이 원본 재변경·삭제 throw/no-op·삭제 후 확인 실패에서 검증 백업과 오류 상태 유지를 확인한다. `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:148-163`은 정리 실패 안내와 첫 시작 미전환을 검증한다. |
| AC-8 | ✅ | 변경하지 않은 `ios/FocusMate/SnapshotCodec.swift:18-39`은 Int 헤더를 읽고 1·2만 허용하며 나머지 정수는 unsupportedVersion, 비정수 헤더는 corrupt로 분류한다. `ios/FocusMateTests/StorageV2Tests.swift:25-129,166-173`의 v1/v2·0·3·999·문자열 회귀가 읽기·저장 차단과 바이트 보존을 검증한다. `ios/FocusMateTests/StorageRecoveryTests.swift:255-273,372-413`은 정상 v1/v2 삭제 금지와 오류 버전의 정확한 원본 백업을 검증한다. 음수는 별도 fixture 실행 증거가 없지만 0과 동일한 switch default 분기이며 코드에 음수 예외가 없다. |

[Must] 8건 중 8건 충족, [Should] 0건 중 0건 충족.

## 설계 범위 이탈

기능 범위 이탈 없음. 운영 변경은 설계의 `LocalSnapshotStore`, `AppModel`, `RootView`, DEBUG `UITestBootstrap` 4개다. 설계 초안의 기존 테스트 파일 확장 대신 `AppRecoveryTests`, `RecoveryBootstrapTests`, `StorageRecoveryFlowTests`로 분리한 파일 구성 차이는 `tasks.md:5-11`에 확정되어 있다. 저장 스키마·Codec·웹 운영 파일은 변경하지 않았다.

## Part 1 판정

**SPEC PASS** — PRD AC-1~8의 Given/When/Then 동작을 코드와 테스트로 확인했다. 이 판정을 먼저 확정한 뒤 아래 코드 품질 판정을 수행했다.

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]

- 없음.

### Important (1건) — 항목마다 [동작결함|동작불변] 표기 필수

- **I-1 — 정리 실패 후 재확인·취소하면 실제 삭제와 모순되는 원본 무변경 안내가 다시 표시된다.** `ios/FocusMate/AppModel.swift:41,47-49` 및 `ios/FocusMate/RootView.swift:100-104` — 활성 파일 삭제가 성공했지만 마지막 읽기 확인이 실패하면 store는 cleanupFailed를 반환하고 원본은 이미 없다(`LocalSnapshotStore.swift:78-80`; 이 상태는 `AppRecoveryTests.swift:310-336`에서도 명시적으로 검증됨). 이때 사용자가 저장 데이터 정리를 다시 열면 `requestCleanup()`이 recoveryFailure를 지우고, 취소하면 cleanupSource도 지워진다. RootView는 recoveryFailure가 nil이라는 이유만으로 “기존 데이터는 변경하지 않았어요.”를 다시 표시한다. 최초 정리에서 실제 삭제가 이루어진 사실과 모순된다. → [동작결함]
  - 권고: 일시적 recoveryFailure와 별개로 정리 시도 이력을 유지하거나 무변경을 보장할 수 없는 이후 오류 화면의 기본 안내를 중립적으로 바꾼다. 최초 오류·아직 정리를 시도하지 않은 취소 경로의 기존 원본 보존 안내는 유지할 수 있다.
  - [검증 필요] 삭제 성공 → 삭제 확인 실패 → 새 정리 요청 → 취소의 실제 모델/화면 경로에서 잘못된 무변경 안내가 재등장하지 않는 회귀 검증이 필요하다. 최초 오류 화면의 기존 안내와 이후 다시 시도 경로도 함께 보호한다. 본 리뷰에서는 테스트를 재실행하지 않았다.

### Minor (0건) — 전부 [동작불변], 비차단

- 없음.

테스트는 실제 Codec·저장소·AppModel과 임시 파일을 사용하며, 실패 주입은 파일 I/O 경계에 한정된다. UI 검증은 접근성 식별자·보이는 문구·탭·화면 결과와 디스크 바이트 진단을 사용한다. 스타일 수치나 전체 뷰 스냅샷에 결합하지 않는다. DEBUG 진단은 Release 분기 밖이다. `StorageRecoveryFlowTests.swift:166-188`은 실제 큰 글자 설정 적용을 확인하고 스크롤 후 확인·취소 동작을 검증한다.

## 실행 증거와 검증 한계

- 기존 Mechanical Gate 로그를 읽었다. `mechanical-node-test.log:40-50`에 31 pass/0 fail 및 edge PASS, `mechanical-node-build.log:5`에 패키징 완료가 있다. `mechanical-ios-build.log:55`에 BUILD SUCCEEDED가 있다.
- `mechanical-ios-test.log:331,1541,1551`에 Unit 104·UI 20, 각 0 failures, TEST SUCCEEDED가 있다. 종료 코드 0은 오케스트레이터의 직접 실행 결과로 전달받았다. 이 리뷰가 테스트를 재실행했다는 뜻은 아니다.
- 단일 MainActor 작성자와 await 없는 동기 복구라는 현재 설계 경계에서 검토했다. 최종 비교와 삭제가 파일 시스템 트랜잭션이 아니라는 점, 외부 작성자 경쟁과 전원 손실 내구성을 보장하지 않는 점은 설계에 명시되어 있다.
- 실기기, VoiceOver 실제 포커스 이동, iOS 27 러너는 미검증이다. 현재 자동 증거는 iOS 26.5 시뮬레이터이며 이 잔여 게이트를 완료로 승격하지 않는다.

## Part 2 판정

**QUALITY FAIL** — Critical 0건, Important 동작 결함 1건. I-1 수정 및 재리뷰가 필요하다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 8
  ac_met: 8
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 1
  minor: 0
```
