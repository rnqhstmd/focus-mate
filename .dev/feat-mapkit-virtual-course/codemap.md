## 코드 맵: W06 MapKit 가상 코스 (journey FR-6)

### 핵심 파일
- ios/FocusMate/JourneyTimerView.swift:18-49 → 타이머 화면. 배경 Color.black(29)을 지도로 교체 예정. 남은 시간 `journey.timer.remaining`, 일시정지/재개 51-79, DEBUG `test.timer` 95-108
- ios/FocusMate/JourneyTimerController.swift:9-62 → @Observable 타이머(running/paused/arrived), elapsedSeconds·remainingSeconds, totalSeconds private(19)
- ios/FocusMate/RouteData.swift:4-87 → RouteStops 9개 순환 정류장(id·이름만, 좌표 없음), StationCatalog, BusLine(2014 5분/정류장, 강남02 6, 343 8)
- ios/FocusMate/JourneyPlanner.swift:19-31 → 정류장 수=minutes/minutesPerStop, 목적지 wrap, 정류장 간격 0.55km
- ios/FocusMate/JourneySnapshot.swift:24-75 → 진행 여정(originStopID, direction, minutes, busID, destinationStopID, progress, paused), totalSeconds/isArrived

### 참조 파일
- ios/FocusMate/JourneyView.swift:28-61 → 출발 안내 후 JourneyTimerView 표시, ensureTimer
- ios/FocusMate/JourneyClock.swift:6-62 → JourneyClock/JourneyTicker 프로토콜, ManualJourneyClock(테스트)
- ios/FocusMate/UITestBootstrap.swift:40-62,147,271-286 → 시드(timerPaused90/NearArrival/Arrived), --fm-ui-route journey, --fm-ui-clock manual, --fm-ui-reduce-motion on
- ios/FocusMateUITests/UITestLaunchSupport.swift:13-145 → launchJourney, timerDiagnostic, advance
- designs/final/animation-preview.html:599,783-844 → 웹 프로토타입 지도(SVG 폐곡선, follow, 테마 시트, 정류장 숨김)
- docs/FLOWS.md:16,68-74 → 집중 화면 지도 도구 스펙
- ios/FocusMateTests/JourneyTimerTestDoubles.swift → 타이머 테스트 더블

### 설정
- scripts/check-ios.py → build|test [파일] (stem=클래스명)
- ios/FocusMate.xcodeproj → 동기화 폴더(pbxproj 수정 불필요), MapKit 프레임워크 링크 여부 확인 필요
