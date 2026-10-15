# T3 IMPLEMENT — 구간 거리·시간

## 구현 내용
- scripts/route_data/segments.py: EARTH_RADIUS_M, MIN_SEGMENT_SECONDS, FALLBACK_SPEED_KMH, OTHER_SPEED_KMH, MIN_PLAUSIBLE_SPEED_KMH, distance_meters(하버사인 floor(d+0.5)), loop_meters(회차 포함 n구간), uses_run_minutes, allocate_seconds(운행시간: S<30n→전부 30, 최소 고정 반복 + 최대 잔여 / 대체 속도: max(30, round_half_up(m×3.6÷v))). 계산은 Fraction.

## GREEN 증거
- `cd scripts && python3 -m unittest tests.test_xlsx tests.test_routes tests.test_segments` → OK (14 + 29 + 28 = 71, 0 fail)
- 실데이터: 712노선 중 운행시간 사용 노선은 한 바퀴 합 = 운행시간×60 (불일치 0). 541번(1190분)은 R1 규칙으로 대체 속도.

## REFACTOR 내역
- _round_half_up를 Fraction floor(x+1/2) 한 줄로 정리, 미사용 import 제거.

## self-review 결과
- 완전성·규율 OK(테스트 미수정). R1/R1b: 실데이터 이상값 → 하한 3km/h 규칙(테스트 먼저).

## 우려사항
- run_minutes가 0 초과지만 S=round(×60)=0인 극소값(예 0.001분)이면 uses_run_minutes에서 0으로 나눔. 실데이터 운행시간은 정수 분이라 미발생 — 관찰.

## Fix R1 (리뷰 Important — 극소 운행시간)
- uses_run_minutes: 반올림 초 S<=0이면 False(대체 속도).
- GREEN: 14+29+30 = 73 OK
