# T11 IMPLEMENT (세션) — 앱 배선

## 구현 내용
- `JourneyServices.liveActivities`(기본 ActivityKitLiveActivityGateway, live() 무수정)
- `JourneyView.ensureTimer`: JourneyLiveActivitySync 생성 → 컨트롤러 observer로 전달
- `FocusMateApp.start` 끝(DEBUG 시나리오 적용 뒤) `cleanUpLiveActivities()` — `.ready`일 때만 `JourneyLiveActivityCleanup.atLaunch`
- `UITestBootstrap.makeJourneyServices`: 항상 RecordingLiveActivityGateway
- `RootView.testDiagnostics`: `test.liveActivity`(기록기일 때만)
- `RecordingLiveActivityGateway.diagnosticJSON`

## GREEN 증거
`check-ios.py test ios/FocusMateUITests/JourneyLiveActivityUITests.swift` → 1 test, 0 failures (34s)

## REFACTOR 내역
정리 없음

## self-review 결과
AppModel·JourneyTimerView 무수정(W07 충돌 최소). Release 경로는 실제 게이트웨이.

## 우려사항
없음
