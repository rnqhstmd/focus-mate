# T11 태스크 리뷰 (sonnet, scoped)
SPEC PASS (7/7) · QUALITY PASS · C0 I0 · Minor 4 (유예)
- UI 테스트 부정 단언에 0.5초 고정 대기
- 재개 endDate 값 근접 확인 없음(단위 테스트 AC-4/9가 정확값 보장)
- DEBUG 비테스트에서 journeyServices가 .live() 재생성(무상태라 무해)
- JourneyServices 기본값이 실제 게이트웨이(UI 테스트는 항상 기록기로 덮어씀)
