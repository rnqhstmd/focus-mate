# t3-red
- 테스트 파일: ios/FocusMateTests/JourneyLiveActivityPolicyTests.swift (전문은 해당 파일 참조), 케이스 21건
  - attributes 3 / request 5(running, paused, 음수, arrived, pausedRequest) / appearPlan 4 / launchPlan 8 (AC-10 x2, AC-11, AC-32, AC-33, 같은 id 없음, AC-34, paused 무시) 
- 실패 명령: FOCUSMATE_SIMULATOR_ID=E9B19D8D-3AD1-4504-8E0B-9511C3A187E5 python3 scripts/check-ios.py test ios/FocusMateTests/JourneyLiveActivityPolicyTests.swift
- 메시지: error: cannot find type 'LiveActivityHandle' / cannot find 'JourneyLiveActivityPolicy' in scope (컴파일 RED)
- 참조: BoardingTestDoubles.swift, JourneyCourseProgressTests.swift(앞 30줄), JourneyMapControllerTests.swift(grep), JourneyPlannerTests/JourneyActivityDisplayTests/RecordSectionTests(grep)
- 우려: seongsuIntersection 정류장 한글 이름을 테스트에서 확인 못 해, AC-31은 destinationName == snapshot.destinationName + non-nil + 기본 도착지 이름과 다름으로 검증. 알 수 없는 버스/도착지 nil 케이스는 설계 규칙(nil이면 nil)에서 도출.
