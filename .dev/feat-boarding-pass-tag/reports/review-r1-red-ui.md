# review-r1 RED (UI)
## 추가
- BoardingLargeTextUITests.testF3_가장_큰_글자에서_진행_여정_안내가_있어도_메인_메뉴_버튼_모두_닿고_프로필을_열_수_있다 (신규, 실패 예상)
## 변경(동작 불변, 통과 예상)
- BoardingFlowUITests testU3: 조건부 release.tap -> 존재 단정 + tap
- BoardingTagUITests: AC5 title에 '서울숲역' 단정; U4/U5 offsetY -> boarding.card frame.minY; AC9 tapBounces 보조 주석 + tapHint/LCD 주 단정
- DepartureBriefingUITests: 주 단정 journey.start hittable·briefingSentence, focus/showsAll 보조 주석
## 명령
FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateUITests/BoardingLargeTextUITests.swift ios/FocusMateUITests/BoardingFlowUITests.swift ios/FocusMateUITests/BoardingTagUITests.swift ios/FocusMateUITests/DepartureBriefingUITests.swift
## 참조
UITestLaunchSupport, BoardingTagUITests, BoardingFlowUITests, DepartureBriefingUITests, BoardingLargeTextUITests, LargeTextUITests (프로덕션 미참조). 테스트 미실행.
