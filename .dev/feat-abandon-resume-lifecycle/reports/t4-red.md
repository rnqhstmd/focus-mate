# T4 RED 보고

## 파일·케이스
- ios/FocusMateTests/LifecycleSeedTests.swift (신규, 9건: 존재, 없는 이름 nil, 형식 검증, launchRoute==.main, 도착지=식, currentStation=출발지, 기록 seed-record-1 1건, paused/phase, 설계 표 값)
- ios/FocusMateUITests/MainActiveJourneyCardUITests.swift (신규, 11건: AC-1 x4, AC-24 카드 x2, AC-25 x2, AC-35 x3)
- ios/FocusMateUITests/NewJourneyUITests.swift (신규, 22건: AC-6 x2, AC-7 x3, AC-8 x4, AC-9 x2, AC-10 x3, AC-11 x2, AC-12 x2, AC-24 확정 x2 + 주석 포함)
- 수정: ActiveJourneyMainUITests.swift 3건 재작성(W07 동작, 정류장 단언 없음), BoardingLargeTextUITests.swift U11에 main.newJourney.confirm 단계, UITestLaunchSupport.swift 도우미 추가(launchLifecycle, writeAttempts, failNextMainSave, alert(titled:), alertButton, persistedState/persistedCurrentStation/persistedRecordCount)

## 명령
cd /Users/bonseung/Documents/ChatGPT/new-w07 && FOCUSMATE_SIMULATOR_ID=113C1ABE-9FC9-48F7-9CA5-60498418C2F1 python3 scripts/check-ios.py test ios/FocusMateTests/LifecycleSeedTests.swift

## 실패 메시지
Type 'UITestBootstrap' has no member 'lifecycleSnapshot' (x3), Cannot convert value of type '_' to expected argument type 'AppSnapshot?' -> 미정의 심볼 컴파일 실패(정상 RED).
UI 테스트 파일 실행은 같은 스킴의 FocusMateTests 컴파일 실패로 막혀 실제 실행 실패는 못 봄. 대신 UI 파일 전부 swiftc -typecheck(시뮬레이터 SDK+XCTest) 에러 0 확인.

## 참조 파일
design.md, prd.md, UITestLaunchSupport.swift, ActiveJourneyMainUITests.swift, BoardingLargeTextUITests.swift, CardCustomizationFlowTests.swift(521-554), JourneyTimerLifecycleUITests.swift, ProfileSeedTests.swift, ActiveJourneyCardContentTests.swift, BoardingTestDoubles.swift, JourneyReachTests.swift(grep), 기타 테스트 grep.

## 재현 RED R1
추가 케이스(MainActiveJourneyCardUITests.swift, 기존 수정 없음, 3건):
- testAC1_카드는_저장된_할_일과_태그_경로를_보인다: card.label에 "생명주기 시드", "독서 · 서울숲 입구까지"
- testAC1_이어가기_버튼의_보이는_문구는_화살표를_포함한다: resume 버튼 내부 staticTexts / title / app.staticTexts 중 하나에 "이전 여정 이어가기 →" (XCUITest에서 SwiftUI 버튼 내부 텍스트 접근은 구현에 따라 달라 불확실 — 접근 불가 시 "이전 여정 이어가기" label과 구분 불가가 사유)
- testAC25_손상_여정_버림은_기록_수와_현재_정류장을_바꾸지_않는다: 시작 직후 persistedRecordCount/persistedCurrentStation.id 와 main.currentStation value(비어있지 않음) 확인, 카드 없음, 재조회 시 기록 수·정류장 동일. (정류장 id↔표시명 매핑을 몰라 id 비교 대신 nil 아님/표시 비어있지 않음/불변으로 단언)
명령: FOCUSMATE_SIMULATOR_ID=113C1ABE-9FC9-48F7-9CA5-60498418C2F1 python3 scripts/check-ios.py test ios/FocusMateUITests/MainActiveJourneyCardUITests.swift (실행 금지 지시로 미실행)
typecheck: xcrun swiftc -typecheck (sim SDK, UITestLaunchSupport 포함) — XCTAssert* 매크로 미지원 노이즈 외 에러 0.
예상: 구현이 이미 있어 통과할 가능성 높음(재현 불가 판정은 오케스트레이터).
참조: MainActiveJourneyCardUITests.swift, UITestLaunchSupport.swift(helper 시그니처 grep), t4-red.md
