# T6 태스크 리뷰 (reviewer, task-scoped, sonnet)
SPEC PASS (AC-1·2·3·4·24·26·27·28 노출·메인 라벨·FR-16) · QUALITY PASS · Critical 0 / Important 0 / Minor 6 (유예)

## Minor
1. BoardingPassView:40 — 낭독 전용 1x1 요소가 VStack 첫 자식이라 22pt 여백 추가·VO 포커스 1pt. overlay로 옮기기 권고.
2. BoardingPassView:89 — CTA accessibility3 상한이 의도인지 확인(accessibility5 도달은 T8 U11).
3. BoardingPassView — 티켓 매직 넘버 인라인.
4. BoardingPassView:34 — navigationTitle("")과 Destination.board.title 불일치(시안상 제목 없음 — 의도).
5. PreparationView ~186 — 빈 #if DEBUG 블록 잔존.
6. services T6 미사용 선주입, RootView 기본값 .live()가 init마다 CoreHaptics 생성. AC-2 테스트는 이동 부재만 확인.
