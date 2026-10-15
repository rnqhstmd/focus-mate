# T8 태스크 리뷰 (reviewer, task-scoped, sonnet)
SPEC PASS (AC-17·18·19·20·23·숨김 복귀 가정·FR-16) · QUALITY PASS · Critical 0 / Important 0 / Minor 5 (유예)

## Minor
1. DepartureBriefingController:57 — 기본 sleep `try?`라 .task 취소 시 즉시 반환 → 사라지는 뷰에서 남은 문장 건너뛰고 revealStart 가능. `!Task.isCancelled` 가드 권고.
2. JourneyView:165 — scenePhase reset/begin 재시작 연결 UI 테스트 없음.
3. DepartureBriefingUITests:393 — "분" 포함 필터 오탐 가능성.
4. JourneyView:206 — journey.briefing 1pt 표지가 VoiceOver에 "출발 안내"로 읽힐 수 있음.
5. JourneyView — 매직 넘버 인라인.
