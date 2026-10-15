## Audit Summary
- 총 5건 (CRITICAL: 0, HIGH: 0, MEDIUM: 5) — 모두 동작 변경 동반이라 유예
- 요약 화면 메모 저장이 .rejected일 때 무안내·반복 실패 시 메모를 비워야만 탈출
- 하차 '이미 저장' 단락의 여정 id 미대조·요약 상태 미초기화(현재 도달 경로 거의 없음)
- 오늘 이후 날짜 기록(시간대 이동·시계 변경)이 기록 화면에서 숨고 통계에는 포함
- 기록 화면 '오늘' 고정, 메모 200자가 UTF-16 단위(W08 규칙과 일치)
- 정합: 하차 원자 저장, 중복 방지, 우회 차단, DEBUG 경계, 개인정보
- 리뷰: SPEC PASS 34/34, Critical 0, Important 1(테스트 단언, 정리 완료), Minor 38 유예

## Rulings
- T1 과잉 구현 정리 — RecordClock·AlightingIssue.unknownCatalog는 설계 명시 멤버라 유지 (틀리면: 미사용 시 JourneyAlighting.swift에서 제거)
- T2 과잉 구현 정리 — leadingBlanks·yearOptions·canGoPreviousYear·selectYear·RecordListItemContent 표시 필드는 설계 명시 멤버라 유지 (틀리면: 화면 미사용 시 제거)
- 잔디 VoiceOver 조정 UI 테스트 대체 — XCUITest가 adjustable 요소를 조정하지 못해 DEBUG test.records.nextDay/previousDay(같은 stepDay)로 대체, 실제 VoiceOver는 W14 (틀리면: DEBUG 버튼 제거 후 좌표 탭 방식)
- 마이페이지 큰 글자 실패는 테스트 결함 — 스크롤 없이 isHittable을 단언하던 테스트를 reachVisible로 교체, 화면 변경 없음 (틀리면: W14 실기기에서 화면 결함 발견 시 별도 수정)
- review 동작 불변 정리 1건 — AC-22 UI 단언의 없는 식별자를 실제 식별자 부재 단언으로 정리하고 하차 태그 화면에도 추가 (틀리면: reports/t6-red.md "수정 R4"로 되돌림)
- verify 실패 1건은 낡은 테스트 가정 — Phase1FlowTests가 기록 화면을 빈 화면(뒤로 버튼만)으로 단언해, 기록은 진입·복귀만 확인하고 설정만 빈 화면 단언 유지 (틀리면: 기록 화면 버튼 수 단언을 RecordsUITests로 옮김)
- verify 경고 정리 — 승차·하차 태그 화면의 weak 캡처 무효 경고(main에도 있던 것 포함)와 미사용 반환값 경고를 지역 바인딩·static 함수로 정리, 동작 동일 (틀리면: 두 View의 onAppear를 이전 형태로 되돌림)
- review Minor 38건 유예 · MEDIUM 5건 유예 — 동작 변경 동반 MEDIUM은 RED 없이 손대지 않음 (틀리면: review-deferred.md 항목을 W09b/W14에서 RGR로 처리)

## Deferred
- [MEDIUM] AppModel+Alighting.swift:55-64, AlightingSummaryView.swift:79-81 — 요약 메모 저장 .rejected 무안내, 반복 실패 시 탈출 경로
- [MEDIUM] AppModel+Alighting.swift:34, AppModel.swift:177,201,203,233 — 이미-저장 단락 id 미대조, 요약 상태 미초기화
- [MEDIUM] RecordsCalendar.swift:142-144,217 — 미래 날짜 기록 노출 정책(W09b)
- [MEDIUM] RecordsView.swift:16, RecordsCalendar.swift:229-233 — 오늘 고정·목록 시각 시간대
- [MEDIUM] RecordMemoDraft.swift:3-28 — 메모 200자 UTF-16 단위
- [Minor] AlightingFlowUITests — AC-5 UI 단언이 시드상 공허(기존 W15 단위 테스트가 커버)
- [Minor] JourneyView.swift:46-48 — 카탈로그 밖 도착 여정은 도착 안내가 없어 출구 없음(로드 검증이 거르면 도달 불가)
- [Minor] JourneyView.swift:107-117 — 아래 깔린 여행 화면의 scenePhase 반응·포커스 경합 가능(W14)
- [Minor] RecordsView.swift:72 — 잔디 가로 스크롤 초기 위치가 오늘이 아님
- [Minor] RecordsCalendar.swift:204 — 이전 연도 하한 1(프로토타입 1000)
- [Minor] RecordsView.swift:101-151 — records(on:) 반복 계산
- [Minor] RecordMemoEditor.swift:26 / AlightingSummaryView.swift:33 — 메모 입력 한 줄/여러 줄 불일치
- [Minor] RecordsView.swift:137-145 — 잔디 색 하드코딩·월/요일 라벨 없음
- [Minor] QE-3 — 새 화면 최대 글자 UI 검증 없음(W14)
- [Minor] 기타 태스크 리뷰 유예 23건 — reports/t1·t3·t5·t6·t7-review.md
