# T6 RED
- 테스트: ios/FocusMateTests/StationSearchTests.swift (13케이스: AC-1~9,12 + 번호검색 이름무시, 방면없음 라벨, 부분일치)
- 실패 확인: FOCUSMATE_SIMULATOR_ID=... python3 scripts/check-ios.py test ios/FocusMateTests/StationSearchTests.swift
- 결과: 컴파일 실패 - cannot find 'StationSearch' / 'StopSearchOption' in scope (연쇄 추론 에러 포함)
- 참조: RouteCatalogTestFixtures.swift, RouteCatalogTests.swift
