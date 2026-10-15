# T4 RED
- 파일: ios/FocusMateTests/JourneyLiveActivitySyncTests.swift (케이스 8건: AC-1,2,4,5,6,7,8,9)
- 실패 명령: FOCUSMATE_SIMULATOR_ID=E9B19D8D-3AD1-4504-8E0B-9511C3A187E5 python3 scripts/check-ios.py test ios/FocusMateTests/JourneyLiveActivitySyncTests.swift
- 메시지: cannot find type 'RecordingLiveActivityGateway' / 'JourneyLiveActivitySync' in scope (컴파일 실패, 미존재 타입)
- Rig(makeRig(elapsed:paused:autoStart:results:))는 T5·T6 재사용용
- 참조: JourneyTimerObserverParityTests, JourneyTimerTestDoubles, JourneyTimerControllerTests, BoardingTestDoubles.swift (테스트 파일만)
