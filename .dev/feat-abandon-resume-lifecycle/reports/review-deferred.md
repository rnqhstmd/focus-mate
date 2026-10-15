# Review Deferred (W07)

## quality Minor (통합 리뷰 R1)
- [Minor] docs/CURRENT-STATE.md — final-verification.md 링크(complete 단계에서 생성 예정)
- [Minor] context/journey/status.md — `W07 [#TBD]` 자리표시자 4곳(PR 번호 확정 후 교체)
- [Minor] JourneyLifecycleSafetyUITests testAC32 카드/버튼 별도 요소 — 항상 참 단언 1줄
- [Minor] NewJourneyUITests testAC12 — 여정 없음 전제를 손상 시드로 만듦(ready 시드 권장)
- [Minor] JourneyResumeUITests testAC30 — 백그라운드 저장을 writeAttempts +1로 단언하지 않음
- [Minor] UITestLaunchSupport persistedState() 관대한 파싱
- [Minor] AppModel+JourneyLifecycle mainStartTitle/confirmNewJourney — card nil·reachedStation nil 방어(도달 불가로 판단)
- [Important·Ruling] T5 UI 테스트 도우미 중복(resumeFromMain·launchPaused·announcement 세기)

## security MEDIUM (통합 감사)
- [MEDIUM] 도착 상태 타이머 화면에 나가는 길 없음 — W09 하차 전 출시 금지(출시 게이트)
- [MEDIUM] 체크포인트 저장 실패 직후 포기 시 도달 정류장이 마지막 저장 경과 기준(화면보다 한 칸 뒤 가능) — 설계 위험 5로 수용
- [MEDIUM] saveJourneyProgress 단조성·도착 불변 가드 없음(W05 이월)
- [MEDIUM] 백그라운드 중 시스템 종료 안내 없음(W05 이월, W14)
- [MEDIUM] Release 빌드에서 DEBUG 코드 제외 실증 없음(W14 출시 게이트: Release 빌드 + strings 확인)
- [MEDIUM] confirmNewJourney .rejected 무반응(도달 불가로 판단)
- [MEDIUM] 포기 버튼·실패 문구 dynamicType 상한 accessibility3(타이머 버튼과 동일 정책)
- [MEDIUM] alert 첫 VoiceOver 포커스·전환 중 낭독(W14 실기기)
- [MEDIUM] 도착 여정 새 여정 확인 문구가 "그만두고"로 고정(W09에서 하차로 대체)
- [MEDIUM] 손상 여정 무음 폐기·원본 사본 없음(W05 결정 유지)
