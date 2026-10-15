# T5 IMPLEMENT — RouteCatalog·Loader

## 구현 내용
- ios/FocusMate/RouteCatalog.swift: RouteDataMetadata, RouteVisit, RouteCatalogIssue, RouteNumberOrder(자연 정렬), RouteCatalog(검증·번호 정렬·색인·첫 지점 visits·방면).
- ios/FocusMate/RouteCatalogLoader.swift: JSONSerialization으로 스크립트 산출 JSON 파싱(좌표 ÷1e6, ARS "" → nil, 모르는 NODE_ID → unknownStop, 형식 오류 malformed).

## GREEN 증거
- `python3 scripts/check-ios.py test ios/FocusMateTests/RouteCatalogTests.swift` → Executed 16 tests, 0 failures

## REFACTOR 내역
- 정리 없음

## self-review 결과
- 기존 파일 미수정(새 파일만). 기존 이름과 충돌 없음(CoursePoint 재사용).

## 우려사항
없음
