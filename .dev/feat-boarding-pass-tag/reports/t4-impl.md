# T4 IMPLEMENT — 승차 태그 컨트롤러

## 구현 내용
- 신규 `ios/FocusMate/BoardingTagController.swift`: `JourneyBoarding` 프로토콜, `BoardingTagController`(Phase 8종, LCDState, pendingSave/pendingTransition 노출).
  - dragChanged: tapSlop 초과 시 dragging, clamp, 접촉이면 손 떼기 전 즉시 인식. dragEnded는 절대 인식하지 않음(끌기 이력 없으면 터치 힌트, dragging이면 원위치).
  - activate: activationOffset으로 올린 뒤 인식.
  - recognize: recognitionID·transitionToken 증가, 동작 줄이기 아니면 햅틱 .boardingContact, contact 0이면 즉시 commit 아니면 pendingSave Task.
  - commit: 저장 성공 시 낭독 1회 → 전환 취소면 abandoned(복귀 예약이면 ready), 아니면 held → hold(holdSleep 우선) → fading → fade → finished → onFinished(phase 설정 후 호출). 실패 시 failed·원위치·실패 낭독.
  - cancelPendingTransition: transitionToken 증가(contacting은 저장 유지 플래그, held/fading → abandoned, dragging → ready). returnToForeground: abandoned → ready, contacting 취소 중이면 저장 후 ready.

## GREEN 증거
focused 6파일 111 pass / 0 fail (BoardingTagControllerTests 20 포함).

## REFACTOR 내역
정리 없음.

## self-review 결과
- 저장과 전환 토큰 분리(설계 2회차 MUST-ADDRESS 2). 화면 사라짐 후 저장 실패는 model.saveFailure로 메인 공용 문구에 표시(별도 처리 없음).
- 발급과 달리 동작 줄이기에서 진동 생략 — 코드 주석.

## 우려사항
없음. (태스크 리뷰 발동 조건: 프로덕션 파일 1개·fix 라운드 없음 → skipped. phase-review 전체 리뷰에서 확인)
