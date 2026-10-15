
## 2026-10-15 19:25 · Ruling: T1 과잉 구현 정리

**판정.** RecordClock, AlightingIssue.unknownCatalog는 focused 테스트가 참조하지 않지만 설계서 C1이 명시한 멤버라 "설계 예약"으로 유지.
**근거.** verify_implement 5 기본값 표 — 설계 명시 멤버는 제거하지 않는다.
**틀리면.** T5에서 미사용이면 제거(JourneyAlighting.swift).

## 2026-10-15 19:31 · Ruling: T2 과잉 구현 정리

**판정.** focused가 참조하지 않는 leadingBlanks·yearOptions·canGoPreviousYear·selectYear·RecordListItemContent 표시 필드는 설계서 C9 명시 멤버라 유지.
**근거.** 기본값 표 — 설계 명시 멤버는 "설계 예약".
**틀리면.** T7 화면에서 쓰지 않으면 제거.

## 2026-10-15 21:03 · Ruling: 잔디 VoiceOver 조정 UI 테스트 대체

**판정.** XCUITest가 슬라이더가 아닌 adjustable 요소를 조정하지 못해(NSInvalidArgumentException) DEBUG 버튼 test.records.nextDay/previousDay(같은 stepDay 호출)로 UI 검증을 대체. 실제 VoiceOver 증감은 W14 실기기.
**근거.** 설계 2회차 C10 스파이크 규칙(안 되면 대체). 날짜별 DEBUG 버튼은 두지 않음.
**틀리면.** RecordsView DEBUG 버튼 2개 제거, 좌표 탭 방식으로 교체.

## 2026-10-15 21:03 · Ruling: 마이페이지 큰 글자 실패는 테스트 결함

**판정.** ProfileUITests testAC20 2건은 스크롤 뷰가 된 메인에서 스크롤 없이 isHittable을 단언하던 테스트 결함. reachVisible로 교체 후 진입 뒤 검증(내비바 겹침·3회 스와이프)까지 통과 — 화면 변경 없음.
**근거.** reports/profile-ac20-investigation.md, reports/t8-red.md.
**틀리면.** 실기기 큰 글자(W14)에서 화면 결함이 보이면 별도 수정.

## 2026-10-15 21:10 · Ruling: review 동작 불변 정리 1건

**판정.** AlightingFlowUITests AC-22 단언(없는 식별자 journey.pause)을 실제 식별자 journey.timer.pause/resume·journey.abandon 부재 단언으로 정리하고 하차 태그 화면에도 추가(red-writer R4).
**근거.** phase-review 4b 기본값 — 동작 불변 정리는 수행.
**틀리면.** reports/t6-red.md "## 수정 R4" 참고해 되돌림.

## 2026-10-15 21:10 · Ruling: review Minor 38건 유예 · MEDIUM 5건 유예

**판정.** quality Minor 38건 유예. security MEDIUM 5건은 모두 동작 변경을 동반(요약 출구 안내, 하차 단락 id 대조·요약 초기화, 미래 날짜 기록 노출 정책, 오늘 갱신, 메모 단위)해 RED 없이 손대지 않고 유예.
**근거.** phase-review 4c 기본값 — 동작 변경·모호 MEDIUM은 유예.
**틀리면.** reports/review-deferred.md 항목을 후속 작업(W09b/W14)에서 RGR로 처리.
