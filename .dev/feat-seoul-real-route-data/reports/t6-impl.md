# T6 IMPLEMENT — StationSearch

## 구현 내용
- ios/FocusMate/StationSearch.swift: StopSearchOption(접근성 "이름, 번호, 방면"에서 없는 값 생략), StationSearchResult(prompt/empty/results+overflow), StationSearch.search — 숫자만이면 번호 정확→앞자리(번호 문자열 순), 그 밖은 이름 정확→앞부분→부분(이름 < → 번호(없으면 뒤) → id), 50건.

## GREEN 증거
- `check-ios.py test StationSearchTests.swift RouteCatalogTests.swift` → Executed 29 tests, 0 failures

## REFACTOR 내역
- 정리 없음

## self-review 결과
- 새 파일 1개만. 기존 StationOption과 이름 충돌 없음(StopSearchOption).

## 우려사항
없음
