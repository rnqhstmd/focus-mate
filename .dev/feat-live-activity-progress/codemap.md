## 코드 맵: W15 다이나믹 아일랜드·잠금 화면 진행 표시(Live Activity)

### 핵심 파일
- ios/FocusMate/JourneyTimerController.swift → 실제 분 타이머(@Observable). status(running/paused/arrived)·remainingSeconds·elapsedSeconds, pause/resume/enterBackground/returnToForeground/leave. 진도 계산 SSOT(변경 금지)
- ios/FocusMate/JourneyView.swift → 타이머·지도 컨트롤러 생성(ensureTimer), scenePhase 생명주기 분기, onDisappear leave
- ios/FocusMate/JourneyServices.swift → 의존성 묶음(clock·ticker·announcer 등). 새 Live Activity 게이트웨이 주입 지점
- ios/FocusMate/JourneyTimerView.swift → 타이머 화면(지도 레이아웃/legacy). DEBUG test.timer 진단
- ios/FocusMate.xcodeproj/project.pbxproj → objectVersion 77, PBXFileSystemSynchronizedRootGroup. 위젯 확장 타깃·Embed App Extensions·NSSupportsLiveActivities 추가 대상

### 참조 파일
- ios/FocusMate/JourneySnapshot.swift → 저장된 여행(id·totalSeconds·progress·paused·phase·버스/도착지)
- ios/FocusMate/RouteData.swift → RouteStops·버스·정류장 이름
- ios/FocusMate/JourneyTimerDisplay.swift → 남은 시간 표시 문자열·낭독
- ios/FocusMate/JourneyClock.swift → JourneyClock/ContinuousJourneyClock/ManualJourneyClock/JourneyTicker
- ios/FocusMate/UITestBootstrap.swift → DEBUG 런치 인자(--fm-ui-seed, --fm-ui-clock manual 등) 하네스
- ios/FocusMate/JourneyCourseProgress.swift → CourseJourney(버스·도착지·정류장 수)
- ios/FocusMateUITests/UITestLaunchSupport.swift → UI 테스트 헬퍼(waitUntil, mapDiagnostic 등)

### 설정
- scripts/check-ios.py → build/test 러너(FOCUSMATE_SIMULATOR_ID, CODE_SIGNING_ALLOWED=NO)
- .claude/config.json → projectTypes.ios-swiftui
- context/journey/{architecture,status,glossary}.md → 도메인 컨텍스트
