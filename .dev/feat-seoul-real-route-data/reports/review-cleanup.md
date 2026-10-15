# Review cleanup (2회차 Important [동작불변] 2건)
1. ARS 이상 집계 일원화: routes.is_ars_anomaly 추가, RouteBuildResult.ars_anomalies를 산출 정류장(NODE_ID 1회) 기준으로 계산, build 요약 "ARS 5자리 아님"은 그 값 사용. ars_zero_filled 기본값 제거.
2. 최소 보정 판정 노출: segments.is_minimum_only 추가, build의 _run_seconds 복제 제거.
GREEN: python3 -m unittest discover -s scripts/tests -t scripts → OK. 실데이터 산출 SHA f691b6fc… 동일.
