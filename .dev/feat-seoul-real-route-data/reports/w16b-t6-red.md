# W16b T6 RED
- 신규: ios/FocusMateTests/RouteDataBundleTests.swift (AC-50,52,53,54,56 + 규모/메타데이터 회귀 + 후보0건 비율 print), RouteDataOfflineTests.swift (AC-51)
- 실행하지 않음 (오케스트레이터 실행). 프로덕션 코드 미열람.
- 성능 수치는 print "[T6] ..." 로 출력.
- 참고: 최다 노선 정류장은 visits(stopIndex:) 전수 스캔, Elapsed 단위/타입은 Int 가정.

## 실행 결과 (오케스트레이터, Debug 시뮬레이터 FM-W16)
- RouteDataBundleTests 8 + RouteDataOfflineTests 1 = 9 pass (프로덕션 변경 없이 통과 — 실데이터 회귀 검증)
- AC-52 검색 20회 평균 0.0103s, 최대 0.0286s (≤ 0.3s)
- AC-53 최다 노선 정류장 '인천공항1층입국장'(37노선) 후보 20회 평균 0.00045s, 최대 0.0012s (≤ 0.2s)
- AC-54 번들 로드 20회 평균 0.166s, 최대 0.214s (≤ 1s)
- AC-56 번들 1,693,124 바이트 (≤ 10MB)
- 25분 후보 0건 비율 9% (18/200)
