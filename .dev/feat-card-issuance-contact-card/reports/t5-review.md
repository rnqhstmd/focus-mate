# T5 태스크 리뷰 (reviewer, sonnet, task-scoped)

SPEC FAIL → 사용자 결정으로 해소 · QUALITY PASS · Critical 0 · Important 0 · Minor 6 (전부 [동작불변], 유예)

## SPEC
- AC-1~7, AC-10, AC-14(UI, rawSeeds↔테스트 리터럴 바이트 일치 확인), AC-16, AC-20, BR-4, BR-6 충족.
- AC-19 ⚠️ 명세 부족: "card.face 하위 장식 0개", "완료 직후 포커스" 자동 단언 없음. 구현 구조(Color.clear 단일 요소 + accessibilityElement 기본 .ignore + artwork accessibilityHidden)는 VoiceOver 관점에서 올바름. 해소는 PRD 보강.
- 처리: 사용자 결정(2026-10-13) — 두 항목을 AC-19M(수동 확인)으로 분리, prd.md 갱신. 재구현 불필요 → spec 재판정 PASS.

## Minor (유예)
1. CardIssuanceView cardOut을 phase 전이 시 리셋하지 않음 (현재 흐름 도달 불가).
2. 동작 줄이기에서 onAppear 전 첫 프레임에 -42 offset/마스크 상태로 그려질 수 있음.
3. 카드 등장 시 무대 높이 6pt→수백pt 레이아웃 점프 — 카드 자리 aspectRatio 예약 권고.
4. card.title/issueError Text에 같은 문자열 accessibilityValue — VoiceOver 중복 낭독 가능성(수동 확인 항목에 포함).
5. UITestIssuanceGate 중복 wait 시 continuation 덮어쓰기, duration 미사용, 불필요한 @Observable (DEBUG, 도달 불가).
6. testAC19 깨짐 명명 주석이 제거된 단언을 여전히 언급, announcements contains만 확인.

## 설계 이탈(허용)
- test.releaseIssuance 위치/구현 변경(히트테스트 사유, DEBUG 한정).
- T2 파일 PassFace.swift 접근성 구조를 T5에서 수정.
