# T7 태스크 리뷰 R1 (reviewer, task-scoped, sonnet)
SPEC FAIL (AC-9 부분: 터치 시 카드 튐 미연결) · QUALITY FAIL · Critical 0 / Important 2 / Minor 8

## Important
1. [동작불변] BoardingTagView init이 뷰 재생성마다 컨트롤러·boarder 생성, finish 변수 캡처 우회와 `_ = finish`.
2. [동작결함] AC-9 튐 없음 — tapBounceCount를 View가 읽지 않음. → 재현 RED 후 fix R2.

## Minor (유예)
1. 진입 오프셋(y+80) 중 측정한 cardRest가 진입 0.5초 안 끌기/활성화에서 어긋날 수 있음.
2. 끄는 중 spring 애니메이션으로 카드가 손가락보다 늦음(R2에서 반영).
3. failed 직후 같은 제스처로 재인식·재낭독 가능(저장 실패 지속 시 반복).
4. terminal .ignore 안 lcdStatus/tagArea — VoiceOver 트리 노출 확인 필요.
5. 낭독 제목 1pt 투명 Text 우회.
6. RootView/FocusMateApp JourneyServices.live() 반복 생성.
7. UITestHoldGate 래치 없음(해제 전 대기 필수).
8. BoardingFlowUITests 조건부 release, AC-5 테스트 정류장 단정 누락.

## 재리뷰 R2
ADDRESSED 2/2 (AC-9 튐 연결, 컨트롤러 1회 생성) + 끄는 중 애니메이션 Minor 반영. SPEC PASS · QUALITY PASS · Minor 3(tapBounces 상태 복제, 튐 매직 넘버, 오프셋 실제 변화 미검증) 유예.
