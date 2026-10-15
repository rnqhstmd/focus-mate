# T3 RED report
- 테스트 파일: ios/FocusMateTests/BoardingModelTests.swift (코드 전문은 해당 파일, 신규 단일 파일, BoardingTestDoubles 변경 없음)
- 케이스 19건: AC1 x2, AC2 x2, AC4 x2, AC11 x2, AC13 x3, AC20 x2, AC21 x1, AC25 x1, AC26 x1, AC27 x3, 메인 라벨 x1 (BR-9는 records 0 단언으로 각 케이스에 포함)
- 실패 확인 명령(미실행): FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateTests/BoardingModelTests.swift
- 예상 실패: 컴파일 에러(Destination.board/boarding/journey, mainMenuTitle, AppModel(journeyFactory:), activeJourney, showBoardingPass, openBoarding, boardJourney, finishBoardingTransition, confirmDeparture, startTripFromMain 부재)
- 참조 파일: design.md(B, C4), JourneyStartModelTests, PreparationModelTests, JourneySnapshotTests, BoardingTestDoubles, StorageTestSupport. 프로덕션 코드 미참조.
- 가정: preparation.chooseTag(id:"reading"), fixture snapshot의 station id "seongsu"로 origin 해석, 저장 실패 시 saveFailure == .writeFailed.
