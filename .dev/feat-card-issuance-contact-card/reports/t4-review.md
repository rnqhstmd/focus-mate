# T4 태스크 리뷰 (reviewer, sonnet, task-scoped)

SPEC PASS (AC-5/17/18/19 로직) · QUALITY PASS · Critical 0 · Important 0 · Minor 6 (전부 [동작불변], 유예)

## Minor (유예)
1. IssuanceFeedback.swift stopped/reset handler — 엔진 동일성 비교 없이 nil 처리(옛 엔진의 늦은 콜백이 새 엔진 해제 가능, 확률 낮음). 권고: `self?.engine === engine` 비교.
2. 같은 handler — [검증 필요] 임의 큐 호출 시 MainActor 격리 상속 클로저. Swift 6 런타임 격리 검사 시 trap 가능성. 현재 프로젝트는 Swift 5 / strict concurrency minimal(project.pbxproj:54)이라 런타임 격리 trap 대상 아님 — 오케스트레이터 확인. `@Sendable` 명시 권고.
3. engine.start() 동기 호출이 MainActor를 잠깐 막음(startAndReturn 대안). 실패 시 재시도 없음(설계 일치).
4. CardIssuanceController private let의 @ObservationIgnored 중복.
5. SuspendingSleep 이중 sleep 시 continuation 덮어쓰기 누수, AC-18(b) 위반은 hang으로 나타남 — XCTFail·타임아웃 보강 권고.
6. slotAnimation 사용처 아직 없음(T5 예약).
