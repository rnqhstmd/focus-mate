# T6 RED report
신규: BoardingFlowUITests.swift(2케이스: 메인 라벨/식별자, U1 흐름), ActiveJourneyMainUITests.swift(3케이스: U10 안내, 폐기, 저장실패)
수정: PreparationFlowUITests(여행 준비 라벨 4곳->open.preparation, +testTappingDisabledConfirmDoesNotOpenBoardingPass), Phase1FlowTests(:50), PreparationEditorUITests(:240 + testAC4_AC12 확정->board->뒤로->수정->재확정->board)
실행 금지 준수(미실행). 실패 확인:
FOCUSMATE_SIMULATOR_ID=031BC52B-E186-4706-B525-763D32DD48E2 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateUITests/BoardingFlowUITests.swift ios/FocusMateUITests/ActiveJourneyMainUITests.swift ios/FocusMateUITests/PreparationFlowUITests.swift ios/FocusMateUITests/PreparationEditorUITests.swift ios/FocusMateUITests/Phase1FlowTests.swift
예상 실패: open.preparation 의존 기존 테스트 전부(식별자 부재), 메인 라벨 케이스(라벨 '여행 준비'), U1(screen.board 부재), ActiveJourney 3건(시드 activeJourney 미지원), 비활성 confirm 케이스는 현재도 통과 가능(미발생 단언 회귀 가드, 구현 후 의미), testAC4_AC12(screen.board 부재).
참조: design.md(E,F,기존 테스트 영향,U표), UITestLaunchSupport, PreparationFlow/Editor/Phase1 UITests.
