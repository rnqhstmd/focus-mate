## Rulings
- T1 과잉 구현 정리 — JourneyCourse.seoulBounds는 테스트 미참조지만 설계서 인터페이스 명시 멤버라 유지(설계 예약). (틀리면: JourneyCourse.swift에서 seoulBounds 한 줄 삭제(참조 없음).)
- T2 과잉 구현 정리 — JourneyMapState.dismissThemeSheet()는 테스트 미참조지만 설계서 인터페이스 명시(시트 사용자 닫기 경로) → 유지. (틀리면: 메서드 한 줄 삭제.)
- T3 과잉 구현 정리 — JourneyMapController.nextStop 계산 프로퍼티 제거(설계 인터페이스 밖·테스트 미참조), focused 18/18 재통과. (틀리면: `var nextStop: CourseStop { JourneyCourse.stops[nextStopIndex] }` 한 줄 복원.)
- review Minor 12건 유예 · MEDIUM 7건 중 1건 정리·6건 유예 — 품질 Minor 12건 유예. 보안 MEDIUM 중 "타일 요청 외부 전달 정보 미문서화"는 문서만 고치는 동작 불변이라 design.md에 기록(정리). 나머지 MEDIUM(크래시 방어 2건·가상 코스 표기·법적 표기 수동 검증·카메라 전제·아이콘)은 동작 변경을 동반하거나 디자인 결정이라 유예. (틀리면: reports/review-deferred.md 목록에서 골라 RGR(크래시 방어) 또는 디자인 작업으로 처리.)

## Deferred
- [MEDIUM] JourneyCourse.swift:35-38 — 좌표 없는 정류장이면 preconditionFailure. 카탈로그 확장 시 nil 폴백으로.
- [MEDIUM] JourneyCourseProgress.swift:14-30 — CourseJourney init에 direction ±1·minutesPerStop>0 가드 없음(현재 validate가 선행 방어).
- [MEDIUM] JourneyMapView — 시각적 "가상 코스" 표기 없음(사용자 결정 필요).
- [MEDIUM] 법적 표기 가림 자동 검증 불가 → M-1·M-4 필수.
- [MEDIUM] 앱 카메라 갱신 후 follow 유지 전제 → M-3에 실기기 확인 추가.
- [MEDIUM] 따라가기 아이콘 location.fill 오해 → 디자인/W14 QE-3.
- [Minor] AC-36 시트 컨트롤 44pt 단언 누락(JourneyMapAccessibilityUITests:172-181).
- [Minor] AC-3·AC-4 UI 테스트 공허 통과 주석 명시 필요.
- [Minor] 큰 글자 시트 detent가 medium→large로 한 번 움직임(JourneyMapThemeSheet:8,44).
- [Minor] 백그라운드 복귀 대점프 시 1초 직선 미끄러짐(JourneyTimerView:56-58).
- [Minor] 위성에도 colorScheme dark(JourneyMapView:48).
- [Minor] 문구 리터럴 중복("도착했어요", "남은 시간", " 개", " km").
- [Minor] DEBUG 시계 줄이 375pt 폭에서 상단 버튼과 겹칠 수 있음.
- [Minor] JourneyMapDisplayTests test4~7 AC 번호 표기 불일치, 테스트 이름 규칙 혼재.
- [Minor] AC-25 부정 단언 고정 sleep.
- [Minor] 회전 중 버스 아이콘 방향 갱신 지연(.onEnd, 의도).
- [Minor] 최대 글자 값 잘림 가능(M-4).
- [Minor] 태스크 리뷰 유예: t1 7, t2 4, t3 6, t5 8, t6 5 — reports/t{N}-review.md.
