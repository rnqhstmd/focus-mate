# T2 RED report
- 테스트 파일: ios/FocusMateTests/JourneyMapStateTests.swift (20 케이스, test1~test20, 전문은 해당 파일)
- 실패 확인 명령: FOCUSMATE_SIMULATOR_ID=$(cat .dev/feat-mapkit-virtual-course/simulator-id.txt) python3 scripts/check-ios.py test ios/FocusMateTests/JourneyMapStateTests.swift
- 실패 메시지: Cannot find 'JourneyCameraPolicy' in scope / Type 'JourneyMapDisplay' has no member 'followValue' (+ JourneyMapState 등 부재) -> build failed, TEST FAILED
- 참조 파일: ios/FocusMateTests/AppFoundationTests.swift(스타일, 상단만), 디렉터리 목록
