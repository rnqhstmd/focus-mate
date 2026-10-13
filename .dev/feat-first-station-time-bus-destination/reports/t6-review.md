## Part 1: AC 충족 매트릭스 (태스크 범위: AC-10, 11, 12, 17, 18, 19, 20, 23 화면 수준)

| AC | 충족도 | 근거 |
|----|-------|------|
| AC-10 | ✅ | `TimeSelectionView.swift:73-76` 휠이 `JourneyPlanner.minuteRange`를 쓰고 `setMinutes`로 바인딩된다. `TimeSelectionUITests.testWheelBoundariesReportFifteenAndThreeSixtyMinutes`와 `testTimeWheelSpike`가 15와 360에서 값이 유지되는지 확인한다. 범위를 벗어나는 값은 휠에 항목이 없어 만들 수 없다. |
| AC-11 | ⚠️ 명세 부족 | 25분, 후보 1건(2014), 선택 없음, 진행 버튼 문구와 비활성은 `testEntryShows...`가 검증한다. 후보 라벨의 "서울숲 입구, 5정류장"도 검증한다. 그러나 화면에 보이는 "2.75km" 문구(`distanceText`)는 UI 테스트에서 단언하지 않는다. 모델 단위 테스트가 다루는지는 이 diff로 확인할 수 없다. |
| AC-12 (대표) | ✅ | `testSixtyToOneTwentyMinutesShowsAllThreeCandidates`가 120분에서 후보 3건과 id 2014, 302, 421을 확인한다. 도착지, 정류장 수, 거리는 대표 범위에서 제외했고 단위 테스트 소관이다. |
| AC-17 | ✅ | `testMinutesWithoutCandidates...`가 17분에서 후보 0건, 문구, 비활성, 탭해도 `screen.time`에 머무는 것을 확인한다. `TimeSelectionView.swift:82-84`에서도 확인된다. |
| AC-18 | ✅ | `testProceedWithoutSelection...`가 60분에서 문구와 탭 후 이동하지 않음을 확인한다. |
| AC-19 | ✅ | `testSelectingCandidateMarksOnlyThatOneAndEnablesProceed`가 2014만 선택되고 302는 선택되지 않으며 "이 여정 준비하기"가 활성인지 확인한다. `TimeSelectionView.swift:121`의 `.isSelected` 트레이트로 구현했다. |
| AC-20 | ✅ | `testChangingMinutesClearsSelectionImmediately`가 61분에서 즉시 후보 0건과 문구를, 60분 복귀 시 선택 해제와 문구를 확인한다. |
| AC-23 (시간 화면) | ✅ | 후보 라벨 "지선 2014번, 성동구민체육센터, 60분, 12정류장"을 확인한다. 진행 버튼 라벨이 있고, 휠에는 접근성 수정자가 없다(`TimeSelectionView.swift:73-76`). 1분 단위는 설계 판단 6의 spike 기준(`testTimeWheelSpike`)으로 충족한다. 실제 VoiceOver 조작은 자동화하지 않았다. 이는 설계서가 허용한 범위다. |
| FR-6 | ✅ | 출발지 이름은 `time.origin`, 방면은 `boundLabel`로 표시한다. 15~360분 범위와 초기값 25를 확인했다. |
| FR-9 | ✅ | 진행 버튼 문구 3종과 차단을 `journeyProceedState`로 구현했고 테스트가 3종을 모두 확인한다. |
| FR-10 (메인에서 시간 선택) | ✅ | `RootView.swift:57-58`에서 `mainMenu`와 `mainMenuTarget`으로 "여행 준비"가 `.time`을 연다. `Phase1FlowTests`에서 기대 화면을 `screen.time`으로 바꿨다. |
| FR-11 (시간 화면 VoiceOver) | ✅ | 후보와 진행 버튼에 라벨이 있고 휠은 시스템 기본을 유지한다. |

[Must] 대표 범위 내 AC는 충족이다. 단 AC-11은 거리 문구 단언이 없는 명세 부족 1건이다. [Should] 해당 없음.

## 설계 범위 이탈
- `RootView.swift:15`에서 `launchState != .ready(.initialStationEntry)`일 때 저장 실패 문구를 숨긴다. 이 변경은 T6 범위가 아니라 검색 화면(T5) 연동이다. 검색 화면이 자체 실패 안내를 갖는다면 의도된 변경으로 보이며, 이탈로 단정하지 않는다. 설계서 판단 4의 메인 메뉴 범위와 어긋나지 않는지 확인이 필요하다.
- 그 외 이탈은 없다.

## Part 1 판정
AC-11의 "2.75km" 문구는 UI 수준에서 검증되지 않지만 구현 자체는 `distanceText`를 렌더링한다. 모델 단위 테스트가 거리를 다루는지 확인이 필요하다. 구현 결함은 아니므로 SPEC PASS로 판정한다. 테스트 보강은 오케스트레이터가 product-owner에게 PRD 보강이나 테스트 추가를 권고하면 된다.

## Part 2: 코드 품질 리뷰

### Critical (0건)
없음.

### Important (1건)
- `TimeSelectionView.swift:113` — 화면에 보이는 문구가 `"\(candidate.minutes) min · ..."`로 영어 "min"이다. PRD QE-2는 쉬운 한국어를 요구한다. 접근성 라벨은 `children: .ignore`와 `accessibilityLabel`로 덮어써서 VoiceOver는 영향이 없지만, 시각 문구는 "25 min"으로 노출된다. 라벨의 "25분"과도 불일치한다. → [동작결함]
  - 권고: "분"으로 바꾸고 UI 테스트에서 화면 문구를 단언한다. 이 단언이 AC-11의 거리 문구 공백도 함께 메운다.

### Minor (4건)
- `Phase1FlowTests.swift:163-166` — 재실행 복원 시나리오에서 "여행 준비" 항목을 `screen.time`으로 바꾸지 않고 삭제했다. 재실행 후 메인 메뉴에서 시간 화면으로 가는 회귀 커버리지가 줄었다. 첫 번째 목록처럼 `screen.time`으로 바꾸는 편이 낫다. 해당 시나리오가 뒤로 가기 등 별도 이유로 제외했다면 이유를 주석으로 남긴다.
- `TimeSelectionUITests.swift:178-179` — 실행 시간 20초 단언은 CI 부하에서 불안정할 수 있다. spike 기준이라 의도적이지만 임계값 상수화를 권한다. `[검증 필요]` 느린 환경에서의 `testTimeWheelSpike` 안정성.
- `TimeSelectionView.swift:108` — 탭 핸들러가 `choose`의 반환값을 `_ =`로 버리고 뷰가 직접 `journeyPlan`을 변경한다. 설계에서 "모델 함수로만 변경"이라면 `AppModel`에 `selectCandidate(_:)`를 두는 편이 일관적이다.
- `TimeSelectionView.swift:76`, `:77` — 휠 높이를 120으로 고정하고 후보 목록을 `ScrollView`에 넣었다. 큰 글자(T8)에서 잘릴 위험이 있으므로 T8에서 확인한다. 이 태스크의 범위 밖이다.

## Part 2 판정
Important 1건으로 QUALITY FAIL.

```yaml
spec_verdict:
  verdict: PASS
  ac_total: 8
  ac_met: 7
  ac_partial: 1
  ac_unmet: 0
  unmet_ids: []
```

```yaml
quality_verdict:
  verdict: FAIL
  critical: 0
  important: 1
  important_behavior: 1
  minor: 4
```

참고: Part 1 산문은 AC-11을 "명세 부족"으로 표기했는데 YAML은 partial 1로 센다. 산문 기준 판정은 SPEC PASS이고, 오케스트레이터는 PRD 보강 권고 사항으로 취급하면 된다.

주요 파일(절대 경로):
- `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/TimeSelectionView.swift`
- `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/RootView.swift`
- `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateUITests/TimeSelectionUITests.swift`
- `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMateUITests/Phase1FlowTests.swift`

## 재리뷰 R1

## 재리뷰 판정

| 항목 | 판정 | 근거 |
|------|------|------|
| 후보 버튼 화면 문구 "N min"이 영어였던 문제 | ADDRESSED | `TimeSelectionView.swift:55`가 `Text("\(candidate.minutes)분 · \(candidate.stops)정류장 · \(candidate.distanceText)")`로 바뀌었다. 파일 안에 "min ·"이 남아 있지 않다. |

오케스트레이터가 이 항목을 `[동작불변]`으로 재분류했다. 상태, 분기, 이동이 바뀌지 않는 문구 변경이라는 판단은 타당하다. 접근성 라벨은 `.accessibilityLabel`로 따로 지정되어 있어 영향이 없다.

AC-11의 "2.75km" 문구는 단위 테스트가 25분 → "2.75km"를 검증한다는 설명을 근거로 명세 부족을 해소한 것으로 받아들인다. 이 단위 테스트는 diff에서 직접 확인하지 못했다.

## Part 2: 코드 품질 리뷰 (수정 diff 기준)

### Critical (0건)
없음.

### Important (0건)
없음.

### Minor (4건, 이전 라운드에서 이어짐, 비차단)
- `Phase1FlowTests.swift:163-166` — 재실행 복원 시나리오에서 "여행 준비" 항목을 `screen.time`으로 바꾸지 않고 삭제했다.
- `TimeSelectionUITests.swift:178-179` — 20초 시간 단언은 느린 환경에서 불안정할 수 있다. `[검증 필요]` 느린 환경에서의 `testTimeWheelSpike`.
- `TimeSelectionView.swift` 후보 탭 핸들러 — 뷰가 `journeyPlan.choose`를 직접 호출하고 반환값을 버린다.
- `TimeSelectionView.swift` 휠 높이 120 고정과 후보 `ScrollView`는 큰 글자(T8)에서 확인이 필요하다.

수정 diff에서 새로 생긴 결함은 없다.

## Part 2 판정
Critical 0, Important 0이므로 QUALITY PASS다.

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
  minor: 4
```

파일: `/Users/bonseung/Documents/ChatGPT/new-w02/ios/FocusMate/TimeSelectionView.swift`