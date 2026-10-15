## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-10 | ✅ | `JourneyMapController.swift:36-42`의 `sync`가 타이머 경과만 읽어 위치를 계산한다. 테스트는 `JourneyMapControllerTests` test1이다. 정지 구간에서 위치가 유지되고, 재개 후 `stops[3]`에서 이어지는 것을 단언한다. |
| AC-11 | ✅ | `JourneyCourseProgress.swift:55-60`이 도착 정류장 위치를 반환하고 `isArrived`가 true가 된다. test2가 이를 단언한다. |
| AC-12 | ✅ | `destinationStop`(`JourneyMapController.swift:32`)은 `showsStops`와 무관하다. test3이 정류장 표시를 껐을 때 `visibleStops`가 0개, `routePoints`가 10개, 도착 좌표가 `stops[5]`인 것을 확인한다. |
| AC-13 | ✅ | `init`이 `.follow`와 pitch 55로 시작한다. 2D로 바꾸는 입력 경로가 없다. test4가 확인한다. |
| AC-14 (앱 갱신 부분) | ✅ | `sync`가 `camera`를 바꾸지 않는다. test5가 확인한다. |
| AC-15 | ✅ | `followTapped`가 `retarget`을 호출해 revision이 올라가고 중심이 현재 버스가 된다. test6이 확인한다. |
| AC-17 | ✅ | `sync`는 `.follow`일 때만 `retarget`한다(`:41`). test7이 버스 이동과 카메라 목표 유지를 단언한다. |
| AC-22 | ✅ | `timerStatusChanged`가 시트를 닫고 `toolsEnabled`를 false로 만든다. `sync`에서 이를 호출한다(`:36`). test13이 확인한다. |
| AC-24 | ✅ | test13의 마지막 부분이 도착 시 시트가 닫히고 도구가 활성인 것을 확인한다. |
| AC-27 | ✅ | 컨트롤러가 인스턴스 상태만 쓰고 정적 상태가 없다. test8이 확인한다. |
| AC-28 | ✅ | 컨트롤러가 saver를 갖지 않는다(구조상 보장). test9가 저장 횟수와 타이머 값을 확인한다. |
| AC-30 | ✅ | `JourneyCameraPolicy`가 heading을 0, `animated`를 `!reduceMotion`으로 둔다. test10이 확인한다. |
| AC-31 | ✅ | test11이 확인한다. |
| AC-32 | ✅ | test12가 확인한다. 다만 단언이 약하다(Part 2 참조). |
| BR-2 | ✅ | `position`이 타이머의 경과 초를 읽기만 한다. |
| BR-6 | ✅ | 컨트롤러에 저장자·타이머 의존이 없다. |
| 설계 결정 (`init?`) | ✅ | `JourneyCourseProgress.swift:29-36`에서 저장 도착지와 계산 도착지가 다르면 nil을 반환한다. test16이 확인한다. |

[Must] 전부 충족. [Should] 해당 없음.

## 설계 범위 이탈
이탈 없음. `JourneyCourseProgress.swift`는 T1 파일이고, 이번 diff에서는 `init?` 추가분만 범위로 봤다.

## Part 1 판정
SPEC PASS

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (6건) — 전부 [동작불변], 비차단
- `JourneyMapController.swift:21-25`, `:37-40` — 남은 값 세 개와 위치를 계산하는 4줄이 `init`과 `sync`에 중복된다(DRY). private `refresh(elapsed:)` 하나로 모으면 된다.
- `JourneyMapController.swift:41` — `sync`가 `.follow`이기만 하면 매 호출마다 revision을 올려 카메라 목표를 다시 낸다. 일시정지 중처럼 버스 위치가 안 변해도 그렇다. 뷰가 revision 변화로 카메라를 다시 적용하면 1초마다 불필요한 갱신이 생길 수 있다. 확신은 낮다. 위치가 바뀐 경우에만 `retarget`하는 방안을 검토한다.
- `JourneyMapControllerTests.swift` test9(AC-28) — 컨트롤러가 saver를 아예 갖지 않아 `writes.count` 단언은 어떤 구현에서도 통과한다. 사실상 동어반복이다. 안전망 가치는 낮고, 구조(의존 없음)가 진짜 보장이다.
- `JourneyMapControllerTests.swift` test12(AC-32) — `reduceMotion`은 `JourneyMapState` 밖에 있어서, `on.state == off.state`는 `reduceMotion`을 어떻게 구현해도 통과한다. 상태 동일성과 함께 `cameraTarget` 중 `animated`·`heading`을 제외한 필드(center 등)도 비교하면 더 의미 있다.
- `JourneyMapControllerTests.swift` test1 — 타이머는 `seoulForestGate` 도착 스냅샷으로 만들고 지도는 `forwardJourney`(origin 0)를 쓰는데, 둘이 `CourseJourney.init?`로 연결되어 있지 않다. 두 입력이 어긋난 상태로 통합 동작을 검증하는 셈이다. 같은 스냅샷에서 `init?`로 지도 여정을 만드는 편이 일관된다.
- `JourneyCourseProgress.swift:29-36` — `direction`이 ±1인지 검증하지 않는다. 또 `minutes <= 0`이면 `totalStops`가 0 이하가 된다. 저장 파일은 신뢰 입력이라 현재 위험은 낮다. 알 수 없는 출발 정류장 ID에 대한 nil 테스트도 없다(test15~18은 도착지·분·버스만 다룬다). test15는 `destinationIndex`도 확인하지 않는다.

## Part 2 판정
QUALITY PASS (Minor만 있다)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 14
  ac_met: 14
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
  minor: 6
```
