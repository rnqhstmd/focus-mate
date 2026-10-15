# T8 RED
- 테스트 파일: ios/FocusMateTests/JourneyActivityDisplayTests.swift (12 케이스 추가, 메서드명 testV15_위젯_*)
- 커버: timeContent 7건(paused, paused+stale, stale, arrived, running 정상, endDate 과거, endDate nil), accessibilityLabel 5건
- 실패 확인: check-ios.py test ... -> error: type 'JourneyActivityDisplay' has no member 'timeContent' (컴파일 실패, 정상 RED)
- 참조 파일: 기존 테스트 파일만 (프로덕션 코드 미열람)
