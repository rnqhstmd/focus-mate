## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-16 (소유) | ✅ | `JourneyMapState.swift:57-61`에서 followTapped가 camera를 `.follow`로 설정한다. 테스트는 `JourneyMapStateTests` test6. |
| AC-18 (소유) | ✅ | `JourneyMapState.swift:72-75`의 timerStatusChanged가 camera를 건드리지 않는다. 테스트는 test8. |
| AC-23 (소유) | ✅ | `JourneyMapState.swift:77`의 leave가 시트를 닫는다. 테스트는 test10. |
| AC-13 (초기값·pitch) | ✅ | 초기값은 `JourneyMapState.swift:42-45`, pitch는 `JourneyCameraPolicy` 55°. 테스트는 test1, test18. 2D 입력 경로 없음은 구조상 확인된다. |
| AC-14 (전이) | ✅ | `userMovedCamera` (`:53`). 테스트는 test3. 앱이 버스를 따라 카메라를 옮기는 갱신이 모드를 바꾸지 않는 부분은 T3 컨트롤러 소관이다. |
| AC-15 (전이) | ✅ | followTapped가 true를 반환해 재정렬을 요청한다. 테스트는 test5. 중심을 버스 위치로 두는 부분은 T3 소관이다. |
| AC-19 (기본값) | ✅ | 기본 테마 dark, 정차역 표시 on (`:43-44`). 테스트는 test1. 시트 컨트롤 존재는 UI 소관이다. |
| AC-20 | ✅ | `select(theme:)`. 테스트는 test14. |
| AC-21 | ✅ | `setShowsStops`. 테스트는 test15. |
| AC-22 | ✅ | `:74`의 시트 닫힘과 `toolsEnabled`. 테스트는 test11. |
| AC-24 | ✅ | arrived에서 시트가 닫히고 도구는 활성이다. 테스트는 test12. |
| AC-25 | ✅ | openThemeSheet의 `guard toolsEnabled`. 테스트는 test9. |
| AC-30 (정책) | ✅ | heading 0, `animated = !reduceMotion`. 테스트는 test16. |
| AC-31 (정책) | ✅ | 테스트는 test17. |
| AC-34 (followValue 문구) | ✅ | `JourneyMapDisplay.swift:21`. 테스트는 test20. |
| BR-3, BR-4, BR-5 | ✅ | 상태 머신이 설계서 §3과 일치한다. |

[Must] 전달된 AC 전부 충족. 컨트롤러·UI에 걸친 부분은 T3 이후 소관으로 판단했다.

## 설계 범위 이탈
이탈 없음. 신규 파일 2개와 테스트 파일은 설계서 §2·§3 범위 안이다. JourneyMapDisplay.swift는 T1 산출물에 followValue를 추가한 것이다. `dismissThemeSheet`는 설계서 시그니처에 있고 T5에서 사용한다.

## Part 1 판정
SPEC PASS

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (4건) — 전부 [동작불변], 비차단
- `JourneyMapState.swift:74` — `timerStatusChanged`는 status가 `.running`이 아니면 시트를 닫는다. 설계서는 paused와 arrived만 나열한다. 지금은 Status 케이스가 그 둘과 running뿐이라면 동일하다. 케이스가 추가되면 의도치 않게 시트가 닫힐 수 있다. 확신은 낮다.
- `JourneyMapState.swift:92-93` — pitch 55와 거리 1200은 설계서가 초안값이라 밝힌 상수다. 디자인 스펙으로 확정되면 상수만 갱신해야 한다.
- `JourneyMapStateTests.swift:161` — test6은 초기 상태가 이미 follow라서, 구현이 항상 follow로 만들지 않아도 통과한다. 구현이 토글로 바뀌어도 한 번 누른 결과는 follow이니 이 경우는 잡히지만, "유지"를 확인하는 변별력은 약하다. 반환값 true를 단언하면 보강된다.
- `JourneyMapStateTests.swift` — `dismissThemeSheet`, `openThemeSheet` 후 `select`·`setShowsStops`가 시트 상태에 영향 없음을 확인하는 테스트가 없다. `dismissThemeSheet`는 T5 사용 전까지 테스트 미참조다. `[검증 필요]` 없음.

테스트 품질: mock 사용이 없고 순수 값 타입 상태를 직접 검증한다. 테스트 전용 메서드도 없다. 안티패턴 위반은 보이지 않는다.

## Part 2 판정
QUALITY PASS

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 15
  ac_met: 15
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
