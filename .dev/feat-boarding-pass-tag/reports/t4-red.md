# T4 RED report
- 테스트: ios/FocusMateTests/BoardingTagControllerTests.swift (케이스 20건: AC-6x2, 7, 8, 9, 10, 11, 12, 13, 14, 15x2, 16x4, 21x2, 22)
- 대역 추가: ios/FocusMateTests/BoardingTestDoubles.swift 끝에 FakeJourneyBoarder 추가 (기존 내용 불변). QueuedSleep은 SuspendingSleep 2개(sleep/holdSleep)로 충분해 생략.
- 실패 확인 명령(미실행): FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateTests/BoardingTagControllerTests.swift
- 예상 실패: 컴파일 에러 (BoardingTagController, JourneyBoarding, IssuanceHapticPattern.boardingContact 일부 부재/신규 타입)
- 손계산 리터럴: activationOffset (0,-196), clamp (26,-240)/(−26,20)
- 참조: design.md, CardIssuanceTestDoubles.swift, CardIssuanceControllerTests.swift(앞 80줄), BoardingTestDoubles.swift
