# 리뷰 유예 목록 (phase-review 2회차 정본)

## 보안 MEDIUM (유예 — 동작 변경 동반, W05/W14 인계)
- [MEDIUM] SnapshotCodec.swift:77-81 — 버린 진행 여정의 원본 사본·사용자 안내 없음(다음 저장 시 덮어씀). W05 착수 전 `.backup` 보관 또는 안내 결정.
- [MEDIUM] AppModel+Boarding.swift:29 / AppModel.swift:49 — 승차 성공 뒤에도 확정값이 남아 재승차로 진행 여정을 덮을 수 있음. W05에서 진도가 생기기 전 정책 결정.
- [MEDIUM] JourneySnapshot.validate — minutes·elapsedSeconds 상한·카탈로그 미존재 id 처리(W05 인계).
- [MEDIUM] cardID == currentCard.id 불변식 — 카드 교체 기능 도입 시 active 처리 정의.
- [MEDIUM] 늦은 commit의 사전조건 실패를 저장소 실패 문구로 낭독(300ms 안 폐기, 도달 극히 어려움).
- [MEDIUM] awaitingRelease가 dragEnded에서만 풀림 — 제스처 시스템 취소 시 한 동작 무시 가능(W14 실기기 확인).

## Minor (유예)
- 재리뷰 Minor 7: RootView 안쪽 VStack 정렬 frame, mainContent 들여쓰기, testF3 넘기기 방향 의존, CURRENT-STATE 최종 검증 링크(완료 단계에서 생성), 진행 여정 폐기 안내 없음(문서 예외 명시함), 늦은 commit 실패 낭독, awaitingRelease 초기화.
- 태스크 리뷰 유예 Minor 41(전체 리뷰 1회차 목록 11~41 + 신규 1~10): reports/t1·t2·t3·t6·t7·t8-review.md 참조. 주요: 매직 넘버 정리, JourneyServices.live() 반복 생성, UITestHoldGate 래치, 진입 오프셋 중 측정, 1pt 낭독 요소, BoardMap 655KB, 빈 #if DEBUG 블록.
