## Trust Ledger

### 통합 감사 (review)
- [GAP/MEDIUM] 요약 화면 출구: updateRecordMemo가 .rejected(launchState 비정상)면 안내 없이 머묾, 메모 저장이 계속 실패하면 메모를 비워야만 나갈 수 있음
  - 근거: AppModel+Alighting.swift:55-64, AlightingSummaryView.swift:79-81
  - 권고: .rejected도 실패 안내, 반복 실패 시 "메모 없이 메인으로" 노출 (기록은 이미 저장 — 데이터 손실 없음)
- [RISK/MEDIUM] alightJourney 이미-저장 단락이 여정 id를 대조하지 않고, loadSnapshot·confirmCleanup이 alightingSummary를 지우지 않음
  - 근거: AppModel+Alighting.swift:34, AppModel.swift:177,201,203,233
  - 권고: summary.recordID 대조 또는 경로 초기화 시 summary 초기화 (현재 흐름에서 도달 경로 거의 없음)
- [GAP/MEDIUM] 오늘 이후 날짜 기록(시간대 이동·시계 변경)이 기록 화면에서 숨고 마이페이지 통계에는 포함, emptyState 문구 불일치
  - 근거: RecordsCalendar.swift:142-144,217, RecordSection.swift:85-88
  - 권고: 미래 날짜 기록 노출 정책 확정 후 기준 통일
- [GAP/MEDIUM] RecordsView '오늘'이 화면 생성 시 고정(자정 넘김 시 stale), 목록 시각은 현재 시간대 기준
  - 근거: RecordsView.swift:16, RecordsCalendar.swift:229-233
- [ASSUMPTION/MEDIUM] 메모 200자 = UTF-16 200단위(W08 저장 검증과 일치), 이모지·결합 문자에서 체감 글자 수와 다름
  - 근거: RecordMemoDraft.swift:3-28, RecordSection.swift:158
  - 권고: PRD에 단위 명시 또는 문자 단위로 변경
- 정합 확인: BR-3 원자 저장, BR-2 중복 방지, BR-1/FR-8 우회 차단, DEBUG 경계(#if DEBUG), 개인정보(로그·진단·Live Activity에 메모 미노출), 시간대 처리.

### 리뷰 품질 요약 (reviewer Part 2)
- SPEC PASS 34/34 · Critical 0 · Important 1 [동작불변](AC-22 UI 단언이 없는 식별자 journey.pause 사용 → 항상 통과) → red-writer R4 정리 · Minor 38(신규 15 + 태스크 유예 23) 유예

### 위험 수용
- [ProfileUITests AC20 기존 실패] main에서도 실패하던 2건은 테스트 결함으로 판정해 테스트만 수정(implement/T8)
- [잔디 VoiceOver 조정 UI 미검증] XCUITest가 adjustable 요소를 조정하지 못해 DEBUG 이동 버튼으로 대체, 실제 VoiceOver 조정은 W14(implement/T7)
