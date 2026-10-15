# T2 태스크 리뷰 R0 (sonnet, task-scoped)
SPEC PASS (8/8) · QUALITY FAIL · Critical 0 · Important 1 · Minor 5
Important [동작결함]: routes.py _stop_point — 좌표 "NaN"이면 Decimal 비교에서 InvalidOperation이 나 build_routes 전체 중단. AC-71은 해당 노선만 "좌표 이상" 제외 요구. → 재현 RED R2 → is_finite 검사 추가.
Minor (유예):
1. virtual_removed·tail_duplicates_removed가 나중에 제외되는 노선 행도 셈(집계 기준 명시 필요)
2. 그룹 키가 정규화 전 raw ROUTE_ID("100" vs "100.0" 분리 가능)
3. 타입 힌트 list/dict, 노선명 두 번 계산
4. test 이름 "끝이 가상인 정류장만 제거"가 내용(중간 행 제거)과 어긋남
5. 경도 범위 밖·경계값·같은 순번 원본 순서 케이스 없음

## 재리뷰 R1
ADDRESSED (is_finite). QUALITY PASS. Minor 2 추가: 좌표·운행시간 finite Decimal 헬퍼 중복, -Infinity·빈 좌표 케이스.
