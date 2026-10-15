# Deferred (phase-review R1)
- [Minor] M1 AC-29 전체 회귀는 complete의 verify 전체 실행에서 확정
- [Minor] M4 JourneyLiveActivityPolicy.appearPlan 튜플 vs launchPlan 구조체 표현 불일치
- [Minor] M6 재실행 후 화면 진입 시 같은 paused update가 한 번 더 나감(앱 시작 정리 + Sync lastSent nil)
- [Minor] M7 기록기가 비활성 id에 대한 update/end도 기록 — 잘못된 순서를 count 외에는 못 잡음
- [Minor] M8 AC-31 테스트가 CourseJourney == nil 전제를 단언하지 않음
- [Minor] M9 설계 수정 표 밖 문서(context/journey/status.md) 변경 — PR 설명에 명시
- [Minor] M10 Sync now 기본값 Date() — UI 테스트 수동 시계와 무관(값 단언 없음)
- [MEDIUM] 앱 시작 정리와 화면 진입 정리의 중복 카드 선택 경합(비동기 end) — 동작 변경 동반, 후속
- 태스크 리뷰 유예 Minor: reports/t1,t4,t5,t6,t9,t11-review.md
