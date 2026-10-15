## Trust Ledger

### 위험 수용
- [전체 테스트 미실행] 사용자 지침(feedback-full-test-once: 이번 작업 테스트만 통과하면 다음 단계)에 따라 기준선·verify에서 전체 스위트를 돌리지 않고 focused 집합만 실행 (implement/Step 0.5)
- [T4 회귀 가드 RED 불가] AC-29 위치 키 부재는 이미 충족 상태라 실패 테스트를 먼저 만들 수 없음 → AppInfoLocationTests를 회귀 가드로 추가하고 T5에 병합 (implement/Step 1)
- [T0 스파이크 비-RGR] 지도 접근성 트리·안전 영역 확인용 임시 코드를 테스트 선행 없이 작성 후 전부 삭제, 결과만 spike-map-a11y.md에 기록 (implement/T0)
- [AC-3·AC-4 UI 단언 약화] 지도 내부를 accessibilityHidden으로 숨겨(FR-12) Legal 링크·MapKit 컨트롤이 접근성 트리에서 빠짐 → AC-3은 M-1(수동), AC-4는 코드 리뷰 체크리스트(mapControls 3종 hidden, interactionModes에 .pitch 없음, UserAnnotation/MapUserLocationButton 없음)로 보증 (implement/T6)
- [AC-37 포커스 수동화] VoiceOver 초기 포커스는 시뮬레이터에서 관찰 불가(@AccessibilityFocusState가 VO 꺼짐에서 false) → 테스트에서 제외, M-2 수동 확인 (implement/T6)

### 통합 감사 (review R1)
- security-auditor: CRITICAL 0, HIGH 0, MEDIUM 6 — 전문 reports/security-r1.md
  - [GAP/MEDIUM] 좌표 누락 시 preconditionFailure(Release 크래시) — 유예(동작 변경, 카탈로그 확장 시 처리)
  - [RISK/MEDIUM] CourseJourney가 direction ±1·minutesPerStop>0 불변식을 스스로 지키지 않음(현재는 JourneySnapshot.validate가 선행 방어) — 유예(동작 변경)
  - [POLICY/MEDIUM] "가상 코스" 시각 표기 없음(BR-1 오인 위험) — 유예, 사용자 결정 필요(디자인 스펙/W14 QE-3)
  - [POLICY/MEDIUM] 법적 표기 가림 자동 검증 불가·첫 프레임 bottomHeight 0 — 유예, M-1·M-4 필수 수동 항목
  - [ASSUMPTION/MEDIUM] 앱 카메라 갱신이 positionedByUser를 일으키지 않는다는 전제 — 유예, M-3에 "가만히 두고 follow 유지" 확인 추가
  - [GAP/MEDIUM] 타일 요청 외부 전달 정보 미문서화 — 정리(design.md 리뷰 반영 메모에 기록)
  - [RISK/MEDIUM] 따라가기 아이콘 location.fill이 내 위치로 오해 — 유예(디자인, W14 QE-3)
- reviewer: SPEC PASS 40/40, QUALITY PASS(Critical 0, Important 0, Minor 12) — 전문 reports/review-r1.md
