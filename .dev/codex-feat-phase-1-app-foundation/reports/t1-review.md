## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 (파일:라인) |
|----|-------|------|
| P1-AC-1 | ✅ | `AppModel.swift:27-39`, `RootView.swift:50-75`, `Phase1FlowTests.swift:13-41` — 무저장·카드만·준비 완료 상태의 세 진입 분기와 표시값 검증 |
| P1-AC-2 | ✅ | `RootView.swift:24-33,67-70`, `Phase1FlowTests.swift:43-69` — 네 화면 진입·기본 뒤로가기·snapshot/저장 바이트 및 출발 상태 불변 확인 |
| P1-AC-3 | ✅ | `LocalSnapshotStore.swift:27-55`, `Phase1FlowTests.swift:72-89,171-174` — 실제 종료 후 동일 UUID/no-seed 재실행과 카드·최초·현재 정류장 복원 |
| P1-AC-4 | ✅ | `LocalSnapshotStore.swift:27-55`, `UITestBootstrap.swift:34-57`, `Phase1FlowTests.swift:91-146` — 손상·미지원 원본 바이트 보존 및 저장 실패 시 메모리·파일 불변과 실패 안내 |

[Must] 4건 중 4건 충족, [Should] 0건 중 0건 충족.

## 설계 범위 이탈

이탈 없음. 변경된 Xcode 프로젝트·scheme, 앱 기반 6개 Swift 파일, 테스트 타깃과 UI 테스트는 `design.md`의 Phase 1 변경 범위에 포함됩니다. MapKit·카드 발급 완료·여행/기록 기능 구현은 없습니다.

## Part 1 판정

- **SPEC PASS**
- 전달된 GREEN 실행 증거는 8 tests / 0 failures / exit 0이며, 지시대로 테스트를 재실행하지 않았습니다.

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]

- 없음

### Important (2건)

- `FocusMateApp.swift:24-32`, `RootView.swift:37-45` — 잘못된 UUID 등으로 `UITestBootstrap` 초기화가 실패하면 `testBootstrap`이 `nil`이 됩니다. 그러나 `test.setupError`는 `if let testBootstrap` 내부에서만 노출되어 준비 실패가 관찰되지 않고, 앱은 일반 저장소 읽기 오류 화면으로 진행합니다. DEBUG 계약의 “시험 준비 실패로 명시 중단”을 충족하지 못하는 경로입니다. → [동작결함]
  - 권고: bootstrap 유무와 독립적으로 setup 오류를 노출하고, 오류가 있으면 `model.loadIfNeeded()` 전에 중단하십시오. 잘못된 UUID/인자 조합을 실행하는 focused UI 테스트도 추가하십시오.

- `Phase1FlowTests.swift:56-61` — 완료 동작 부재 검사가 버튼 라벨에 `"완료"`가 포함되는지만 확인합니다. `"여행 시작"`, `"카드 발급"`, `"저장"` 같은 후속 완료 버튼을 추가해도 테스트가 통과하므로 AC의 단계 경계 회귀를 방어하지 못합니다. → [동작불변]
  - 권고: 각 기본 화면에서 허용되는 사용자 동작 집합을 명시하거나, navigation back 이외의 사용자용 버튼이 없음을 검증하십시오.

### Minor (1건) — 전부 [동작불변], 비차단

- `Phase1FlowTests.swift:63-65` — 뒤로가기를 `navigationBars.buttons.firstMatch`로 선택해 향후 toolbar 버튼 추가 시 순서에 따라 잘못된 요소를 누를 수 있습니다.
  - 권고: 접근 가능한 뒤로가기 이름이나 안정적인 navigation bar 범위 쿼리를 사용하십시오.

## Part 2 판정

- **QUALITY FAIL** — Critical 0건, Important 2건, Minor 1건

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
  important: 2
  important_behavior: 1
  minor: 1
```



# R1 재검토

## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 (파일:라인) |
|---|---|---|
| P1-AC-1 | ✅ 충족 | `AppModel.swift:27-39`, `RootView.swift:50-75`, `Phase1FlowTests.swift:13-41` — 세 저장 상태별 진입 분기와 표시값 검증 |
| P1-AC-2 | ✅ 충족 | `RootView.swift:24-33,67-70`, `Phase1FlowTests.swift:43-69,161-186` — 네 화면 왕복, 상태 불변, 후속 완료 동작 부재 검증 |
| P1-AC-3 | ✅ 충족 | `LocalSnapshotStore.swift:27-41`, `Phase1FlowTests.swift:72-89` — 종료·동일 UUID 재실행 후 카드·최초/현재 정류장 복원 |
| P1-AC-4 | ✅ 충족 | `LocalSnapshotStore.swift:27-55`, `Phase1FlowTests.swift:91-146` — 손상·미지원 원본 보존과 저장 실패 시 메모리·파일 불변 검증 |

[Must] 4건 중 4건 충족, [Should] 0건 중 0건 충족.

## 설계 범위 이탈

이탈 없음. R1의 앱 시작 오류 처리·RootView 진단 노출·UI 테스트 변경은 `design.md:54-86`의 루트/DEBUG bootstrap/UI 테스트 범위에 포함됩니다.

현재 테스트 파일의 Git blob hash는 보고된 `dd5e9f8e892afeff9d26746a7462c890dc482d94`와 일치합니다. 테스트를 재실행하지 않았으며, 제공 로그에서 RED는 9 PASS/1 assertion failure, GREEN은 10 tests/0 failures 및 `TEST SUCCEEDED`를 확인했습니다.

## Part 1 판정

- **SPEC PASS**

## 재리뷰 판정

| 항목 | 판정 | 근거 |
|---|---|---|
| bootstrap 생성 실패 시 setup 오류가 노출되지 않고 load가 진행됨 | ADDRESSED | `FocusMateApp.swift:24-34,48-56`, `RootView.swift:37-46`, `Phase1FlowTests.swift:148-159` — 오류를 bootstrap과 독립 보관·표시하고 load 전에 중단 |
| 완료 문자열만 검사해 다른 후속 동작 버튼을 놓침 | ADDRESSED | `Phase1FlowTests.swift:161-186` — 각 destination에서 내비게이션 뒤로가기 외 전체 버튼이 없음을 검증 |
| `navigationBars.buttons.firstMatch`가 잘못된 버튼을 선택할 수 있음 | ADDRESSED | `Phase1FlowTests.swift:176-183` — 선택 전에 navigation bar 버튼이 정확히 1개이고 앱 전체 버튼 수도 동일함을 검증 |

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]

- 없음

### Important (0건)

- 없음

### Minor (0건) — 전부 [동작불변], 비차단

- 없음

R1 수정 diff에서 새 결함은 발견되지 않았습니다. 추가 Unit 검증 초안과 예정된 전체 native/node gate는 이번 태스크 범위에서 제외했습니다.

## Part 2 판정

- **QUALITY PASS**

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
  minor: 0
```
