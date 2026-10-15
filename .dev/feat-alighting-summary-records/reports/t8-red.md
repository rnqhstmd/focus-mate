# T8 RED report

파일: ios/FocusMateUITests/ProfileUITests.swift

## 변경
- 전: `XCTAssertTrue(entry.isHittable, "메인에서 마이페이지 진입 불가(메인 스크롤 없음)")` (281, 305행)
- 후: `try reachVisible(entry, h)` (waitForExistence 단언은 유지)
- 두 번째 테스트 시그니처에 `throws` 추가. 진입 뒤 검증(내비바 겹침, 3회 스와이프)은 변경 없음.

## 실행
명령: xcodebuild ... -only-testing 두 테스트 (log: scratchpad/t8-red.log)
결과: 두 테스트 모두 passed (26.3s / 45.8s), TEST SUCCEEDED.
해석: RED 예외 - 결함이 테스트에 있었음. 진입 뒤 단계에서 화면 결함은 드러나지 않음.

## 참조 파일
- reports/profile-ac20-investigation.md
- ios/FocusMateUITests/ProfileUITests.swift (265~335행)
