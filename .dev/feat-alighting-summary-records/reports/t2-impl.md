# T2 IMPLEMENT (세션)

## 구현 내용
- 신규 ios/FocusMate/RecordsCalendar.swift: RecordDay(key 왕복·존재 검증·adding(days:)·from), RecordHeatLevel(0/1~30/31~60/61~120/121+), RecordDayCell(낭독 "M월 D일 · N회 · ProfileTimeText.spoken"), RecordYearSummary(0분이면 시간 생략), RecordsCalendar(leadingBlanks·cells·summary·records(on:) 최신순·latestRecordDay·yearOptions, 오늘 이후 기록 제외, instant 파서), RecordsEmptyState, RecordsBrowser(select 미래 거부·stepDay 연도 내·moveYear/selectYear 규칙·showMore·visible/hasMore·emptyState), RecordListItemContent(memoButtonTitle).

## GREEN 증거
RecordsCalendarTests 9/0, RecordsBrowserTests 13/0, T1 회귀(AlightingSnapshot 7, RecordMemoDraft 5) → 34 pass / 0 fail.

## REFACTOR 내역
- ISO8601DateFormatter를 정적 캐시로(정렬 비교마다 생성 → focused 4.8s → 0.05s). records(on:)를 컴파일러 타입 추론이 가능한 형태로 분해. RecordListItemContent가 RecordsCalendar.instant 재사용.

## self-review 결과
완전성: 22건 대응(red report의 10/14는 오기, 실제 9/13). 품질: 정렬 안정(동시각은 원순서). 규율: 테스트 무수정(해시 일치). 테스트: 경계는 today 고정.

## 우려사항
없음

## 과잉 구현 정리
- 유지(설계 예약): leadingBlanks, yearOptions, canGoPreviousYear, selectYear, RecordListItemContent의 task/minutesText/timeText/routeText/tag(설계 C9 명시, T7 화면에서 사용).
