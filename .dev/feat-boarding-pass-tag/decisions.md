
## 2026-10-15 09:09 · Ruling: T2 과잉 구현 정리

**판정.** BoardingGeometry.tagAreaSize·cardWidth, BoardingTiming.terminalEntrance·cardEntrance, IssuanceHapticPattern.boardingContact는 focused 테스트 미참조이나 설계서 인터페이스(design.md 8항)에 명시되어 "설계 예약"으로 유지.
**근거.** T6 화면·T4 컨트롤러에서 사용 예정.
**틀리면.** T6 완료 후 미사용이면 제거.

## 2026-10-15 12:27 · Ruling: review Minor 48건 유예 · MEDIUM 6건 유예

**판정.** 2회차 리뷰 Minor 7건과 태스크 리뷰 유예 Minor 41건은 수정하지 않고 Deferred로 올렸다. 보안 MEDIUM 6건은 모두 동작 변경을 동반하거나 미래 기능(W05·카드 교체·W14 실기기)에 걸려 유예했다.
**근거.** phase-review 판정 기본값(Minor 유예, 동작 변경 MEDIUM 유예). 보안 재감사 판정 "배포 차단 사유 없음".
**틀리면.** reports/review-deferred.md 목록을 W05 착수 전 재검토해 RGR로 처리.
