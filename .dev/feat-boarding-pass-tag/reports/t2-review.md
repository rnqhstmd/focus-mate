# T2 태스크 리뷰 (reviewer, task-scoped, sonnet)
SPEC PASS (AC-3·5·6/7/9·8·10·22·BR-7 충족, 이탈 없음) · QUALITY PASS · Critical 0 / Important 0 / Minor 6 (전부 [동작불변], 유예)

## Minor (유예 → phase-review)
1. BoardingPassContentTests:260 — "긴 쪽으로 정한다" 테스트가 변별력 없음(출발 3자라 max/min 같음).
2. BoardingPassContentTests:201 — late 케이스는 두 타임존 모두 10/14라 타임존 무시를 못 잡음(early가 실제 변별). 이름·주석 정리.
3. BoardingRulesTests:422 — hold 1400 테스트는 상수 확인만. "동작 줄이기와 무관"은 T4에서 증명.
4. BoardingRules.swift — tagAreaSize·cardWidth·terminalEntrance·cardEntrance 아직 미사용(설계 예약), Duration/TimeInterval 혼용.
5. BoardingRules.swift:92 — 카드 폭 ~55pt 미만이면 필요 겹침 높이가 카드 높이를 넘음(현 폭 268에선 해당 없음).
6. IssuanceHapticPattern.boardingContact 검증 테스트 없음(T4에서 사용 시 확인).
