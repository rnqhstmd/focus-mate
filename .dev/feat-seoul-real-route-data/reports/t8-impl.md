# T8 IMPLEMENT — RouteCandidates

## 구현 내용
- ios/FocusMate/RouteCandidates.swift: RouteCandidate(id=routeID, distanceText 0.1km 반올림, accessibilityLabel), RouteCandidates.candidates — visits 노선마다 RouteLegFinder, (차이, 노선 정렬 색인) 정렬, 20건.

## GREEN 증거
- RouteCandidatesTests + RouteLegTests + StationSearchTests + RouteCatalogTests → Executed 60 tests, 0 failures

## REFACTOR 내역
- 정리 없음

## self-review 결과
- 새 파일 1개, 기존 JourneyPlanner/JourneyCandidate 미수정.

## 우려사항
없음

## 실데이터 후보 0건 비율(PRD 성공 지표, Python으로 같은 규칙 재현, 15~360분)
- 노선 많은 정류장 상위 200 표본 40: 0.4% (평균 노선 19.8, 평균 후보 14.5)
- 중간 표본 40: 3.2% (평균 노선 2.0)
- 노선 적은 하위 표본 40: 16.2% (평균 노선 1.0)
- 무작위 300정류장(5분 간격): 9.0%. 노선 1개 정류장이 전체의 44%.
