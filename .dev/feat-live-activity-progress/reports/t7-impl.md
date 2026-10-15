# T7 IMPLEMENT (세션)

## 구현 내용
- 신규 `ios/FocusMate/JourneyLiveActivityCleanup.swift`: `atLaunch(gateway:journey:)` — launchPlan의 endIDs 종료 후 pausedUpdate 갱신. start 없음.

## GREEN 증거
focused(Cleanup 6, Sync 25, Policy 20, Parity 4, Display 9) → Executed 64 tests, 0 failures

## REFACTOR 내역
정리 없음

## self-review 결과
end → update 순서(설계 7절). 규칙은 Policy에 있고 여기선 적용만.

## 우려사항
없음
