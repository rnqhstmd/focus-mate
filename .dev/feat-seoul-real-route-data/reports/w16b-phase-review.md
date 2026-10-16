# W16b phase-review
## reviewer (opus)
- SPEC FAIL(테스트 공백만): AC-28 남은 거리 1.4km, AC-32 서울 밖 좌표 코스 → 보강 RED
- QUALITY FAIL: Important 1 [동작결함] BR-17 출처 화면 실패 상태가 출처 문구를 숨김 → DataSourceContent.unavailable
- Minor 9: 잘못된 커버리지 주석, retryLoad 후 BR-16 재확인 없음, main.bound 빈 Text 낭독, `.last`, RouteCatalogStore 오류 버림, 오프라인 테스트 한계 주석, nameTooLong 중복 단언, AC-53 visits 중복 계수, AC-45 연속 시나리오
## security-auditor
- CRITICAL 0, HIGH 0, MEDIUM 5, LOW 7
- 결정(오케스트레이터, 설계 확정 사항 근거): 옛 파일 이전 원본 백업 없음 유지(사용자 결정 Q4 "비우고 다시 고르기") → PRD에 여정 소실 명시
- 번들 이름·출처 메타 실데이터 회귀 테스트 추가(MEDIUM 2·3 완화). 스크립트 측 이름 검증·xlsx 합계 상한·MemoryError·음수 인덱스·해시 TOCTOU·옵션 검증 → review-deferred
