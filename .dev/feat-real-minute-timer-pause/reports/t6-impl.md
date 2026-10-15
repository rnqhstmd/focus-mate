# T6 IMPLEMENT 보고
## 구현 내용
- 신규 JourneyTimerView.swift: journey.timer.remaining(라벨 "타이머", 값 "남은 시간 N분", 진입 시 접근성 초점 1회), pause/resume(상태별 하나, 44pt 이상, 글자 상한 accessibility3), saveFailure·saveWarning(도착이면 도착 문구), journey.arrived 임시 도착, reduce motion 시 숫자 전환 효과 제거, DEBUG test.timer 진단(status·elapsed·remainingMinutes·text·showsSaveWarning·showsSaveFailure·focus·path).
- 신규 NavigationPopBlocker.swift: interactivePop(+iOS 26 interactiveContentPop) 비활성, 사라질 때 복원.
- JourneyView.swift: timer 컨트롤러 소유(ensureTimer: departed이고 nil일 때, autoStart = briefing.isConfirmed), placeholder 제거, 모든 단계에서 뒤로가기 숨김·내비 바 숨김·PopBlocker, scenePhase 한 곳에서 단계별(타이머: background→enterBackground, active→beforeForeground+returnToForeground, inactive 무시), onDisappear leave 방어, DEBUG 상단 safe-area 시계·실패 버튼.
- JourneyServices.swift: clock, makeTicker, beforeForeground, DEBUG testClock·failNextSave.
- UITestBootstrap.swift: --fm-ui-clock manual(ManualJourneyClock을 clock·ticker로), UITestNextSaveFailure(writeData OR), 시드 timerPaused90/timerNearArrival/timerArrived, v3 파생 시드 4종(v4 인코드 후 version 3·paused 제거), --fm-ui-route journey(active 필요, open(.journey)).
## GREEN 증거
- 1차: UI 4파일 26 tests 중 24 통과, 2건은 테스트 결함(실시간 진도를 저장값 진단으로 단언) → red-writer 수정 R2 → 재실행(오케스트레이터) 결과는 아래 verify 기록.
## REFACTOR 내역
정리 없음
## self-review 결과
테스트 파일은 red-writer만 수정(수정 R1: persistedBytes base64 디코드, R2: 실시간 진도 단언). 구현 주체는 테스트 미수정.
## 우려사항
없음
