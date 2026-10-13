# Deferred (review R1)

## security MEDIUM
- [MEDIUM] 저장 경로 단일화 가정 — W01 병합 시 모든 저장이 AppModel.save를 거치는지 확인 (AppModel+JourneyStart.swift:25-28)
- [MEDIUM] 검색 화면 저장 실패 문구가 원인 무관 "다시 눌러 주세요", VoiceOver 알림 없음 (InitialStationSearchView.swift)
- [MEDIUM] 카탈로그 밖 정류장 id면 시간 선택이 막힘 — W04 이후 재검토 (RouteData.swift:33-36)
- [MEDIUM] VoiceOver 중복 낭독(테스트용 accessibilityValue)·시간 변경 시 선택 해제 알림 없음 (TimeSelectionView.swift)
- [MEDIUM] confirmInitialStation 카탈로그 소속 검증·StationOption.init 범위 검사 없음 (AppModel+JourneyStart.swift, RouteData.swift)

## quality Minor (요약)
- N1 JourneyStartModelTests:128 choose 결과 미사용 경고·미단언
- N2 작은 기기 XXXL 스크롤 영역 협소 [검증 필요]
- N3 UI 테스트 helper 5개 파일 중복
- N4 LargeTextUITests 테스트 이름 "WithoutScrolling" 부정확
- N5 design.md W03 인계가 없는 파일명(FirstStationTimeFlowTests) 지칭 → 실제 PreparationFlowUITests
- N6 DestinationScreen DEBUG 진단(설계 승인, 관례)
- N7 TimeSelectionUITests 테스트 이름·경계 테스트 표현
- t1~t6 태스크 리뷰 유예 21건 (reports/t{1..6}-review.md)
