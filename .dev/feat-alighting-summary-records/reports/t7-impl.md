# T7 IMPLEMENT (세션)

## 구현 내용
- UITestBootstrap.swift: recordSeeds(recordsMemo 12건 — records-memo-0 최신, 1번 "집중 잘됨"; recordsTwoYears — 오늘·작년 6/20·3/10), 실행일 로컬 정오 기준 생성, lifecycleSnapshot 경유.
- 신규 RecordsView.swift: 연도 바(records.year.previous/next/picker), records.summary, 잔디(격자 전체 adjustable 요소 records.heatmap, 칸 탭 선택, 미래 흐림), 날짜 목록(records.item/memo.<id>, records.more, records.empty 두 문구), 메모 시트, DEBUG test.records JSON·test.records.failNextSave·test.records.nextDay/previousDay(XCUITest가 adjustable 요소를 조정하지 못해 같은 stepDay를 부르는 대체 — 설계 C10 스파이크 결과).
- 신규 RecordMemoEditor.swift: RecordMemoDraft + 입력 원문 onChange 되돌려 쓰기(200자), updateRecordMemo, 실패 시 시트·입력 유지 + recordMemo.saveFailure.
- DestinationScreen.swift: .records → RecordsView, 자리표시 문구 제거.

## GREEN 증거
LifecycleSeedTests 21/0, RecordsUITests 3/3(1차 2 통과 + 잔디 조정 스파이크 실패 → DEBUG 이동 버튼 + red-writer R1 → 통과). 함께 T6 R3 정리 테스트 3건 재실행 통과.

## REFACTOR 내역
정리 없음.

## self-review 결과
예시 기록 경로 없음(snapshot.records만 읽음). 날짜 '오늘'은 recordClock.

## 우려사항
없음
