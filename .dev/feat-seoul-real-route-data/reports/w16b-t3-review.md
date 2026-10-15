# W16b T3 태스크 리뷰 (reviewer sonnet)
- SPEC PASS (AC-24, 27~48, 78, 79 9묶음 전부 충족)
- QUALITY FAIL: Important 3 (동작결함 2, 동작불변 1), Minor 6
## Important
1. [동작결함] `--fm-ui-route boarding`: FocusMateApp.start가 startRouteData 직후 동기로 applyRoute → journeyOrigin nil → 설정 오류. 로딩 완료를 기다려야 함.
2. [동작결함] retryLoad: isRecovering 중 persistMigrationIfNeeded → save 거절, pendingMigration은 이미 nil → 파일이 v4로 남음.
3. [동작불변] InitialStationSearchView: body 한 번에 12k 검색 3회 → 한 번으로.
## Minor
- 정류장 재선택/확정 시 journeyPlan 선택이 남음
- 로딩 중 메인 "새 여정" 확인이 거절돼도 반응 없음(포기와 비일관)
- 이전 저장 실패 시 "출발 정류장 저장 실패" 문구가 사용자 행동 없이 뜸
- BR-16 재선택 저장 실패 시 재시도 없음(문서화)
- seedJourney 주석의 fallback 언급·기본값 정리
- [검증 필요] 포기 재선택 분기 후 timer.leave 되쓰기 — journeyID 가드로 막힐 것으로 보임
