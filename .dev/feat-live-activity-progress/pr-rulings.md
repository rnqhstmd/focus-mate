## Rulings
- T5 테스트 헬퍼 중복 정리 이월 — makeRigWithLeftovers 중복을 태스크 중 고치지 않고 phase-review 정리로 넘김 (틀리면: makeRig에 existing 매개변수를 두고 위임 — 리뷰 정리에서 수행 완료)
- review 동작 불변 정리 2건 + Minor 3건 정리 — 테스트 헬퍼 통합·RED 단계 주석 제거(red-writer), Parity 주석·Policy 주석·게이트웨이 선택 일원화(세션) (틀리면: reports/review-cleanup.md 목록으로 되돌림)
- review Minor 7건 유예 · MEDIUM 6건 — Minor 유예, MEDIUM은 문서 반영 4·증거 확인 2·동작 변경 동반 1건 유예 (틀리면: reports/review-deferred.md 항목을 후속 작업으로 엶)

## Deferred
- [Minor] JourneyLiveActivityPolicy.swift:53 — appearPlan 튜플 vs launchPlan 구조체 표현 불일치
- [Minor] JourneyLiveActivityCleanup.swift:9 / JourneyLiveActivitySync.swift:39 — 재실행 후 화면 진입 시 같은 일시정지 갱신이 한 번 더 나감
- [Minor] LiveActivityGateway.swift:102 — 기록기가 비활성 id의 update/end도 기록(잘못된 순서 검출 약함)
- [Minor] JourneyLiveActivityPolicyTests.swift:21 — AC-31 테스트가 CourseJourney == nil 전제를 단언하지 않음
- [Minor] context/journey/status.md:38 — 설계 수정 표 밖 문서 변경(W15 보조 기록)
- [Minor] JourneyView.swift:36 — Sync now 기본값 Date()(UI 테스트 수동 시계와 무관, 값 단언 없음)
- [Minor] JourneyLiveActivityWidget.swift — 일시정지·만료 때 설명 라벨과 시간 텍스트 이중 낭독, 위젯 private statusName 이름 중복(M-9에서 확인)
- [MEDIUM] JourneyLiveActivityPolicy.swift:53-56 / JourneyLiveActivitySync.swift:50-56 — 앱 시작 정리와 화면 진입 정리의 중복 카드 선택 경합(비동기 end), 후속
- 태스크 리뷰 유예 Minor: reports/t1, t4, t5, t6, t9, t11-review.md
