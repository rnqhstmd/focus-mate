# T4 IMPLEMENT (세션)

## 구현 내용
- 신규 `ios/FocusMate/LiveActivityGateway.swift`: `LiveActivityGateway` 프로토콜, `ActivityKitLiveActivityGateway`(activities 필터 .active/.stale, start 동기 try?, update/end Task 발사), DEBUG `RecordingLiveActivityGateway`(entries, activeActivities, lastStartAttributes, count).
- 신규 `ios/FocusMate/JourneyLiveActivitySync.swift`: `init?`(속성 없으면 nil), timerDidChange — running/paused면 activityID 유무로 update/start, arrived면 있을 때만 end.
- 최소 구현: 재사용 정리(reconcile)·중복 억제(SentKey)·startFailed·기록기 failsStart/existing/diagnosticJSON은 T5·T6·T11 RED로 연다.

## GREEN 증거
focused(Sync 8, Policy 20, Parity 4, Display 9) → Executed 41 tests, 0 failures

## REFACTOR 내역
정리 없음

## self-review 결과
AC-1,2,4,5,6,7,8,9 경로 확인. 저장 guard 실패 시 알림 자체가 없어 요청 0(AC-5). 도착 후 activityID nil → 추가 end 없음.

## 우려사항
없음
