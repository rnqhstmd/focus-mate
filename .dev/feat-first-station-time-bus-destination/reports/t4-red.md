# t4 RED 보고

- 테스트 파일: ios/FocusMateUITests/FirstStationSearchUITests.swift (7 케이스)
- 케이스: 초기 결과 3개+확인 비활성 / 쿼리 "성수"→3, "건대"→1 / 공백 포함 "  성수사거리  "→1 / "없는역" empty+confirm 비활성+저장 바이트 불변 / 선택 시 확인문구·isSelected·confirm 활성 / 키보드 경로 → screen.time, time.origin "성수역", snapshot 저장 / 뒤로→screen.main
- 실패 확인 명령: FOCUSMATE_SIMULATOR_ID=65C4EB57-5CAD-4C4C-9FA5-1EF70EF47DEA python3 scripts/check-ios.py test ios/FocusMateUITests/FirstStationSearchUITests.swift
- 결과: Executed 7 tests, with 7 failures. 사유: search.* 요소 waitForExistence 실패 (검색 화면 없음). 컴파일 성공.
- 테스트 코드 전문: 위 파일 참조 (헬퍼 private 재작성, 강제 언래핑 없음)
- 참조한 파일: ios/FocusMateUITests/Phase1FlowTests.swift (패턴 참고만). 프로덕션 코드는 읽지 않음.
