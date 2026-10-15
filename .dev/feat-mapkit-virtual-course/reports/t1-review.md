## Part 1: AC 충족 매트릭스

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-5 | ✅ | `JourneyCourse.swift:29-49`는 9개 정류장을 `RouteStops.all` 순서대로 만들고, 좌표는 서로 다르며 서울 경계 안에 있다. `closedPath`는 10점으로 닫힌다. 테스트는 `JourneyCourseTests` test1~5다. |
| AC-6 | ✅ | `JourneyCourseProgress.swift:92-108`이 정수 초로 k, 나머지, 선형 보간을 계산하고, `k >= totalStops`이면 도착 정류장에 고정한다. 테스트는 `JourneyCourseProgressTests` test1~3(0, 300, 750, 1500초)이다. |
| AC-7 | ✅ | 역방향은 `direction * k`로 처리한다. `heading`(`:140-145`)은 평균 위도 기준 `atan2`라서 반대 방향이면 180° 차이가 난다. 테스트는 test4, test5이고, 비교 쌍은 `journey(i,1)`과 `journey(wrap(i+1),-1)`이다. |
| AC-8 | ✅ | test6이 360분 여정에서 2700초에 출발 정류장으로 돌아오는지(정방향·역방향 각각), 21600초에 도착하는지, 30000초에 도착 위치에 고정되는지 확인한다. |
| AC-9 | ✅ | test7~9가 5분·6분·8분 버스를 1초 단위로 훑는다. 정류장 좌표 위에 있는 시점이 `e % sps == 0`과 정확히 일치하는지 본다. |
| AC-39 (계산·문구) | ✅ | 남은 정류장은 `:115-117`, 남은 거리는 `:120-126`이고 test10~13이 검증한다. 문구는 `JourneyMapDisplay`와 그 테스트로 확인했다. 화면 노출은 T5 몫이다. |
| BR-1 | ✅ | 좌표는 id를 키로 하는 사전이고, 정류장 사이는 직선이다. |
| BR-2 | ✅ | 정수 초 산술로 정류장 단위 직선 보간을 한다. |
| BR-7 | ✅ | 남은 정류장은 `total − min(total,k)`, 남은 거리는 `(2n+10T)/(20T)`다. |

[Must] 9건 중 9건 충족, [Should] 해당 없음.

### 직접 검증한 항목
- **반올림 공식**
  - 남은 거리는 km 단위로 `n/(100T)`이고, 0.1km 단위로는 `n/(10T)`다. 여기에 half-up을 적용하면 `floor((2n+10T)/(20T))`이고, 이는 구현과 같다.
  - 예) 5정류장 전체 거리 2.75km는 28로 반올림된다.
  - test12의 손계산 값(90초 26, 750초 14, 1000초 9, 1499초 0)도 재계산해 맞았다.
- **heading 정의**
  - 북쪽 0°, 시계 방향, 국지 평면 근사다.
  - `(a+b)/2`는 교환 가능하고 Δlon의 부호만 뒤집히므로, 반대 방향은 부동소수 오차(1e-9) 안에서 180° 차이가 난다.
- **자기 교차**
  - 아홉 좌표로 선분을 직접 따져 봤다.
  - 6→7(성수대교 북단→뚝섬한강공원) 선분은 위도 37.5403 이하에만 있다. 나머지 정류장은 모두 위도 37.5410 이상이라 6→7 선분 위에 올라서지 않는다.
  - 선분끼리도 교차하지 않는다. 6→7과 7→8은 끝점 7을 공유할 뿐이고, 8→0은 짧다.
  - 따라서 AC-9의 "정류장 좌표 위는 경계에서만" 판정에 영향을 주는 중간 통과는 없다.
- **좌표 타당성(상식 수준)**
  - 성수역, 뚝섬역, 서울숲역은 실제 위치와 수십 m 안에서 일치한다.
  - 서울숲 정문과 성수대교 북단은 수백 m 오차 안의 근사다.

## 설계 범위 이탈
이탈 없음. 신규 파일 3개와 테스트 3개뿐이다. `init?(journey:)`와 `followValue`는 설계대로 뒤로 미뤘다.

## Part 1 판정
모두 ✅ → **SPEC PASS**

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (7건) — 전부 [동작불변], 비차단
- `JourneyCourseProgressTests.swift:347` — test12가 `if c.0 != 299`로 299초의 거리 기대값(22)을 건너뛴다.
  - 계산하면 `2.75×1201/1500=2.2018`이라 22가 맞으므로 건너뛸 이유가 없다. 테스트 안의 조건 분기와 죽은 기대값이다.
  - 권고: 분기를 없애고 299초 거리도 검증한다.
- `JourneyCourseProgressTests.swift:296` — 연속성 단언 `step <= maxSegment`는 전 구간 중 최대 길이를 상한으로 쓴다. 1초 간격 이동량은 늘 이보다 훨씬 작아 사실상 실패할 수 없다.
  - 점프 검출은 뒤의 `atStop` 단언이 맡고 있다.
  - 권고: 상한을 `구간 길이 / sps × 2`처럼 조이거나 단언 의도를 주석으로 정리한다.
- `JourneyCourseProgress.swift:90` — `hundredthsKmPerStop = 55`가 `JourneyPlanner.swift:19`의 private 상수와 중복이다. 설계서가 이 중복을 명시했으므로 차단하지 않는다.
  - 권고: 이후 `JourneyPlanner`의 상수를 internal로 열어 공유한다.
- `JourneyCourseProgress.swift:66,128` — `minutesPerStop == 0`이면 0 나눗셈으로 크래시한다. `init?(journey:)`가 T3에서 막을 예정이므로 지금은 확신이 낮은 관찰이다.
  - 권고: T3에서 `minutesPerStop > 0`을 가드한다.
- `JourneyCourseProgress.swift:144` — heading이 이론상 `-1e-15`일 때 `+360`이 `360.0`으로 반올림될 수 있다. 현재 좌표에서는 발생하지 않는다.
  - 권고: 필요하면 `truncatingRemainder` 후 `360`이면 `0`으로 정규화한다.
- `JourneyCourse.swift:30-38` 좌표 일부는 미검증 근사다. 성동구민체육센터(37.5466, 127.0429)와 성수사거리는 설계서도 "T1 확인"이라 적었고, 좌표 근거는 diff에서 확인되지 않는다.
  - 뚝섬한강공원(37.5296, 127.0670)은 사용자가 지정한 값이다. 다만 한강 북안 물가에 걸치는 위치로 보여 지도에서 아이콘이 수면 위에 놓일 수 있다.
  - 권고: 지도 렌더 시점(T2 이후)에 육안으로 확인한다.
- `JourneyMapDisplayTests.swift:469-477` — 라벨 상수와 같은 리터럴을 비교하는 값 복사형 테스트다. PRD가 문구를 계약으로 정했으므로 허용하지만, 가치는 낮다. `CourseJourney`의 명시 `init`(`:70-75`)도 합성 memberwise init과 동일해 중복이다.

## Part 2 판정
Critical 0, Important 0 → **QUALITY PASS** (Minor만 7건)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 6
  ac_met: 6
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
  minor: 7
```
