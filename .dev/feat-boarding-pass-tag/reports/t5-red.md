# T5 RED
- 파일: ios/FocusMateTests/DepartureBriefingControllerTests.swift (케이스 10), BoardingTestDoubles.swift에 FakeDepartureConfirmer·QueuedSleep 추가(append only)
- 명령: FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateTests/DepartureBriefingControllerTests.swift
- 예상 실패: DepartureConfirming / DepartureBriefingController 타입 부재 컴파일 에러
- 참조: CardIssuanceTestDoubles.swift, BoardingTestDoubles.swift, CardIssuanceControllerTests.swift, 설계서(전달된 프롬프트)
