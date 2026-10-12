## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 (파일:라인) |
|----|-------|------|
| P1-AC-1 | ✅ | `ios/FocusMate/AppModel.swift:27`, `ios/FocusMate/RootView.swift:50`, `ios/FocusMateUITests/Phase1FlowTests.swift:13` — 무저장·카드만·설정 완료 상태의 진입 분기와 현재 정류장 표시 구현·검증 |
| P1-AC-2 | ✅ | `ios/FocusMate/RootView.swift:24`, `ios/FocusMate/AppModel.swift:61`, `ios/FocusMateUITests/Phase1FlowTests.swift:43`, `:161` — 네 화면 왕복, 상태 보존, 뒤로가기 외 완료 동작 부재 검증 |
| P1-AC-3 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:27`, `:44`, `ios/FocusMateUITests/Phase1FlowTests.swift:72` — 저장 후 동일 UUID 경로로 seed 없이 종료·재실행하여 카드·최초/현재 정류장 복원 검증 |
| P1-AC-4 | ✅ | `ios/FocusMate/LocalSnapshotStore.swift:27`, `:44`, `ios/FocusMate/AppModel.swift:43`, `ios/FocusMateUITests/Phase1FlowTests.swift:91` — 손상·미지원 원본 보존, 저장 실패 시 상태 유지와 실패 안내 구현·검증 |

[Must] 4건 중 4건 충족, [Should] 0건 중 0건 충족.

## 설계 범위 이탈

`design.md:7`의 명시적 파일 목록 밖 변경이 있습니다.

- `scripts/check-ios.py`, `package.json`: 네이티브 검사 실행기 추가와 Python 3 명령 정리.
- `context/README.md`, `docs/CURRENT-STATE.md`, `docs/DEVELOPMENT-PHASES.md`, `docs/MVP.md`, `docs/PHASE-1-FOUNDATION.md`: 기반 구현 범위·실행 근거 안내.

검증·문서 보완에 해당하며 후속 제품 기능 확장은 없습니다. 설계의 변경 파일 목록에 반영할 필요가 있습니다.

## Part 1 판정

**SPEC PASS**

현재 코드와 테스트를 기준으로 확정했습니다. 기존 실행 로그에서도 Unit 15건·UI 11건, 각각 0 failures와 `TEST SUCCEEDED`를 확인했습니다. 테스트는 재실행하지 않았습니다.

이 판정은 P1 이름공간 AC에 한정합니다. 도메인 iOS FR 전체 충족이나 Phase 0 시각 검증 대기 2건 해소를 의미하지 않습니다.

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]

없음.

### Important (1건)

- [ios/FocusMateTests/AppFoundationTests.swift:241](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateTests/AppFoundationTests.swift:241) — 화면 왕복의 무저장 검증에서 `readData`·`writeData`만 대체하고 `createDirectory`는 실제 파일 시스템에 연결했습니다. 탐색 중 잘못된 저장 호출이 추가되더라도 `/unused` 폴더 생성에서 실패하면 writer에 도달하지 않아 `writeCalls == 0`이 통과합니다. 저장 실패도 assertion 대상이 아니므로 이 회귀를 놓칠 수 있습니다. `LocalSnapshotStore.swift:53`의 호출 순서로 확인되는 불완전한 I/O 대체입니다. → **[동작불변]**
  - 권고: `createDirectory`도 카운터로 대체하고 왕복 후 호출 0회 및 `saveFailure == nil`을 검증하십시오. 기존 `/unused` fixture 수정 두 곳과 별개로 남은 경로입니다.
  - **[검증 필요]** `AppFoundationTests/testMainDestinationsRoundTripSynchronouslyWithoutWrites` — 탐색 중 동일 snapshot 저장을 시도하는 변이를 해당 검사가 실제로 잡는지 focused 확인.

### Minor (3건) — 전부 [동작불변], 비차단

- [scripts/check-ios.py:37](/Users/bonseung/Documents/ChatGPT/new/scripts/check-ios.py:37) — focused 입력을 부모 폴더명·확장자로만 검사하고 파일명을 테스트 클래스명으로 사용합니다. 없는 파일이나 클래스명 불일치가 잘못된 `-only-testing` 필터로 전달됩니다. 선택된 테스트가 0건일 때 성공으로 처리될 가능성은 실행 확인이 필요합니다.
  - 권고: 실제 파일 존재를 확인하고 테스트 선택 0건을 실패로 처리하십시오.
  - **[검증 필요]** 존재하지 않는 `ios/FocusMateTests/MissingTests.swift` 입력 시 종료 코드와 실행 건수 확인.

- [ios/FocusMateUITests/Phase1FlowTests.swift:60](/Users/bonseung/Documents/ChatGPT/new/ios/FocusMateUITests/Phase1FlowTests.swift:60), `:136`, `:142` — snapshot 동등성을 JSON 원문 문자열로 비교합니다. 현재 정렬 인코딩에서는 안정적이지만 값이 같은 JSON의 표현 차이에도 결합됩니다. 설계는 진단 JSON을 decode한 뒤 값으로 비교하도록 정했습니다.
  - 권고: 기존 `snapshot(in:)`·`jsonData(_:)`를 사용해 값으로 비교하십시오. 원본 보존 대상인 `test.persistedBytes`의 바이트 비교는 유지하십시오.

- [docs/CURRENT-STATE.md:44](/Users/bonseung/Documents/ChatGPT/new/docs/CURRENT-STATE.md:44), `docs/DEVELOPMENT-PHASES.md:8` — 현재 상태가 초기 UI 8건 기준으로 남아 있습니다. `docs/PHASE-1-FOUNDATION.md:33`의 제품 UI 10건 및 mechanical gate의 전체 26건과 검증 시점이 다릅니다.
  - 권고: 초기 RED/GREEN 8건과 최신 제품 UI 10건·전체 26건을 구분해 갱신하십시오. 전체 리뷰·인수는 완료 전까지 진행 중으로 유지하십시오.

## Part 2 판정

**QUALITY FAIL** — Critical 0건, Important 1건, Minor 3건.

차단 사유는 기존 단위 테스트의 불완전한 I/O 대체입니다. 현재 제품 동작 결함으로 확정한 항목은 없습니다. 기존 AppIntents 경고와 `/unused` fixture 복구를 신규 제품 동작 변경으로 분류하지 않았습니다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 4
  ac_met: 4
  ac_partial: 0
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 0
  minor: 3
```

# 전체 리뷰 2차

## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 |
|----|-------|------|
| P1-AC-1 | ✅ | `AppSnapshot.swift:31`, `AppModel.swift:27`, `RootView.swift:50` — 저장 상태별 진입 분기. `Phase1FlowTests.swift:13,20,31`에서 세 조건과 현재 정류장 확인 |
| P1-AC-2 | ✅ | `AppModel.swift:61`, `RootView.swift:24` — 네 화면 왕복. `Phase1FlowTests.swift:43,161`에서 상태 보존·완료 동작 부재 확인 |
| P1-AC-3 | ✅ | `LocalSnapshotStore.swift:27,44` — 저장·복원. `Phase1FlowTests.swift:72`에서 동일 경로에 seed 없이 종료·재실행하여 세 값 확인 |
| P1-AC-4 | ✅ | `LocalSnapshotStore.swift:27,44`, `AppModel.swift:43`, `RootView.swift:15` — 원본 보호·실패 안내. `Phase1FlowTests.swift:91,107,123`에서 대응 조건 확인 |

[Must] 4건 중 4건 충족, [Should] 0건 중 0건 충족.

## 설계 범위 이탈

이탈 없음. `design.md:7`에 검사 실행기·`package.json`·연결 문서가 반영됐으며, 후속 카드·지도·여행 기능 확장은 없습니다.

## Part 1 판정

**SPEC PASS**

제공된 최신 로그에서 focused Unit 14건, 전체 native 26건, 웹 31건의 실패 0건과 VM 26개 PASS 항목을 확인했습니다. 테스트·빌드는 재실행하지 않았습니다. 판정 범위는 P1-AC-1~4입니다.

## 재리뷰 판정

| 이전 항목 | 판정 | 근거 |
|------|------|------|
| Important — 화면 왕복 fixture의 불완전한 I/O 대체 | **ADDRESSED** | `AppFoundationTests.swift:245`에서 디렉터리 생성을 카운터로 대체. `:260–262`에서 directory/write 호출 0회와 `saveFailure == nil` 검증 |
| Minor — focused 선택 0건의 성공 처리 | **NOT ADDRESSED** | `scripts/check-ios.py:37,39,43` — 파일 존재·실행 건수 검사 없음. MissingTests 로그 `:51,61`에서 0건과 `TEST SUCCEEDED` 확인 |
| Minor — snapshot의 JSON 문자열 비교 | **NOT ADDRESSED** | `Phase1FlowTests.swift:60,136,142` — 원문 문자열 비교 유지 |
| Minor — 공개 문서의 오래된 검사 수 | **ADDRESSED** | `docs/CURRENT-STATE.md:44`, `docs/DEVELOPMENT-PHASES.md:8`, `docs/PHASE-1-FOUNDATION.md:32,38` — 최초 UI 8건과 최신 UI 10건·Unit 14건·smoke 2건 구분 |

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]

없음.

### Important (0건)

없음. 수정된 fixture는 실제 모델의 탐색 동작을 호출하며, 저장 시도가 디렉터리 단계에서 가려지던 경로를 제거했습니다.

### Minor (2건) — 전부 [동작불변], 비차단

- [scripts/check-ios.py:37](</Users/bonseung/Documents/ChatGPT/new/scripts/check-ios.py:37>) — 잘못된 focused 입력이 0건 실행으로 성공할 수 있습니다. 기존 유예 항목이며 이번 전체 26건 실행 증거와는 구분합니다. → [동작불변]  
  권고: 파일·클래스 선택을 검증하고 0건 실행을 실패 처리하십시오.

- [Phase1FlowTests.swift:60](</Users/bonseung/Documents/ChatGPT/new/ios/FocusMateUITests/Phase1FlowTests.swift:60>) 및 `:136,142` — snapshot 비교가 JSON 표현에 결합돼 있습니다. 기존 유예 항목입니다. → [동작불변]  
  권고: decode한 값으로 비교하고, 원본 보존을 검사하는 `test.persistedBytes`는 바이트 비교를 유지하십시오.

새 품질 결함은 발견하지 못했습니다. 보안 보고서의 파일 보존 증거 일반화는 `docs/PHASE-1-FOUNDATION.md:11,34`에서 쓰기 전 주입 실패로 한정됐습니다. 크기·보호 정책과 복구 기능은 `:52–54`에 후속 과제로 남아 있으며, 해결 완료로 판단하지 않습니다.

## Part 2 판정

**QUALITY PASS** — Critical 0건, Important 0건, Minor 2건. 이전 차단 지적은 해결됐고 비차단 유예 2건은 유지됩니다.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 4
  ac_met: 4
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
  minor: 2
```
