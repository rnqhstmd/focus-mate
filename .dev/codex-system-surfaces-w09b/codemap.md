# W09b 초기 코드 맵
- ios/FocusMate/RecordSection.swift: RecordSnapshot, RecordSection.validate, 실제 하차 기록/예시배제/중복저장 방지
- ios/FocusMate/RecordsCalendar.swift: RecordDay, 저장date 날짜집계/미래제외, RecordsBrowser, RecordListItemContent
- ios/FocusMate/RecordsView.swift: 기존기록·잔디·메모시트. 분석진입추가 지점
- ios/FocusMate/RecordMemoEditor.swift: 기존저장·실패·취소 계약 재사용
- ios/FocusMate/AppModel.swift / AppModel+Alighting.swift: 저장·요약·기록 권위. W09b저장변경없음
- ios/Shared/: app/widget 공용 Foundation타입. app전용 RecordSnapshot참조금지
- designs/final/animation-preview.html: 기존analytics 주/월·태그·insight경험
- .claude/config.json: ios-swiftui focused python3 scripts/check-ios.py test {files}
