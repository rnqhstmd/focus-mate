# Deferred (phase-review 1회차)

## security MEDIUM (동작 변경 동반 — 유예)
- [MEDIUM] AppModel+Alighting.swift:55-64, AlightingSummaryView.swift:79-81 — 요약 메모 저장 .rejected 무안내, 반복 실패 시 메모 비워야만 탈출
- [MEDIUM] AppModel+Alighting.swift:34, AppModel.swift:177,201,203,233 — 이미-저장 단락 id 미대조, 요약 상태 미초기화(도달 경로 거의 없음)
- [MEDIUM] RecordsCalendar.swift:142-144,217 — 미래 날짜 기록 기록 화면 숨김 vs 통계 포함(정책 필요, W09b)
- [MEDIUM] RecordsView.swift:16, RecordsCalendar.swift:229-233 — 오늘 고정·목록 시각 시간대 기준
- [MEDIUM] RecordMemoDraft.swift:3-28 — 메모 200자 UTF-16 단위(W08 규칙과 일치, 체감 글자 수와 다름)

## quality Minor (유예)
- 신규 15: AC-5 UI 단언 공허(기존 W15 단위 테스트가 커버), 카탈로그 밖 도착 여정 출구 없음(로드 검증이 거르면 도달 불가), 아래 깔린 JourneyScreen의 scenePhase 반응·포커스 경합(W14), 요약 상태 미초기화, AlightingTagView [weak model] 무의미, 잔디 가로 스크롤 초기 위치, 오늘 고정, canGoPreviousYear 하한 1(프로토타입 1000), records(on:) 반복 계산, 메모 입력 한 줄/여러 줄 불일치, 잔디 색 하드코딩·월/요일 라벨 없음, 마이페이지 0 단언 느슨, QE-3 새 화면 최대 글자 UI 검증 없음, ProfileUITests 통과 근거(t8-red 실행 로그 + 전체 실행에서 재확인), 프로토콜 정의 위치 설계와 다름
- 태스크 리뷰 유예 23: reports/t1-review.md(4), t3-review.md(4), t5-review.md(4), t6-review.md(5), t7-review.md(6)
