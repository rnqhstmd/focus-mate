# T2 IMPLEMENT — 노선 정리·기본정보 결합

## 구현 내용
- scripts/route_data/routes.py: normalize_integer, normalize_ars, StopPoint, CleanRoute, RouteBuildResult, JoinRateError, build_routes.
- 노선별 처리: ID 정규화(실패 시 "ID 오류") → 순번 정수 정렬 → 좌표 검사("좌표 이상") → "(가상)" 끝 지점 제거 → 연속 NODE_ID 합치기 → 끝 중복 제거 → 2개 미만("정류장 부족") → 결합("기본정보에 없는 노선") → 한강·관광("유형 제외"), 빈 유형 "심야".

## GREEN 증거
- `cd scripts && python3 -m unittest discover -s tests -t .` → Ran 42 tests, OK (T1 14 + T2 28, 0 fail)
- 실데이터: 포함 노선 712, 유형 제외 6(한강·관광), 가상 지점 제거 900행, 끝 중복 130노선, 공동운행 중복 번호 81, ARS 이상 2, 결합률 100%, 정류장 12,758, 운행시간 없음/0 노선 49.

## REFACTOR 내역
- 정리 없음

## self-review 결과
- 완전성: 인터페이스 전부. 명세 정정(열 이름 "운행시간")은 재현 RED R1로 테스트 먼저 수정 후 구현 반영.
- 규율: 테스트 파일 미수정(구현 측). 테스트: 42/42.

## 우려사항
없음

## Fix R1 (리뷰 Important — NaN 좌표)
- _stop_point에 latitude/longitude is_finite 검사 추가 → None("좌표 이상").
- GREEN: cd scripts && python3 -m unittest tests.test_xlsx tests.test_routes → OK (43)
