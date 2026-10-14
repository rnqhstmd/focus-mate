# T3 RED
- 파일: ios/FocusMateTests/ProfileSeedTests.swift (5 케이스, #if DEBUG, XCTUnwrap 사용)
- 케이스: AC6 디코드 통과 / AC6 카드번호 FM-12345678 / AC9 기록 3건·id / AC18 분 합 65 / AC22 launchRoute == .main
- 명령: FOCUSMATE_SIMULATOR_ID=7815DB9D-633D-441D-B3B5-C7DABF274EB8 FOCUSMATE_DERIVED_DATA=.build/ios-red python3 scripts/check-ios.py test ios/FocusMateTests/ProfileSeedTests.swift
- 결과: Executed 5 tests, 8 failures (rawSeeds["profileRecords"] nil -> XCTUnwrap 실패 등)
- 참조: ios/FocusMateTests/CardStorageTests.swift (스타일만)
