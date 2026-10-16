# Review Deferred (W16 1~11단계) — W16b 앱 연결 전에 처리

## quality Minor (12)
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

## security MEDIUM (9)
- [MEDIUM] xlsx.py 압축 해제·XML·행 수 상한 없음(zip bomb)
- [MEDIUM] xlsx.py DOCTYPE/ENTITY 차단 없음
- [MEDIUM] routes.py normalize_integer 지수 표기 거대 정수 DoS(adjusted() 상한)
- [MEDIUM] 손상 xlsx·누락 파트가 traceback(종료 1) — InputError(2)로 변환
- [MEDIUM] build_route_data.py 교체 후 SHA 계산·임시 파일 잔존·fsync 없음, --out이 Resources/ 아래면 경고
- [MEDIUM] RouteCatalog/Loader 값 범위(초·m 상한, 좌표 범위)·leg minutes 상한·중복 id 거부
- [MEDIUM] 출처 문구 "가공·계산" 표기·원천 URL을 source에 추가(W16b 출처 화면 설계)
- [MEDIUM] 라이선스 하드코딩 — 매월 재확인 절차(README에 추가됨, 자동 검증은 없음)
- [MEDIUM] 노선번호 정규화·"(가상)" 판정 기준 설계 문구 차이(구현은 PRD "끝나는" 기준)

## 태스크 리뷰 유예 Minor
- reports/t1-review.md(5), t2-review.md(7), t3-review.md(8), t4-review.md(7), t5-review.md(6)

## 2회차 Minor (4)
- [Minor] routes.py 같은 NODE_ID가 숫자/문자열 ARS 혼재 시 0 채움 건수와 산출 값 출처 불일치 가능(실데이터 숫자 셀 0건)
- [Minor] 요약에 ARS "숫자 셀 건수" 줄 없음(design J절)
- [Minor] test_build_route_data·test_routes 빈 줄·헬퍼 위치 정리
- [Minor] (정리됨) ars_zero_filled 기본값

## W16b phase-review 유예 (2026-10-16)
- [security MEDIUM] 스크립트·로더의 이름/id 공백·500자 검증(현재는 실데이터 회귀 테스트로 감시) — 월별 갱신 전 처리 권고
- [security MEDIUM] xlsx 합계 압축 해제 상한, sharedStrings iterparse, MemoryError → XlsxError
- [security MEDIUM] OA-15066 라이선스 확인 근거 기록(decisions.md)
- [security LOW] 공유 문자열 음수 인덱스, 입력 해시 TOCTOU, --base-date/--min-join-rate 검증, 같은 NODE_ID 이름·좌표 불일치 보고, StationSnapshot 이름 상한, v5 손상 여정 무알림 폐기(의도)
- [reviewer Minor] retryLoad 복구 후 BR-16 재확인 없음, RouteCatalogStore 로드 오류 진단 로그, 오프라인 테스트 URLProtocol 한계, nameTooLong 중복 단언, AC-53 visits 중복 계수
- [reviewer Minor] main.bound 빈 Text 낭독: AC-42 UI 테스트가 요소 존재를 보므로 유지
