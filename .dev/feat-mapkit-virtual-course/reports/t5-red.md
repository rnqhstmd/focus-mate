# T5 RED report

- 케이스: UI 14건(ios/FocusMateUITests/JourneyMapUITests.swift) + 단위 1건 회귀 가드(ios/FocusMateTests/AppInfoLocationTests.swift, RED 불가: 현재도 통과)
- 하네스 확장: ios/FocusMateUITests/UITestLaunchSupport.swift (waitUntil/waitForValue/value/frame/mapDiagnostic/dragMap/persistedText)
- 실행: FOCUSMATE_SIMULATOR_ID=$(cat .dev/feat-mapkit-virtual-course/simulator-id.txt) python3 scripts/check-ios.py test ios/FocusMateUITests/JourneyMapUITests.swift
- 결과: 14 tests, 14 failures (컴파일 성공, 존재 대기/assertion 실패)

## 케이스별 실패 메시지
```
FocusMateUITests/UITestLaunchSupport.swift:192: error: -[FocusMateUITests.JourneyMapUITests testAC14_15_드래그로만_자유_탐색이_되고_따라가기_탭으로_버스에_복귀한다] : Failed to get matching snapshot: No matches found for Elements matching predicate '"journ
FocusMateUITests/UITestLaunchSupport.swift:128: error: -[FocusMateUITests.JourneyMapUITests testAC19_테마_시트는_어두운_지도와_정류장_켜짐으로_열린다] : XCTAssertTrue failed - Missing: journey.map.theme
FocusMateUITests/JourneyMapUITests.swift:44: error: -[FocusMateUITests.JourneyMapUITests testAC1_지도와_지표_컨트롤이_모두_보이고_위치_권한_요청이_없다] : XCTAssertTrue failed - Missing: journey.map
FocusMateUITests/UITestLaunchSupport.swift:128: error: -[FocusMateUITests.JourneyMapUITests testAC20_테마를_바꾸면_선택_표시가_따라_바뀐다] : XCTAssertTrue failed - Missing: journey.map.theme
FocusMateUITests/UITestLaunchSupport.swift:128: error: -[FocusMateUITests.JourneyMapUITests testAC21_정류장_표시를_끄면_마커만_사라지고_켜면_돌아온다] : XCTAssertTrue failed - Missing: journey.map.theme
FocusMateUITests/UITestLaunchSupport.swift:128: error: -[FocusMateUITests.JourneyMapUITests testAC22_시트가_열린_채_일시정지하면_시트가_닫히고_도구가_잠긴다] : XCTAssertTrue failed - Missing: journey.map.theme
FocusMateUITests/UITestLaunchSupport.swift:128: error: -[FocusMateUITests.JourneyMapUITests testAC24_시트가_열린_채_도착하면_시트가_닫히고_도구는_활성이다] : XCTAssertTrue failed - Missing: journey.map.theme
FocusMateUITests/JourneyMapUITests.swift:186: error: -[FocusMateUITests.JourneyMapUITests testAC25_일시정지_상태에서는_테마_버튼이_잠기고_시트가_열리지_않는다] : XCTAssertTrue failed
FocusMateUITests/UITestLaunchSupport.swift:128: error: -[FocusMateUITests.JourneyMapUITests testAC26_지도_조작_후에도_저장_파일에_지도_키가_없고_버전은_4다] : XCTAssertTrue failed - Missing: journey.map.theme
FocusMateUITests/UITestLaunchSupport.swift:128: error: -[FocusMateUITests.JourneyMapUITests testAC27_재실행하면_지도_상태가_기본값으로_돌아온다] : XCTAssertTrue failed - Missing: journey.map.theme
FocusMateUITests/UITestLaunchSupport.swift:219: error: -[FocusMateUITests.JourneyMapUITests testAC28_지도_조작은_저장_파일과_타이머를_바꾸지_않는다] : XCTAssertTrue failed - Missing: journey.map
FocusMateUITests/UITestLaunchSupport.swift:203: error: -[FocusMateUITests.JourneyMapUITests testAC2_지표는_아래에_좌중우로_컨트롤은_위에_배치된다] : XCTAssertTrue failed - Missing: journey.timer.stops
FocusMateUITests/UITestLaunchSupport.swift:192: error: -[FocusMateUITests.JourneyMapUITests testAC39_남은_정류장과_거리가_진행과_도착에서_올바르게_표시된다] : Failed to get matching snapshot: No matches found for Elements matching predicate '"journey.tim
FocusMateUITests/JourneyMapUITests.swift:77: error: -[FocusMateUITests.JourneyMapUITests testAC4_금지된_기본_지도_컨트롤이_화면에_없다] : XCTAssertTrue failed
```

## 참조 파일
- ios/FocusMateUITests/UITestLaunchSupport.swift, JourneyTimerLifecycleUITests.swift (스타일), 프로덕션 코드 미참조
