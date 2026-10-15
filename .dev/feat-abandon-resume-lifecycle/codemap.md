## 코드 맵: W07 포기·이어가기·생명주기

### 핵심 파일
- ios/FocusMate/AppModel+Boarding.swift:53 → startTripFromMain(진행 여정을 확인 없이 정리 — W07에서 확인 단계로 교체), activeJourney
- ios/FocusMate/AppModel.swift:180 → loadSnapshot(진행 여정 restingForLaunch로 일시정지 복원), :198 save, :263 open(.journey 가드), :270 goBack(출발 여정 가드)
- ios/FocusMate/RootView.swift:175 → 메인 진행 여정 임시 안내 main.activeJourney, 메인 메뉴 버튼(open.preparation → startTripFromMain)
- ios/FocusMate/JourneyView.swift:1-80 → 여행 화면, 타이머 컨트롤러 생성(autoStart=briefing.isConfirmed), scenePhase 처리, NavigationPopBlocker
- ios/FocusMate/JourneyTimerController.swift → 타이머 상태(running/paused/arrived), pause/resume/leave, 저장자 JourneyProgressSaving

### 참조 파일
- ios/FocusMate/JourneyTimerView.swift → 남은 시간·일시정지/재개 버튼, 저장 실패 안내, test.timer 진단
- ios/FocusMate/AppModel+JourneyTimer.swift → saveJourneyProgress, hasDepartedJourney
- ios/FocusMate/JourneySnapshot.swift → 진행 여정(origin/direction/minutes/bus/destination/progress/paused), restingForLaunch
- ios/FocusMate/AppSnapshot.swift → currentStation(StationSnapshot id/name/direction), updatingStage/updating(journey:)
- ios/FocusMate/RouteData.swift → RouteStops(9개 순환 정류장, wrap), StopPosition
- ios/FocusMate/JourneyPlanner.swift → 버스 정류장 간격·정류장 수 계산
- ios/FocusMate/NavigationPopBlocker.swift → 여행 화면 스와이프 뒤로가기 차단
- ios/FocusMate/UITestBootstrap.swift → UI 테스트 시드(activeJourney, timerPaused90 등)·수동 시계·저장 실패 주입

### 설정
- scripts/check-ios.py → iOS build/test(focused) 실행
- docs/FLOWS.md → 화면 계약(메인·멈춤·포기 행, W05 타이머 절)
- context/journey/status.md → FR-13 / AC-15, NFR-2
