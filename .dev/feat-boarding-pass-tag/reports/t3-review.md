# T3 태스크 리뷰 (reviewer, task-scoped, sonnet)
SPEC PASS (AC-1·2·4·11·13·20·21·25·26·27·BR-9·메인 라벨) · QUALITY PASS · Critical 0 / Important 0 / Minor 4 (유예)

## Minor
1. AppModel+Boarding.swift:31 — boardJourney에 path.last == .boarding 가드 없음(호출부 T4/T6 보장).
2. startTripFromMain — 메인이 아닌 상태면 폐기 저장 후 open 무시인데 true 반환(실제 도달 어려움).
3. AppModel.swift open 가드 — 승차 후 메인 복귀 시 storedConfirmedPreparation 유지로 open(.board) 재통과 가능(호출부 없음, T6 확인).
4. BoardingModelTests AC-21 — writes.count 불변 단언 없음.
