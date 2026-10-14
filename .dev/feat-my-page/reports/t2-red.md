# t2-red report

- 테스트 파일: ios/FocusMateTests/ProfileTimeTextTests.swift
- 케이스 수: 16 (AC-10 8건: 0/59/60/61/120/6000/6005/60000, AC-11 7건, AC-22 1건 — 8개 값 반복 검사)
- 테스트 코드 전문: 위 파일 참조 (각 테스트 위 `// 깨짐 명명:` 주석, 손으로 도출한 리터럴 기댓값)
- 실패 확인 명령: cd /Users/bonseung/Documents/ChatGPT/new-w11 && FOCUSMATE_SIMULATOR_ID=7815DB9D-633D-441D-B3B5-C7DABF274EB8 FOCUSMATE_DERIVED_DATA=.build/ios-red python3 scripts/check-ios.py test ios/FocusMateTests/ProfileTimeTextTests.swift
- 실패 메시지: `Cannot find 'ProfileTimeText' in scope` (컴파일 에러, 5 failures, Testing cancelled because the build failed). 심볼 없음 컴파일 에러이므로 오케스트레이터가 뼈대로 단언 RED 확인 필요.
- 참조한 파일: ios/FocusMateTests/JourneyPlannerTests.swift (스타일, 1-40행). 프로덕션 코드 미참조.
- 비고: 기존 스타일 메서드명은 test_ 형식이었으나 지시대로 testAC{n}_ 형식 사용.
