# W07 최종 검증 (2026-10-15)

- 빌드: `python3 scripts/check-ios.py build` 성공, 경고 기준선(5) 이하.
- iOS 테스트(시뮬레이터 FM-W07, iPhone 18 Pro / iOS 27.0):
  - 전체 1회 실행(중단 전 66 스위트 완료): 실패는 CardIssuanceFlowTests 2건뿐 — W07 DEBUG 버튼(test.main.failNextSave)이 발급 해제 버튼을 가린 회귀. 수정 후 CardIssuanceFlowTests 11/11 통과.
  - 미실행 13개 UI 파일 실행: 95건 중 ProfileUITests testAC20 2건 실패 — main 6b7d4b7에서도 동일 재현(기존 실패, 위험 수용). 원인 조사 중 메인 빈 포기 안내 자리·DEBUG 버튼 겹침도 정리.
  - 회귀 수정 후 영향 테스트 재실행: JourneyAbandon 포기 안내 4건, LifecycleSafety AC34, MainActiveJourneyCard AC35, NewJourneyUITests 전체 → 통과.
  - W07 focused: 단위 95/0, UI(JourneyResume·JourneyAbandon·JourneyLifecycleSafety·MainActiveJourneyCard·NewJourney·ActiveJourneyMain·BoardingLargeText) 통과, 회귀 V7 AC29·JourneyTimerUITests·DepartureBriefingUITests 통과.
- 웹: `npm test`, `npm run build` 통과.
- 이월: ProfileUITests AC20 기존 실패 2건, Release 빌드 DEBUG 제외 확인·확인 창 첫 VoiceOver 포커스(W14), 도착 화면 나가기(W09 전 외부 배포 금지).
