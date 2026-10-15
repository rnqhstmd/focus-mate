# t11 RED 리포트

- 테스트 파일: ios/FocusMateUITests/JourneyLiveActivityUITests.swift
- 테스트: testV15_배선_일시정지_시드_진입부터_재개_시계진행_일시정지까지_요청이_기록된다 (시나리오 1~4 한 흐름, JSON 파싱 헬퍼 private)
- 실패 확인 명령: FOCUSMATE_SIMULATOR_ID=E9B19D8D-3AD1-4504-8E0B-9511C3A187E5 python3 scripts/check-ios.py test ios/FocusMateUITests/JourneyLiveActivityUITests.swift
- 실패 메시지: UITestLaunchSupport.swift:197: error: ... Failed to get matching snapshot: No matches found for Elements matching predicate '"test.liveActivity" IN identifiers'; Executed 1 test, with 1 failure; ** TEST FAILED **
- 실패 사유: 진단 요소 test.liveActivity 없음 (정상 RED)
- 참조한 파일: UITestLaunchSupport.swift, JourneyTimerUITests.swift (JourneyMapUITests는 미열람)
