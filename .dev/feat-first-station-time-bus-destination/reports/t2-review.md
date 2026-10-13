## Part 1: AC 충족 매트릭스 (태스크 범위: 상태 계층)

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-1 (초기 3건, 확인 불가) | ✅ | `StationSearchState.swift:9-10`의 `canConfirm`/`selectedOption`. `StationSearchStateTests.swift:255-261`에서 3건과 선택 없음을 확인 |
| AC-4 (0건, 선택 불가) | ✅ | `StationSearchState.swift:91-95`는 현재 결과에 없는 id를 거부한다. 테스트 `:263-278`은 카탈로그 전체 id를 시도해 거부를 확인한다. "눌러도 저장 없음"은 T3/T4 소관 |
| AC-5 (확인 문구, 활성) | ✅ | `StationSearchState.swift:10`. 테스트 `:280-287`이 "성수역 · 성수사거리 방면에서 출발"과 `canConfirm`을 확인한다 |
| AC-10 (15/360 경계 모델) | ✅ | `JourneyPlanDraft.swift:43-48`은 `JourneyPlanner.clamp`를 쓴다. 테스트 `:116-128`이 14→15, 361→360, 15와 360 허용을 확인한다 |
| AC-11 (25분, 후보 1건, 미선택, needsSelection 문구) | ✅ | `JourneyPlanDraft.swift:39,70`. 테스트 `:138-156`이 25분, 2014 서울숲 입구 5정류장, 미선택, 문구를 확인한다. 2.75km 표기는 T1(JourneyPlanner) 범위 |
| AC-17 (noCandidates 문구) | ✅ | `:24,70`. 테스트 `:158-165` |
| AC-18 (미선택 진행 차단) | ✅ | `:70`. 테스트 `:167-171`이 `isEnabled == false`를 확인한다. 화면 이동 없음은 T3/T6 소관 |
| AC-19 (단일 선택, ready 문구) | ✅ | `:50-54,64-71`. 테스트 `:173-201`이 2014→302 교체, ready의 JourneySelection 값, 문구, 활성을 확인한다 |
| AC-20 (시간 변경 해제, 되돌려도 해제) | ✅ | `:43-48`. 테스트 `:217-226`이 61분의 noCandidates와 60분 복귀 후 needsSelection을 확인한다 |
| FR-3 (선택 항목이 결과에서 빠지면 확인 불가) | ✅ | `StationSearchState.swift:7`의 파생 `selectedOption`. 테스트 `:289-295` |
| FR-8 (같은 버스가 새 시간에도 후보여도 해제) | ✅ | `:46-47`. 테스트 `:228-233`이 60→120분에서 2014번이 남아도 해제됨을 확인한다 |

[Must] 11건 중 11건 충족, [Should] 해당 없음.

## 설계 범위 이탈
이탈 없음. 신규 4개 파일(`StationSearchState.swift`, `JourneyPlanDraft.swift`와 각 테스트)은 설계서 파일 목록과 일치한다. 시그니처도 설계 판단 1과 같다. 테스트 파일명 보완(`StationSearchStateTests`)도 설계 리뷰 권고를 반영했다.

## Part 1 판정
모두 충족 → **SPEC PASS**

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (4건) — 전부 [동작불변], 비차단
- `StationSearchState.swift:7` — 확신 낮은 관찰. `selectedID`는 유지되고 `selectedOption`은 파생값이다. 그래서 선택 후 검색어를 바꿔 항목이 빠졌다가 검색어를 되돌리면 선택이 다시 살아난다. 설계서의 "선택 효과가 사라집니다" 문구와 PRD FR-3은 이 경우를 명시하지 않아 위반은 아니다. 단언 테스트도 없다.
  - 권고: 의도라면 테스트로 고정하고, 아니라면 결과 변경 시 `selectedID`를 비우는 방식으로 정한다.
- `JourneyPlanDraftTests.swift` — 360분에서 `setMinutes(361)`처럼 선택이 있는 상태의 상한 clamp 유지 케이스가 없다. 하한(14→15)만 있다. 같은 `guard clamped != minutes` 분기를 타므로 위험은 낮다.
- `JourneyPlanDraft.swift:50-70` — `choose`, `selectedCandidate`, `proceedState`가 호출마다 `candidates(from:)`를 다시 계산한다. 후보가 최대 3건이라 성능 문제는 없다. 가독성 관점의 관찰이다.
- `JourneyPlanDraftTests.swift:235-238` — `originUnavailable` 테스트는 enum 상수 문구만 확인한다. 실제 도달 경로는 T3(AppModel)에서 검증해야 한다. 이 태스크에서는 결함이 아니다.

[검증 필요] 없음.

## Part 2 판정
Critical 0 + Important 0 → **QUALITY PASS**

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 11
  ac_met: 11
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
  minor: 4
```