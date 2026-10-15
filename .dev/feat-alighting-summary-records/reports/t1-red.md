# t1 RED 보고
- 테스트 파일(전문은 해당 파일 참조): ios/FocusMateTests/AlightingSnapshotTests.swift (7케이스), ios/FocusMateTests/RecordMemoDraftTests.swift (5케이스)
- 실패 확인 명령: FOCUSMATE_SIMULATOR_ID=7D81AFEE-FC29-4E6F-8E2C-195C022C52A6 python3 scripts/check-ios.py test ios/FocusMateTests/AlightingSnapshotTests.swift ios/FocusMateTests/RecordMemoDraftTests.swift
- 실패 메시지: error: value of type 'AppSnapshot' has no member 'alightingActiveJourney' / cannot find type 'AlightingIssue' in scope (로그: scratchpad/t1-red.log)
- 실패 사유: 신규 심볼 미존재 컴파일 실패 (NoSuchMethod 유형)
- 가정: bus 기록값 "버스2014"(기존 기록 형식), 도착=departed+elapsed 1500+paused, 미도착=elapsed 600
- 참조: BoardingTestDoubles.swift, StorageTestSupport.swift, JourneyReachTests.swift, RecordSectionTests.swift(1-120, input 헬퍼), RecordStorageTests.swift(1-140)
- 수정: AC-10 필드 케이스의 bus 기댓값을 "버스2014"에서 "2014"로 변경(BusLine.number 규칙, 코디네이터 지시). 가정 2번은 폐기.
