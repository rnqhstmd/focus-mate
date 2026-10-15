# T6 태스크 리뷰 (reviewer, sonnet, scoped)
SPEC PASS (21/21) · QUALITY FAIL(Important 1 [동작불변]) · Critical 0 · Minor 6(유예)
MUST(하차 후 고립) 확인: contacting 중 백그라운드→복귀, held/fading 중 백그라운드, abandoned 재등장, 정상 finished(멱등), 재태그 모두 요약으로 감 — 갇히는 경로 없음.
Important 1 [동작불변]: R2의 `!exists || 값 != …` / `|| !isHittable` 부정 단언이 느슨함 → R3로 단일 부재 단언 정리(red-writer).
Minor:
1. CardTagScreen focus 진단이 실제 포커스가 아니라 요청 플래그.
2. AlightingSummaryView DEBUG 버튼 검은 44pt 배경(다른 DEBUG 버튼과 같은 히트 테스트 규약 — 유지).
3. AlightingSummaryView finish가 .rejected면 안내 없이 머묾.
4. testAC1_22 route·1~2번째 문장, 하차 태그의 pause/abandon 부재 미단언.
5. testAC1_22·testAC4 실시간 1.7초 의존(flaky 가능).
6. AC-7 카드 번호 부재·AC-23 정류장 목록 접힘 미단언.

## 재리뷰 R1 (T7 리뷰와 함께)
Important 1 → ADDRESSED(3건 모두 긍정 단언 뒤 단일 부재 단언). 새 결함 없음.
