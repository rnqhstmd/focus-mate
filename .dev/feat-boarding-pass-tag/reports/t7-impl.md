# T7 IMPLEMENT — 승차 태그 화면

## 구현 내용
- 신규 `BoardingTagView.swift`: 단말기(274, LCD Focus Mate·TimelineView HH:mm·승차 준비/카드 이름+체크), 태그 영역 238×160(`boarding.tagArea`), 위쪽 화살표, 점선 테두리 카드(PassFace 꾸민 외형, 폭 268). 바깥 틀로 카드 기준 위치를 재고 안쪽 카드만 오프셋. DragGesture(minimumDistance 0, named 좌표) → controller.dragChanged/dragEnded. 접근성: 카드 버튼 라벨 '집중동행카드'·힌트(카드를 여기에/눌러서 태그하기)·accessibilityAction → activate, 낭독 전용 boarding.title(제목·정류장·단계·하단 안내), boarding.terminal(상표·시각·상태), lcdStatus. 터치 안내·저장 실패 문구. 진입 연출(단말기 0.12/카드 0.38)·점선 깜빡임·페이드 450ms — 동작 줄이기면 생략. onDisappear·background → cancelPendingTransition, active → returnToForeground. onFinished → 애니메이션 없이 finishBoardingTransition. DEBUG test.boarding·test.activateBoardingCard.
- `DestinationScreen.swift`: `.boarding` → BoardingTagView.
- `UITestBootstrap.swift`: --fm-ui-boarding-hold manual(UITestHoldGate 다중 대기자), --fm-ui-reduce-motion on, --fm-ui-route boarding(ready 시드 전용, 저장 없이 경로 구성), --fm-ui-save fail-once-boarding(ArmingBoarder가 승차 저장 직전에만 arm), makeJourneyServices.
- `FocusMateApp.swift`: 테스트 services·hold 게이트 조립, applyRoute.
- `RootView.swift`: test.releaseBoardingHold 버튼.

## GREEN 증거
BoardingTagUITests 7/7, BoardingFlowUITests 3/3(U3 포함).

## fix 라운드
- R1: Codex stop-time 리뷰 지적 "인식 후 뒤로가기를 숨겨 필수 취소 흐름이 막힘" — `navigationBarBackButtonHidden(isRecognized…)` 제거(AC-14). U3가 같은 결함으로 실패했던 것을 재실행으로 통과 확인.

## REFACTOR 내역
정리 없음.

## 우려사항
없음.

## fix R2 (태스크 리뷰 SPEC FAIL AC-9 + Important [동작불변])
- 재현 RED: BoardingTagUITests.testU5_AC9_끌지_않고_터치하면_튐_연출이_실행되고_안내가_뜬다(진단 tapBounces) — 실패 확인 후 수정.
- 터치 튐: controller.tapBounceCount 변화 → 카드 -14pt 튀었다 복귀(동작 줄이기면 횟수만), 진단 `tapBounces`.
- 컨트롤러 1회 생성: BoardingTagView(바깥)가 onAppear에서 한 번만 만들고 BoardingTagScreen(안쪽)에 전달. finish 변수 우회·`_ = finish` 제거, onFinished에 [weak model] 직접.
- (Minor 반영) 끄는 동안 spring 애니메이션 끔.
- GREEN: BoardingTagUITests 8/8 + BoardingFlowUITests 3/3.
