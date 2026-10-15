# T5 RED
- 테스트: ios/FocusMateTests/JourneyTimerControllerTests.swift (29 케이스, 설계 T5 표 전 행), 더블: ios/FocusMateTests/JourneyTimerTestDoubles.swift (FakeProgressSaver, CountingTicker)
- 명령: FOCUSMATE_SIMULATOR_ID=497AF082-... FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateTests/JourneyTimerControllerTests.swift (로그 /tmp/red-t5.log)
- 실패: error: cannot find type 'JourneyTimerController' in scope / cannot find 'JourneyTimerController' in scope / type 'Equatable' has no member 'arrived|paused|running' (컴파일 실패 = NoSuchMethod 등가)
- 참조: design.md, prd.md(미열람), testing-anti-patterns.md(미열람), JourneyClockTests.swift, CardIssuanceTestDoubles.swift(RecordingAnnouncer 재사용), BoardingTestDoubles.swift(journey 시그니처), ios/FocusMate/JourneySnapshot.swift·IssuanceFeedback.swift(grep으로 enum Phase·AccessibilityAnnouncing 시그니처만)

## 재현 RED R1
JourneyTimerControllerTests.swift에 케이스 3건 추가(기존 무변경): testR1_일시정지_상태의_재개_저장_실패..., testR1_이미_총시간에_도달한_running에서_pause..., testR1_체크포인트_실패_후_재개하면....
실행 결과(/tmp/red-t5r1.log): 30 tests, 0 failures. 3건 모두 현재 구현에서 통과 -> 재현 불가(리뷰 지적 시나리오가 이미 충족됨). 
