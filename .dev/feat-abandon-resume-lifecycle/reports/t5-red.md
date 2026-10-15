# T5 RED 보고

## 파일·케이스
- ios/FocusMateUITests/JourneyResumeUITests.swift (신규, 15건): AC-3 x4, AC-4 x3, AC-5 x2, AC-23 x2, AC-29 x1, AC-30 x2, AC-32 낭독 x2 (+ 1건 포함 시 합계 16이 아님; 위 합 = 16)
- ios/FocusMateUITests/JourneyAbandonUITests.swift (신규, 33건): AC-13 x3, AC-14 x3, AC-15 x2, AC-16 x5, AC-17/18/19 x5, AC-20 x3, AC-21 x2, AC-22 x2, AC-26 x3, AC-31 x1, AC-32 라벨 x1 (합 30)
- 수정: UITestLaunchSupport.swift (abandonDiagnostic 추가만)

## 실패 확인 명령 (오케스트레이터 실행)
cd /Users/bonseung/Documents/ChatGPT/new-w07 && FOCUSMATE_SIMULATOR_ID=113C1ABE-9FC9-48F7-9CA5-60498418C2F1 python3 scripts/check-ios.py test ios/FocusMateUITests/JourneyResumeUITests.swift ios/FocusMateUITests/JourneyAbandonUITests.swift

## typecheck
xcrun swiftc -typecheck (iphonesimulator SDK, XCTest 경로) 3개 파일: 에러 0.

## 예상 실패
journey.abandon / test.abandon / 이어가기 낭독 / 이어가기 직후 진행 상태 / 포기 후 메인 안내 등 미구현 -> 요소 없음·assertion 실패. 이어가기가 이미 동작하는 케이스 일부(AC-3 path 등)는 통과할 수 있음.

## 가정·우려
- 포기 안내 낭독은 main.abandonNotice 문구와 동일한 줄 1개로 가정.
- test.failNextSave는 일시정지 화면에서도 보인다고 가정.
- main.currentStation은 value, abandonNotice/saveFailure는 label로 읽음.
- 성수동·성수사거리 이름은 PRD 기준.

## 참조 파일
design.md(D-8, 시드표, 관측 규칙), UITestLaunchSupport.swift, NewJourneyUITests.swift, MainActiveJourneyCardUITests.swift, JourneyTimerUITests.swift, JourneyTimerLifecycleUITests.swift, JourneyTimerAccessibilityUITests.swift, CardIssuanceFlowTests.swift(announcements), CardStorageFlowTests.swift(grep), t4-red.md

## 테스트 결함 수정 R1
1. JourneyResumeUITests `testAC32_이어가기_낭독_문구는_화면에_글자로_나오지_않는다`
   - 전: `XCTAssertFalse(h.app.staticTexts[resumeAnnouncement].exists)`
   - 후: `staticTexts.matching(NSPredicate("label == %@ AND NOT (identifier BEGINSWITH 'test.')"))` 의 count == 0
   - 사유: 서브스크립트가 value까지 일치시켜 DEBUG 진단 요소 test.announcements(value=문구)에 걸림. FR-2 의미 유지.
2. MainActiveJourneyCardUITests `testAC1_이어가기_버튼의_보이는_문구는_화살표를_포함한다`
   - 전: 버튼 내부 staticText/title/app.staticTexts 중 "이전 여정 이어가기 →" 존재 단언(관측 불가)
   - 후: `testAC1_이어가기_버튼_낭독_라벨은_화살표가_없고_누를_수_있다` — label == "이전 여정 이어가기", "→" 미포함, isHittable, frame.height >= 44. `// 깨짐:` 갱신, 보이는 화살표는 코드 리뷰·W14 실기기 시각 점검으로 이관(주석).
typecheck: xcrun --sdk iphonesimulator swiftc -typecheck (UITestLaunchSupport+2파일, platform path의 XCTest) 에러 0. xcodebuild/check-ios 미실행.
