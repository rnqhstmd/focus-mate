# T5 RED
- 테스트: ios/FocusMateTests/RouteCatalogTests.swift (케이스 16), 픽스처 ios/FocusMateTests/RouteCatalogTestFixtures.swift (코드 전문은 해당 파일)
- 명령: FOCUSMATE_SIMULATOR_ID=9306E393-1808-45F1-8C65-CD6E57D7DF98 python3 scripts/check-ios.py test ios/FocusMateTests/RouteCatalogTests.swift (exit 65)
- 실패: 빌드 실패, 미정의 심볼은 RouteCatalog / RouteVisit / RouteCatalogIssue / RouteCatalogLoader / RouteNumberOrder / RouteDataMetadata 뿐 (cannot find ... in scope)
- 로그: /private/tmp/claude-501/red-t5.log
- 참조: ActiveJourneyCardContentTests.swift (스타일), scripts 출력 로그
