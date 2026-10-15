## Rulings
- T5 테스트 도우미 중복 정리 유예 — UI 테스트 3파일의 resumeFromMain 등 복제를 이번 브랜치에서 정리하지 않음 (틀리면: UITestLaunchSupport 확장으로 옮기고 3파일 재실행)
- T5 Minor 처리 — JourneyView 하단 inset 주석을 실제 동작으로 수정, 나머지 Minor 유예 (틀리면: 주석 한 줄 되돌리기)
- review 동작 불변 정리 1건 — docs/FLOWS.md 없어진 임시 안내 문장 삭제·저장 형식 버전 문장 정정 (틀리면: 두 줄 되돌리기)
- review Minor 7건 유예 · MEDIUM 11건 중 1건 정리·10건 유예 — 동작 변경 동반·출시 게이트·W05 이월 항목은 RED 없이 손대지 않음 (틀리면: review-deferred.md 항목을 후속 RGR)

## Deferred
- [Minor] context/journey/status.md — `W07 [#TBD]` 자리표시자(PR 번호로 교체 예정)
- [Minor] JourneyLifecycleSafetyUITests testAC32 — 카드/버튼 별도 요소 단언 중 항상 참인 1줄
- [Minor] NewJourneyUITests testAC12 — 여정 없음 전제를 손상 시드로 만듦(ready 시드 권장)
- [Minor] JourneyResumeUITests testAC30 — 백그라운드 저장을 writeAttempts +1로 단언하지 않음
- [Minor] UITestLaunchSupport persistedState() — 관대한 파싱
- [Minor] AppModel+JourneyLifecycle — card nil·reachedStation nil 방어(도달 불가 판단)
- [Important·Ruling] UI 테스트 도우미 중복
- [MEDIUM] 도착 화면 나가기 없음 — W09 전 외부 배포 금지
- [MEDIUM] 체크포인트 실패 후 포기 시 도달 정류장 한 칸 뒤 가능
- [MEDIUM] saveJourneyProgress 단조성·도착 불변 가드(W05 이월)
- [MEDIUM] 백그라운드 중 시스템 종료 안내 없음(W05 이월)
- [MEDIUM] Release 빌드 DEBUG 제외 실증(W14)
- [MEDIUM] confirmNewJourney .rejected 무반응(도달 불가 판단)
- [MEDIUM] 포기 버튼·실패 문구 dynamicType 상한 accessibility3
- [MEDIUM] alert 첫 VoiceOver 포커스·전환 중 낭독(W14)
- [MEDIUM] 도착 여정 새 여정 확인 문구 "그만두고" 고정(W09)
- [MEDIUM] 손상 여정 무음 폐기(W05 결정 유지)
- [기존 실패] ProfileUITests testAC20 최대 글자 크기 2건 — main에서도 실패, 후속 수정 필요
