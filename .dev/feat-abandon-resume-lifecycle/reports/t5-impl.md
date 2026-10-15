# T5 IMPLEMENT (세션) — 타이머 화면 연결 (+T6 검증 대상)

## 구현 내용
- ios/FocusMate/JourneyAbandonBar.swift (신규): 일시정지 중에만 '포기하기'(journey.abandon, accessibility3 상한, 44pt), 포기 alert(journey.abandon.cancel/confirm), 실패 문구 journey.timer.saveFailure(타이머 실패 문구와 중복 시 생략), 포커스 복귀는 onChange(isConfirming) + focusTarget, DEBUG test.abandon
- ios/FocusMate/JourneyView.swift: ensureTimer에서 consumeResumeEntry → autoStart 확장 + 이어가기 낭독 1회, JourneyScreen에 .safeAreaInset(edge: .bottom) 포기 바, 주석 갱신
- JourneyTimerView.swift·JourneyTimerController.swift 미수정(W06 충돌 회피 유지 — V7 AC29 통과로 조건부 수정 불필요)

## GREEN 증거
check-ios.py test (단위 5파일 + UI JourneyResume/JourneyAbandon/JourneyLifecycleSafety/MainActiveJourneyCard/JourneyTimerAccessibility/JourneyTimer/DepartureBriefing) → 단위 67/0, UI 90 중 88 pass · 2 fail(테스트 결함 의심 2건 — red-writer 재호출)
- 회귀 대상 V7 AC29(JourneyTimerAccessibilityUITests) 통과, JourneyTimerUITests·DepartureBriefingUITests 통과

## REFACTOR 내역
정리 없음

## self-review 결과
설계 D-8·E-9 일치. 포기 후 onDisappear leave()는 paused라 저장 없음.

## 우려사항
- 테스트 결함 의심: JourneyResumeUITests testAC32 화면 문구 판정이 test.announcements 진단(value)과 일치 / MainActiveJourneyCardUITests 화살표 보이는 문구는 accessibilityLabel 덮어쓰기로 관측 불가 → red-writer 수정
