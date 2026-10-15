
## 테스트 동작 불변 정리 (red-writer)
- JourneyLiveActivitySyncTests: makeRigWithLeftovers 삭제, makeRig에 `existing: [LiveActivityHandle] = []`(첫 인자) 추가해 호출부 통합. 기본값 elapsed 0/paused false/autoStart true 동일, saver는 FakeProgressSaver() == results: [] 로 동일.
- `// 깨짐:` 끝의 "(appear 반복: 현재 실패 예상)", "(현재 통과 예상: 회귀 방지)" 제거(AC3, AC19, AC21).
- JourneyTimerObserverParityTests: 111행 주석을 "저장 실패 정지 끝에서 알림을 보내지 않으면 실패"로 축소.
- 실행: Executed 29 tests (Sync 25 + Parity 4), 0 failures, TEST SUCCEEDED.
