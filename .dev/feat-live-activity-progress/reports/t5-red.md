# t5 RED
추가 5케이스(AC-11~15) + 헬퍼 makeRigWithLeftovers, 파일: ios/FocusMateTests/JourneyLiveActivitySyncTests.swift
명령: FOCUSMATE_SIMULATOR_ID=E9B19D8D-... python3 scripts/check-ios.py test ios/FocusMateTests/JourneyLiveActivitySyncTests.swift
실패: JourneyLiveActivitySyncTests.swift:204:62: error: argument passed to call that takes no arguments (RecordingLiveActivityGateway(existing:) 미존재) -> 정상 1차 RED
우려: 프로덕션 미열람이라 LiveActivityHandle(id:journeyID:), entries 항목의 .activityID(옵셔널), activeActivities 원소의 .id/.journeyID 는 추정. 1차 컴파일 에러에 가려 검증 안 됨.
참조: JourneyLiveActivitySyncTests.swift, JourneyTimerTestDoubles.swift, BoardingTestDoubles.swift (+ grep으로 RecordingLiveActivityGateway 위치만 확인, 미열람)
