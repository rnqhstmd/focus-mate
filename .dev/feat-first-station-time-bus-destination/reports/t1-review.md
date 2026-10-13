## Part 1: AC 충족 매트릭스

대상은 T1의 AC-2, 3, 12~16, AC-11·17의 후보 계산 부분, AC-23의 후보 레이블 문자열입니다. 테스트는 재실행하지 않았습니다. 각 AC의 기대값을 `RouteData.swift`와 `JourneyPlanner.swift` 로직으로 직접 손계산해 확인했습니다.

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-2 | ✅ | `StationCatalog.search`는 이름·방면 문구·별칭 각각을 부분 일치로 봅니다(RouteData.swift diff 113-127행). 별칭은 웹 값과 같습니다(115-117행). "서울숲"은 성수역 정방향(별칭)과 서울숲역(이름) 2건입니다. "건대"는 성수역 역방향 1건, "성수"는 3건입니다. 테스트는 StationCatalogTests 274-291행입니다. |
| AC-3 | ✅ | trim과 lowercased 처리(122행), 빈 검색어는 전체 반환(123행)입니다. "성수사거리"는 성수역 역방향의 방면 문구에만 일치해 1건이고, 공백만 있는 검색어와 빈 검색어는 3건입니다. 테스트는 293-304행입니다. |
| AC-11 (후보 계산) | ✅ | 성수역 정방향 25분은 2014번 1건입니다. 5정류장 → 인덱스 5 → 서울숲 입구, 275/100이라 "2.75km"입니다. 테스트는 JourneyPlannerTests 212-216행입니다. |
| AC-12 | ✅ | 24정류장은 인덱스 6(성수대교 북단)에 "13.2km", 20정류장은 인덱스 2(뚝섬역)에 "11km", 15정류장은 인덱스 6에 "8.25km"입니다. 후보 순서도 2014번, 강남02번, 343번입니다. 테스트는 170-176행입니다. |
| AC-13 | ✅ | 24분은 5로 나누어떨어지지 않아 2014번이 빠집니다(`minutes % minutesPerStop`). 강남02번은 4정류장·서울숲역·2.2km, 343번은 3정류장·성동구민체육센터·1.65km입니다. |
| AC-14 | ✅ | 15분은 2014번만 3정류장·성동구민체육센터·1.65km입니다. 360분은 72정류장(인덱스 0, 성수역, 39.6km), 60정류장(인덱스 6, 성수대교 북단, 33km), 45정류장(인덱스 0, 성수역, 24.75km)입니다. |
| AC-15 | ✅ | 역방향 60분에서 12정류장은 wrap(-12)=6이라 성수대교 북단, 10정류장은 wrap(-10)=8이라 성수사거리입니다. 거리는 6.6km와 5.5km이고, 343번은 60%8≠0이라 제외됩니다. |
| AC-16 | ✅ | 서울숲역(인덱스 4)에서 12정류장은 인덱스 7(뚝섬한강공원), 10정류장은 인덱스 5(서울숲 입구)입니다. 테스트는 206-210행입니다. |
| AC-17 (후보 계산) | ✅ | 17분은 5, 6, 8 어느 것으로도 나누어떨어지지 않아 빈 배열입니다. 범위 밖 14분과 361분도 `guard minuteRange.contains`로 빈 배열입니다. |
| AC-23 (후보 레이블) | ✅ | `accessibilityLabel`은 `"\(kind) \(number)번, \(destination), \(minutes)분, \(stops)정류장"`입니다. 60분·성수역 정방향·2014번은 12정류장·인덱스 3이라 "지선 2014번, 성동구민체육센터, 60분, 12정류장"이 됩니다. 테스트는 244-247행입니다. |

[Must] 대상 AC 9건 중 9건 충족. [Should] 해당 없음.

## 설계 범위 이탈
- 설계서 외 파일 수정은 없습니다. 변경은 신규 4파일(RouteData.swift, JourneyPlanner.swift, JourneyPlannerTests.swift, StationCatalogTests.swift)뿐입니다.
- 설계서 "판단 1"의 `JourneyPlanner.swift` 블록에 있는 `JourneySelection`이 diff에 없습니다. T1의 AC가 쓰지 않는 타입이고 `ProceedState.ready`와 `preparedJourney`가 쓰므로 T2/T3에서 추가하는 편이 자연스럽습니다. 이탈로 보지 않고 인계 사항으로만 적습니다.

## Part 1 판정
모두 ✅ → **SPEC PASS**

## Part 2: 코드 품질 리뷰

### Critical (0건) — 전부 [동작결함]
- 없음

### Important (0건) — 항목마다 [동작결함|동작불변] 표기 필수
- 없음

### Minor (4건) — 전부 [동작불변], 비차단
- JourneyPlannerTests.swift:238-242 — `distanceText` 테스트에 소수 둘째 자리 앞 0 패딩 분기(`%02d`)를 타는 케이스가 없습니다. 11정류장(605 → "6.05km")이 그 경우입니다. 구현은 맞게 계산되지만 분기가 회귀 보호를 받지 못합니다.
  - 권고: `distanceText(stops: 11) == "6.05km"` 단언을 추가합니다.
- JourneyPlannerTests.swift:249-253 — `BusLine.id`(내부 코드 "2014", "302", "421")를 검증하지 않습니다. 이 id는 `JourneyCandidate.id`와 후속 태스크의 `time.candidate.<bus.id>` 식별자·선택 키로 쓰입니다. 확신이 낮은 관찰이며, 후속 UI 테스트가 식별자로 간접 검증합니다.
  - 권고: `BusLine.all.map(\.id) == ["2014", "302", "421"]` 단언을 추가합니다.
- JourneyPlanner.swift:44 — `String(format: "%02d", fraction)` 때문에 이 파일이 Foundation에 의존합니다. 정수 연산 설계 의도와는 맞지만 `fraction < 10 ? "0\(fraction)" : "\(fraction)"`로 대체할 수 있습니다. 취향 수준입니다.
- RouteData.swift:104 — `StationOption.init`이 `RouteStops.all[index]`를 범위 검사 없이 접근합니다. 내부 정적 카탈로그만 호출해 현재는 안전합니다. 외부에서 생성하게 되면 크래시 가능성이 있습니다. 확신 낮은 관찰입니다.

참고로 decisions.md의 T1 Ruling을 diff와 대조했습니다. 뼈대 상태에서 통과한 3건(17분, 14/361분, 미지 id → nil)은 "없음"이 기대값인 경계 케이스입니다. 이를 회귀 가드로 유지하는 판단은 타당해 지적하지 않습니다. 테스트가 모의 동작을 검증하거나 테스트 전용 메서드를 쓰는 안티패턴은 보이지 않습니다. `StationOption.snapshot`은 T3에서 쓰는 운영 코드 경로입니다.

## Part 2 판정
Critical 0 + Important 0 → **QUALITY PASS** (Minor 4건, 비차단)

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 9
  ac_met: 9
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