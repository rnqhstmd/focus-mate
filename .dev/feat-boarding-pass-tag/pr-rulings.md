## Rulings
- T2 과잉 구현 정리 — BoardingGeometry.tagAreaSize·cardWidth, BoardingTiming.terminalEntrance·cardEntrance, IssuanceHapticPattern.boardingContact는 focused 테스트 미참조이나 설계서 인터페이스(design. (틀리면: T6 완료 후 미사용이면 제거.)
- review Minor 48건 유예 · MEDIUM 6건 유예 — 2회차 리뷰 Minor 7건과 태스크 리뷰 유예 Minor 41건은 수정하지 않고 Deferred로 올렸다. 보안 MEDIUM 6건은 모두 동작 변경을 동반하거나 미래 기능(W05·카드 교체·W14 실기기)에 걸려 유예했다. (틀리면: reports/review-deferred.md 목록을 W05 착수 전 재검토해 RGR로 처리.)

## Deferred
- [MEDIUM] SnapshotCodec.swift:77-81 — 버린 진행 여정의 원본 사본·사용자 안내 없음(다음 저장 시 덮어씀). W05 착수 전 `.backup` 보관 또는 안내 결정.
- [MEDIUM] AppModel+Boarding.swift:29 / AppModel.swift:49 — 승차 성공 뒤에도 확정값이 남아 재승차로 진행 여정을 덮을 수 있음. W05에서 진도가 생기기 전 정책 결정.
- [MEDIUM] JourneySnapshot.validate — minutes·elapsedSeconds 상한·카탈로그 미존재 id 처리(W05 인계).
- [MEDIUM] cardID == currentCard.id 불변식 — 카드 교체 기능 도입 시 active 처리 정의.
- [MEDIUM] 늦은 commit의 사전조건 실패를 저장소 실패 문구로 낭독(300ms 안 폐기, 도달 극히 어려움).
- [MEDIUM] awaitingRelease가 dragEnded에서만 풀림 — 제스처 시스템 취소 시 한 동작 무시 가능(W14 실기기 확인).
- [Minor] 재리뷰 Minor 7건·태스크 리뷰 Minor 41건 — reports/review-deferred.md 및 reports/t*-review.md 참조
