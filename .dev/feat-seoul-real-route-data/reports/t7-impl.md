# T7 IMPLEMENT — RouteLeg

## 구현 내용
- ios/FocusMate/RouteLeg.swift: RouteLeg, RouteLegFinder.leg — 첫 지점부터 회차·여러 바퀴 진행, 출발 정류장은 도착 후보 제외, ±60초 안 최소 차이(동률 이른 지점), T+60 초과 시 중단. 비례 조정은 정수식 (2·seg·T+O)/(2·O), 마지막이 흡수, 1초 미만이면 nil.

## GREEN 증거
- RouteLegTests + StationSearchTests + RouteCatalogTests → Executed 44 tests, 0 failures

## REFACTOR 내역
- 정리 없음

## self-review 결과
- 새 파일 1개. 테스트 결함(정류장 id "X"→"S6")은 red-writer가 수정(테스트 결함 수정 R1), 구현 측 테스트 미수정.

## 우려사항
없음
