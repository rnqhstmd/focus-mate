# T7 RED
- 테스트 파일: ios/FocusMateTests/JourneyLiveActivityCleanupTests.swift (6케이스: AC10, AC11, AC32, AC33, AC34, AC32b 미출발 전부 end)
- 실패 명령: FOCUSMATE_SIMULATOR_ID=E9B19D8D-3AD1-4504-8E0B-9511C3A187E5 python3 scripts/check-ios.py test ios/FocusMateTests/JourneyLiveActivityCleanupTests.swift
- 실패 메시지: error: cannot find 'JourneyLiveActivityCleanup' in scope (컴파일 실패, 정상 1차 RED)
- 참조: JourneyLiveActivitySyncTests.swift, BoardingTestDoubles.swift
