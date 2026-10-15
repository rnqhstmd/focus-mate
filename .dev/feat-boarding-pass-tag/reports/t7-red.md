# T7 RED report
- 파일: ios/FocusMateUITests/BoardingTagUITests.swift (신규, 7케이스: AC5, U4, U5, U6, U7, U8, U9), ios/FocusMateUITests/BoardingFlowUITests.swift (U3 1케이스 추가). 총 8케이스. UITestLaunchSupport 수정 없음(extraArguments 사용).
- 실패 확인(실행하지 않음): FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateUITests/BoardingTagUITests.swift ios/FocusMateUITests/BoardingFlowUITests.swift
- 예상 실패: 컴파일은 통과(신규 인자·식별자는 문자열). 런타임에 --fm-ui-route boarding 미지원/식별자(boarding.card, test.boarding 등) 부재로 waitForExistence 실패.
- 가정: snapshot active.progress.elapsedSeconds, phase 문자열 "awaitingDeparture", test.boarding phase "held"/"ready", test.hapticCount는 정수 문자열.
- 참조: design.md, testability.md, UITestLaunchSupport/BoardingFlow/ActiveJourneyMain/CardIssuanceFlow/PreparationFlow UITests.
