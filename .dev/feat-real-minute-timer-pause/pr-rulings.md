## Rulings
- 연타 방어 위치 — 컨트롤러 0.5초 가드는 기존 testAC28(일시정지 직후 재개 즉시 성공)과 충돌해, 버튼(뷰) 계층에서 마지막 탭 후 0.5초 안의 탭을 무시 (틀리면: 컨트롤러에 주입 시계 기반 가드를 두고 AC-28 기대를 조정)
- JourneyProgressSaving 프로토콜 위치 — T4가 먼저 필요해 AppModel+JourneyTimer.swift에 둠 (틀리면: JourneyTimerController.swift로 이동)
- T6 태스크 리뷰 생략 — 사용자 속도 요청으로 phase-review 전체 리뷰에 통합 (틀리면: T6 범위 재리뷰)
- 전체 스위트 미실행 — 사용자 지시, focused 집합 통과로 verify 처리 (틀리면: 머지 전 check-ios.py test 1회)

## Deferred
- [Minor] JourneyTimerController.swift deinit — MainActor.assumeIsolated 메인 해제 가정
- [Minor] JourneyTimerView.swift — tapGuard 0.5초가 모든 control 버튼 공통, doubleTap UI 테스트는 간격 의존
- [Minor] JourneyView.swift — inactive→active에서도 returnToForeground(tick) 호출, 비활성 무변화 UI 테스트 없음
- [Minor] UITestLaunchSupport.swift — 미사용 waitForTimerText, goBackground 고정 sleep
- [Minor] JourneySnapshot.swift — CodingUserInfoKey 강제 언랩, 디코드 삼항 try 가독성
- [Minor] BoardingModelTests/JourneyTimerModelTests — confirmDeparture 저장 실패 시 확정값 유지 테스트 없음, Probe 중복, openBoarding 가드 독립 검증 약함
- [MEDIUM] trust-ledger.md 통합 감사 6건 (W07·W14 이월)
