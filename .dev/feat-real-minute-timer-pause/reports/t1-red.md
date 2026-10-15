# T1 RED 보고

- 신규: ios/FocusMateTests/JourneySnapshotV4StorageTests.swift (케이스 26개). 전문은 해당 파일 참조(쓰기 거부 9: AC-20/21/22/paused, 읽기 버림 11, v4 왕복 2, v3 읽기 7 등).
- 구성: 실제 LocalSnapshotStore + 임시 파일. 읽기 케이스는 유효 v4 저장 후 JSONSerialization으로 active를 손상. v3는 v4 저장 후 version=3, active.paused 삭제로 생성.
- 수정한 기존 테스트: BoardingTestDoubles(기본 destination -> seongdongSportsCenter, paused 인자; memberwise init에 progress 뒤 `paused:` 마지막 인자로 전달), JourneySnapshotTests(withDestination paused 전달, 카탈로그 밖 id 거부 테스트 4개로 교체, 361/360 케이스 추가, invalidProgress 유지), JourneySnapshotStorageTests(version 4, active.paused==false), SnapshotCodecTests, StorageV2Tests, CardSupplementTests, CardStorageTests, CardCustomizationAppModelTests, CardStyleStorageTests, RecordStorageTests (version 4).
- 추가 수정(표에 없음): 미지원 버전 테스트 입력이 version 4였으므로(이제 지원 버전) 5로 변경 - SnapshotCodecTests, StorageV2Tests, AppRecoveryTests, RecordStorageTests, StorageRecoveryTests. SnapshotCodecTests의 testCurrentVersionIsThree -> IsFour.
- 실패 확인 명령: FOCUSMATE_SIMULATOR_ID=497AF082-E352-4A42-8323-A08B2D3BFCB5 FOCUSMATE_DERIVED_DATA=.build/ios python3 scripts/check-ios.py test ios/FocusMateTests/JourneySnapshotV4StorageTests.swift
- 결과: exit 65, 컴파일 실패. 원인은 전부 새 API 부재: `JourneySnapshot has no member 'paused'`, `ActiveJourneyValidationIssue has no member 'unknownStop'/'unknownBus'/'invalidPausedState'`, `cannot find 'paused'`.
- 참조 파일: design.md, prd.md(grep), FocusMateTests의 JourneySnapshotStorageTests/JourneySnapshotTests/BoardingTestDoubles/StorageTestSupport/SnapshotCodecTests/StorageV2Tests 및 버전 관련 grep. 프로덕션 코드 미참조.
