# W06 리뷰 유예 목록 (phase-review R1)

## 보안 MEDIUM (유예 5)
- [MEDIUM] JourneyCourse.swift:35-38 — 좌표 없는 정류장이면 preconditionFailure. 카탈로그 확장 시 nil 폴백으로.
- [MEDIUM] JourneyCourseProgress.swift:14-30 — CourseJourney init에 direction ±1·minutesPerStop>0 가드 없음(현재 validate가 선행 방어).
- [MEDIUM] JourneyMapView — 시각적 "가상 코스" 표기 없음(사용자 결정 필요).
- [MEDIUM] 법적 표기 가림 자동 검증 불가 → M-1·M-4 필수.
- [MEDIUM] 앱 카메라 갱신 후 follow 유지 전제 → M-3에 실기기 확인 추가.
- [MEDIUM] 따라가기 아이콘 location.fill 오해 → 디자인/W14 QE-3.

## 품질 Minor (리뷰 R1 12건 + 태스크 리뷰 30건, 요약)
- AC-36 시트 컨트롤 44pt 단언 누락(JourneyMapAccessibilityUITests:172-181).
- AC-3·AC-4 UI 테스트 공허 통과 주석 명시 필요.
- 큰 글자 시트 detent가 medium→large로 한 번 움직임(JourneyMapThemeSheet:8,44).
- 백그라운드 복귀 대점프 시 1초 직선 미끄러짐(JourneyTimerView:56-58).
- 위성에도 colorScheme dark(JourneyMapView:48).
- 문구 리터럴 중복("도착했어요", "남은 시간", " 개", " km").
- DEBUG 시계 줄이 375pt 폭에서 상단 버튼과 겹칠 수 있음.
- JourneyMapDisplayTests test4~7 AC 번호 표기 불일치, 테스트 이름 규칙 혼재.
- AC-25 부정 단언 고정 sleep.
- 회전 중 버스 아이콘 방향 갱신 지연(.onEnd, 의도).
- 최대 글자 값 잘림 가능(M-4).
- 태스크 리뷰 유예: t1 7, t2 4, t3 6, t5 8, t6 5 — reports/t{N}-review.md.
