# T6 IMPLEMENT (세션)

## 구현 내용
- `RecordingLiveActivityGateway.failsStart` — true면 start가 nil, 시도(activityID nil)만 기록.
- `JourneyLiveActivitySync`: `SentKey(status, pausedRemainingSeconds)` 중복 억제(activityID 있을 때 같은 키면 update 생략), `startFailed`(start nil이면 세션 동안 모든 요청 중단).
- 테스트 결함 1건(AC22 기대 개수 10→9)은 red-writer 재호출로 보정(보정 R1), 테스트 기준선 해시 갱신.

## GREEN 증거
focused(Sync 25, Policy 20, Parity 4, Display 9) → Executed 58 tests, 0 failures. RED 단계 실패: AC3·AC17·AC18(+AC22 테스트 결함)

## REFACTOR 내역
Sync 파일 정리(SentKey 사설 타입, 상태 프로퍼티 주석). 동작 변경 없음.

## self-review 결과
AC-20 저장 실패 정지 → halt 알림 → paused 키가 running과 달라 update 1. AC-24 leave running → paused update 1. AC-25 paused/arrived leave는 알림 없음.

## 우려사항
없음
