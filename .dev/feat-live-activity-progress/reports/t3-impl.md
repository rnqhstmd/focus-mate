# T3 IMPLEMENT (세션)

## 구현 내용
- 신규 `ios/FocusMate/JourneyLiveActivityPolicy.swift`: `JourneyActivityRequest`, `LiveActivityHandle`, `JourneyLaunchPlan`, `JourneyLiveActivityPolicy`(attributes, request, pausedRequest, appearPlan, launchPlan). launchPlan은 appearPlan을 재사용.

## GREEN 증거
focused(Policy 20, Parity 4, Display 9) → Executed 33 tests, 0 failures

## REFACTOR 내역
launchPlan에서 같은 id 첫 handle 선택·나머지 종료를 appearPlan 재사용으로 통합(중복 제거).

## self-review 결과
설계 시그니처 일치. journey.paused 미참조. 진도 계산 없음(타이머 남은 초·저장 경과만).

## 우려사항
없음 (red report의 "21건"은 실제 20건 — 파일 내 testV15 개수 20)
