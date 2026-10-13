# W13 전체 브랜치 재리뷰 — round 2

입력은 `branch-diff-r2.txt`, `reports/review-fix-diff.txt`, 이전 `reports/branch-review.md`, T4 RED/구현/리뷰 보고서 및 통합 `integrated-*.log`다. PRD·설계의 AC 범위는 유지한다. `origin/main`은 `47a2b5f`이며 W08은 이미 main에 포함되어 있다. 현재 체크아웃의 `git diff origin/main -- ios`는 제공된 r2 diff와 diff 문맥의 빈 줄 후행 공백을 제외하면 완전히 일치한다. 실제 코드와 새 테스트를 읽었으며 테스트 재실행·운영 소스 수정은 하지 않았다.

## 재리뷰 판정

| 항목 | 판정 | 근거 |
|------|------|------|
| I-1: 삭제 확인 실패 후 정리 재요청·취소 시 원본 무변경 안내 재노출 | ADDRESSED | `ios/FocusMate/AppModel.swift:25,53-68`은 유효한 확인 guard를 통과한 뒤 I/O 전에 `hasAttemptedCleanup`을 기록한다. `AppModel.swift:32-50`의 재시도·재요청·취소는 그 이력을 초기화하지 않는다. `ios/FocusMate/RootView.swift:100-106`은 구체적 실패가 사라져도 이력이 있으면 중립 안내를 표시한다. `ios/FocusMateTests/RecoveryHistoryTests.swift:11-52`는 실제 삭제 후 확인 읽기 실패와 후속 request/cancel/retry에서도 이력이 유지되는 것을 검증한다. `ios/FocusMateUITests/RecoveryHistoryFlowTests.swift:14-49`는 정리 실패 후 재요청·취소 시 기존 무변경 문구가 재등장하지 않고 저장물과 복구 선택지가 유지됨을 검증한다. |

## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 (파일:라인 또는 PRD 인용) |
|----|-------|------|
| AC-1 | ✅ | `ios/FocusMate/RootView.swift:84-126`이 오류 원인과 두 복구 선택지를 유지한다. `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:15-34`의 오류 4종·무자동실행 회귀는 변경되지 않았다. |
| AC-2 | ✅ | `ios/FocusMate/AppModel.swift:32-37,78-85`가 store를 재읽어 기존 시작 route를 복원한다. `ios/FocusMateTests/AppRecoveryTests.swift:21-49,79-104`의 쓰기·삭제 0회와 정상/파일 없음 복구, `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:53-64`의 main 복귀가 유지된다. |
| AC-3 | ✅ | `ios/FocusMate/AppModel.swift:86-89`의 최신 오류·nil snapshot·빈 경로와 `ios/FocusMateTests/AppRecoveryTests.swift:52-76`의 쓰기·삭제 0회 검증이 유지된다. `RecoveryHistoryTests.swift:48-51`은 정리 실패 후 재시도에서도 최신 unreadable과 이력 보존을 추가 검증한다. |
| AC-4 | ✅ | `ios/FocusMate/RootView.swift:90-98`, `ios/FocusMate/AppModel.swift:40-50`의 확인 안내·읽기만 하는 캡처·취소가 유지된다. `ios/FocusMateTests/AppRecoveryTests.swift:107-132`, `ios/FocusMateUITests/StorageRecoveryFlowTests.swift:68-83`이 원본 동일·백업 없음·첫 시작 미전환을 검증한다. |
| AC-5 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:44-81`의 원본 비교→백업→동일 바이트 검증→재비교→삭제→완료 확인과 `ios/FocusMate/AppModel.swift:60-66`의 성공 후 empty/cardEntry 전환이 그대로다. `StorageRecoveryTests.swift:38-55`, `AppRecoveryTests.swift:213-235`, `StorageRecoveryFlowTests.swift:86-107`의 실제 파일·재시작 검증도 유지된다. |
| AC-6 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:46-70`은 원본 읽기/백업 쓰기/readback/불일치 오류에서 삭제 전 종료한다. `StorageRecoveryTests.swift:59-173`, `AppRecoveryTests.swift:240-283`, `StorageRecoveryFlowTests.swift:111-145`의 원본 보존·오류 유지·첫 시작 미전환 회귀가 유지된다. |
| AC-7 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:72-80`, `ios/FocusMate/AppModel.swift:53-69`, `ios/FocusMate/RootView.swift:100-106,130-136`이 정리 실패를 성공으로 안내하지 않는다. 기존 `StorageRecoveryTests.swift:278-368`와 `AppRecoveryTests.swift:287-337`의 검증 백업 보존에 더해 새 `RecoveryHistoryTests.swift:11-52` 및 `RecoveryHistoryFlowTests.swift:14-49`가 후속 복구 동작에서도 잘못된 원본 무변경 보장을 막는다. |
| AC-8 | ✅ | `ios/FocusMate/SnapshotCodec.swift:18-39`의 v1/v2 허용·나머지 정수 미지원·비정수 corrupt·v2 쓰기 계약은 W13에서 변경되지 않았다. `ios/FocusMateTests/StorageV2Tests.swift:25-129,166-173`과 `StorageRecoveryTests.swift:255-273,372-413`의 정상 파일 보호·버전 경계·원본 보존 회귀가 유지된다. 음수 전용 fixture가 없다는 이전 증거 한계도 동일하며 음수는 0과 같은 default 분기로 거부된다. |

[Must] 8건 중 8건 충족, [Should] 0건 중 0건 충족.

## 설계 범위 이탈

이탈 없음. I-1 수정은 AppModel의 사용자 안내용 상태 1개와 RootView의 기본 안내 분기, 이를 보호하는 단위·UI 테스트에 한정된다. W13 운영 변경은 기존 4개 파일이며 저장 스키마·외부 공유·웹 기능을 추가하지 않았다. 이미 main에 있는 W08 기록·메모 기능은 이번 변경사항으로 계산하지 않았다.

## Part 1 판정

**SPEC PASS** — AC-1~8 모두 충족한다. 이 판정을 확정한 뒤 Part 2 품질 판정을 수행했다.

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]

- 없음.

### Important (0건) — 항목마다 [동작결함|동작불변] 표기 필수

- 없음. 이전 I-1은 ADDRESSED다.

### Minor (0건) — 전부 [동작불변], 비차단

- 없음.

`hasAttemptedCleanup`은 운영 화면의 잘못된 데이터 보존 보장을 막는 상태다. 초기값 false이며 실제 확인 guard 뒤에서만 true가 되므로 최초 오류·확인하지 않은 취소·loading/ready의 무효 확인은 기존 동작을 유지한다. 성공이나 실패의 세부 결과를 이력 값으로 대체하지 않으며 저장소의 백업·삭제 순서에도 영향을 주지 않는다.

새 테스트는 실제 AppModel·LocalSnapshotStore·임시 파일을 사용하고, 읽기 실패만 파일 I/O 경계에서 주입한다. UI 회귀는 화면 문구·사용자 탭·복구 선택지·실제 저장 바이트를 검증한다. 단위 테스트의 삭제 후 확인 실패 경로와 UI 테스트의 삭제 자체 실패 경로를 구별해 읽었으며, 두 경로가 공유하는 `hasAttemptedCleanup`과 동일 RootView 분기가 I-1을 차단한다. UI 테스트가 실제 삭제 후 확인 실패까지 직접 주입했다고 과장하지 않는다.

W08 통합 상호작용도 확인했다. `ios/FocusMate/AppModel.swift:114-152`의 기록 완료·메모 편집은 준비된 snapshot을 요구하므로 시작 오류 상태에서 복구 대상을 수정하지 않는다. 실제 저장은 `AppModel.swift:94-109`의 `!isRecovering` guard를 거친다. 성공 복구는 전체 `.empty`를 사용하고 정상 재시도는 decode된 전체 snapshot을 복원하므로 기존 기록/메모 영역을 별도로 재구성하거나 유실시키는 새 코드가 없다. 현재 단일 MainActor·동기 호출 경계에서 W13과 W08 사이의 새 충돌을 발견하지 않았다.

## 실행 증거와 한계

- `integrated-node-test.log:40-50`: 31 pass, 0 fail, edge assertions PASS 및 Findings 없음. `integrated-node-build.log:5`: 패키징 완료.
- `integrated-ios-build.log:310`: BUILD SUCCEEDED.
- `integrated-ios-test.log:781,2067,2077`: Unit 141건·UI 21건, 합계 162건 0 failures 및 TEST SUCCEEDED. 종료 코드 0과 22:39 KST 완료는 오케스트레이터의 직접 실행 증거로 전달받았다.
- `t4-red.log:580-583,662`의 이력·문구 assertion 실패와 `t4-green.log`의 성공 종료를 읽었다. 리뷰 자체에서 테스트를 실행하지 않았다.
- T1/T2/T3의 테스트 4개는 저장된 git object hash와 일치한다. 신규 T4 테스트 2개도 RED 보고서의 SHA-256과 일치한다. 합계 6개 테스트 파일에서 검증 후 수정 흔적을 발견하지 않았다.
- 최종 비교/삭제의 비트랜잭션성, 외부 작성자 경쟁·전원 손실 내구성의 비보장 경계는 그대로다. 실기기·VoiceOver 실제 포커스 이동 및 iOS 27 러너의 별도 검증 한계를 이 리뷰로 해소했다고 주장하지 않는다.

## Part 2 판정

**QUALITY PASS** — Critical 0건, Important 0건, Minor 0건. 이전 차단 항목 I-1은 해결되었다.

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
  verdict: PASS
  critical: 0
  important: 0
  important_behavior: 0
  minor: 0
```
