# T4 태스크 리뷰 (reviewer, sonnet, scoped)

- Part 1: AC 11건 중 10건 ✅, AC-27 ⚠️(테스트가 빈 경로 1가지만 검증 — 구현 가드는 정확). spec_verdict FAIL(테스트 보강 필요, 재구현 불필요).
- Part 2: Critical 0, Important 0, Minor 3(전부 동작불변·비차단) → QUALITY PASS.
  - Minor 1: AC-14 단일 출처 테스트가 구현식과 같은 식 비교(records 없으면 양쪽 unavailable).
  - Minor 2: AC-14 Mirror 금지어 부분 일치 — 허용 목록 방식이 더 견고.
  - Minor 3: ProfileMenuItem Equatable/CaseIterable 미명시(자동 Equatable, 조치 불필요).
  - 검증 필요: AC-15 writeCalls 절대값 0 단언 — 초기 로드 쓰기가 생기면 취약(Minor).
- 우연 통과 7건 회귀 가드 유지: 타당.
- 처리: AC-27 재현 RED R1(케이스 추가) → 재리뷰. Minor는 유예.

## 재리뷰 R1
- AC-27 ADDRESSED(케이스 추가, 구현이 이미 만족 — 재현 불가). SPEC PASS, QUALITY PASS(Minor 1 비차단).
