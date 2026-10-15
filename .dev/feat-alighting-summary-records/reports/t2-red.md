# t2 RED report
- 테스트 파일: ios/FocusMateTests/RecordsCalendarTests.swift (10건), ios/FocusMateTests/RecordsBrowserTests.swift (14건) = 24건 (RecordsCalendarTests의 공유 헬퍼 record(...) 사용)
- 실패 확인 명령: FOCUSMATE_SIMULATOR_ID=7D81AFEE-... python3 scripts/check-ios.py test <두 파일>
- 실패 메시지: cannot find 'RecordDay' / 'RecordHeatLevel' / 'RecordsCalendar' / 'RecordsBrowser' in scope (컴파일 실패 = NoSuchMethod RED). 로그: scratchpad/t2-red.log
- 참조한 파일: ios/FocusMateTests/RecordSectionTests.swift(RecordSnapshot 생성), 디렉터리 목록
