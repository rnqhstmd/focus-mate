# T3 RED report
- 테스트 파일: scripts/tests/test_segments.py (20 케이스, 거리 3 / 운행시간 배분 12 / 대체속도 5)
- 실패 확인: cd scripts && python3 -m unittest tests.test_segments -v
- 실패 메시지: ModuleNotFoundError: No module named 'route_data.segments' (Ran 20, FAILED errors=28 — subTest 포함)
- 코드 전문: 위 테스트 파일 참조
- 참조 파일: scripts/tests 디렉터리 목록만 확인. 프로덕션 코드 열람 없음. 거리 리터럴은 독립 하버사인 계산(0.009도=1000.756, 0.018도=2001.511)으로 검산.

## 재현 RED R1 — 비현실적 운행시간
- 추가: ImplausibleRunMinutesTest 9 케이스 (상수 1, 느림 2, 빠름 2, 경계 3.0 신뢰 1, ΣM=0 1, None 1, 0 이하 1). 기존 케이스 수정·삭제 없음.
- 리터럴: 느림 [269,269](1001*3.6/13.4=268.925), 빠름 [5172,5172](5172.41), 경계 [3000,3000].
- 실행: cd scripts && python3 -m unittest tests.test_segments -v → 모듈 부재 ImportError로 전체 실패(기존 20 + 신규 9 = 29). 모듈이 아직 없어 "신규만 실패"는 구분 불가; 기존 구현 후 신규만 실패할 것.
- 참조: 프로덕션 코드 열람 없음.

## 재현 RED R1b — 상한 제거
- R1 신규 케이스만 수정: 상수 케이스 → MIN_PLAUSIBLE_SPEED_KMH == Decimal("3"); "너무 빠름" 2건 삭제 → "빠른 운행시간도 신뢰" 1건([50000,50000], 60분, 공항 → uses True, [1800,1800]). 신규 클래스 케이스 수 9 → 8. 기존 20개 미수정. 프로덕션 코드 열람 없음.

## 재현 RED R2 — 극소 운행시간
- 추가 2케이스(ImplausibleRunMinutesTest 끝): [1001], Decimal("0.001"), "간선" → uses_run_minutes False / allocate [269]. S=0 → ZeroDivisionError 기대. 기존 케이스 미수정, 프로덕션 열람 없음.
