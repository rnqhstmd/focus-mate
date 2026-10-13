## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-6 (저장값·영역 보존) | ✅ | `AppModel+JourneyStart.swift:33-34`가 `updatingStage`로 카드·여정·기록을 복사한다. 테스트 `JourneyStartModelTests.swift:135-150`이 저장값을 검증한다. |
| AC-7 (저장 후 메인+시간 선택 path) | ✅ | `AppModel+JourneyStart.swift:35`가 `path = [.time]`을 넣는다. `AppModel.swift:55`가 route 변경 시 path를 비운 뒤라서 `[.time]`이 된다. 테스트는 `:153-161`. |
| AC-8 (저장 실패 시 상태 유지·재시도) | ✅ | `guard save(...) else { return false }`가 path 변경 전에 반환한다. 테스트는 `:164-190`. |
| AC-9 / BR-1 (메인에서 재확정 불가, 쓰기 0) | ✅ | `launchState == .ready(.initialStationEntry)` 가드(`:31`). 테스트 `:193-202`가 쓰기 0건을 확인한다. |
| AC-21 (준비 진행·선택값·쓰기 없음) | ✅ | `proceedToPreparation`은 `open(.preparation)`만 부르고 저장하지 않는다. 테스트 `:216-235`가 `JourneySelection`과 쓰기 0건을 확인한다. |
| AC-22 (뒤로 왕복 유지) | ✅ | `journeyPlan`을 `AppModel`이 보관한다(`AppModel.swift:24`). 테스트 `:261-271`. |
| AC-25 (정류장 외 저장 항목 유지) | ✅ | `updatingStage` 복사로 충족한다. 다만 테스트 데이터가 비어 있다(Minor 참고). |
| AC-26 (모델 기본값) | ✅ | 테스트 `:287-292`가 기본 25분과 버스 미선택을 확인한다. |
| BR-2 (미선택 진행 차단) | ✅ | `preparedJourney != nil` 가드(`:42`). 테스트 `:249-258`. |
| BR-5 (1회 저장) | ✅ | 저장은 `save` 호출 한 번뿐이고 테스트가 `writes.count == 1`을 확인한다. |
| FR-10 (mainMenuTarget) | ✅ | `:52`와 테스트 `:319-324`. |
| 사용자 결정 (메인 재진입 시 선택 유지) | ✅ | 테스트 `:274-284`. |
| 설계 결정 (`.originUnavailable`, 연타 1회) | ✅ | `:20`, `:43`. 테스트 `:238-246`, `:305-315`. |

[Must] 전달된 AC 모두 충족. [Should] 해당 없음.

## 설계 범위 이탈
이탈 없음. `AppModel.swift`의 변경은 설계 판단 3이 정한 `case time`, title, `journeyPlan` 세 가지뿐이다.

## Part 1 판정
SPEC PASS

## Part 2: 코드 품질 리뷰

### Critical (0건)

### Important (0건)

### Minor (3건), 전부 [동작불변]
- `JourneyStartModelTests.swift:135-150`, `:123-125` — 카드·진행 여정·기록이 모두 빈 상태로 시드되어 있다. `saved.cards.items.isEmpty` 같은 단언은 `updatingStage`가 이 영역들을 지워도 통과한다. 따라서 AC-6/AC-25의 "보존"을 실제로는 검증하지 못한다. 이 영역에 데이터가 있는 시드로 확정하는 케이스를 추가하면 좋다(red-writer 소관).
- `AppModel+JourneyStart.swift:44` — `proceedToPreparation`이 현재 `path` 위치(`.time`이 `path`에 있는지)는 확인하지 않는다. 지금은 `open`이 메인 상태만 요구해서 문제가 없다. 화면 태스크에서 다른 경로로 호출되면 `path`가 `[.preparation]`만 될 수 있다. 확신이 낮은 관찰이다.
- `AppModel.swift:5` — `Destination.time`이 `CaseIterable`에 포함되므로 `allCases`를 도는 코드가 있으면 `.time`이 노출될 수 있다. 설계는 메뉴를 `mainMenu`로 분리해 대응했다. 다른 `allCases` 사용처는 UI 태스크에서 확인하면 된다.

## Part 2 판정
QUALITY PASS

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 13
  ac_met: 13
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
  minor: 3
```

> 오케스트레이터 메모: Minor 1(영역 보존 시드가 비어 있음)은 현재 CardSnapshot/JourneySnapshot/RecordSnapshot이 값 없는 enum(W00)이라 비어 있지 않은 영역을 만들 수 없어 지금은 강화 불가. W01/W04/W08이 원소 타입을 정의한 뒤 보존 테스트를 강화하도록 인계.
