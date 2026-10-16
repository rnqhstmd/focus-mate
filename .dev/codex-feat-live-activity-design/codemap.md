# W17 코드 맵

## 핵심
- ios/FocusMateWidgets/JourneyLiveActivityWidget.swift — compact/minimal/expanded/lockscreen 뷰
- ios/Shared/JourneyActivityAttributes.swift — 외부 표시 상태 계약
- ios/Shared/JourneyActivityDisplay.swift — 상태/시간/접근성 표시 정책
- ios/FocusMate/JourneyLiveActivityPolicy.swift — 요청/종료/복원 정책
- ios/FocusMate/JourneyLiveActivitySync.swift — 타이머 옵저버와 ActivityKit 동기화

## 참조
- ios/FocusMate/LiveActivityGateway.swift — 시스템 어댑터; 완료 immediate
- ios/FocusMate/JourneyTimerController.swift — 실제 타이머 소유자; 백그라운드 시간 유지
- ios/FocusMate/JourneyView.swift — 화면/생명주기 연결
- ios/FocusMateTests/JourneyActivityDisplayTests.swift — 순수 표시 정책 테스트
- ios/FocusMateTests/JourneyLiveActivityPolicyTests.swift — 요청 정책 테스트
- ios/FocusMateTests/JourneyLiveActivitySyncTests.swift — 중복 갱신/재사용 테스트
- ios/FocusMateUITests/JourneyLiveActivityUITests.swift — 기록기 UI 테스트; 실제 Island 증거 아님

## 설정
- .claude/config.json — 빌드/테스트 명령
- ios/FocusMate.xcodeproj/project.pbxproj — 앱/확장 타깃
- .dev/system-surfaces-plan/plan.md — 승인 범위와 시안 링크
