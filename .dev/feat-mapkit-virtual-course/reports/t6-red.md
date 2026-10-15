# T6 RED 보고

- 테스트 파일: ios/FocusMateUITests/JourneyMapAccessibilityUITests.swift (10케이스: AC-3, 30, 31, 32, 33, 34, 35, 36, 37, 38)
- 명령: FOCUSMATE_SIMULATOR_ID=$(cat .dev/feat-mapkit-virtual-course/simulator-id.txt) python3 scripts/check-ios.py test ios/FocusMateUITests/JourneyMapAccessibilityUITests.swift
- 결과: 10건 실행, 2건 실패(정상 RED), 8건 이미 충족(회귀 가드)

## 케이스별
- AC-33: 실패 — XCTAssertEqual failed: (["뚝섬역"]) is not equal to ([]) : journey.map 하위에 정류장 이름 라벨 요소가 노출됨
- AC-37: 실패 — focus가 Optional("none"), 기대 "remaining" (test.timer의 focus 키)
- AC-3, 30, 31, 32, 34, 35, 36, 38: 이미 충족(회귀 가드)
  - AC-3은 Legal 링크 탐색 후 통과(로그상 링크 발견 경로로 보이나, 미발견 시 M-1 대체 기록으로 통과하는 구조)
  - AC-37의 낭독 1회 검증은 focus 단언에서 먼저 중단되어 미검증

## 참조 파일
UITestLaunchSupport.swift, JourneyTimerAccessibilityUITests.swift, JourneyMapUITests.swift, JourneyTimerLifecycleUITests.swift(grep), DepartureBriefingUITests.swift(grep, focus 키 패턴)

## 재작성 R1 (AC-37 테스트 결함)
- 결함: `test.timer` 진단 focus는 `@AccessibilityFocusState`를 읽는데 시뮬레이터에선 VoiceOver 꺼짐으로 항상 "none" → 구현과 무관하게 실패하는 단언.
- 수정: focus 단언 제거, 이름을 `testAC37_일시정지와_재개는_한_번씩_낭독된다`로 변경, 주석에 "VoiceOver 초기 포커스(남은 시간)는 시뮬레이터에서 관찰 불가 → 수동 확인 M-2" 추가. 다른 테스트 무변경.
- 파일: ios/FocusMateUITests/JourneyMapAccessibilityUITests.swift
- 실행: `FOCUSMATE_SIMULATOR_ID=$(cat .dev/feat-mapkit-virtual-course/simulator-id.txt) python3 scripts/check-ios.py test ios/FocusMateUITests/JourneyMapAccessibilityUITests.swift`
- 결과: 10 tests, 0 failures, TEST SUCCEEDED (AC-37 포함 통과)
- 참조 파일: 위 테스트 파일만 (프로덕션 미참조)
