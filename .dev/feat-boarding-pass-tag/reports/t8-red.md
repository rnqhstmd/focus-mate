# T8 RED 보고
- 파일: ios/FocusMateUITests/DepartureBriefingUITests.swift (2건: U4 후반 AC-17·19·20, U9 후반 AC-18), ios/FocusMateUITests/BoardingLargeTextUITests.swift (1건: U11 AC-23)
- 실행 명령(미실행): FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateUITests/DepartureBriefingUITests.swift ios/FocusMateUITests/BoardingLargeTextUITests.swift
- 예상 실패: screen.journey / journey.briefing / journey.start / test.briefing 식별자 부재로 waitForExistence 단언 실패 (컴파일은 통과해야 함).
- 우려: 출발 확인 저장 실패 케이스는 작성하지 않음 -> 단위 테스트(T5)가 담당. 문장 간격 약 1.7초 x3 대기를 위해 10초 타임아웃 사용. 일시정지 부재 검사는 label '일시정지' 또는 identifier 'pause' 포함 요소로 판정.
- 참조: UITestLaunchSupport, BoardingTagUITests, BoardingFlowUITests, ActiveJourneyMainUITests, LargeTextUITests (설계서는 프롬프트 계약으로 대체, 미Read)
