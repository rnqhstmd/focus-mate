# T5 IMPLEMENT (세션)

## 구현 내용
- `RecordingLiveActivityGateway.init(existing:)` — 이전 실행 잔존 표시 시드.
- `JourneyLiveActivitySync.reconcileOnce()` — 첫 알림에서 1회 `appearPlan` 적용: endIDs 종료, reuseID를 activityID로(재사용 시 update 경로).

## GREEN 증거
focused(Sync 13, Policy 20, Parity 4, Display 9) → Executed 46 tests, 0 failures

## REFACTOR 내역
정리 없음

## self-review 결과
AC-11 화면(도착 + 같은 id 잔존 → reuse 후 arrived 분기에서 end 1), AC-12/13 update 재사용, AC-14 여분 end, AC-15 다른 id end 후 start.

## 우려사항
없음
