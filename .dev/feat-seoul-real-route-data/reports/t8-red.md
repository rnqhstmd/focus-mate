# T8 RED
테스트: ios/FocusMateTests/RouteCandidatesTests.swift (17케이스: AC-13~23, 차이 우선, AC-25 3건, AC-26)
명령: FOCUSMATE_SIMULATOR_ID=9306E393-... python3 scripts/check-ios.py test ios/FocusMateTests/RouteCandidatesTests.swift
결과: 컴파일 실패 (RouteCandidate/RouteCandidates 미정의)
    |                                                                              `- error: use [:] to get an empty dictionary literal
    |                                   `- error: cannot infer key path type from context; consider explicitly specifying a root type
    |                  `- error: cannot find type 'RouteCandidate' in scope
    |                `- error: cannot find 'RouteCandidates' in scope
/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMateTests/RouteCandidatesTests.swift:10:18: error: cannot find type 'RouteCandidate' in scope
/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMateTests/RouteCandidatesTests.swift:101:35: error: cannot infer key path type from context; consider explicitly specifying a root type
/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMateTests/RouteCandidatesTests.swift:112:35: error: cannot infer key path type from context; consider explicitly specifying a root type
/Users/bonseung/projects/focus-mate/next-step-w16/ios/FocusMateTests/RouteCandidatesTests.swift:12:16: error: cannot find 'RouteCandidates' in scope
참조: RouteCatalogTestFixtures.swift, RouteLegTests.swift
