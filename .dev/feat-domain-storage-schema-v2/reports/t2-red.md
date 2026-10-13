# T2 RED
- 테스트: ios/FocusMateTests/SnapshotCodecTests.swift (SnapshotCodecTests, 케이스 16건: golden 2, 왕복 1, 재인코딩 1, currentVersion 1, 헤더·미지원 표 1, 영역 누락/형식/골격/원소 4, 모르는 키 1, 순서 3, migrateV1 1, AC-1 1)
- 깨짐 명명: 각 케이스 위 주석 참조
- 실패 확인: python3 scripts/check-ios.py test ios/FocusMateTests/SnapshotCodecTests.swift
- 실패 메시지: cannot find 'SnapshotCodec' in scope / cannot find 'LegacySnapshotV1' in scope (컴파일 실패, 누락 심볼 외 오류 없음)
- 참조: AppFoundationTests.swift(스타일, assertStorageIssue, launchRoute try 사용 확인 grep), reports 디렉터리 ls
- 부수 오류(누락 심볼 연쇄로 추정): "type 'Equatable' has no member 'main'"(snapshot 타입 미해결), "failed to produce diagnostic"(LegacySnapshotV1 디코딩식). launchRoute()는 throws라 try 사용.
