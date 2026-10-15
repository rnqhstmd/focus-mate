## Audit Summary
- security: CRITICAL 0, HIGH 0, MEDIUM 11 (2 정리 — .gitignore *.xlsx, README 라이선스 확인일 / 9 유예 — W16b 앱 연결 전 처리)
- reviewer: 1회차 SPEC FAIL(AC-77 요약 집계) → 재현 RED 후 수정, 2회차 SPEC PASS 47/47·동작불변 2건 정리
- 위험 수용: 기준선 전체 테스트 생략, verify UI 테스트 165/277 실행 후 중단(사용자 결정, 실패 0)

## Rulings
- 비현실적 운행시간 대체 — 운행시간이 뜻하는 직선 속도가 3km/h 미만이면(상한 없음 — PRD 픽스처 AC-66이 84km/h) 대체 속도로 계산(scripts/route_data/segments.py). 실데이터 해당 541번 1건. (틀리면: MIN_PLAUSIBLE_SPEED_KMH 상수를 조정하거나 검사를 제거하면 원래 비례 배분으로 돌아감(테스트 test_segments의 R1 케이스 함께 수정).)
- review Minor 12건 유예 · MEDIUM 11건 중 2건 정리, 9건 유예 — quality Minor 12건은 수정하지 않고 유예. security MEDIUM 중 동작 불변이 명백한 2건(.gitignore `*.xlsx`, README 라이선스 확인일·원천 보관 규칙)은 정리. 나머지 9건(압축·XML 크기 상한, DOCTYPE 차단, 지수 정수 DoS, 손 (틀리면: reports/review-deferred.md 목록으로 W16b 태스크화.)
- review 동작 불변 정리 2건 — 2회차 Important [동작불변] 2건(ARS 이상 집계 일원화, 최소 보정 판정 segments 노출)을 세션이 정리. 2회차 Minor 4건은 유예. (틀리면: reports/review-cleanup.md 내역대로 되돌림.)

## Deferred
- [Minor] scripts/data/README.md 합 예외 문구 — 정리됨(최소 보정 노선 예외 명시). 대체 속도 노선 예외는 남음
- [Minor] build_route_data.py uses_run_minutes 중복 호출(DRY)
- [Minor] routes.py 노선번호 숫자 셀 Decimal 정규화 미적용(원문 결합)
- [Minor] routes.py 제외 순서에 따른 "기본정보에 없는 노선" 목록과 unmatched 불일치 가능
- [Minor] routes.py 빈 노선번호 행이 "" 키로 결합 가능
- [Minor] RouteCatalogLoader JSONSerialization 사용(설계는 Decodable), Bool→Int 수용
- [Minor] RouteCatalogLoader bundledURL/bundled 미구현(W16b 24단계)
- [Minor] RouteNumberOrder 유니코드 스칼라 비교(NFD 입력 시 순서 어긋남)
- [Minor] StationSearch 같은 단계 정렬이 원문 대소문자 기준
- [Minor] StationSearchTests options 헬퍼 불필요한 throws
- [Minor] RouteCandidates stopIndices[count-1] → last
- [Minor] .claude/config.json python-scripts 추가(범위 밖 도구 설정)
- [MEDIUM] xlsx.py 압축 해제·XML·행 수 상한 없음(zip bomb)
- [MEDIUM] xlsx.py DOCTYPE/ENTITY 차단 없음
- [MEDIUM] routes.py normalize_integer 지수 표기 거대 정수 DoS(adjusted() 상한)
- [MEDIUM] 손상 xlsx·누락 파트가 traceback(종료 1) — InputError(2)로 변환
- [MEDIUM] build_route_data.py 교체 후 SHA 계산·임시 파일 잔존·fsync 없음, --out이 Resources/ 아래면 경고
- [MEDIUM] RouteCatalog/Loader 값 범위(초·m 상한, 좌표 범위)·leg minutes 상한·중복 id 거부
- [MEDIUM] 출처 문구 "가공·계산" 표기·원천 URL을 source에 추가(W16b 출처 화면 설계)
- [MEDIUM] 라이선스 하드코딩 — 매월 재확인 절차(README에 추가됨, 자동 검증은 없음)
- [MEDIUM] 노선번호 정규화·"(가상)" 판정 기준 설계 문구 차이(구현은 PRD "끝나는" 기준)
- [Minor] routes.py 같은 NODE_ID가 숫자/문자열 ARS 혼재 시 0 채움 건수와 산출 값 출처 불일치 가능(실데이터 숫자 셀 0건)
- [Minor] 요약에 ARS "숫자 셀 건수" 줄 없음(design J절)
- [Minor] test_build_route_data·test_routes 빈 줄·헬퍼 위치 정리
- [Minor] (정리됨) ars_zero_filled 기본값
