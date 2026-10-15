# T6 RED 보고

## 파일·케이스 (신규 1파일, 15건)
ios/FocusMateUITests/JourneyLifecycleSafetyUITests.swift
- AC-27 x2 (포기/새 여정 alert 백그라운드 왕복 후 존재, 안전 버튼 닫은 뒤 writeAttempts·persistedBytes 불변)
- AC-28 x2 (새 여정/포기 alert 열린 채 relaunch(manual): 카드 "24 min 남음", 경과 90, paused true, 성수역)
- AC-32 x3 (두 alert 안전 버튼 존재·문구, 카드 한 요소+별도 resume 버튼). 포기 낭독 1회는 JourneyAbandonUITests AC-16과 중복이라 생략. 첫 VoiceOver 포커스는 W14 이관(파일 상단 주석)
- AC-33 x4 (일시정지 화면 remaining/resume/abandon isHittable·높이>=44·scrollViews 0, 포기 alert 버튼, 메인 resume/open.preparation 스크롤 허용, 새 여정 alert 버튼)
- AC-34 x3 (reduce-motion: AC-3 요지, AC-8 요지, AC-16 요지)
- UITestLaunchSupport.swift 변경 없음(기존 도우미만 재사용)

## 실패 확인 명령 (실행 안 함)
FOCUSMATE_SIMULATOR_ID=113C1ABE-9FC9-48F7-9CA5-60498418C2F1 python3 scripts/check-ios.py test ios/FocusMateUITests/JourneyLifecycleSafetyUITests.swift

## typecheck
xcrun --sdk iphonesimulator swiftc -typecheck -target arm64-apple-ios17.0-simulator -sdk <SDK> -F <platform>/Developer/Library/Frameworks -I <platform>/Developer/usr/lib UITestLaunchSupport.swift JourneyLifecycleSafetyUITests.swift -> 에러 0

## 예상 실패 유형
컴파일은 통과. 프로덕션(alert, main.resumeJourney, life* 시드, 포기/새 여정 흐름) 미구현이면 요소 미존재(waitForExistence/XCTAssertTrue)로 실패. 단 T4/T5 선행 테스트가 같은 스킴 컴파일을 막으면 실행 실패는 못 볼 수 있음.

## 참조 파일
prd.md(AC-3/8/16/27/28/32/33/34), design.md 식별자, t4-red.md, UITestLaunchSupport.swift, JourneyAbandonUITests.swift, NewJourneyUITests.swift, JourneyResumeUITests.swift(grep), JourneyTimerAccessibilityUITests.swift, MainActiveJourneyCardUITests.swift(grep). 프로덕션 코드 열람 없음.
